
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2025 23:02:24
// Design Name: 
// Module Name: Branch_Comparator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Branch_Comparator(A, B, funct3, BranchTaken);
    input [31:0] A, B;
    input [2:0] funct3;
    output BranchTaken;
    
    wire eq, lt, ltu;
    
    assign eq = (A == B);
    assign lt = ($signed(A) < $signed(B));
    assign ltu = (A < B);
    
    assign BranchTaken = (funct3 == 3'b000) ? eq :      // BEQ
                         (funct3 == 3'b001) ? ~eq :     // BNE
                         (funct3 == 3'b100) ? lt :      // BLT
                         (funct3 == 3'b101) ? ~lt :     // BGE
                         (funct3 == 3'b110) ? ltu :     // BLTU
                         (funct3 == 3'b111) ? ~ltu :    // BGEU
                         1'b0;
endmodule
