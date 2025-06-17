
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2025 23:04:14
// Design Name: 
// Module Name: JALR_Target_Calculator
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


module JALR_Target_Calculator(Src_A, Imm_Ext, JALR_Target);
    input [31:0] Src_A, Imm_Ext;
    output [31:0] JALR_Target;
    
    // JALR target = (rs1 + immediate) & ~1 (LSB cleared)
    assign JALR_Target = (Src_A + Imm_Ext) & 32'hFFFFFFFE;
endmodule
