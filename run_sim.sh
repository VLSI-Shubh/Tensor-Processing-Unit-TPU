#!/usr/bin/env bash

set -e

# ===================================================
# TPU 4x4 Systolic Array - Simulation & Synthesis
# ===================================================

# Paths
RTL_MODULES="rtl/module/mac.v \
             rtl/module/systolic_array.v \
             rtl/module/sram_dp.v \
             rtl/module/control_unit.v \
             rtl/module/feeder.v \
             rtl/module/collector.v"

RTL_TOP="rtl/topmodule/tpu_core.v"

TB_SYSTOLIC="verif/functionalVerification/modules/tb_systolic_array.v"
TB_SRAM="verif/functionalVerification/modules/tb_sram_dp.v"
TB_CONTROL="verif/functionalVerification/modules/tb_control_unit.v"
TB_TPU="verif/functionalVerification/topmodule/tb_tpu_core.v"

# Output directories
mkdir -p simulation_output
mkdir -p synth

# ===================================================
# 1. Functional Simulations (iverilog + vvp)
# ===================================================

echo "=================================================="
echo "[1] Simulating Systolic Array..."
echo "=================================================="
iverilog -g2012 -o simulation_output/tb_systolic_array.out \
  rtl/module/mac.v \
  rtl/module/systolic_array.v \
  "$TB_SYSTOLIC"
vvp simulation_output/tb_systolic_array.out
mv tb_systolic_array.vcd verif/functionalVerification/modules/ 2>/dev/null
echo "VCD generated: verif/functionalVerification/modules/tb_systolic_array.vcd"

echo ""
echo "=================================================="
echo "[2] Simulating SRAM (Dual Port)..."
echo "=================================================="
iverilog -g2012 -o simulation_output/tb_sram_dp.out \
  rtl/module/sram_dp.v \
  "$TB_SRAM"
vvp simulation_output/tb_sram_dp.out
mv tb_sram_dp.vcd verif/functionalVerification/modules/ 2>/dev/null
echo "VCD generated: verif/functionalVerification/modules/tb_sram_dp.vcd"

echo ""
echo "=================================================="
echo "[3] Simulating Control Unit..."
echo "=================================================="
iverilog -g2012 -o simulation_output/tb_control_unit.out \
  rtl/module/control_unit.v \
  "$TB_CONTROL"
vvp simulation_output/tb_control_unit.out
mv tb_control_unit.vcd verif/functionalVerification/modules/ 2>/dev/null
echo "VCD generated: verif/functionalVerification/modules/tb_control_unit.vcd"

echo ""
echo "=================================================="
echo "[4] Simulating Complete TPU Core..."
echo "=================================================="
iverilog -g2012 -o simulation_output/tb_tpu_core.out \
  $RTL_MODULES \
  "$RTL_TOP" \
  "$TB_TPU"
vvp simulation_output/tb_tpu_core.out
mv tb_tpu_core.vcd verif/functionalVerification/topmodule/ 2>/dev/null
echo "VCD generated: verif/functionalVerification/topmodule/tb_tpu_core.vcd"

# ===================================================
# 2. Logic Synthesis (Yosys)
# ===================================================

echo ""
echo "=================================================="
echo "[5] Running Yosys Synthesis..."
echo "=================================================="

cat > synth/tpu_synth.ys <<'EOF'
# Read all RTL files
read_verilog rtl/module/mac.v
read_verilog rtl/module/systolic_array.v
read_verilog rtl/module/sram_dp.v
read_verilog rtl/module/control_unit.v
read_verilog rtl/module/feeder.v
read_verilog rtl/module/collector.v
read_verilog rtl/topmodule/tpu_core.v

# Hierarchy and clean up
hierarchy -top tpu_core
proc; opt
fsm; opt
memory; opt

# Optimize for area
opt -full

# Technology mapping (generic Verilog)
abc -g cmos

# Create netlist
clean

# Statistics
stat

# Write synthesized Verilog
write_verilog -attr2comment synth/tpu_synth.v
EOF

yosys -s synth/tpu_synth.ys

echo ""
echo "=================================================="
echo "[6] Creating Block Diagram (Yosys show)..."
echo "=================================================="

cat > synth/tpu_show.ys <<'EOF'
read_verilog rtl/module/mac.v
read_verilog rtl/module/systolic_array.v
read_verilog rtl/module/sram_dp.v
read_verilog rtl/module/control_unit.v
read_verilog rtl/module/feeder.v
read_verilog rtl/module/collector.v
read_verilog rtl/topmodule/tpu_core.v

hierarchy -top tpu_core
proc; opt
select -module tpu_core
show -format svg -prefix synth/tpu_core
EOF

yosys -s synth/tpu_show.ys

echo ""
echo "=================================================="
echo "SIMULATION & SYNTHESIS COMPLETE"
echo "=================================================="
echo ""
echo "Simulation VCD files (open with GTKWave):"
echo "  - verif/functionalVerification/modules/tb_systolic_array.vcd"
echo "  - verif/functionalVerification/modules/tb_sram_dp.vcd"
echo "  - verif/functionalVerification/modules/tb_control_unit.vcd"
echo "  - verif/functionalVerification/topmodule/tb_tpu_core.vcd"
echo ""
echo "Synthesis outputs:"
echo "  - synth/tpu_synth.v (Verilog netlist)"
echo "  - synth/tpu_core.svg (Block diagram)"
echo ""
echo "Next: Run OpenLane flow in Docker for physical design"
echo "  export OPENLANE_ROOT=/path/to/OpenLane"
echo "  export PDK_ROOT=/path/to/pdks"
echo "  cd \$OPENLANE_ROOT && make mount"
echo "  ./flow.tcl -design /path/to/TPU -tag tpu_v1 -overwrite"
