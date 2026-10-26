# gds

The final layout of `tpu_core`.

```
gds/
└── tpu_core.gds
```

`tpu_core.gds` is the GDSII file produced by the OpenLane flow on SKY130A. The top cell is `tpu_core` and it measures about 159.1 x 169.8 um. A render of it, used in the main README, is in [../asset/gds_layout.png](../asset/gds_layout.png).

The same layout also exists in [../signoff](../signoff), which holds the KLayout and Magic versions, the LEF, the SPICE netlist and the timing models.

## Signoff status

From [../reports/manufacturability.rpt](../reports/manufacturability.rpt):

- Magic DRC: 0 violations
- LVS: clean (1,062 nets on each side)
- Antenna: 0 pin and 0 net violations

## Viewing it

Any layout viewer will open it. With KLayout:
```bash
klayout tpu_core.gds
```

Related: [reports](../reports), [project overview](../README.md).
