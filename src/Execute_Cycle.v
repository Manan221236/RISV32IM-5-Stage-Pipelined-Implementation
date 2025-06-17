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
    input  wire [XLEN-1:0]      ALU_ResultMEM,   // new port!

    // value that is written back this cycle
    input  wire [XLEN-1:0]      ResultW,

    // size / branch info
    input  wire [2:0]           LoadTypeE,
    input  wire [2:0]           StoreTypeE,
    input  wire [2:0]           funct3_E,

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
    output wire                 is_jalr_E,

    // preview for hazard unit (one-cycle early)
    output reg                  RegWriteM_haz,
    output reg  [4:0]           RD_M_haz
);
    //----------------------------------------------------------------
    // Forwarding Muxes
    //----------------------------------------------------------------
    wire [XLEN-1:0] Src_A_pre, Src_B_pre, Src_B;
    Mux_3_by_1 muxA (
        .a(RD1_E),       // 00
        .b(ResultW),     // 01
        .c(ALU_ResultMEM),// 10  <-- MEM value, NOT current value
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

    assign is_jalr_E =  JumpE & (funct3_E == 3'b000);
    assign PCSrcE    = (BranchTakenE & BranchE) | JumpE;

    //----------------------------------------------------------------
    //  EX/MEM pipeline register
    //----------------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            {RegWriteM, MemWriteM} <= 0;
            ResultSrcM <= 2'b00;
            RD_M       <= 5'd0;
            PCPlus4M   <= 0;
            WriteDataM <= 0;
            ALU_ResultM<= 0;
            LoadTypeM  <= 3'b000;
            StoreTypeM <= 3'b000;
            RegWriteM_haz <= 1'b0;
            RD_M_haz      <= 5'd0;
        end
        else begin
            RegWriteM   <= RegWriteE;
            MemWriteM   <= MemWriteE;
            ResultSrcM  <= ResultSrcE;
            RD_M        <= RD_E;
            PCPlus4M    <= PCPlus4E;
            WriteDataM  <= Src_B_pre;   // value after fwd. but before imm-mux
            ALU_ResultM <= ALU_out;
            LoadTypeM   <= LoadTypeE;
            StoreTypeM  <= StoreTypeE;

            // preview
            RegWriteM_haz <= RegWriteE;
            RD_M_haz      <= RD_E;
        end
    end
endmodule