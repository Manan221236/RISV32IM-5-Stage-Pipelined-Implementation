module Control_Unit_Top (
    input  [6:0] Op,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output       RegWrite,
    output [2:0] ImmSrc,        // widened
    output       ALUSrc,
    output       MemWrite,
    output [1:0] ResultSrc,
    output       Branch,
    output [4:0] ALUControl,
    output       Jump,
    output [2:0] LoadType,
    output [2:0] StoreType
);
    wire [2:0] ALUOp;

    Main_Decoder MD (
        .Op(Op), .funct3(funct3), .funct7(funct7),
        .RegWrite(RegWrite), .ImmSrc(ImmSrc), .ALUSrc(ALUSrc),
        .MemWrite(MemWrite), .ResultSrc(ResultSrc), .Branch(Branch),
        .ALUOp(ALUOp), .Jump(Jump),
        .LoadType(LoadType), .StoreType(StoreType)
    );

    ALU_Decoder AD (
        .ALUOp(ALUOp), .funct3(funct3),
        .funct7(funct7), .op(Op), .ALUControl(ALUControl)
    );
endmodule
