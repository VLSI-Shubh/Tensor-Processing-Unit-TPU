# synth

Yosys scripts and the files they produce. This is the quick, tool-independent synthesis used to check the RTL and get a netlist and a block diagram. The synthesis used for the physical design ran inside OpenLane, and its reports are in [../reports/synthesis](../reports/synthesis).

```
synth/
├── tpu_synth.ys
├── tpu_show.ys
├── tpu_synth.v
├── tpu_core.svg
└── tpu_core.dot
```

## Scripts

**tpu_synth.ys** reads all the RTL, sets `tpu_core` as the top, runs `proc`, `fsm` and `memory` passes and optimizes. It then maps to a generic gate set with `abc -g cmos`, prints statistics and writes `tpu_synth.v`.

**tpu_show.ys** reads the same RTL, elaborates it and uses Yosys `show` to draw the top module as `tpu_core.svg` and `tpu_core.dot`.

## Outputs

- `tpu_synth.v` is the gate-level netlist.
- `tpu_core.svg` is the block diagram, also used in the main README.
- `tpu_core.dot` is the Graphviz source for the same diagram.

## How to run

`run_sim.sh` in the repository root runs both scripts after the simulations, and it rewrites the two `.ys` files each time. To run Yosys on its own from the repository root:

```bash
yosys -s synth/tpu_synth.ys
yosys -s synth/tpu_show.ys
```

The easiest setup is the Docker image described in the [main README](../README.md#9-running-simulation-and-synthesis).

## Notes

The `abc -g cmos` option needs a reasonably recent Yosys. Version 0.9, which is what `apt` installs on Ubuntu 22.04, rejects it.

Related: [RTL](../rtl/readme.md), [verification](../verif/readme.md), [project overview](../README.md).
