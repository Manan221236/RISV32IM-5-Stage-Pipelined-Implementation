module Instruction_Memory
(
    input         rst,
    input  [31:0] A,          // byte address from IF stage
    output [31:0] RD          // fetched instruction
);
    reg [31:0] mem [0:255];
    integer i;
    
    // Fixed combinational read logic
    assign RD = (A[31:2] < 256) ? mem[A[31:2]] : 32'h0000_0013;
    
    // Debug output
    always @(*) begin
        if (!rst && A[31:2] < 10) begin
            $display("IMEM ACCESS: rst=%b, Address=0x%08h, Word_Addr=%0d, Instruction=0x%08h", 
                     rst, A, A[31:2], mem[A[31:2]]);
        end
    end
    
    // --------------------------------------------------------------
    //  PIPELINE HAZARD FIX - ADDED NOP FOR DATA DEPENDENCY
    //  Ensures x15 write completes before x10 read
    // --------------------------------------------------------------
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013;
        
        #1; // Wait for initialization
        
        // CORRECTED PROGRAM WITH PIPELINE HAZARD FIX
        mem[0]  = 32'h00100793;  // addi x15, x0, 1     ; x15 = 1 (result)
        mem[1]  = 32'h00200713;  // addi x14, x0, 2     ; x14 = 2 (counter)  
        mem[2]  = 32'h00500693;  // addi x13, x0, 5     ; x13 = 5 (limit)
        mem[3]  = 32'h02e787b3;  // mul  x15, x15, x14  ; x15 = x15 * x14 (LOOP START)
        mem[4]  = 32'h00170713;  // addi x14, x14, 1    ; x14 = x14 + 1
        mem[5]  = 32'hfed74ce3;  // blt  x14, x13, -8   ; if x14 < x13, branch to mem[3]
        mem[6]  = 32'h00000013;  // nop                 ; PIPELINE HAZARD FIX
        mem[7]  = 32'h00078513;  // addi x10, x15, 0    ; x10 = x15 (move result)
        mem[8]  = 32'h00000073;  // ecall               ; end program
        
        $display("=== PIPELINE HAZARD FIX APPLIED ===");
        $display("Added NOP at mem[6] to resolve data hazard");
        $display("This ensures x15 writeback completes before x10 read");
        $display("");
        $display("MEMORY LAYOUT:");
        $display("  mem[0] = 0x%08h (addi x15,x0,1)   - init result=1", mem[0]);
        $display("  mem[1] = 0x%08h (addi x14,x0,2)   - init counter=2", mem[1]);
        $display("  mem[2] = 0x%08h (addi x13,x0,5)   - set limit=5", mem[2]);
        $display("  mem[3] = 0x%08h (mul x15,x15,x14) - multiply ← LOOP TARGET", mem[3]);
        $display("  mem[4] = 0x%08h (addi x14,x14,1)  - increment counter", mem[4]);
        $display("  mem[5] = 0x%08h (blt x14,x13,-8)  - branch back to mem[3]", mem[5]);
        $display("  mem[6] = 0x%08h (nop)             - PIPELINE HAZARD FIX", mem[6]);
        $display("  mem[7] = 0x%08h (addi x10,x15,0)  - move result to return reg", mem[7]);
        $display("  mem[8] = 0x%08h (ecall)           - terminate", mem[8]);
        $display("");
        $display("HAZARD RESOLUTION:");
        $display("  Problem: x10 read x15 before MUL result written");
        $display("  Solution: NOP ensures pipeline stages complete in order");
        $display("  Expected result: Both x15=24 AND x10=24");
    end
endmodule