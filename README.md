# Advent of FPGA

This repo contains the solution to day 2 of advent of code 2025.

Product IDs can be fed sequentially as `data_in` into the circuit.
To determine whether an ID is invalid by a cases for different number of digits in base 10 (10..=99, 100..=999, ...).

When for example a number like 1001001 is multiplied by any 3 digit number n, the result has the digits of this numbers repeated three times.

This can be used to check for repeated parts by checking for divisibility.

* 2 digits:
  * repeated twice = id is divisible by 11
* 3 digits:
  * repeated three times = id is divisible by 111
* 4 digits:
  * repeated twice = id is divisible by 101
  * repeated four times = id is divisible by 1111
* 5 digits:
  * repeated five times = id is divisible by 11111
* 6 digits:
  * repeated twice = id is divisible by 1001
  * repeated three times = id is divisible by 10101
  * repeated six times = id is divisible by 111111
* ...

```
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
```


**The followoing is the original README**


"Hardcaml Template Project"
===========================


This repository provides a simple starter template for getting started with Hardcaml, including:

- An RTL design that accepts a stream of numbers and calculates the range of the values,
  including use of the Always DSL to construct a state-machine
- A testbench, including waveform printing and VCD export using `hardcaml_test_harness`
- A binary to generate RTL for synthesis

## Installing Hardcaml

Hardcaml can be installed with opam. We highly recommend using Hardcaml with OxCaml (a
bleeding-edge OCaml compiler), which includes some Jane Street compiler extensions and
maintains the latest version of Hardcaml; while still maintaining direct compatibility
with existing OCaml code and libraries. Note that when looking at Hardcaml GitHub
repositories, the OxCaml version is in a branch named `with-extensions`.

Install [opam, the OxCaml compiler, and some basic developer
tools](https://oxcaml.org/get-oxcaml/) to get started.

For additional information on setting up the OCaml toolchain and editor support, see [Real
World OCaml](https://dev.realworldocaml.org/install.html).

Once it's set up, make sure you have the current switch selected in your shell:

```
opam switch 5.2.0+ox

eval $(opam env)
```

Then, install the core Hardcaml libraries and some other libraries used in Hardcaml projects:

```
opam install -y hardcaml hardcaml_test_harness hardcaml_waveterm ppx_hardcaml

opam install -y core core_unix ppx_jane rope re dune
```

## Building the Example Project

To build the project, clone this repository and then run the following command, which will
build the generator binary (note the exe prefix is standard for OCaml, even on Unix
systems), as well as building and running all of the tests.

```
dune build bin/generate.exe @runtest
```

To validate that the tests are running, try changing one of the input values in
`test_range_finder.ml` and re-running the tests, to see if the printed values change. Once
`dune` shows a diff in the tests, it can be accepted using the following command (this
will modify the file in-place, so you may need to close and re-open it):

```
dune promote
```

For more on how expect-tests work, see [this blog post](https://blog.janestreet.com/the-joy-of-expect-tests/)

### Viewing Waveforms

Hardcaml has two main ways to view waveforms:

- Exporting to a `.hardcamlwaveform` file, which, can be viewed using the Hardcaml
  terminal waveform viewer.
  - To try this, uncomment the `waves_config` definition that sets the format to
    `Hardcamlwaveform`, then run the tests again. The file should save into `/tmp/` by
    default.
  - To run the viewer, `hardcaml-waveform-viewer show file.hardcamlwaveform` (if the
    command isn't available, make sure you've activated the opam switch in the same shell
    you're trying to run in, see above)
  - Some more details on using the viewer are available [here](
    https://www.janestreet.com/web-app/hardcaml-docs/simulating-circuits/waveterm_interactive_viewer)

- Exporting to a `.vcd` file, which can be viewed using standard tools like
  [GTKWave](https://gtkwave.sourceforge.net/) and [Surfer](https://surfer-project.org/)
  - To try this, uncomment the `waves_config` definition that sets the format to
    `Vcd`, then run the tests again. The file should save into `/tmp/` by default.

For small tests, waveforms can also be printed inline (as shown in
`test_range_finder.ml`), which is useful for documenting and visualizing design behavior,
albeit not as useful for interactive debugging.

### Generating RTL

To generate RTL, run the compiled `generate.exe` binary, which will print the Verilog source:
```
bin/generate.exe range-finder
```

Note that dune should automatically copy the compiled binary into your source directory,
but if it does not, all build products can be found in `_build/default/`.

## Resources

- If you would like to run dune continuously to re-run tests every time a file is edited:

```
dune build --watch --terminal-persistence=clear-on-rebuild-and-flush-history bin/generate.exe @runtest
```

- Hardcaml documentation and further tutorials [can be found
  here](https://www.janestreet.com/web-app/hardcaml-docs/introduction/why/)

- Real World OCaml is a [free online book](https://dev.realworldocaml.org/toc.html) for learning OCaml

- The OCaml LSP and autoformatter can be used with VSCode, Emacs, and Vim, [see
  instructions here](https://dev.realworldocaml.org/install.html#editor-setup)
