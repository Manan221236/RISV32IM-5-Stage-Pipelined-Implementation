module writeback_cycle(clk, rst, ResultSrcW, PCPlus4W, ALU_ResultW, ReadDataW, ResultW);
    // Declaration of IOs
    input clk, rst;
    input [1:0] ResultSrcW;
    input [31:0] PCPlus4W, ALU_ResultW, ReadDataW;
    output [31:0] ResultW;
    
    // 3-to-1 Mux for result selection
    assign ResultW = (ResultSrcW == 2'b00) ? ALU_ResultW :    // ALU result
                     (ResultSrcW == 2'b01) ? ReadDataW :      // Memory data
                     (ResultSrcW == 2'b10) ? PCPlus4W :       // PC+4 for JAL/JALR
                     32'h00000000;                            // Default
endmodule