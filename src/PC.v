
module PC_Module(clk, rst, PC, PC_Next);
    input clk, rst;
    input [31:0] PC_Next;
    output [31:0] PC;
    reg [31:0] PC;
    
    always @(posedge clk) begin
        if (rst == 1'b1) begin      // FIXED: rst=1 means reset (active-HIGH)
            PC <= 32'h0000_0000;   // FIXED: Start at address 0x00000000
            $display("PC_MODULE: RESET - PC set to 0x00000000");
        end
        else begin                  // rst=0 means normal operation
            PC <= PC_Next;
            $display("PC_MODULE: PC=0x%08h -> PC_Next=0x%08h", PC, PC_Next);
        end
    end
endmodule
