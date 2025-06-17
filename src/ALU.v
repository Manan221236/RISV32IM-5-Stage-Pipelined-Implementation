module ALU(A, B, Result, ALUControl, OverFlow, Carry, Zero, Negative);
    input [31:0] A, B;
    input [4:0] ALUControl; // Extended to 5 bits for more operations
    output Carry, OverFlow, Zero, Negative;
    output [31:0] Result;
    
    wire Cout;
    wire [31:0] Sum;
    wire [4:0] shamt;
    wire [63:0] mul_result;
    wire [63:0] mulh_result;
    wire [63:0] mulhsu_result;
    wire [63:0] mulhu_result;
    
    assign shamt = B[4:0]; // Shift amount from lower 5 bits of B
    
    // Addition/Subtraction
    assign {Cout, Sum} = (ALUControl[0] == 1'b0) ? A + B : (A + ((~B) + 1));
    
    // Multiplication operations
    assign mul_result = $signed(A) * $signed(B);
    assign mulh_result = $signed({{32{A[31]}}, A}) * $signed({{32{B[31]}}, B});
    assign mulhsu_result = $signed({{32{A[31]}}, A}) * $unsigned({32'b0, B});
    assign mulhu_result = $unsigned({32'b0, A}) * $unsigned({32'b0, B});
    
    assign Result = (ALUControl == 5'b00000) ? Sum :                    // ADD
                    (ALUControl == 5'b00001) ? Sum :                    // SUB
                    (ALUControl == 5'b00010) ? A & B :                  // AND
                    (ALUControl == 5'b00011) ? A | B :                  // OR
                    (ALUControl == 5'b00100) ? A ^ B :                  // XOR
                    (ALUControl == 5'b00101) ? {{31{1'b0}}, (Sum[31])} : // SLT
                    (ALUControl == 5'b00110) ? {{31{1'b0}}, (A < B)} :   // SLTU
                    (ALUControl == 5'b00111) ? A << shamt :             // SLL
                    (ALUControl == 5'b01000) ? A >> shamt :             // SRL
                    (ALUControl == 5'b01001) ? $signed(A) >>> shamt :   // SRA
                    (ALUControl == 5'b01010) ? mul_result[31:0] :       // MUL
                    (ALUControl == 5'b01011) ? mulh_result[63:32] :     // MULH
                    (ALUControl == 5'b01100) ? mulhsu_result[63:32] :   // MULHSU
                    (ALUControl == 5'b01101) ? mulhu_result[63:32] :    // MULHU
                    (ALUControl == 5'b01110) ? B :                      // LUI (pass B)
                    (ALUControl == 5'b01111) ? Sum :                    // AUIPC (A + B)
                    32'h00000000;
    
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]));
    assign Carry = ((~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];
endmodule