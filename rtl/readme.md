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

Top module. It instantiates the control unit, feeder, systolic array and collector. The SRAM banks sit inside the feeder and the MAC cells sit inside the systolic array.

| Port | Dir | Width | Meaning |
|------|-----|-------|---------|
| clk, rst_n | in | 1 | clock and active-low reset |
| a_in, b_in | in | 8 signed | next element of matrix A and B, row-major |
| start | in | 1 | pulse to begin a run |
| valid_in | in | 1 | qualifies an `a_in`/`b_in` beat during the load phase |
| relu_mode | in | 1 | zero out negative results |
| transpose_mode | in | 1 | stream the result transposed |
| c_out | out | 16 signed | result stream |
| c_valid | out | 1 | c_out is valid |
| busy, done | out | 1 | run status, `done` is a one-cycle pulse with the last result |

A run goes like this: pulse `start`, send 16 beats with `valid_in` high (beat `n` carries `A[n/4][n%4]` on `a_in` and `B[n/4][n%4]` on `b_in`), then wait while the core computes and streams out the 16 elements of C in row-major order. `relu_mode` and `transpose_mode` should be held steady from `start` until `done`.

## control_unit.v

FSM with five states: IDLE, LOAD, COMPUTE, READ and FIN. LOAD waits for 16 `valid_in` beats and counts them as the write index. COMPUTE lasts 14 cycles and enables the operand reads for the first seven of them. READ lasts 16 cycles and counts the output index. FIN lasts one cycle and is where `done` pulses. `busy` is high in every state except IDLE, and the array is cleared during LOAD so each run starts from zero.

## feeder.v

Eight 4-word, 8-bit dual-port SRAM banks: one per row of A and one per column of B. During LOAD, `A[r][k]` is written to bank `r` at address `k`, and `B[k][c]` is written to bank `c` at address `k`. During COMPUTE, bank `n` is read at address `t - n` on cycle `t` while that address is between 0 and 3, and returns zero otherwise. That stagger is what lines the operands up for the systolic array: row `i` of A and column `j` of B arrive `i` and `j` cycles late, so `A[i][k]` and `B[k][j]` meet in cell (i, j) on the same cycle. The outputs are the packed buses `a_row` and `b_col`.

## sram_dp.v

Parameterized dual-port memory (`depth` and `width`, default 16 x 16). Each port has its own clock, chip select, write enable, read enable and address. Reads are registered and return zero when the port is not reading. There is no handling for both ports writing the same address. The feeder uses it at 4 x 8, with port A for writes and port B for reads.

## systolic_array.v

A 4x4 generate grid of `mac` cells. `a_row` feeds the left edge and `b_col` feeds the top edge. Each cell passes its A input to the right and its B input down, one cycle later, and accumulates `C[i][j]` for its own position. All 16 accumulators are exposed on `c_flat`, with `C[i][j]` at bits `[16*(4*i+j) +: 16]`. The inputs are expected to be skewed already, which the feeder takes care of.

## mac.v

8-bit signed multiply-accumulate. Every cycle it does `acc <= acc + a*b`, saturating to the 16-bit range, and it passes its two operands on to the next cell through `a_out` and `b_out`. The sum is formed in 17 bits and clamps to -32768 or 32767 on overflow. `clr` clears the accumulator synchronously between runs, and `rst_n` is the asynchronous reset.

## collector.v

Selects one of the 16 results from `c_flat` by index (row-major, or transposed when `transpose_mode` is set), applies ReLU when `relu_mode` is set, and registers the result. `c_valid` is registered from the output enable, so it lines up with `c_out`.

Related: [simulation and testbenches](../verif/readme.md), [synthesis](../synth/readme.md), [project overview](../README.md).
