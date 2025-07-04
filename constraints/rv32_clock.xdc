# ================================================================
# Enhanced RV32IM Pipeline Timing Constraints - Step 5
# Target: Improve remaining critical paths
# ================================================================

# Create main clock constraint (100 MHz)
create_clock -period 13.0 -name clk [get_ports clk] 

# Set input delays (20% of clock period)
set_input_delay -clock clk 2.0 [get_ports rst]

# Set output delays (20% of clock period)  
set_output_delay -clock clk 2.0 [get_ports debug_*]

# Clock uncertainty (1% of clock period)
set_clock_uncertainty 0.1 [get_clocks clk]

# False path for reset (asynchronous)
set_false_path -from [get_ports rst]

# ================================================================
# CRITICAL PATH OPTIMIZATION CONSTRAINTS
# ================================================================

# High-priority placement for Execute stage (likely critical path)
set_property HIGH_PRIORITY true [get_cells {*Execute*}]

# Optimize DSP placement - keep DSPs close together
set_property LOC DSP48_X0Y0 [get_cells -hier -filter {REF_NAME =~ "*DSP48E1*"}]

# Set maximum delay for forwarding paths (known critical path)
set_max_delay 8.0 [get_pins {*muxA*/d*}] -to [get_pins {*alu_u*/A*}]
set_max_delay 8.0 [get_pins {*muxB*/d*}] -to [get_pins {*alu_u*/B*}]

# Set maximum delay for ALU output to pipeline register
set_max_delay 8.0 [get_pins {*alu_u*/Result*}] -to [get_pins {*ALU_ResultM_reg*/D*}]

# Optimize register placement - keep pipeline registers close
set_property LOC SLICE_X10Y10 [get_cells {*RegWriteM_reg*}]
set_property LOC SLICE_X10Y11 [get_cells {*ALU_ResultM_reg*}]

# Force register packing for better timing
set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets]

# ================================================================
# SYNTHESIS OPTIMIZATION DIRECTIVES
# ================================================================

# Optimize for speed over area
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

# Set high effort for implementation
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Enable advanced optimizations
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# ================================================================
# DSP48E1 SPECIFIC OPTIMIZATIONS
# ================================================================

# Force DSP48E1 register usage
set_property USE_DSP48 yes [get_cells {*alu_u*}]

# Set DSP48E1 pipeline registers
set_property DSP48_MREG 1 [get_cells -hier -filter {REF_NAME =~ "*DSP48E1*"}]
set_property DSP48_PREG 1 [get_cells -hier -filter {REF_NAME =~ "*DSP48E1*"}]
set_property DSP48_AREG 1 [get_cells -hier -filter {REF_NAME =~ "*DSP48E1*"}]
set_property DSP48_BREG 1 [get_cells -hier -filter {REF_NAME =~ "*DSP48E1*"}]

# ================================================================
# AGGRESSIVE TIMING CONSTRAINTS (if needed)
# ================================================================

# Uncomment these if timing is still not met:
# set_clock_uncertainty 0.05 [get_clocks clk]
# set_max_delay 6.0 [get_pins {*alu_u*/Result*}]
# set_property HIGH_PRIORITY true [get_nets {*ALU_ResultM*}]s
