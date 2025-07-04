module ALU(clk, rst, A, B, Result, ALUControl, OverFlow, Carry, Zero, Negative);
    input clk, rst;
    input [31:0] A, B;
    input [4:0] ALUControl;
    output Carry, OverFlow, Zero, Negative;
    output [31:0] Result;
    
    wire Cout;
    wire [31:0] Sum;
    wire [4:0] shamt;
    
    assign shamt = B[4:0];
    
    // Addition/Subtraction
    assign {Cout, Sum} = (ALUControl[0] == 1'b0) ? A + B : (A + ((~B) + 1));
    
    // ================================================================
    // MULTIPLICATION PIPELINE (2 stages)
    // ================================================================
    
    // Stage 1: Input registration
    reg [31:0] A_reg, B_reg;
    reg [4:0] ALUControl_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            A_reg <= 32'h0;
            B_reg <= 32'h0;
            ALUControl_reg <= 5'h0;
        end else begin
            A_reg <= A;
            B_reg <= B;
            ALUControl_reg <= ALUControl;
        end
    end
    
    // Stage 2: Multiplication
    reg [63:0] mult_result;
    reg [4:0] mult_control;
    
    wire signed [31:0] A_reg_signed = $signed(A_reg);
    wire signed [31:0] B_reg_signed = $signed(B_reg);
    wire [31:0] A_reg_unsigned = A_reg;
    wire [31:0] B_reg_unsigned = B_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            mult_result <= 64'h0;
            mult_control <= 5'h0;
        end else begin
            mult_control <= ALUControl_reg;
            case (ALUControl_reg)
                5'b01010: mult_result <= A_reg_signed * B_reg_signed;                    // MUL
                5'b01011: mult_result <= A_reg_signed * B_reg_signed;                    // MULH
                5'b01100: mult_result <= A_reg_signed * $signed({1'b0, B_reg_unsigned}); // MULHSU
                5'b01101: mult_result <= A_reg_unsigned * B_reg_unsigned;                // MULHU
                default:  mult_result <= 64'h0;
            endcase
        end
    end
    
    // Multiplication result selection
    wire [31:0] mult_final;
    assign mult_final = 
        (mult_control == 5'b01010) ? mult_result[31:0] :      // MUL
        (mult_control == 5'b01011) ? mult_result[63:32] :     // MULH
        (mult_control == 5'b01100) ? mult_result[63:32] :     // MULHSU
        (mult_control == 5'b01101) ? mult_result[63:32] :     // MULHU
        32'h0;
    
    // ================================================================
    // IMMEDIATE OPERATIONS (Combinational)
    // ================================================================
    wire [31:0] immediate_result;
    assign immediate_result = 
        (ALUControl == 5'b00000) ? Sum :                          // ADD
        (ALUControl == 5'b00001) ? Sum :                          // SUB
        (ALUControl == 5'b00010) ? A & B :                        // AND
        (ALUControl == 5'b00011) ? A | B :                        // OR
        (ALUControl == 5'b00100) ? A ^ B :                        // XOR
        (ALUControl == 5'b00101) ? {{31{1'b0}}, (Sum[31])} :      // SLT
        (ALUControl == 5'b00110) ? {{31{1'b0}}, (A < B)} :        // SLTU
        (ALUControl == 5'b00111) ? A << shamt :                   // SLL
        (ALUControl == 5'b01000) ? A >> shamt :                   // SRL
        (ALUControl == 5'b01001) ? $signed(A) >>> shamt :         // SRA
        (ALUControl == 5'b01110) ? B :                            // LUI
        (ALUControl == 5'b01111) ? Sum :                          // AUIPC
        32'h00000000;
    
    // ================================================================
    // RESULT SELECTION
    // ================================================================
    wire is_mult_ready = (mult_control >= 5'b01010) && (mult_control <= 5'b01101);
    assign Result = is_mult_ready ? mult_final : immediate_result;
    
    // ================================================================
    // FLAGS
    // ================================================================
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]));
    assign Carry = ((~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];
    
    // ================================================================
    // DEBUG
    // ================================================================
    always @(posedge clk) begin
        if (!rst && (ALUControl_reg >= 5'b01010) && (ALUControl_reg <= 5'b01101)) begin
            $display("ALU MULT STAGE2: A_reg=%0d * B_reg=%0d = %0d, control=%b", 
                     $signed(A_reg), $signed(B_reg), $signed(mult_result), mult_control);
        end
    end
    
endmodule
