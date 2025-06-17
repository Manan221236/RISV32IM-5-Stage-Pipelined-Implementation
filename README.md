# RV32IM 5-Stage Pipeline Processor

A complete implementation of a 5-stage pipelined RISC-V processor supporting the RV32IM instruction set architecture (32-bit base integer instructions with multiplication extension).

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Performance Analysis](#performance-analysis)
- [Getting Started](#getting-started)
- [Synthesis Results](#synthesis-results)
- [Critical Path Analysis](#critical-path-analysis)
- [Usage](#usage)
- [Timing Constraints](#timing-constraints)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

This project implements a fully functional 5-stage pipelined RISC-V processor core that supports:
- **RV32I**: Base 32-bit integer instruction set
- **RV32M**: Integer multiplication and division extension
- **Pipeline**: Fetch → Decode → Execute → Memory → Write-back
- **Hazard Handling**: Complete forwarding logic and hazard detection
- **FPGA Target**: Xilinx Zynq-7000 series FPGAs

## ✨ Features

### Core Features
- ✅ **Complete RV32IM ISA Support**
- ✅ **5-Stage Pipeline** with proper hazard handling
- ✅ **Data Forwarding** to minimize pipeline stalls
- ✅ **Branch Prediction** and jump target calculation
- ✅ **Memory Interface** with load/store operations
- ✅ **Multiplication/Division** using dedicated DSP blocks

### Implementation Features
- 🎯 **FPGA Optimized** for Xilinx 7-series devices
- 🔧 **Modular Design** with clear stage separation
- 📊 **Performance Analysis** with detailed timing reports
- 🧪 **Comprehensive Testing** with self-test ROM
- 📈 **Synthesis Ready** with proper constraints

## 🏗️ Architecture

### Pipeline Stages
```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  FETCH   │───▶│  DECODE  │───▶│ EXECUTE  │───▶│  MEMORY  │───▶│WRITEBACK │
│          │    │          │    │          │    │          │    │          │
│ • PC     │    │ • RegFile│    │ • ALU    │    │ • DMEM   │    │ • Result │
│ • IMEM   │    │ • Decode │    │ • Branch │    │ • Load   │    │ • Mux    │
│ • +4     │    │ • Extend │    │ • Forward│    │ • Store  │    │          │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Key Components
- **ALU**: Full arithmetic and logic operations with DSP-optimized multiplication
- **Register File**: 32×32-bit general-purpose registers
- **Memory System**: Separate instruction and data memory
- **Hazard Unit**: Forward detection and pipeline control
- **Control Unit**: Instruction decode and control signal generation

## 📁 Project Structure

```
RV32IM-Processor/
├── src/
│   ├── Pipeline_Top.v          # Top-level processor module
│   ├── Fetch_Cycle.v           # Instruction fetch stage
│   ├── Decode_Cyle.v           # Instruction decode stage  
│   ├── Execute_Cycle.v         # Execution stage with ALU
│   ├── Memory_Cycle.v          # Memory access stage
│   ├── Writeback_Cycle.v       # Write-back stage
│   ├── ALU.v                   # Arithmetic Logic Unit
│   ├── ALU_Decoder.v           # ALU control logic
│   ├── Control_Unit_Top.v      # Main control unit
│   ├── Main_Decoder.v          # Instruction decoder
│   ├── Register_File.v         # 32×32 register file
│   ├── Data_Memory.v           # Data memory module
│   ├── Instruction_Memory.v    # Instruction memory with test ROM
│   ├── Hazard_unit.v           # Hazard detection and forwarding
│   ├── Branch_Comparator.v     # Branch condition evaluation
│   ├── JALR_Target_Calculator.v # Jump target calculation
│   ├── Sign_Extend.v           # Immediate value extension
│   ├── Mux.v                   # Multiplexer utilities
│   ├── PC.v                    # Program counter
│   └── PC_Adder.v              # PC increment logic
├── constraints/
│   └── rv32_clock.xdc          # Timing constraints
├── sim/
│   └── Pipeline_tb.v           # Testbench
└── README.md
```

## 📊 Performance Analysis

### Target Specifications
- **Target Device**: Xilinx Zynq xc7z010iclg225-1L
- **Target Frequency**: 100 MHz (10 ns period)
- **Actual Performance**: 60.3 MHz (16.7 ns period)

### Resource Utilization
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs     | 3,247| 17,600    | 18.4%       |
| FFs      | 2,079| 35,200    | 5.9%        |
| DSPs     | 16   | 80        | 20.0%       |
| BRAMs    | 2    | 60        | 3.3%        |

### Performance Metrics
- **Maximum Frequency**: 60.3 MHz
- **Pipeline Efficiency**: 5-stage with minimal stalls
- **Instruction Throughput**: 1 instruction/cycle (ideal)
- **Memory Bandwidth**: 32-bit/cycle for loads/stores

## 🚀 Getting Started

### Prerequisites
- **Xilinx Vivado** 2025.1
- **Target Device**: Zynq-7000 series FPGA
- **Optional**: ModelSim/QuestaSim for simulation

### Quick Start
1. **Clone the repository**
   ```bash
   git clone https://github.com/Manan221236/RISV32IM-5-Stage-Pipelined-Implementation
   cd RISV32IM-5-Stage-Pipelined-Implementation
   ```

2. **Open in Vivado**
   ```tcl
   # Create new project
   create_project rv32im_processor ./vivado_project -part xc7z010iclg225-1L
   
   # Add source files
   add_files [glob src/*.v]
   add_files -fileset constrs_1 constraints/rv32_clock.xdc
   
   # Set top module
   set_property top Pipeline_top [current_fileset]
   ```

3. **Run Synthesis and Implementation**
   ```tcl
   # Synthesis
   launch_runs synth_1 -jobs 4
   wait_on_run synth_1
   
   # Implementation  
   launch_runs impl_1 -jobs 4
   wait_on_run impl_1
   
   # Generate bitstream
   launch_runs impl_1 -to_step write_bitstream -jobs 4
   ```

## 🔧 Synthesis Results

### Post-Implementation Results
- **Worst Negative Slack (WNS)**: -14.727 ns
- **Total Negative Slack (TNS)**: -10,187.641 ns  
- **Failing Endpoints**: 7,408 out of 7,759
- **Hold Violations**: Minimal (0.036 ns WHS)

### Key Findings
- **Critical Path**: Through RV32IM multiplication (MULHSU operation)
- **Bottleneck**: 3-stage DSP48E1 cascade for 64-bit multiplication
- **Logic Levels**: 14-18 levels in critical path
- **Routing Delay**: 43% of total path delay

## ⚡ Critical Path Analysis

### Critical Path Breakdown
The critical path runs through the multiplication unit in the Execute stage:

```
Memory/RD_M_r_reg[0] → Load/Store Logic → MULHSU DSP Cascade → Execute/ALU_ResultM_reg[31]
```

### Timing Breakdown
| Component | Delay (ns) | % of Total |
|-----------|------------|------------|
| DSP48E1 Chain (3 stages) | 7.082 | 40.8% |
| CARRY4 Logic | 0.893 | 5.1% |
| LUT Logic | 1.920 | 11.1% |
| Net Routing | 7.446 | 43.0% |
| **Total** | **17.341** | **100%** |

### Optimization Recommendations
1. **Pipeline the Multiplier**: Split DSP cascade across multiple cycles
2. **Reduce Clock Frequency**: Target 50-60 MHz for timing closure
3. **Upgrade Device**: Use faster speed grade (-2 instead of -1L)
4. **Architectural Changes**: Dedicated multiply unit separate from main ALU

## 💻 Usage

### Running Test Programs
The processor includes a built-in self-test ROM with RV32IM instruction validation:

```verilog
// The instruction memory contains a comprehensive test suite
// covering all RV32IM instructions including:
// - Basic arithmetic (ADD, SUB, XOR, OR, AND)
// - Logical operations (SLL, SRL, SRA)  
// - Multiplication (MUL, MULH, MULHSU, MULHU)
// - Division (DIV, DIVU, REM, REMU)
// - Load/Store operations
// - Branch and jump instructions
```

### Debug Outputs
The top module provides debug outputs for monitoring:
```verilog
output wire [31:0] debug_alu_result,  // ALU computation result
output wire [4:0]  debug_reg_addr,    // Target register address  
output wire        debug_reg_write,   // Register write enable
output wire        debug_mem_write    // Memory write enable
```

## ⏱️ Timing Constraints

### Clock Constraints
```tcl
# Primary clock constraint
create_clock -period 2.0 -name clk [get_ports clk]

# Input/Output delays
set_input_delay -clock clk 1.0 [get_ports rst]
set_output_delay -clock clk 0.5 [get_ports debug_*]

# Clock uncertainty
set_clock_uncertainty 0.01 [get_clocks clk]
```

### Performance Targets
- **Conservative**: 50 MHz (meets timing)
- **Optimistic**: 60 MHz (requires optimization)
- **Aggressive**: 100 MHz (requires architectural changes)

## 🛠️ Development

### Testing
Run the testbench to verify functionality:
```bash
# Compile with ModelSim/QuestaSim
vlog src/*.v sim/Pipeline_tb.v
vsim -t ps Pipeline_tb
run -all
```

### Debugging
Use Vivado's integrated logic analyzer (ILA) for hardware debugging:
```tcl
# Add ILA to monitor critical signals
create_debug_core u_ila_0 ila
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets debug_alu_result[*]]
```

---

**⭐ If you found this project helpful, please consider giving it a star!**