module Register_File
(
    input         clk,
    input         rst,        // active-high
    input         WE3,        // write enable
    input  [4:0]  A1, A2, A3, // rs1, rs2, rd
    input  [31:0] WD3,        // write data
    output [31:0] RD1, RD2    // read data
);
    // --------------------------------------------------------------
    // 32 × 32-bit register array
    // --------------------------------------------------------------
    reg [31:0] regf [0:31];
    integer    i;
    
    // --------------------------------------------------------------
    // FIXED: write port with Active-HIGH reset and STACK INITIALIZATION
    // --------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin           // rst=1 means reset (active-HIGH)
            // reset - clear whole file
            for (i = 0; i < 32; i = i + 1)
                regf[i] <= 32'h0000_0000;
                
            // CRITICAL FIX: Initialize stack pointer to valid address
            regf[2] <= 32'h0000_1000;  // SP = 4KB (top of data memory)
            
            $display("REGFILE: RESET - All registers cleared");
            $display("REGFILE: Stack pointer (x2) initialized to 0x00001000");
        end
        else begin
            if (WE3 && (A3 != 5'd0))
                regf[A3] <= WD3;         // architectural write
            regf[0] <= 32'h0000_0000;    // keep x0 hard-wired to 0
        end
    end
    
    // --------------------------------------------------------------
    // read ports with 1-cycle bypass (combinational)
    // --------------------------------------------------------------
    wire bypassA = (A1 == A3) && WE3 && (A3 != 5'd0);
    wire bypassB = (A2 == A3) && WE3 && (A3 != 5'd0);
    
    assign RD1 = (A1 == 5'd0)         ? 32'h0000_0000 :
                 bypassA              ? WD3            :
                                        regf[A1];
    assign RD2 = (A2 == 5'd0)         ? 32'h0000_0000 :
                 bypassB              ? WD3            :
                                        regf[A2];
    
    // --------------------------------------------------------------
    // Register write trace
    // --------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst && WE3 && (A3 != 5'd0))
            $display("REGWRITE: t=%0t  x%0d <= 0x%08h (%0d)",
                     $time, A3, WD3, $signed(WD3));
    end
endmodule