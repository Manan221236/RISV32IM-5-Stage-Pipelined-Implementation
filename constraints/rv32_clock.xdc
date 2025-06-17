# ================================================================
# Corrected RV32IM Pipeline Timing Constraints
# ================================================================

# Create main clock constraint (500MHz as you wanted)
create_clock -period 2.0 -name clk [get_ports clk]

# Set input delays
set_input_delay -clock clk 1.0 [get_ports rst]

# Set output delays for debug ports
set_output_delay -clock clk 0.5 [get_ports debug_*]

# Clock uncertainty (remove the problematic clock transition commands)
set_clock_uncertainty 0.01 [get_clocks clk]

# Optional: Add some timing exceptions if needed
set_false_path -from [get_ports rst]