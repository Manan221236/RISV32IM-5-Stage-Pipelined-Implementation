module ALU(A, B, Result, ALUControl, OverFlow, Carry, Zero, Negative);
    input [31:0] A, B;
    input [4:0] ALUControl;
    output Carry, OverFlow, Zero, Negative;
    output [31:0] Result;
    
    wire Cout;
    wire [31:0] Sum;
    wire [4:0] shamt;
    
    // FIXED: Properly declared multiplication results
    wire signed [31:0] A_signed, B_signed;
    wire [31:0] A_unsigned, B_unsigned;
    wire signed [63:0] mul_result_signed;
    wire [63:0] mul_result_unsigned;
    wire signed [63:0] mul_result_mixed;
    
    assign A_signed = $signed(A);
    assign B_signed = $signed(B);
    assign A_unsigned = A;
    assign B_unsigned = B;
    
    assign shamt = B[4:0];
    
    // Addition/Subtraction
    assign {Cout, Sum} = (ALUControl[0] == 1'b0) ? A + B : (A + ((~B) + 1));
    
    // FIXED: Properly implemented multiplication operations
    assign mul_result_signed = A_signed * B_signed;
    assign mul_result_mixed = A_signed * $signed({1'b0, B_unsigned});
    assign mul_result_unsigned = A_unsigned * B_unsigned;
    
    // CRITICAL DEBUG: Show ALU inputs and outputs for ALL operations
    always @(*) begin
        if (ALUControl == 5'b01010) begin // MUL instruction
            $display("ALU DEBUG MUL: A=%0d (0x%08h), B=%0d (0x%08h)", 
                     $signed(A), A, $signed(B), B);
            $display("ALU DEBUG MUL: mul_result_signed=%0d (0x%016h)", 
                     $signed(mul_result_signed), mul_result_signed);
            $display("ALU DEBUG MUL: Final Result=%0d (0x%08h)", 
                     $signed(mul_result_signed[31:0]), mul_result_signed[31:0]);
        end
        else if (ALUControl == 5'b00000 || ALUControl == 5'b00001) begin // ADD/SUB
            $display("ALU DEBUG ADD/SUB: A=%0d, B=%0d, Sum=%0d, ALUControl=%b", 
                     $signed(A), $signed(B), $signed(Sum), ALUControl);
        end
    end
    
    assign Result = (ALUControl == 5'b00000) ? Sum :                          // ADD
                    (ALUControl == 5'b00001) ? Sum :                          // SUB
                    (ALUControl == 5'b00010) ? A & B :                        // AND
                    (ALUControl == 5'b00011) ? A | B :                        // OR
                    (ALUControl == 5'b00100) ? A ^ B :                        // XOR
                    (ALUControl == 5'b00101) ? {{31{1'b0}}, (Sum[31])} :      // SLT
                    (ALUControl == 5'b00110) ? {{31{1'b0}}, (A < B)} :        // SLTU
                    (ALUControl == 5'b00111) ? A << shamt :                   // SLL
                    (ALUControl == 5'b01000) ? A >> shamt :                   // SRL
                    (ALUControl == 5'b01001) ? $signed(A) >>> shamt :         // SRA
                    (ALUControl == 5'b01010) ? mul_result_signed[31:0] :      // MUL
                    (ALUControl == 5'b01011) ? mul_result_signed[63:32] :     // MULH
                    (ALUControl == 5'b01100) ? mul_result_mixed[63:32] :      // MULHSU
                    (ALUControl == 5'b01101) ? mul_result_unsigned[63:32] :   // MULHU
                    (ALUControl == 5'b01110) ? B :                            // LUI
                    (ALUControl == 5'b01111) ? Sum :                          // AUIPC
                    32'h00000000;
    
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]));
    assign Carry = ((~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];
endmodule