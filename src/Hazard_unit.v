// ================================================================
//  hazard_unit.v   -   2-source forwarding (EX/MEM & MEM/WB)
// ================================================================

module hazard_unit (
    input        rst,

    // -------- EX/MEM register  (one-cycle-old ALU result) --------
    input        RegWriteM,          // write-enable bit in EX/MEM
    input  [4:0] RD_M,               // destination register in EX/MEM

    // -------- MEM/WB register  (value being written back) --------
    input        RegWriteW,          // write-enable bit in MEM/WB
    input  [4:0] RD_W,               // destination register in MEM/WB

    // -------- current EX operands --------
    input  [4:0] Rs1_E,              // rs1 of the instruction in EX stage
    input  [4:0] Rs2_E,              // rs2 of the instruction in EX stage

    // -------- forwarding selections --------
    output [1:0] ForwardAE,          // 00=ID/EX, 10=EX/MEM, 01=MEM/WB
    output [1:0] ForwardBE
);
    // -------------------------------------------------------------
    //  Forward A (rs1)
    // -------------------------------------------------------------
    assign ForwardAE =
        (rst == 1'b0)                           ? 2'b00 :
        ( RegWriteM && (RD_M != 5'd0) &&
          (RD_M == Rs1_E) )                     ? 2'b10 :
        ( RegWriteW && (RD_W != 5'd0) &&
          (RD_W == Rs1_E) )                     ? 2'b01 :
                                                  2'b00;

    // -------------------------------------------------------------
    //  Forward B (rs2)
    // -------------------------------------------------------------
    assign ForwardBE =
        (rst == 1'b0)                           ? 2'b00 :
        ( RegWriteM && (RD_M != 5'd0) &&
          (RD_M == Rs2_E) )                     ? 2'b10 :
        ( RegWriteW && (RD_W != 5'd0) &&
          (RD_W == Rs2_E) )                     ? 2'b01 :
                                                  2'b00;
endmodule
