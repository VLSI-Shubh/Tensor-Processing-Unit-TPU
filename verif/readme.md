# verif

Testbenches for the modules in [../rtl](../rtl/readme.md). Everything here is plain Verilog run with Icarus Verilog, and each testbench writes a VCD file you can open in GTKWave.

```
verif/functionalVerification/
├── modules/
│   ├── tb_mac.v
│   ├── tb_systolic_array.v
│   ├── tb_sram_dp.v
│   └── tb_control_unit.v
└── topmodule/
    └── tb_tpu_core.v
```

A UVM environment was planned for this folder but is not part of the project yet.

## What each testbench does

**tb_mac.v**: accumulates positive, negative and zero products, checks that the operands are passed on one cycle later, that `clr` and the reset zero the cell, and that the accumulator saturates at both +32767 and -32768. It prints PASS or FAIL.

**tb_systolic_array.v**: applies the row and column stagger itself, then runs an identity case, 20 random matrix pairs back to back and an all `-128` saturation case. All 16 accumulators of every run are compared with a software `A x B`, and the result is printed as PASS or FAIL.

**tb_sram_dp.v**: writes 0xAAAA through port A and 0xBBBB through port B, reads each back through the port that wrote it, then does a write on A and a read on B in the same cycle. The two ports run on different clocks (10 ns and 14 ns).

**tb_control_unit.v**: runs two full sequences with a stalled `valid_in` and checks the write, read and output indices, the number of cycles in each phase, the single `done` pulse and that `busy` falls at the end. Use the waveform to follow the state and enable signals.

**tb_tpu_core.v**: drives the whole core through `start` and `valid_in` and compares all 16 outputs of every run with a software `A x B`. It covers random matrices run back to back, ReLU, transpose, gaps in `valid_in`, saturation in both directions and a `start` pulse while busy, and it checks the `busy`, `done` and `c_valid` behaviour. It ends with a PASS or FAIL line.

## Running

From the repository root, `run_sim.sh` compiles and runs all five and moves the VCD files into this folder. It stops with an error if any testbench prints FAIL. The Docker route is described in the [main README](../README.md#9-running-simulation-and-synthesis).

To run just one:
```bash
iverilog -g2005 -o /tmp/tb.out rtl/module/mac.v rtl/module/systolic_array.v verif/functionalVerification/modules/tb_systolic_array.v
vvp /tmp/tb.out
gtkwave tb_systolic_array.vcd
```

The top-level test needs every RTL file:
```bash
iverilog -g2005 -o /tmp/tb_top.out rtl/module/*.v rtl/topmodule/tpu_core.v verif/functionalVerification/topmodule/tb_tpu_core.v
vvp /tmp/tb_top.out
```

Related: [RTL](../rtl/readme.md), [synthesis](../synth/readme.md), [project overview](../README.md).
