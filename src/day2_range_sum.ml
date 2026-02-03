open! Core
open! Hardcaml
open! Signal

module Div = Hardcaml_circuits.Divide_by_constant.Make (Signal)

let num_bits = 32


let rec pow a = function
  | 0 -> 1
  | 1 -> a
  | n -> 
    let b = pow a (n / 2) in
    b * b * (if n mod 2 = 0 then 1 else a)

let max_number = (pow 2 num_bits) - 1

let signal_min (a: Signal.t) (b: int) = Signal.mux2 (a <:. b) a (Signal.of_int_trunc ~width:(width a) b)
let signal_max (a: Signal.t) (b: int) = Signal.mux2 (a >:. b) a (Signal.of_int_trunc ~width:(width a) b)

let sum_multiples_up_to n q =
  let qb = Bigint.of_int q in
  let qs = Signal.of_int_trunc q ~width:(num_bits_to_represent q) in

  (* the sum of all multiples of `q` up to `n` is given by
  q * m * (m+1) / 2, where m = floor(n/q) *)
  let num_multiples = Div.divide ~divisor:qb n in
  srl (num_multiples *: ((ue num_multiples) +:. 1) *: qs) ~by:1

let sum_multiples_in_range start _end q d_digit_width = 
  let range_is_empty = _end <: start in

  (* `sum_in_range` value is only used, when `width _end <= d_digit_width`.
  Restricting `start` and `_end` to this width greatly reduces the width of
  `num_multiples` in `sum_multiples_up_to` and consequently its resulting `sum`. *)
  let start = uresize ~width:d_digit_width start in
  let _end = uresize ~width:d_digit_width _end in

  let sum_in_range = (sum_multiples_up_to _end q) -: (sum_multiples_up_to (start -:. 1) q) in

  Signal.mux2 range_is_empty (zero (width sum_in_range)) sum_in_range

let sum_invalid_ids start _end : Signal.t =
  (* An ID is invalid if consists of repeating parts.
  For example: 123123, 121212, or 111111.
  For a known number of digits, this can be checked by the divisibility with
  right numbers. For example for a six digit number, we can check the patterns
  (abc)^2, (ab)^3, and (a)^6 by divisiblity with 1001, 10101, and 111111 respectively.
  For the intersection of start..=end and 100000..=999999 we count the IDs that are
  multiples of 1001, 10101, and 111111. The pattern (a)^6 is double counted by the
  other two patterns and is subtracted instead of added to get the correct count.
  Another step is to sum up all invalid IDs instead of counting them. *)
  let table = [
    2,[1,11];
    3,[1,111];
    4,[1,101];
    5,[1,11111];
    6,[1,1001; 1,10101; -1,111111];
    7,[1,1111111];
    8,[1,10001];
    9,[1,1001001];
    10,[1,100001; 1,101010101; -1,1111111111];
    11,[1,11111111111];
    12,[1,100010001; 1,1001001001; -1,111111111111];
    13,[1,1111111111111];
  ] in

  (* 32 bit number are at most 10 digits wide. *)
  let table_too_small = match List.nth table ((List.length table) - 1) with
    Some (max_d, _) -> (pow 10 max_d) < max_number | None -> true
  in
  if table_too_small then raise_s [%message "[sum_invalid_ids] num_bits not covered by table"];

  let counts = List.map table ~f:(fun (d, l) ->
    if pow 10 (d-1) > max_number then [] else
    let smallest_d_digit_number, largest_d_digit_number = min (pow 10 (d-1)) max_number, min ((pow 10 d)-1) max_number in
    
    let d_digit_width = num_bits_to_represent largest_d_digit_number in

    (* Intersection of start..=end and 10^(d-1)..=10^d.
    If end > start, then the range is regarded as empty and the sum of multiples
    in that range is returned as zero. *)
    let start = signal_max start smallest_d_digit_number in
    let _end = signal_min _end largest_d_digit_number in
    List.map l ~f:(fun (m, q) -> 
      let count = sum_multiples_in_range start _end q d_digit_width in
      if m = 1 then count else negate count
    )
  ) in

  (* Resize to common bit width to be able to sum them. *)
  let counts = resize_list ~resize:(fun l w -> sresize l ~width:w) (List.concat counts) in

  let sum = tree ~arity:2 counts ~f:(reduce ~f:(+:)) in

  (zero (2 * num_bits - width sum)) @: sum


module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; finish : 'a
    ; data_in_start : 'a [@bits num_bits]
    ; data_in_end : 'a [@bits num_bits]
    ; data_in_valid : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { sum : 'a [@bits 2 * num_bits] }
  [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle
    | Accepting_inputs
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create scope ({ clock; clear; start; finish; data_in_start; data_in_end; data_in_valid } : _ I.t) : _ O.t
  =
  let spec = Reg_spec.create ~clock ~clear () in
  let open Always in
  let sm =
    (* Note that the state machine defaults to initializing to the first state *)
    State_machine.create (module States) spec
  in

  let _ = scope in
  
  let sum = Variable.reg spec ~width:(2 * num_bits) in
  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                start
                [ sum <-- zero (2 * num_bits)
                ; sm.set_next Accepting_inputs
                ]
            ] )
        ; ( Accepting_inputs
          , [ when_ data_in_valid [sum <-- sum.value +: sum_invalid_ids data_in_start data_in_end ]
            ; when_ finish [ sm.set_next Done ]
            ] )
        ; ( Done
          , [ when_ finish [ sm.set_next Accepting_inputs ]
            ] )
        ]
    ];
  { sum = sum.value }
;;

(* The [hierarchical] wrapper is used to maintain module hierarchy in the generated
   waveforms and (optionally) the generated RTL. *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"day2" create
;;
