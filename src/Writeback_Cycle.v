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
    
    // CRITICAL DEBUG: Track writeback result selection
    always @(*) begin
        if (ResultSrcW == 2'b00 && ALU_ResultW != 0) begin
            $display("WRITEBACK_MUX: Selecting ALU result 0x%08h (%0d) for writeback", 
                     ALU_ResultW, $signed(ALU_ResultW));
        end
        else if (ResultSrcW == 2'b01) begin
            $display("WRITEBACK_MUX: Selecting memory data 0x%08h for writeback", ReadDataW);
        end
        else if (ResultSrcW == 2'b10) begin
            $display("WRITEBACK_MUX: Selecting PC+4 0x%08h for writeback (JAL/JALR)", PCPlus4W);
        end
    end
    
    // ENHANCED DEBUG: Track final result
    always @(*) begin
        if (ResultW != 0) begin
            $display("WRITEBACK_FINAL: Final result = 0x%08h (%0d) from source %b", 
                     ResultW, $signed(ResultW), ResultSrcW);
        end
    end
    
    // MULTIPLICATION SPECIFIC DEBUG
    always @(*) begin
        if (ALU_ResultW == 32'd4 || ALU_ResultW == 32'd6 || ALU_ResultW == 32'd24) begin
            $display("WRITEBACK_FACTORIAL: Detected factorial value %0d in writeback!", $signed(ALU_ResultW));
        end
    end
endmodule