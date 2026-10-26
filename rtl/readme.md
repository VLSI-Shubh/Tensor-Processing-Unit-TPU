# rtl

All the Verilog for the TPU core.

```
rtl/
├── module/
│   ├── control_unit.v
│   ├── feeder.v
│   ├── sram_dp.v
│   ├── systolic_array.v
│   ├── mac.v
│   └── collector.v
└── topmodule/
    └── tpu_core.v
```

## tpu_core.v

Top module. It instantiates the control unit, feeder, SRAM, systolic array and collector.

| Port | Dir | Width | Meaning |
|------|-----|-------|---------|
| clk, rst_n | in | 1 | clock and active-low reset |
| a_in, b_in | in | 8 signed | input streams for matrix A and B |
| start | in | 1 | pulse to begin a run |
| relu_mode | in | 1 | zero out negative results |
| valid_in, transpose_mode | in | 1 | reserved for later use |
| c_out | out | 16 signed | result stream |
| c_valid | out | 1 | c_out is valid |
| busy, done | out | 1 | run status |

The SRAM is 16 x 16. The 8-bit feeder output is sign-extended before it is written.

## control_unit.v

FSM with five states: IDLE, LOAD_A, LOAD_B, COMPUTE and READ. LOAD_A and LOAD_B each last four cycles and generate SRAM port A addresses 0 to 3 and 4 to 7. READ lasts four cycles and enables port B reads. The unit also produces `busy`, `done`, the array reset and the load/read phase flag.

## feeder.v

Combinational mux. When bit 3 of the address is 0 it passes `a_in`, otherwise `b_in`.

## sram_dp.v

Parameterized dual-port memory (`depth` and `width`, default 16 x 16). Each port has its own clock, chip select, write enable, read enable and address. Reads are registered and return zero when the port is not reading. There is no handling for both ports writing the same address.

## systolic_array.v

Two 4-stage shift registers hold the A and B operands. A 4x4 array of 16-bit accumulators does `p_reg[i][j] += a_stage[i] * b_stage[j]` on every clock. The output `y` is `p_reg[3][3]`. There is no saturation in this module.

## mac.v

A standalone 8-bit signed multiply-accumulate with saturation to the 16-bit range and pass-through of its operands. It is compiled by the scripts but not instantiated anywhere.

## collector.v

Registers the SRAM port B data and applies ReLU when `relu_mode` is set. `c_valid` follows the SRAM read enable one cycle later.

Related: [simulation and testbenches](../verif/readme.md), [synthesis](../synth/readme.md), [project overview](../README.md).
