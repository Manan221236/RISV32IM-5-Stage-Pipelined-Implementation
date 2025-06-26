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
// 2.  ID/EX pipeline register - COMPLETELY FIXED
//--------------------------------------------------------------------
reg        RegWriteE_r, ALUSrcE_r, MemWriteE_r, BranchE_r, JumpE_r;
reg [1:0]  ResultSrcE_r;
reg [4:0]  ALUControlE_r;
reg [31:0] RD1_E_r, RD2_E_r, Imm_Ext_E_r;
reg [4:0]  RS1_E_r, RS2_E_r, RD_E_r;
reg [31:0] PCE_r, PCPlus4E_r;
reg [2:0]  LoadTypeE_r, StoreTypeE_r, funct3_E_r;

always @(posedge clk) begin
    if (rst) begin           // rst=1 means reset (active-HIGH)
        // Reset all pipeline registers to safe values
        RegWriteE_r   <= 1'b0;
        ALUSrcE_r     <= 1'b0;
        MemWriteE_r   <= 1'b0;
        ResultSrcE_r  <= 2'b00;
        BranchE_r     <= 1'b0;
        JumpE_r       <= 1'b0;
        ALUControlE_r <= 5'b00000;

        RD1_E_r <= 32'd0;
        RD2_E_r <= 32'd0;
        Imm_Ext_E_r <= 32'd0;

        RS1_E_r <= 5'd0;
        RS2_E_r <= 5'd0;
        RD_E_r  <= 5'd0;

        PCE_r      <= 32'd0;
        PCPlus4E_r <= 32'd0;

        LoadTypeE_r  <= 3'd0;
        StoreTypeE_r <= 3'd0;
        funct3_E_r   <= 3'd0;
        
        $display("DECODE_REG: RESET - All pipeline registers cleared");
    end
    else begin               // rst=0 means normal operation
        // Store control signals
        RegWriteE_r   <= RegWriteD;
        ALUSrcE_r     <= ALUSrcD;
        MemWriteE_r   <= MemWriteD;
        ResultSrcE_r  <= ResultSrcD;
        BranchE_r     <= BranchD;     // CRITICAL: Preserve branch signal
        JumpE_r       <= JumpD;       // CRITICAL: Preserve jump signal
        ALUControlE_r <= ALUControlD;

        // Store data signals
        RD1_E_r <= RD1_D;
        RD2_E_r <= RD2_D;
        Imm_Ext_E_r <= Imm_Ext_D;

        RS1_E_r <= InstrD[19:15];
        RS2_E_r <= InstrD[24:20];
        RD_E_r  <= InstrD[11:7];

        PCE_r      <= PCD;
        PCPlus4E_r <= PCPlus4D;

        LoadTypeE_r  <= LoadTypeD;
        StoreTypeE_r <= StoreTypeD;
        funct3_E_r   <= InstrD[14:12];
        
        // Debug output INSIDE the always block to show actual updates
        $display("DECODE_REG: Storing - BranchD=%b->BranchE_r=%b, JumpD=%b->JumpE_r=%b, RegWriteD=%b->RegWriteE_r=%b", 
                 BranchD, BranchD, JumpD, JumpD, RegWriteD, RegWriteD);
    end
end

//--------------------------------------------------------------------
// 3.  ID/EX outputs (DIRECT ASSIGNMENTS - NO RESET LOGIC)
//--------------------------------------------------------------------
assign RegWriteE   = RegWriteE_r;
assign ALUSrcE     = ALUSrcE_r;
assign MemWriteE   = MemWriteE_r;
assign ResultSrcE  = ResultSrcE_r;
assign BranchE     = BranchE_r;     // DIRECT assignment from register
assign JumpE       = JumpE_r;       // DIRECT assignment from register
assign ALUControlE = ALUControlE_r;

assign RD1_E       = RD1_E_r;
assign RD2_E       = RD2_E_r;
assign Imm_Ext_E   = Imm_Ext_E_r;

assign RS1_E       = RS1_E_r;
assign RS2_E       = RS2_E_r;
assign RD_E        = RD_E_r;

assign PCE         = PCE_r;
assign PCPlus4E    = PCPlus4E_r;

assign LoadTypeE   = LoadTypeE_r;
assign StoreTypeE  = StoreTypeE_r;
assign funct3_E    = funct3_E_r;

//--------------------------------------------------------------------
// 4.  ENHANCED DEBUG OUTPUT
//--------------------------------------------------------------------

// Debug output for control signal generation in decode stage
always @(*) begin
    if (!rst) begin
        // Branch detection
        if (InstrD[6:0] == 7'b1100011) begin
            $display("DECODE_CONTROL: BRANCH detected - Op=0x%02h, BranchD=%b, funct3=0x%h", 
                     InstrD[6:0], BranchD, InstrD[14:12]);
            $display("DECODE_CONTROL: Control active - JumpD=%b, BranchD=%b, RegWriteD=%b", 
                     JumpD, BranchD, RegWriteD);
        end
    end
end

// Pipeline verification debug with timing delay
always @(posedge clk) begin
    if (!rst) begin
        #1; // Small delay to see updated values
        $display("DECODE_PIPELINE: Post-clock verification");
        $display("  BranchE_r=%b, BranchE=%b (should match)", BranchE_r, BranchE);
        $display("  JumpE_r=%b, JumpE=%b (should match)", JumpE_r, JumpE);
        
        // Error detection
        if (BranchE_r !== BranchE) begin
            $display("DECODE_ERROR: BranchE mismatch! BranchE_r=%b but BranchE=%b", BranchE_r, BranchE);
        end
        if (JumpE_r !== JumpE) begin
            $display("DECODE_ERROR: JumpE mismatch! JumpE_r=%b but JumpE=%b", JumpE_r, JumpE);
        end
    end
end

//--------------------------------------------------------------------
// 5.  RD DEBUG - CRITICAL FOR FINDING PIPELINE BUG
//--------------------------------------------------------------------

// Debug MUL instruction decoding
always @(posedge clk) begin
    if (!rst && InstrD == 32'h02e787b3) begin // MUL instruction
        $display("DECODE DEBUG MUL: InstrD=0x%08h", InstrD);
        $display("DECODE DEBUG MUL: InstrD[11:7]=%05b (x%0d) -> RD_E_r", InstrD[11:7], InstrD[11:7]);
        $display("DECODE DEBUG MUL: InstrD[19:15]=%05b (x%0d) -> RS1_E_r", InstrD[19:15], InstrD[19:15]);
        $display("DECODE DEBUG MUL: InstrD[24:20]=%05b (x%0d) -> RS2_E_r", InstrD[24:20], InstrD[24:20]);
        $display("DECODE DEBUG MUL: Storing RD_E_r=%0d (should be 15)", InstrD[11:7]);
    end
end

// Track RD through the pipeline
always @(*) begin
    if (RD_E == 5'd15 || RD_E == 5'd14) begin
        $display("DECODE DEBUG: RD_E=%0d at time %0t", RD_E, $time);
    end
end

// Debug any register writes to x14 or x15
always @(posedge clk) begin
    if (!rst && RegWriteW && (RDW == 5'd14 || RDW == 5'd15)) begin
        $display("REGWRITE: t=%0t  x%0d <= 0x%08h (%0d)", $time, RDW, ResultW, $signed(ResultW));
    end
end

endmodule