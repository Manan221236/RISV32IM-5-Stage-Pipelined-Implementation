module Pipeline_Full_tb;

    //---------------------------- 1. clock / reset -------------------
    reg  clk = 0;
    reg  rst = 0;                 // active-LOW
    always #10 clk = ~clk;        // 50 MHz

    //---------------------------- 2. Debug signal wires --------------
    wire [31:0] debug_alu_result;
    wire [4:0]  debug_reg_addr;
    wire        debug_reg_write;
    wire        debug_mem_write;

    //---------------------------- 3. DUT -----------------------------
    Pipeline_top dut ( 
        .clk(clk), 
        .rst(rst),
        .debug_alu_result(debug_alu_result),
        .debug_reg_addr(debug_reg_addr),
        .debug_reg_write(debug_reg_write),
        .debug_mem_write(debug_mem_write)
    );

    //---------------------------- 4. wave + reset pulse --------------
    initial begin
        $dumpfile("pipeline_full.vcd");
        $dumpvars(0, Pipeline_Full_tb);
        
        // Explicitly dump debug signals for better visibility
        $dumpvars(1, debug_alu_result);
        $dumpvars(1, debug_reg_addr);
        $dumpvars(1, debug_reg_write);
        $dumpvars(1, debug_mem_write);

        rst = 0;  repeat (2) @(posedge clk);   // 2 cycles reset
        rst = 1;                               // release reset
    end

    //---------------------------- 5. cycle counter -------------------
    integer cyc = 0;
    always @(posedge clk) if (rst) cyc = cyc + 1;

    //---------------------------- 6. Debug signal monitoring ----------
    always @(posedge clk) begin
        if (rst) begin
            $display("DEBUG: cyc=%0d alu_result=0x%08h reg_addr=x%0d reg_write=%b mem_write=%b",
                     cyc, debug_alu_result, debug_reg_addr, debug_reg_write, debug_mem_write);
        end
    end

    //----------------------------------------------------------------
    // 7. 32-bit → ASCII decoder (input argument is mandatory!)
    //----------------------------------------------------------------
    function [200*8-1:0] decode_instruction;
        input [31:0] ins;
        reg [6:0] op;  reg [2:0] f3;  reg [6:0] f7;
        begin
            op = ins[6:0];
            f3 = ins[14:12];
            f7 = ins[31:25];
            decode_instruction = "UNKNOWN";
            case (op)

            // ---------------- R / M-extension -----------------------
            7'b0110011 : begin
                if (f7 == 7'b0000001) begin
                    case (f3)
                        3'b000: decode_instruction = "MUL";
                        3'b001: decode_instruction = "MULH";
                        3'b010: decode_instruction = "MULHSU";
                        3'b011: decode_instruction = "MULHU";
                    endcase
                end
                else begin
                    case (f3)
                        3'b000: decode_instruction = f7[5] ? "SUB" : "ADD";
                        3'b001: decode_instruction = "SLL";
                        3'b010: decode_instruction = "SLT";
                        3'b011: decode_instruction = "SLTU";
                        3'b100: decode_instruction = "XOR";
                        3'b101: decode_instruction = f7[5] ? "SRA" : "SRL";
                        3'b110: decode_instruction = "OR";
                        3'b111: decode_instruction = "AND";
                    endcase
                end
            end

            // ---------------- I-type ALU ----------------------------
            7'b0010011 : begin
                case (f3)
                    3'b000: decode_instruction =
                             (ins == 32'h0000_0013) ? "NOP" : "ADDI";
                    3'b001: decode_instruction = "SLLI";
                    3'b010: decode_instruction = "SLTI";
                    3'b011: decode_instruction = "SLTIU";
                    3'b100: decode_instruction = "XORI";
                    3'b101: decode_instruction = f7[5] ? "SRAI" : "SRLI";
                    3'b110: decode_instruction = "ORI";
                    3'b111: decode_instruction = "ANDI";
                endcase
            end

            // ---------------- Loads --------------------------------
            7'b0000011 : begin
                case (f3)
                    3'b000: decode_instruction = "LB";
                    3'b001: decode_instruction = "LH";
                    3'b010: decode_instruction = "LW";
                    3'b100: decode_instruction = "LBU";
                    3'b101: decode_instruction = "LHU";
                endcase
            end

            // ---------------- Stores -------------------------------
            7'b0100011 : begin
                case (f3)
                    3'b000: decode_instruction = "SB";
                    3'b001: decode_instruction = "SH";
                    3'b010: decode_instruction = "SW";
                endcase
            end

            // ---------------- Branches -----------------------------
            7'b1100011 : begin
                case (f3)
                    3'b000: decode_instruction = "BEQ";
                    3'b001: decode_instruction = "BNE";
                    3'b100: decode_instruction = "BLT";
                    3'b101: decode_instruction = "BGE";
                    3'b110: decode_instruction = "BLTU";
                    3'b111: decode_instruction = "BGEU";
                endcase
            end

            // ---------------- Jumps, LUI, AUIPC --------------------
            7'b1101111 : decode_instruction = "JAL";
            7'b1100111 : decode_instruction = "JALR";
            7'b0110111 : decode_instruction = "LUI";
            7'b0010111 : decode_instruction = "AUIPC";
            endcase
        end
    endfunction

    //----------------------------------------------------------------
    // 8. Decode-stage trace (console + CSV)
    //----------------------------------------------------------------
    integer dlog;  reg [200*8-1:0] asm;
    initial dlog = $fopen("decoded_instr.txt","w");

    always @(posedge clk) begin
        if (rst && dut.Decode.InstrD != 32'h0000_0013) begin
            asm = decode_instruction(dut.Decode.InstrD);
            $display("DECODE: cyc=%0d pc=%08h instr=%08h  %s",
                     cyc, dut.Decode.PCD, dut.Decode.InstrD, asm);
            $fdisplay(dlog,"%0d,%08h,%08h,%s",
                      cyc, dut.Decode.PCD, dut.Decode.InstrD, asm);
        end
    end

    //----------------------------------------------------------------
    // 9. Score-board (same five results)
    //----------------------------------------------------------------
    task check_results;
        reg [31:0] r16,r17,r24,r25,mem80; integer err;
        begin
            r16   = dut.Decode.rf.regf[16];
            r17   = dut.Decode.rf.regf[17];
            r24   = dut.Decode.rf.regf[24];
            r25   = dut.Decode.rf.regf[25];
            mem80 = dut.Memory.dmem.mem[32];

            err = 0;
            if (r16!==32'd8)  begin $display("FAIL: x16=%0d",r16); err=err+1; end
            if (r17!==32'd2)  begin $display("FAIL: x17=%0d",r17); err=err+1; end
            if (r24!==32'd7)  begin $display("FAIL: x24=%0d",r24); err=err+1; end
            if (r25!==32'd1)  begin $display("FAIL: x25=%0d",r25); err=err+1; end
            if (mem80!==32'h12345000) begin
                $display("FAIL: MEM[0x80]=0x%08h",mem80); err=err+1; end

            if (err==0)
                $display("\n>>>>>  ALL TESTS PASSED!  <<<<<\n");
            else
                $display("\n>>>>>  %0d TEST(S) FAILED! <<<<<\n",err);
        end
    endtask

    //----------------------------------------------------------------
    // 10. Stop on first JAL 0 (PC = 0xC0) so second lap never starts
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (rst && dut.PCD == 32'h000000C0) begin
            repeat (6) @(posedge clk);   // allow write-back to finish
            check_results;
            $finish;
        end
    end
endmodule