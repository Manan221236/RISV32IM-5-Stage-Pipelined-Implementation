// ================================================================
//  hazard_unit.v   -   2-source forwarding (EX/MEM & MEM/WB)
//  FIXED: Active-HIGH reset logic
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
    //  Forward A (rs1) - FIXED RESET LOGIC
    // -------------------------------------------------------------
    assign ForwardAE =
        (rst == 1'b1)                           ? 2'b00 :  // FIXED: rst=1 disables forwarding during reset
        ( RegWriteM && (RD_M != 5'd0) &&
          (RD_M == Rs1_E) )                     ? 2'b10 :  // Forward from EX/MEM (higher priority)
        ( RegWriteW && (RD_W != 5'd0) &&
          (RD_W == Rs1_E) )                     ? 2'b01 :  // Forward from MEM/WB
                                                  2'b00;    // No forwarding needed
    
    // -------------------------------------------------------------
    //  Forward B (rs2) - FIXED RESET LOGIC
    // -------------------------------------------------------------
    assign ForwardBE =
        (rst == 1'b1)                           ? 2'b00 :  // FIXED: rst=1 disables forwarding during reset
        ( RegWriteM && (RD_M != 5'd0) &&
          (RD_M == Rs2_E) )                     ? 2'b10 :  // Forward from EX/MEM (higher priority)
        ( RegWriteW && (RD_W != 5'd0) &&
          (RD_W == Rs2_E) )                     ? 2'b01 :  // Forward from MEM/WB
                                                  2'b00;    // No forwarding needed
    
    // Debug output for forwarding decisions
    always @(*) begin
        if (!rst) begin // During normal operation
            if (ForwardAE != 2'b00) begin
                $display("HAZARD DEBUG: ForwardAE=%b - Rs1_E=x%0d matches RD_%s=x%0d", 
                         ForwardAE, Rs1_E, (ForwardAE == 2'b10) ? "M" : "W", 
                         (ForwardAE == 2'b10) ? RD_M : RD_W);
            end
            if (ForwardBE != 2'b00) begin
                $display("HAZARD DEBUG: ForwardBE=%b - Rs2_E=x%0d matches RD_%s=x%0d", 
                         ForwardBE, Rs2_E, (ForwardBE == 2'b10) ? "M" : "W", 
                         (ForwardBE == 2'b10) ? RD_M : RD_W);
            end
        end
    end
endmodule