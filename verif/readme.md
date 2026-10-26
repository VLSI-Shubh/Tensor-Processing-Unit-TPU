# verif

Testbenches for the modules in [../rtl](../rtl/readme.md). Everything here is plain Verilog run with Icarus Verilog, and each testbench writes a VCD file you can open in GTKWave.

```
verif/functionalVerification/
├── modules/
│   ├── tb_systolic_array.v
│   ├── tb_sram_dp.v
│   └── tb_control_unit.v
└── topmodule/
    └── tb_tpu_core.v
```

A UVM environment was planned for this folder but is not part of the project yet.

## What each testbench does

**tb_systolic_array.v**: holds reset, then feeds two short sequences of A and B values (2x3, 4x5, 6x7, 8x9 and then 5x7, 10x11, 3x4, 2x1) with a reset in between. Look at the accumulators and `y` in the waveform.

**tb_sram_dp.v**: writes 0xAAAA through port A and 0xBBBB through port B, reads each back through the port that wrote it, then does a write on A and a read on B in the same cycle. The two ports run on different clocks (10 ns and 14 ns).

**tb_control_unit.v**: reset, one `start` pulse, then 500 ns of waiting. Use it to follow the state, address and enable signals.

**tb_tpu_core.v**: reset, four values on `a_in`, four values on `b_in`, a `start` pulse and 500 ns of waiting on the whole core.

## Running

From the repository root, `run_sim.sh` compiles and runs all four and moves the VCD files into this folder. The Docker route is described in the [main README](../README.md#9-running-simulation-and-synthesis).

To run just one:
```bash
iverilog -g2012 -o /tmp/tb.out rtl/module/mac.v rtl/module/systolic_array.v verif/functionalVerification/modules/tb_systolic_array.v
vvp /tmp/tb.out
gtkwave tb_systolic_array.vcd
```

The `.vcd` files already in this folder came from earlier runs.

Related: [RTL](../rtl/readme.md), [synthesis](../synth/readme.md), [project overview](../README.md).
