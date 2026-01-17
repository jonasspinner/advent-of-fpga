open! Core
open! Hardcaml
open! Advent_of_fpga_project

let generate_day2_rtl () =
  let module C = Circuit.With_interface (Day2.I) (Day2.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"day2_top" (Day2.hierarchical scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let day2_rtl_command =
  Command.basic
    ~summary:""
    [%map_open.Command
      let () = return () in
      fun () -> generate_day2_rtl ()]
;;

let () =
  Command_unix.run
    (Command.group ~summary:"" [ "range-finder", day2_rtl_command ])
;;
