// ================================================================
//  Pipeline_top.v   -   RV32IM 5-stage pipeline (correct forwarding)
//  Modified with debug outputs to prevent synthesis optimization
// ================================================================

module Pipeline_top (input  wire clk,
                     input  wire rst,
                     // Debug outputs to prevent optimization
                     output wire [31:0] debug_alu_result,  // 32 pins
                     output wire [4:0]  debug_reg_addr,    // 5 pins  
                     output wire        debug_reg_write,   // 1 pin
                     output wire        debug_mem_write);  

    // -----------------------------------------------------------------
    //  Inter-stage wires
    // -----------------------------------------------------------------
    /* Fetch → Decode */
    wire [31:0] InstrD, PCD, PCPlus4D;

    /* Decode → Execute */
    wire        RegWriteE, ALUSrcE, MemWriteE, BranchE, JumpE;
    wire [1:0]  ResultSrcE;
    wire [4:0]  ALUControlE, RD_E, RS1_E, RS2_E;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E;
    wire [2:0]  LoadTypeE, StoreTypeE, funct3_E;

    /* Execute → Memory */
    wire        PCSrcE;
    wire [31:0] PCTargetE, JALR_TargetE;
    wire        RegWriteM, MemWriteM;
    wire [1:0]  ResultSrcM;
    wire [31:0] PCPlus4M, WriteDataM, ALU_ResultM;   // ← EX/MEM value
    wire [4:0]  RD_M;
    wire [2:0]  LoadTypeM, StoreTypeM;
    wire        is_jalr_E;

    /* Memory → Write-back */
    wire        RegWriteW;
    wire [1:0]  ResultSrcW;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW;
    wire [4:0]  RDW;
    wire [2:0]  LoadTypeW, StoreTypeW;

    /* Final WB data (goes back to Decode & Execute) */
    wire [31:0] ResultW;

    /* Forwarding selections */
    wire [1:0]  ForwardAE, ForwardBE;

    // ================================================================
    //  Stage 0 - FETCH
    // ================================================================
    fetch_cycle Fetch (
        .clk          (clk),
        .rst          (rst),
        .PCSrcE       (PCSrcE),
        .PCTargetE    (PCTargetE),
        .JALR_TargetE (JALR_TargetE),
        .JumpE        (JumpE),
        .is_jalr_E    (is_jalr_E),
        .InstrD       (InstrD),
        .PCD          (PCD),
        .PCPlus4D     (PCPlus4D)
    );

    // ================================================================
    //  Stage 1 - DECODE
    // ================================================================
    decode_cycle Decode (
        .clk          (clk),
        .rst          (rst),
        .InstrD       (InstrD),
        .PCD          (PCD),
        .PCPlus4D     (PCPlus4D),
        .RegWriteW    (RegWriteW),
        .RDW          (RDW),
        .ResultW      (ResultW),
        .RegWriteE    (RegWriteE),
        .ALUSrcE      (ALUSrcE),
        .MemWriteE    (MemWriteE),
        .ResultSrcE   (ResultSrcE),
        .BranchE      (BranchE),
        .ALUControlE  (ALUControlE),
        .RD1_E        (RD1_E),
        .RD2_E        (RD2_E),
        .Imm_Ext_E    (Imm_Ext_E),
        .RD_E         (RD_E),
        .PCE          (PCE),
        .PCPlus4E     (PCPlus4E),
        .RS1_E        (RS1_E),
        .RS2_E        (RS2_E),
        .JumpE        (JumpE),
        .LoadTypeE    (LoadTypeE),
        .StoreTypeE   (StoreTypeE),
        .funct3_E     (funct3_E)
    );

    // ================================================================
    //  Stage 2 - EXECUTE  (forwarding uses EX/MEM value)
    // ================================================================
    execute_cycle Execute (
        .clk             (clk),
        .rst             (rst),
        .RegWriteE       (RegWriteE),
        .ALUSrcE         (ALUSrcE),
        .MemWriteE       (MemWriteE),
        .ResultSrcE      (ResultSrcE),
        .BranchE         (BranchE),
        .JumpE           (JumpE),
        .ALUControlE     (ALUControlE),
        .RD1_E           (RD1_E),
        .RD2_E           (RD2_E),
        .Imm_Ext_E       (Imm_Ext_E),
        .RD_E            (RD_E),
        .PCE             (PCE),
        .PCPlus4E        (PCPlus4E),
        .ForwardA_E      (ForwardAE),
        .ForwardB_E      (ForwardBE),
        .ALU_ResultMEM   (ALU_ResultM),   // ← correct one-cycle-old value
        .ResultW         (ResultW),
        .LoadTypeE       (LoadTypeE),
        .StoreTypeE      (StoreTypeE),
        .funct3_E        (funct3_E),
        .PCTargetE       (PCTargetE),
        .JALR_TargetE    (JALR_TargetE),
        .is_jalr_E       (is_jalr_E),
        .PCSrcE          (PCSrcE),
        .RegWriteM       (RegWriteM),
        .MemWriteM       (MemWriteM),
        .ResultSrcM      (ResultSrcM),
        .RD_M            (RD_M),
        .PCPlus4M        (PCPlus4M),
        .WriteDataM      (WriteDataM),
        .ALU_ResultM     (ALU_ResultM),   // to MEM stage and to hazard unit
        .LoadTypeM       (LoadTypeM),
        .StoreTypeM      (StoreTypeM)
    );

    // ================================================================
    //  Stage 3 - MEMORY
    // ================================================================
    memory_cycle Memory (
        .clk           (clk),
        .rst           (rst),
        .RegWriteM     (RegWriteM),
        .MemWriteM     (MemWriteM),
        .ResultSrcM    (ResultSrcM),
        .RD_M          (RD_M),
        .PCPlus4M      (PCPlus4M),
        .WriteDataM    (WriteDataM),
        .ALU_ResultM   (ALU_ResultM),
        .LoadTypeM     (LoadTypeM),
        .StoreTypeM    (StoreTypeM),
        .RegWriteW     (RegWriteW),
        .ResultSrcW    (ResultSrcW),
        .RD_W          (RDW),
        .PCPlus4W      (PCPlus4W),
        .ALU_ResultW   (ALU_ResultW),
        .ReadDataW     (ReadDataW),
        .LoadTypeW     (LoadTypeW),
        .StoreTypeW    (StoreTypeW)
    );

    // ================================================================
    //  Stage 4 - WRITE-BACK
    // ================================================================
    writeback_cycle WriteBack (
        .clk         (clk),
        .rst         (rst),
        .ResultSrcW  (ResultSrcW),
        .PCPlus4W    (PCPlus4W),
        .ALU_ResultW (ALU_ResultW),
        .ReadDataW   (ReadDataW),
        .ResultW     (ResultW)
    );

    // ================================================================
    //  Hazard / Forwarding Unit
    // ================================================================
    hazard_unit Forwarding_block (
        .rst          (rst),
        .RegWriteM    (RegWriteM),   // use EX/MEM register
        .RD_M         (RD_M),
        .RegWriteW    (RegWriteW),   // use MEM/WB register
        .RD_W         (RDW),
        .Rs1_E        (RS1_E),
        .Rs2_E        (RS2_E),
        .ForwardAE    (ForwardAE),
        .ForwardBE    (ForwardBE)
    );

    // ================================================================
    //  DEBUG OUTPUT ASSIGNMENTS
    //  These prevent synthesis from optimizing away the entire design
    // ================================================================
    assign debug_alu_result = ALU_ResultW;      
    assign debug_reg_addr   = RDW;              
    assign debug_reg_write  = RegWriteW;        
    assign debug_mem_write  = MemWriteM;

endmodule