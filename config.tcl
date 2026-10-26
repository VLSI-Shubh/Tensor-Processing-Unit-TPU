# OpenRoad Configuration for 4x4 TPU with Systolic Array
# SKY130A PDK

# Design name
set ::env(DESIGN_NAME) "tpu_core"

# RTL source files (in order of dependency)
set ::env(VERILOG_FILES) "\
  $::env(DESIGN_DIR)/rtl/module/mac.v \
  $::env(DESIGN_DIR)/rtl/module/systolic_array.v \
  $::env(DESIGN_DIR)/rtl/module/sram_dp.v \
  $::env(DESIGN_DIR)/rtl/module/control_unit.v \
  $::env(DESIGN_DIR)/rtl/module/feeder.v \
  $::env(DESIGN_DIR)/rtl/module/collector.v \
  $::env(DESIGN_DIR)/rtl/topmodule/tpu_core.v \
"

# Clock configuration
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) 10.0

# Floorplanning
set ::env(FP_CORE_UTIL) 40
set ::env(PL_TARGET_DENSITY) 0.65

# Placement
set ::env(PL_TIME_DRIVEN) 1

# Routing
set ::env(GRT_LAYERS) "met1 met2 met3 met4 met5"
set ::env(ROUTING_LAYER_ADJUSTMENT) {met1 0.5 met2 0.5}

# Power grid
set ::env(VDD_PIN) "vccd1"
set ::env(GND_PIN) "vssd1"

# Standard cell library
set ::env(SYNTH_STRATEGY) "DELAY 2"
set ::env(SYNTH_MAX_FANOUT) 6
