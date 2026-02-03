open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness
module Day2_range_sum = Advent_of_fpga_project.Day2_range_sum
module Harness = Cyclesim_harness.Make (Day2_range_sum.I) (Day2_range_sum.O)

let ( <--. ) = Bits.( <--. )

let sample_input_values = [
  11,22;
  95,115;
  998,1012;
  1188511880,1188511890;
  222220,222224;
  1698522,1698528;
  446443,446449;
  38593856,38593862;
  565653,565659;
  824824821,824824827;
  2121212118,2121212124;
]

let simple_testbench (sim : Harness.Sim.t) =
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in
  (* Helper function for inputting one value *)
  let feed_input start _end =
    inputs.data_in_start <--. min start 4294967295;
    inputs.data_in_end <--. min _end 4294967295;
    inputs.data_in_valid := Bits.vdd;
    cycle ();
    inputs.data_in_valid := Bits.gnd;
    cycle ()
  in
  (* Reset the design *)
  inputs.clear := Bits.vdd;
  cycle ();
  inputs.clear := Bits.gnd;
  cycle ();
  (* Pulse the start signal *)
  inputs.start := Bits.vdd;
  cycle ();
  inputs.start := Bits.gnd;
  (* Input some data *)
  List.iter sample_input_values ~f:(fun (start, _end) -> feed_input start _end);
  inputs.finish := Bits.vdd;
  cycle ();
  inputs.finish := Bits.gnd;
  cycle ();
  let sum = Bits.to_unsigned_int !(outputs.sum) in
  print_s [%message "Result" (sum : int)];
  (* Show in the waveform that [valid] stays high. *)
  cycle ~n:2 ()
;;

(* The [waves_config] argument to [Harness.run] determines where and how to save waveforms
   for viewing later with a waveform viewer. The commented examples below show how to save
   a waveterm file or a VCD file. *)
let waves_config = Waves_config.no_waves

(* let waves_config = *)
(*   Waves_config.to_directory "/tmp/" *)
(* |> Waves_config.as_wavefile_format ~format:Hardcamlwaveform *)
(* ;; *)

(* let waves_config = *)
(*   Waves_config.to_directory "/tmp/" *)
(* |> Waves_config.as_wavefile_format ~format:Vcd *)
(* ;; *)

let%expect_test "Simple test, optionally saving waveforms to disk" =
  Harness.run_advanced ~waves_config ~create:Day2_range_sum.hierarchical simple_testbench;
  [%expect {| (Result (sum 4174379265)) |}]
;;

let%expect_test "Simple test with printing waveforms directly" =
  (* For simple tests, we can print the waveforms directly in an expect-test (and use the
     command [dune promote] to update it after the tests run). This is useful for quickly
     visualizing or documenting a simple circuit, but limits the amount of data that can
     be shown. *)
  let display_rules =
    [ Display_rule.port_name_matches
        ~wave_format:(Bit_or Unsigned_int)
        (Re.Glob.glob "day2*" |> Re.compile)
    ]
  in
  Harness.run_advanced
    ~create:Day2_range_sum.hierarchical
    ~trace:`All_named
    ~print_waves_after_test:(fun waves ->
      Waveform.print
        ~display_rules
          (* [display_rules] is optional, if not specified, it will print all named
             signals in the design. *)
        ~signals_width:30
        ~display_width:140
        ~wave_width:1
        (* [wave_width] configures how many chars wide each clock cycle is *)
        waves)
    simple_testbench;
  [%expect
    {|
    (Result (sum 4174379265))
    ┌Signals─────────────────────┐┌Waves───────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │day2$i$clear                ││────┐                                                                                                       │
    │                            ││    └───────────────────────────────────────────────────────────────────────────────────────────────────────│
    │day2$i$clock                ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ │
    │                            ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─│
    │                            ││────────────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────────────│
    │day2$i$data_in_end          ││ 0          │22     │115    │1012   │118851.│222224 │1698528│446449 │385938.│565659 │824824.│2121212124     │
    │                            ││────────────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────────────│
    │                            ││────────────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────────────│
    │day2$i$data_in_start        ││ 0          │11     │95     │998    │118851.│222220 │1698522│446443 │385938.│565653 │824824.│2121212118     │
    │                            ││────────────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────────────│
    │day2$i$data_in_valid        ││            ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐           │
    │                            ││────────────┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───────────│
    │day2$i$finish               ││                                                                                                    ┌───┐   │
    │                            ││────────────────────────────────────────────────────────────────────────────────────────────────────┘   └───│
    │day2$i$start                ││        ┌───┐                                                                                               │
    │                            ││────────┘   └───────────────────────────────────────────────────────────────────────────────────────────────│
    │                            ││────────────────┬───────┬───────┬───────┬───────┬───────────────┬───────┬───────┬───────┬───────┬───────────│
    │day2$o$sum                  ││ 0              │33     │243    │2252   │118851.│1188736359     │118918.│122777.│122834.│205316.│4174379265 │
    │                            ││────────────────┴───────┴───────┴───────┴───────┴───────────────┴───────┴───────┴───────┴───────┴───────────│
    └────────────────────────────┘└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    |}]
;;
