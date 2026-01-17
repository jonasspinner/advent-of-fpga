open! Core
open! Hardcaml
open! Hardcaml_waveterm
open! Hardcaml_test_harness
module Day2 = Advent_of_fpga_project.Day2
module Harness = Cyclesim_harness.Make (Day2.I) (Day2.O)

let ( <--. ) = Bits.( <--. )
(* let sample_input_values = [ 11; 21; 111; 121; 1212; 1111; 11111; 22222; 111111; 1111111; 11111111; 101101102; 123123123; 1111111111 ] *)
let sample_input_values = [ 11; 22; 99; 110; 111; 999; 1010; 1188511885; 222222; 446446; 38593859; 565656; 824824824; 2121212121 ]

let simple_testbench (sim : Harness.Sim.t) =
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  let cycle ?n () = Cyclesim.cycle ?n sim in
  (* Helper function for inputting one value *)
  let feed_input n =
    inputs.data_in <--. n;
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
  List.iter sample_input_values ~f:(fun n -> feed_input n);
  inputs.finish := Bits.vdd;
  cycle ();
  inputs.finish := Bits.gnd;
  cycle ();
  (* Wait for result to become valid *)
  while not (Bits.to_bool !(outputs.counter.valid)) do
    cycle ()
  done;
  let counter = Bits.to_unsigned_int !(outputs.counter.value) in
  print_s [%message "Result" (counter : int)];
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
  Harness.run_advanced ~waves_config ~create:Day2.hierarchical simple_testbench;
  [%expect {| (Result (counter 4174379265)) |}]
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
    ~create:Day2.hierarchical
    ~trace:`All_named
    ~print_waves_after_test:(fun waves ->
      Waveform.print
        ~display_rules
          (* [display_rules] is optional, if not specified, it will print all named
             signals in the design. *)
        ~signals_width:30
        ~display_width:190
        ~wave_width:1
        (* [wave_width] configures how many chars wide each clock cycle is *)
        waves)
    simple_testbench;
  [%expect
    {|
    (Result (counter 4174379265))
    ┌Signals─────────────────────┐┌Waves─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │day2$i$clear                ││────┐                                                                                                                                                         │
    │                            ││    └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────                  │
    │day2$i$clock                ││┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─│
    │                            ││  └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ │
    │                            ││────────────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────────────────────                  │
    │day2$i$data_in              ││ 0          │11     │22     │99     │110    │111    │999    │1010   │118851.│222222 │446446 │385938.│565656 │824824.│2121212121                               │
    │                            ││────────────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────────────────────                  │
    │day2$i$data_in_valid        ││            ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐                                     │
    │                            ││────────────┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───────────────────                  │
    │day2$i$finish               ││                                                                                                                            ┌───┐                             │
    │                            ││────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   └───────────                  │
    │day2$i$start                ││        ┌───┐                                                                                                                                                 │
    │                            ││────────┘   └───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────                  │
    │day2$o$counter$valid        ││                                                                                                                                ┌───────────                  │
    │                            ││────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘                             │
    │                            ││────────────────┬───────┬───────┬───────────────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────────────────                  │
    │day2$o$counter$value        ││ 0              │11     │33     │132            │243    │1242   │2252   │118851.│118873.│118918.│122777.│122834.│205316.│4174379265                           │
    │                            ││────────────────┴───────┴───────┴───────────────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────────────────                  │
    │day2$o$invalid_id           ││            ┌───┐   ┌───┐   ┌───┐           ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐                                     │
    │                            ││────────────┘   └───┘   └───┘   └───────────┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───────────────────                  │
    └────────────────────────────┘└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
    |}]
;;
