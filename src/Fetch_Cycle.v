module fetch_cycle(clk, rst, PCSrcE, PCTargetE, JALR_TargetE, JumpE, InstrD, PCD, PCPlus4D, is_jalr_E);
    // Declare input & outputs
    input clk, rst;
    input PCSrcE, JumpE, is_jalr_E;
    input [31:0] PCTargetE, JALR_TargetE;
    output [31:0] InstrD;
    output [31:0] PCD, PCPlus4D;
    
    // Declaring interim wires
    wire [31:0] PC_F, PCF, PCPlus4F;
    wire [31:0] InstrF;
    wire [31:0] PC_Next;
    
    // Declaration of Register
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;
    
    // PC Next selection: JALR has priority, then other jumps/branches, then PC+4
    assign PC_Next = (JumpE & is_jalr_E) ? JALR_TargetE :
                     PCSrcE ? PCTargetE :
                     PCPlus4F;
    
    // Initiation of Modules
    // Declare PC Counter
    PC_Module Program_Counter (
        .clk(clk),
        .rst(rst),
        .PC(PCF),
        .PC_Next(PC_Next)
    );
    
    // Declare Instruction Memory
    Instruction_Memory IMEM (
        .rst(rst),
        .A(PCF),
        .RD(InstrF)
    );
    
    // Declare PC adder
    PC_Adder PC_adder (
        .a(PCF),
        .b(32'h00000004),
        .c(PCPlus4F)
    );
    
    // Fetch Cycle Register Logic
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end
        else begin
            InstrF_reg <= InstrF;
            PCF_reg <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
    end
    
    // Assigning Registers Value to the Output port
    assign  InstrD = (rst == 1'b0) ? 32'h00000000 : InstrF_reg;
    assign  PCD = (rst == 1'b0) ? 32'h00000000 : PCF_reg;
    assign  PCPlus4D = (rst == 1'b0) ? 32'h00000000 : PCPlus4F_reg;
endmodule