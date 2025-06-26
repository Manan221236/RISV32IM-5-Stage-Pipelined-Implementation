module execute_cycle
#(parameter XLEN = 32)
(
    input  wire                 clk,
    input  wire                 rst,

    // control from Decode
    input  wire                 RegWriteE,
    input  wire                 ALUSrcE,
    input  wire                 MemWriteE,
    input  wire [1:0]           ResultSrcE,
    input  wire                 BranchE,
    input  wire                 JumpE,
    input  wire [4:0]           ALUControlE,

    // data from Decode
    input  wire [XLEN-1:0]      RD1_E,
    input  wire [XLEN-1:0]      RD2_E,
    input  wire [XLEN-1:0]      Imm_Ext_E,
    input  wire [4:0]           RD_E,
    input  wire [XLEN-1:0]      PCE,
    input  wire [XLEN-1:0]      PCPlus4E,

    // forwarding selects
    input  wire [1:0]           ForwardA_E,
    input  wire [1:0]           ForwardB_E,

    // *** value that is ALREADY in MEM stage ***  (one cycle old)
    input  wire [XLEN-1:0]      ALU_ResultMEM,

    // value that is written back this cycle
    input  wire [XLEN-1:0]      ResultW,

    // size / branch info
    input  wire [2:0]           LoadTypeE,
    input  wire [2:0]           StoreTypeE,
    input  wire [2:0]           funct3_E,

    input  wire [4:0]           RS1_E,

    // outputs to MEM
    output reg                  RegWriteM,
    output reg                  MemWriteM,
    output reg  [1:0]           ResultSrcM,
    output reg  [4:0]           RD_M,
    output reg  [XLEN-1:0]      PCPlus4M,
    output reg  [XLEN-1:0]      WriteDataM,
    output reg  [XLEN-1:0]      ALU_ResultM,
    output reg  [2:0]           LoadTypeM,
    output reg  [2:0]           StoreTypeM,

    // branch / jump
    output wire                 PCSrcE,
    output wire [XLEN-1:0]      PCTargetE,
    output wire [XLEN-1:0]      JALR_TargetE,
    output wire                 is_jalr_E
);
    //----------------------------------------------------------------
    // Forwarding Muxes
    //----------------------------------------------------------------
    wire [XLEN-1:0] Src_A_pre, Src_B_pre, Src_B;
    Mux_3_by_1 muxA (
        .a(RD1_E),       // 00
        .b(ResultW),     // 01
        .c(ALU_ResultMEM),// 10
        .s(ForwardA_E),
        .d(Src_A_pre)
    );

    Mux_3_by_1 muxB (
        .a(RD2_E),
        .b(ResultW),
        .c(ALU_ResultMEM),
        .s(ForwardB_E),
        .d(Src_B_pre)
    );

    // ALU-src mux (Immed vs reg)
    Mux mux_imm (
        .a(Src_B_pre),
        .b(Imm_Ext_E),
        .s(ALUSrcE),
        .c(Src_B)
    );

    //----------------------------------------------------------------
    //  ALU + branch compare
    //----------------------------------------------------------------
    wire [XLEN-1:0] ALU_out;
    ALU alu_u (
        .A(Src_A_pre), .B(Src_B),
        .Result(ALU_out),
        .ALUControl(ALUControlE),
        .OverFlow(), .Carry(), .Zero(), .Negative()
    );

    wire BranchTakenE;
    Branch_Comparator cmp_u (
        .A(Src_A_pre), .B(Src_B_pre),
        .funct3(funct3_E),
        .BranchTaken(BranchTakenE)
    );

    // branch/jump targets
    PC_Adder add_branch (.a(PCE), .b(Imm_Ext_E), .c(PCTargetE));

    JALR_Target_Calculator jalr_u (
        .Src_A(Src_A_pre), .Imm_Ext(Imm_Ext_E), .JALR_Target(JALR_TargetE)
    );

    wire is_jalr_opcode = JumpE & (funct3_E == 3'b000);
    assign is_jalr_E = is_jalr_opcode;
    
    // PC source control: take branch/jump if condition is met
    assign PCSrcE = (BranchTakenE & BranchE) | JumpE;

    //----------------------------------------------------------------
    //  EX/MEM pipeline register - COMPLETELY FIXED
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            RegWriteM   <= 1'b0;
            MemWriteM   <= 1'b0;
            ResultSrcM  <= 2'b00;
            RD_M        <= 5'd0;
            PCPlus4M    <= 32'd0;
            WriteDataM  <= 32'd0;
            ALU_ResultM <= 32'd0;
            LoadTypeM   <= 3'b000;
            StoreTypeM  <= 3'b000;
            $display("EXECUTE_REG: RESET - All registers cleared");
        end
        else begin
            // CLEAN ASSIGNMENT - No delays, no complications
            RegWriteM   <= RegWriteE;
            MemWriteM   <= MemWriteE;
            ResultSrcM  <= ResultSrcE;
            RD_M        <= RD_E;        // This works correctly now
            PCPlus4M    <= PCPlus4E;
            WriteDataM  <= Src_B_pre;
            ALU_ResultM <= ALU_out;
            LoadTypeM   <= LoadTypeE;
            StoreTypeM  <= StoreTypeE;
            
            // CORRECT DEBUG: Show what we're ABOUT TO assign
            $display("EXECUTE_REG: Assigning RD_E=%0d -> RD_M, ALU_out=0x%08h", RD_E, ALU_out);
        end
    end
    
    //----------------------------------------------------------------
    //  FIXED DEBUG OUTPUT - Proper Timing
    //----------------------------------------------------------------
    
    // Debug AFTER pipeline register update (use #1 delay to see final values)
    always @(posedge clk) begin
        if (!rst) begin
            #1; // Small delay to see the updated register values
            $display("EXECUTE_POST: Pipeline updated - RD_M=%0d, ALU_ResultM=0x%08h", RD_M, ALU_ResultM);
            if (RegWriteM && RD_M != 0) begin
                $display("EXECUTE_POST: Will write 0x%08h to x%0d in next stage", ALU_ResultM, RD_M);
            end
        end
    end

    // Branch debug
    always @(posedge clk) begin
        if (!rst && BranchE) begin
            $display("EXECUTE BRANCH: BranchE=%b, A=%0d, B=%0d, BranchTakenE=%b, PCSrcE=%b", 
                     BranchE, $signed(Src_A_pre), $signed(Src_B_pre), BranchTakenE, PCSrcE);
        end
    end

    // MUL-specific debug
    always @(posedge clk) begin
        if (!rst && ALUControlE == 5'b01010) begin // MUL operation
            $display("EXECUTE MUL: RD_E=x%0d, A=%0d * B=%0d = %0d", 
                     RD_E, $signed(Src_A_pre), $signed(Src_B_pre), $signed(ALU_out));
        end
    end

endmodule