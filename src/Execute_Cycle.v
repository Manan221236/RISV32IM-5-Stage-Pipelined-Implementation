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
    // Original Forwarding Muxes - No pipeline changes to maintain timing
    //----------------------------------------------------------------
    wire [XLEN-1:0] Src_A_pre, Src_B_pre, Src_B;
    
    // Keep original 3:1 muxes but add attributes for better synthesis
    (* parallel_case *) wire [1:0] ForwardA_E_attr = ForwardA_E;
    (* parallel_case *) wire [1:0] ForwardB_E_attr = ForwardB_E;
    
    Mux_3_by_1 muxA (
        .a(RD1_E),       // 00
        .b(ResultW),     // 01
        .c(ALU_ResultMEM),// 10
        .s(ForwardA_E_attr),
        .d(Src_A_pre)
    );

    Mux_3_by_1 muxB (
        .a(RD2_E),
        .b(ResultW),
        .c(ALU_ResultMEM),
        .s(ForwardB_E_attr),
        .d(Src_B_pre)
    );

    // ALU-src mux (Immed vs reg) with attribute
    (* parallel_case *) wire ALUSrcE_attr = ALUSrcE;
    Mux mux_imm (
        .a(Src_B_pre),
        .b(Imm_Ext_E),
        .s(ALUSrcE_attr),
        .c(Src_B)
    );

    //----------------------------------------------------------------
    //  ALU + branch compare
    //----------------------------------------------------------------
    wire [XLEN-1:0] ALU_out;
    ALU alu_u (
        .clk(clk),
        .rst(rst),
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
    // CONSERVATIVE: Additional pipeline stage for multiplication ONLY
    //----------------------------------------------------------------
    reg [31:0] alu_result_pipe;
    reg        alu_valid_pipe;
    reg [4:0]  rd_pipe;
    reg        regwrite_pipe;
    reg [1:0]  resultsrc_pipe;
    reg        memwrite_pipe;
    reg [2:0]  loadtype_pipe, storetype_pipe;
    reg [31:0] writedata_pipe, pcplus4_pipe;
    
    // Detect multiplication operations
    wire is_multiply = (ALUControlE >= 5'b01010) && (ALUControlE <= 5'b01101);
    
    // Extra pipeline stage for multiplication ONLY
    always @(posedge clk) begin
        if (rst) begin
            alu_result_pipe <= 32'h0;
            alu_valid_pipe <= 1'b0;
            rd_pipe <= 5'h0;
            regwrite_pipe <= 1'b0;
            resultsrc_pipe <= 2'b00;
            memwrite_pipe <= 1'b0;
            loadtype_pipe <= 3'b000;
            storetype_pipe <= 3'b000;
            writedata_pipe <= 32'h0;
            pcplus4_pipe <= 32'h0;
        end else if (is_multiply) begin
            // Pipeline multiplication results
            alu_result_pipe <= ALU_out;
            alu_valid_pipe <= 1'b1;
            rd_pipe <= RD_E;
            regwrite_pipe <= RegWriteE;
            resultsrc_pipe <= ResultSrcE;
            memwrite_pipe <= MemWriteE;
            loadtype_pipe <= LoadTypeE;
            storetype_pipe <= StoreTypeE;
            writedata_pipe <= Src_B_pre;
            pcplus4_pipe <= PCPlus4E;
        end else begin
            alu_valid_pipe <= 1'b0;
        end
    end

    //----------------------------------------------------------------
    //  EX/MEM pipeline register - CONSERVATIVE VERSION
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
        end else begin
            // Use pipelined results for multiplication, direct for others
            if (alu_valid_pipe) begin
                RegWriteM   <= regwrite_pipe;
                MemWriteM   <= memwrite_pipe;
                ResultSrcM  <= resultsrc_pipe;
                RD_M        <= rd_pipe;
                PCPlus4M    <= pcplus4_pipe;
                WriteDataM  <= writedata_pipe;
                ALU_ResultM <= alu_result_pipe;
                LoadTypeM   <= loadtype_pipe;
                StoreTypeM  <= storetype_pipe;
                $display("EXECUTE_REG: Using PIPELINED multiplication result - RD_M=x%0d, ALU_ResultM=0x%08h", 
                         rd_pipe, alu_result_pipe);
            end else begin
                RegWriteM   <= RegWriteE;
                MemWriteM   <= MemWriteE;
                ResultSrcM  <= ResultSrcE;
                RD_M        <= RD_E;
                PCPlus4M    <= PCPlus4E;
                WriteDataM  <= Src_B_pre;
                ALU_ResultM <= ALU_out;
                LoadTypeM   <= LoadTypeE;
                StoreTypeM  <= StoreTypeE;
                $display("EXECUTE_REG: Using DIRECT result - RD_M=x%0d, ALU_ResultM=0x%08h", 
                         RD_E, ALU_out);
            end
        end
    end
    
    //----------------------------------------------------------------
    //  DEBUG OUTPUT
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

    // MUL-specific debug with pipeline awareness
    always @(posedge clk) begin
        if (!rst && ALUControlE == 5'b01010) begin // MUL operation
            $display("EXECUTE MUL: RD_E=x%0d, A=%0d * B=%0d = %0d (will be pipelined)", 
                     RD_E, $signed(Src_A_pre), $signed(Src_B_pre), $signed(ALU_out));
        end
        if (!rst && alu_valid_pipe) begin
            $display("EXECUTE MUL_PIPE: Pipelined multiplication result ready - RD=x%0d, Result=%0d", 
                     rd_pipe, $signed(alu_result_pipe));
        end
    end

endmodule
