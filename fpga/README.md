# FPGA Implementation (TinyFPGA BX)

Status: **in progress**. The wrapper simulates correctly; synthesis and place-and-route on the board have not been run yet.

## Feasibility

The TinyFPGA BX uses a Lattice iCE40 LP8K: 7,680 logic cells, 32 x 4 Kbit block RAMs, a 16 MHz clock and no DSP blocks.

| Item | Estimate for tpu_core | iCE40 LP8K |
|---|---|---|
| Logic cells | about 3,000 to 4,500 | 7,680 |
| Multipliers | 16 x (8x8) built from LUTs | no DSPs, so all in logic |
| Memory | 8 tiny 4 x 8 memories (block RAM or flip-flops) | 32 block RAMs |
| Clock | 16 MHz (62.5 ns period) | 16 MHz |

These are hand estimates, not tool output, so the real numbers come from the first nextpnr report. The design should fit with room to spare. The 8x8 multiplier plus 16-bit saturating add per MAC is the longest path and is expected to meet 16 MHz.

## Files

- `main.v`: top module required by the board. It runs a power-on self-test: it streams a fixed pair of 4x4 matrices through `tpu_core`, checks all 16 results and shows the outcome on the LED (off = running, solid = pass, blinking = fail).
- `pins.pcf`: pin constraints (CLK, LED, USBPU).
- `tb_main.v`: simulation of `main.v` at 16 MHz.

## Simulate

```bash
iverilog -g2005 -o main_sim fpga/main.v fpga/tb_main.v rtl/module/*.v rtl/topmodule/tpu_core.v
vvp main_sim
```

## Build and program (apio)

```bash
apio init --board TinyFPGA-BX
cp rtl/module/*.v rtl/topmodule/tpu_core.v fpga/main.v fpga/pins.pcf .
apio build
apio upload
```

Press the reset button on the board first so the bootloader is active during upload.
