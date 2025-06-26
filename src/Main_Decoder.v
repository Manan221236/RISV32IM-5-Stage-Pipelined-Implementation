module Main_Decoder (
    input  [6:0] Op,        // opcode
    input  [2:0] funct3,
    input  [6:0] funct7,
    output       RegWrite,
    output [2:0] ImmSrc,    // 3-bit now
    output       ALUSrc,
    output       MemWrite,
    output [1:0] ResultSrc,
    output       Branch,
    output [2:0] ALUOp,
    output       Jump,
    output [2:0] LoadType,
    output [2:0] StoreType
);

    // instruction classes
    wire is_load   = (Op == 7'b0000011);
    wire is_store  = (Op == 7'b0100011);
    wire is_rtype  = (Op == 7'b0110011);
    wire is_itype  = (Op == 7'b0010011);
    wire is_branch = (Op == 7'b1100011);
    wire is_jal    = (Op == 7'b1101111);
    wire is_jalr   = (Op == 7'b1100111);
    wire is_lui    = (Op == 7'b0110111);
    wire is_auipc  = (Op == 7'b0010111);
    wire is_mtype  =  is_rtype & (funct7 == 7'b0000001);

    // register write enable
    assign RegWrite =  is_load | is_rtype | is_itype |
                       is_jal  | is_jalr  | is_lui   | is_auipc;

    // *** 3-bit ImmSrc ***
    // 000 = I, 001 = S, 010 = B, 011 = U, 100 = J
    assign ImmSrc = is_store  ? 3'b001 :
                    is_branch ? 3'b010 :
                    is_lui |
                    is_auipc ? 3'b011 :
                    is_jal   ? 3'b100 :
                               3'b000;   // default I-type

    assign ALUSrc  = is_load | is_store | is_itype | is_lui | is_auipc | is_jalr;
    assign MemWrite = is_store;

    // 00 = ALU, 01 = load data, 10 = PC+4
    assign ResultSrc = is_load         ? 2'b01 :
                       (is_jal | is_jalr) ? 2'b10 :
                                            2'b00;

    assign Branch = is_branch;
    assign Jump   = is_jal | is_jalr;

    // ALUOp (unchanged, still 3 bits)
    assign ALUOp =
        is_load | is_store | is_jalr                ? 3'b000 :
        is_branch                                   ? 3'b001 :
        (is_rtype & ~is_mtype) | is_itype           ? 3'b010 :
        is_mtype                                    ? 3'b011 :
        is_lui                                      ? 3'b100 :
        is_auipc                                    ? 3'b101 :
        (is_jal | is_jalr)                          ? 3'b110 :
                                                      3'b000 ;

    // Load / Store size indicators
    assign LoadType  = is_load  ? funct3 : 3'b000;
    assign StoreType = is_store ? funct3 : 3'b000;
    always @(*) begin
    if (Op == 7'b1101111) begin  // JAL instruction
        $display("CONTROL DEBUG: JAL instruction detected!");
        $display("  Op=0x%02h, Jump=%b, RegWrite=%b, ImmSrc=%b", 
                 Op, Jump, RegWrite, ImmSrc);
    end
    if (Op == 7'b1100111) begin  // JALR instruction  
        $display("CONTROL DEBUG: JALR instruction detected!");
        $display("  Op=0x%02h, Jump=%b, RegWrite=%b, ImmSrc=%b",
                 Op, Jump, RegWrite, ImmSrc);
    end
    if (Op == 7'b1100011) begin  // Branch instruction
        $display("CONTROL DEBUG: BRANCH instruction detected!");
        $display("  Op=0x%02h, Branch=%b, funct3=0x%h", Op, Branch, funct3);
    end
end
endmodule
