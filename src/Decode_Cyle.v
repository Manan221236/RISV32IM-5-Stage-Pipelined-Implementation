module decode_cycle (
    input         clk,
    input         rst,

    // IF/ID inputs
    input  [31:0] InstrD,          // current instruction
    input  [31:0] PCD,             // PC of InstrD
    input  [31:0] PCPlus4D,        // PC+4 of InstrD

    // WB-stage write-back interface
    input         RegWriteW,
    input  [4:0]  RDW,
    input  [31:0] ResultW,

    // ID/EX outputs
    output        RegWriteE,
    output        ALUSrcE,
    output        MemWriteE,
    output [1:0]  ResultSrcE,
    output        BranchE,
    output        JumpE,
    output [4:0]  ALUControlE,

    output [31:0] RD1_E,
    output [31:0] RD2_E,
    output [31:0] Imm_Ext_E,

    output [4:0]  RS1_E,
    output [4:0]  RS2_E,
    output [4:0]  RD_E,

    output [31:0] PCE,
    output [31:0] PCPlus4E,

    output [2:0]  LoadTypeE,
    output [2:0]  StoreTypeE,
    output [2:0]  funct3_E
);

//--------------------------------------------------------------------
// 1.  Control-unit, register file, immediate generator
//--------------------------------------------------------------------
wire        RegWriteD, ALUSrcD, MemWriteD, BranchD, JumpD;
wire [2:0]  ImmSrcD;           // 3-bit now  (000 I, 001 S, 010 B, 011 U, 100 J)
wire [1:0]  ResultSrcD;
wire [4:0]  ALUControlD;

wire [31:0] RD1_D, RD2_D, Imm_Ext_D;
wire [2:0]  LoadTypeD, StoreTypeD;

// --- control and decode ---
Control_Unit_Top control (
    .Op       (InstrD[6:0]),
    .funct3   (InstrD[14:12]),
    .funct7   (InstrD[31:25]),
    .RegWrite (RegWriteD),
    .ImmSrc   (ImmSrcD),
    .ALUSrc   (ALUSrcD),
    .MemWrite (MemWriteD),
    .ResultSrc(ResultSrcD),
    .Branch   (BranchD),
    .ALUControl(ALUControlD),
    .Jump     (JumpD),
    .LoadType (LoadTypeD),
    .StoreType(StoreTypeD)
);

// --- register file ---
Register_File rf (
    .clk (clk),
    .rst (rst),
    .WE3 (RegWriteW),
    .WD3 (ResultW),
    .A1  (InstrD[19:15]),
    .A2  (InstrD[24:20]),
    .A3  (RDW),
    .RD1 (RD1_D),
    .RD2 (RD2_D)
);

// --- immediate generator ---
Sign_Extend extension (
    .In     (InstrD),
    .ImmSrc (ImmSrcD),
    .Imm_Ext(Imm_Ext_D)
);

//--------------------------------------------------------------------
// 2.  ID/EX pipeline register
//--------------------------------------------------------------------
reg        RegWriteD_r, ALUSrcD_r, MemWriteD_r, BranchD_r, JumpD_r;
reg [1:0]  ResultSrcD_r;
reg [4:0]  ALUControlD_r;
reg [31:0] RD1_D_r, RD2_D_r, Imm_Ext_D_r;
reg [4:0]  RS1_D_r, RS2_D_r, RD_D_r;
reg [31:0] PCD_r, PCPlus4D_r;
reg [2:0]  LoadTypeD_r, StoreTypeD_r, funct3_D_r;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        RegWriteD_r   <= 1'b0;
        ALUSrcD_r     <= 1'b0;
        MemWriteD_r   <= 1'b0;
        ResultSrcD_r  <= 2'b00;
        BranchD_r     <= 1'b0;
        JumpD_r       <= 1'b0;
        ALUControlD_r <= 5'b00000;

        RD1_D_r <= 32'd0;
        RD2_D_r <= 32'd0;
        Imm_Ext_D_r <= 32'd0;

        RS1_D_r <= 5'd0;
        RS2_D_r <= 5'd0;
        RD_D_r  <= 5'd0;

        PCD_r      <= 32'd0;
        PCPlus4D_r <= 32'd0;

        LoadTypeD_r  <= 3'd0;
        StoreTypeD_r <= 3'd0;
        funct3_D_r   <= 3'd0;
    end
    else begin
        RegWriteD_r   <= RegWriteD;
        ALUSrcD_r     <= ALUSrcD;
        MemWriteD_r   <= MemWriteD;
        ResultSrcD_r  <= ResultSrcD;
        BranchD_r     <= BranchD;
        JumpD_r       <= JumpD;
        ALUControlD_r <= ALUControlD;

        RD1_D_r <= RD1_D;
        RD2_D_r <= RD2_D;
        Imm_Ext_D_r <= Imm_Ext_D;    // <-- critical: pass through fresh immediate

        RS1_D_r <= InstrD[19:15];
        RS2_D_r <= InstrD[24:20];
        RD_D_r  <= InstrD[11:7];

        PCD_r      <= PCD;
        PCPlus4D_r <= PCPlus4D;

        LoadTypeD_r  <= LoadTypeD;
        StoreTypeD_r <= StoreTypeD;
        funct3_D_r   <= InstrD[14:12];
    end
end

//--------------------------------------------------------------------
// 3.  ID/EX outputs (simple assigns)
//--------------------------------------------------------------------
assign RegWriteE   = RegWriteD_r;
assign ALUSrcE     = ALUSrcD_r;
assign MemWriteE   = MemWriteD_r;
assign ResultSrcE  = ResultSrcD_r;
assign BranchE     = BranchD_r;
assign JumpE       = JumpD_r;
assign ALUControlE = ALUControlD_r;

assign RD1_E       = RD1_D_r;
assign RD2_E       = RD2_D_r;
assign Imm_Ext_E   = Imm_Ext_D_r;

assign RS1_E       = RS1_D_r;
assign RS2_E       = RS2_D_r;
assign RD_E        = RD_D_r;

assign PCE         = PCD_r;
assign PCPlus4E    = PCPlus4D_r;

assign LoadTypeE   = LoadTypeD_r;
assign StoreTypeE  = StoreTypeD_r;
assign funct3_E    = funct3_D_r;

endmodule