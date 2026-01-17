(* An example design that takes a series of input values and calculates the range between
   the largest and smallest one. *)

(* We generally open Core and Hardcaml in any source file in a hardware project. For
   design source files specifically, we also open Signal. *)
open! Core
open! Hardcaml
open! Signal

module Div = Hardcaml_circuits.Divide_by_constant.Make (Bits)

let num_bits = 32


let rec pow a = function
  | 0 -> 1
  | 1 -> a
  | n -> 
    let b = pow a (n / 2) in
    b * b * (if n mod 2 = 0 then 1 else a)

let between start end_ x = (x >:. start) &: (x <:. (min end_ ((pow 2 num_bits) - 1)))
let has_num_digits d x = between (pow 10 (d-1)) (pow 10 (d)) x
let divided_by x n = (Hardcaml_circuits.Modulo.unsigned_by_constant (module Signal) x n) ==:. 0

(* Every hardcaml module should have an I and an O record, which define the module
   interface. *)
module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; start : 'a
    ; finish : 'a
    ; data_in : 'a [@bits num_bits]
    ; data_in_valid : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { counter : 'a With_valid.t [@bits num_bits]
    ; invalid_id : 'a }
  [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle
    | Accepting_inputs
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create scope ({ clock; clear; start; finish; data_in; data_in_valid } : _ I.t) : _ O.t
  =
  let spec = Reg_spec.create ~clock ~clear () in
  let open Always in
  let sm =
    (* Note that the state machine defaults to initializing to the first state *)
    State_machine.create (module States) spec
  in

  let _ = scope in
  
  let counter = Variable.reg spec ~width:num_bits in
  let counter_valid = Variable.wire ~default:gnd () in
  let invalid_id = Variable.wire ~default:gnd () in
  compile
    [ sm.switch
        [ ( Idle
          , [ when_
                start
                [ counter <-- zero num_bits
                ; sm.set_next Accepting_inputs
                ]
            ] )
        ; ( Accepting_inputs
          , [ when_
                data_in_valid
                [ when_ (has_num_digits 2 data_in) [ when_ ((divided_by data_in 11)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 3 data_in) [ when_ ((divided_by data_in 111)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 4 data_in) [ when_ ((divided_by data_in 1111) |: (divided_by data_in 101)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 5 data_in) [ when_ ((divided_by data_in 11111)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 6 data_in) [ when_ ((divided_by data_in 111111) |: (divided_by data_in 10101) |: (divided_by data_in 1001)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 7 data_in) [ when_ ((divided_by data_in 1111111)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 8 data_in) [ when_ ((divided_by data_in 11111111) |: (divided_by data_in 1010101) |: (divided_by data_in 10001) ) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 9 data_in) [ when_ ((divided_by data_in 111111111) |: (divided_by data_in 1001001)) [ invalid_id <-- Signal.vdd ] ]
                ; when_ (has_num_digits 10 data_in) [ when_ ((divided_by data_in 1111111111) |: (divided_by data_in 101010101) |: (divided_by data_in 100001)) [ invalid_id <-- Signal.vdd ] ]
                (* ; when_ (has_num_digits 11 data_in) [ when_ ((divided_by data_in 11111111111)) [ invalid_id <-- Signal.vdd ] ] *)
                (* ; when_ (has_num_digits 12 data_in) [ when_ ((divided_by data_in 111111111111) |: (divided_by data_in 10101010101) |: (divided_by data_in 1001001001) |: (divided_by data_in 100010001)) [ invalid_id <-- Signal.vdd ] ] *)
                (* ; when_ (has_num_digits 13 data_in) [ when_ ((divided_by data_in 1111111111111)) [ invalid_id <-- Signal.vdd ] ] *)
                ]
            ; when_ invalid_id.value [ counter <-- counter.value +:. 1]
            ; when_ finish [ sm.set_next Done ]
            ] )
        ; ( Done
          , [ counter_valid <-- vdd
            ; when_ finish [ sm.set_next Accepting_inputs ]
            ] )
        ]
    ];
  (* [.value] is used to get the underlying Signal.t from a Variable.t in the Always DSL. *)
  { counter = { value = counter.value; valid = counter_valid.value }; invalid_id = invalid_id.value }
;;

(* The [hierarchical] wrapper is used to maintain module hierarchy in the generated
   waveforms and (optionally) the generated RTL. *)
let hierarchical scope =
  let module Scoped = Hierarchy.In_scope (I) (O) in
  Scoped.hierarchical ~scope ~name:"day2" create
;;
