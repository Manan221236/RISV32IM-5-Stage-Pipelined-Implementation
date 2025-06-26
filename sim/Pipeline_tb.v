module Pipeline_Full_tb;

    //---------------------------- 1. Clock & Reset ----------------------------
    reg  clk;
    reg  rst;                     // active-HIGH reset
    
    initial begin
        clk = 0;
        forever #10 clk = ~clk;   // 50 MHz clock
    end
    
    //---------------------------- 2. Debug Signal Wires -----------------------
    wire [31:0] debug_alu_result;
    wire [4:0]  debug_reg_addr;
    wire        debug_reg_write;
    wire        debug_mem_write;

    //---------------------------- 3. Device Under Test ------------------------
    Pipeline_top dut ( 
        .clk(clk), 
        .rst(rst),
        .debug_alu_result(debug_alu_result),
        .debug_reg_addr(debug_reg_addr),
        .debug_reg_write(debug_reg_write),
        .debug_mem_write(debug_mem_write)
    );

    //---------------------------- 4. Simulation Setup -------------------------
    initial begin
        $dumpfile("pipeline_multiplication.vcd");
        $dumpvars(0, Pipeline_Full_tb);
        
        // Explicitly dump debug signals
        $dumpvars(1, debug_alu_result, debug_reg_addr, debug_reg_write, debug_mem_write);
        
        // Reset sequence
        rst = 1;  
        repeat (5) @(posedge clk);   // 5 cycles reset
        rst = 0;                     // release reset
        
        $display("=== RISC-V MULTIPLICATION LOOP TEST STARTED ===");
        $display("Testing: 4! factorial calculation using MUL instruction");
        $display("Expected result: 24 (1*2*3*4)");
        $display("Fixed program layout: starts at mem[0], loop at mem[3]");
    end

    //---------------------------- 5. Cycle Counter ----------------------------
    integer cyc;
    initial cyc = 0;
    always @(posedge clk) begin
        if (!rst) cyc = cyc + 1;
    end

    //---------------------------- 6. Basic Debug Output -----------------------
    always @(posedge clk) begin
        if (!rst) begin
            $display("DEBUG: cyc=%0d alu_result=0x%08h reg_addr=x%0d reg_write=%b mem_write=%b",
                     cyc, debug_alu_result, debug_reg_addr, debug_reg_write, debug_mem_write);
        end
    end

    //---------------------------- 7. Register Monitoring ----------------------
    always @(posedge clk) begin
        if (!rst && (cyc % 15 == 0) && (cyc > 0)) begin  // Every 15 cycles
            $display("REGISTERS: cyc=%0d a0(x10)=%0d a3(x13)=%0d a4(x14)=%0d a5(x15)=%0d", 
                     cyc, $signed(dut.Decode.rf.regf[10]), $signed(dut.Decode.rf.regf[13]),
                     $signed(dut.Decode.rf.regf[14]), $signed(dut.Decode.rf.regf[15]));
        end
    end

    //---------------------------- 8. Critical Register Writes ----------------
    always @(posedge clk) begin
        if (!rst && debug_reg_write && (debug_reg_addr != 5'd0)) begin
            case (debug_reg_addr)
                5'd10: $display("REGWRITE: a0(x10) <= %0d (return value)", $signed(debug_alu_result));
                5'd13: $display("REGWRITE: a3(x13) <= %0d (loop limit)", $signed(debug_alu_result));
                5'd14: $display("REGWRITE: a4(x14) <= %0d (loop counter)", $signed(debug_alu_result));
                5'd15: $display("REGWRITE: a5(x15) <= %0d (result accumulator)", $signed(debug_alu_result));
                default: $display("REGWRITE: x%0d <= %0d", debug_reg_addr, $signed(debug_alu_result));
            endcase
        end
    end

    //---------------------------- 9. Multiplication Detection -----------------
    always @(posedge clk) begin
        if (!rst && (dut.InstrD[6:0] == 7'b0110011) && (dut.InstrD[31:25] == 7'b0000001)) begin
            case (dut.InstrD[14:12])
                3'b000: $display("MUL_EXEC: MUL instruction detected at PC=0x%08h", dut.PCD);
                3'b001: $display("MUL_EXEC: MULH instruction detected at PC=0x%08h", dut.PCD);
                3'b010: $display("MUL_EXEC: MULHSU instruction detected at PC=0x%08h", dut.PCD);
                3'b011: $display("MUL_EXEC: MULHU instruction detected at PC=0x%08h", dut.PCD);
            endcase
        end
    end

    //---------------------------- 10. Branch Detection ------------------------
    always @(posedge clk) begin
        if (!rst && (dut.InstrD[6:0] == 7'b1100011)) begin
            $display("BRANCH: BLT instruction at PC=0x%08h, BranchE=%b", 
                     dut.PCD, dut.BranchE);
        end
    end

    //---------------------------- 11. Instruction Decoder --------------------
    function [1599:0] decode_instruction;  // 200*8-1 = 1599
        input [31:0] ins;
        reg [6:0] op;  
        reg [2:0] f3;  
        reg [6:0] f7;
        begin
            op = ins[6:0];
            f3 = ins[14:12];
            f7 = ins[31:25];
            decode_instruction = "UNKNOWN";
            
            case (op)
                // R-type & M-extension
                7'b0110011: begin
                    if (f7 == 7'b0000001) begin
                        case (f3)
                            3'b000: decode_instruction = "MUL";
                            3'b001: decode_instruction = "MULH";
                            3'b010: decode_instruction = "MULHSU";
                            3'b011: decode_instruction = "MULHU";
                        endcase
                    end else begin
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
                
                // I-type ALU
                7'b0010011: begin
                    case (f3)
                        3'b000: decode_instruction = (ins == 32'h0000_0013) ? "NOP" : "ADDI";
                        3'b001: decode_instruction = "SLLI";
                        3'b010: decode_instruction = "SLTI";
                        3'b011: decode_instruction = "SLTIU";
                        3'b100: decode_instruction = "XORI";
                        3'b101: decode_instruction = f7[5] ? "SRAI" : "SRLI";
                        3'b110: decode_instruction = "ORI";
                        3'b111: decode_instruction = "ANDI";
                    endcase
                end
                
                // Loads & Stores
                7'b0000011: begin
                    case (f3)
                        3'b000: decode_instruction = "LB";
                        3'b001: decode_instruction = "LH";
                        3'b010: decode_instruction = "LW";
                        3'b100: decode_instruction = "LBU";
                        3'b101: decode_instruction = "LHU";
                    endcase
                end
                7'b0100011: begin
                    case (f3)
                        3'b000: decode_instruction = "SB";
                        3'b001: decode_instruction = "SH";
                        3'b010: decode_instruction = "SW";
                    endcase
                end
                
                // Branches
                7'b1100011: begin
                    case (f3)
                        3'b000: decode_instruction = "BEQ";
                        3'b001: decode_instruction = "BNE";
                        3'b100: decode_instruction = "BLT";
                        3'b101: decode_instruction = "BGE";
                        3'b110: decode_instruction = "BLTU";
                        3'b111: decode_instruction = "BGEU";
                    endcase
                end
                
                // Jumps, LUI, AUIPC
                7'b1101111: decode_instruction = "JAL";
                7'b1100111: decode_instruction = "JALR";
                7'b0110111: decode_instruction = "LUI";
                7'b0010111: decode_instruction = "AUIPC";
                
                // System
                7'b1110011: decode_instruction = "ECALL";
            endcase
        end
    endfunction

    //---------------------------- 12. Instruction Trace -----------------------
    integer trace_log;
    reg [1599:0] asm_name;  // 200*8-1 = 1599
    initial begin
        trace_log = $fopen("instruction_trace.txt", "w");
    end
    
    always @(posedge clk) begin
        if (!rst && (dut.InstrD != 32'h0000_0013)) begin
            asm_name = decode_instruction(dut.InstrD);
            $display("TRACE: cyc=%0d PC=0x%08h instr=0x%08h %s",
                     cyc, dut.PCD, dut.InstrD, asm_name);
            $fdisplay(trace_log, "%0d,0x%08h,0x%08h,%s",
                      cyc, dut.PCD, dut.InstrD, asm_name);
        end
    end

    //---------------------------- 13. Register State Dumper -------------------
    task dump_critical_registers;
        begin
            $display("=== CRITICAL REGISTERS ===");
            $display("x0  (zero) = 0x%08h (%0d)", dut.Decode.rf.regf[0], $signed(dut.Decode.rf.regf[0]));
            $display("x10 (a0)   = 0x%08h (%0d) <- RESULT", dut.Decode.rf.regf[10], $signed(dut.Decode.rf.regf[10]));
            $display("x13 (a3)   = 0x%08h (%0d) <- LIMIT", dut.Decode.rf.regf[13], $signed(dut.Decode.rf.regf[13]));
            $display("x14 (a4)   = 0x%08h (%0d) <- COUNTER", dut.Decode.rf.regf[14], $signed(dut.Decode.rf.regf[14]));
            $display("x15 (a5)   = 0x%08h (%0d) <- ACCUMULATOR", dut.Decode.rf.regf[15], $signed(dut.Decode.rf.regf[15]));
        end
    endtask

    //---------------------------- 14. Results Checker -------------------------
    task check_multiplication_results;
        reg [31:0] final_a0, final_a5, final_a4, final_a3;
        integer err;
        begin
            final_a0 = dut.Decode.rf.regf[10];  // return value
            final_a5 = dut.Decode.rf.regf[15];  // result accumulator  
            final_a4 = dut.Decode.rf.regf[14];  // loop counter
            final_a3 = dut.Decode.rf.regf[13];  // loop limit
            
            err = 0;
            $display("");
            $display("=== MULTIPLICATION LOOP TEST RESULTS ===");
            dump_critical_registers();
            
            // Check factorial calculation: 4! = 24
            if (final_a0 !== 32'd24) begin
                $display("FAIL: Expected a0=24 (4! factorial), got a0=%0d", final_a0);
                err = err + 1;
            end else begin
                $display("PASS: a0 contains expected factorial result 24");
            end
            
            // Check result accumulator
            if (final_a5 !== 32'd24) begin
                $display("FAIL: Expected a5=24 (accumulator), got a5=%0d", final_a5);
                err = err + 1;
            end else begin
                $display("PASS: a5 contains expected result 24");
            end
            
            // Check loop limit - should be 5, not 4
            if (final_a3 !== 32'd5) begin
                $display("WARNING: Expected a3=5 (limit), got a3=%0d", final_a3);
            end else begin
                $display("PASS: Loop limit correctly set to 5");
            end

            // Correct factorial calculation trace
            $display("");
            $display("Factorial Calculation Trace:");
            $display("  Start: result=1, counter=2, limit=5");
            $display("  Step 1: 1 * 2 = 2,  counter=3 (3<5, continue)");
            $display("  Step 2: 2 * 3 = 6,  counter=4 (4<5, continue)"); 
            $display("  Step 3: 6 * 4 = 24, counter=5 (5>=5, exit)");
            $display("  Result: 24 moved to x10");

            if (err == 0) begin
                $display("");
                $display("ALL TESTS PASSED!");
                $display("RISC-V32IM Multiplication Loop Test: SUCCESS");
            end else begin
                $display("");
                $display("%0d TEST(S) FAILED!", err);
            end
        end
    endtask

    //---------------------------- 15. Program Termination ---------------------
    integer program_ended;
    integer ecall_detected;
    integer ecall_cycle;
    integer final_result_detected;
    
    initial begin
        program_ended = 0;
        ecall_detected = 0;
        ecall_cycle = 0;
        final_result_detected = 0;
    end
    
    always @(posedge clk) begin
        if (!rst && !program_ended) begin
            // Check if factorial calculation is complete (result = 24)
            if (dut.Decode.rf.regf[15] == 32'd24 && !final_result_detected) begin
                final_result_detected = 1;
                $display("");
                $display("=== FACTORIAL CALCULATION COMPLETE: x15 = 24 at cycle %0d ===", cyc);
            end
            
            // Detect ECALL instruction but don't terminate immediately
            if (dut.InstrD == 32'h00000073 && !ecall_detected) begin  // ECALL instruction
                ecall_detected = 1;
                ecall_cycle = cyc;
                $display("");
                $display("=== ECALL DETECTED at cycle %0d - Allowing pipeline to complete ===", cyc);
            end
            
            // Terminate only after ECALL has been detected AND pipeline has settled
            if (ecall_detected && (cyc >= ecall_cycle + 8)) begin
                program_ended = 1;
                $display("");
                $display("=== PROGRAM COMPLETED at cycle %0d ===", cyc);
                repeat (3) @(posedge clk);   // allow final pipeline operations
                
                check_multiplication_results();
                
                $display("");
                $display("Performance Statistics:");
                $display("  Total execution cycles: %0d", cyc);
                $display("  Instructions in program: 8");
                $display("  Average CPI: %0d", cyc / 8);
                $display("  Clock frequency: 50 MHz");
                $display("  Execution time: %0d ns", cyc * 20);
                
                $fclose(trace_log);
                $display("");
                $display("=== SIMULATION COMPLETE ===");
                $finish;
            end
            
            // Alternative termination: if result is correct AND ECALL detected
            if (final_result_detected && ecall_detected && (cyc >= ecall_cycle + 3)) begin
                program_ended = 1;
                $display("");
                $display("=== PROGRAM COMPLETED SUCCESSFULLY at cycle %0d ===", cyc);
                repeat (3) @(posedge clk);
                check_multiplication_results();
                $fclose(trace_log);
                $finish;
            end
            
            // Safety: if PC goes beyond program space
            if (dut.PCD > 32'h0000001C && !ecall_detected) begin  
                program_ended = 1;
                $display("");
                $display("=== PROGRAM ENDED (PC out of range) at cycle %0d ===", cyc);
                repeat (3) @(posedge clk);
                check_multiplication_results();
                $fclose(trace_log);
                $finish;
            end
        end
    end

    //---------------------------- 16. Safety Timeout --------------------------
    initial begin
        #200000; // 200us timeout
        $display("");
        $display("ERROR: Simulation timeout - program may be stuck");
        $display("Final state at timeout:");
        $display("  PC: 0x%08h", dut.PCD);
        $display("  Current instruction: 0x%08h", dut.InstrD);
        $display("  Cycles executed: %0d", cyc);
        
        check_multiplication_results();
        $fclose(trace_log);
        $finish;
    end

    //---------------------------- 17. Early Debug ----------------------------- 
    always @(posedge clk) begin
        if (!rst && (cyc <= 10)) begin
            $display("EARLY: cyc=%0d PC=0x%08h instr=0x%08h", 
                     cyc, dut.PCD, dut.InstrD);
        end
    end

    //---------------------------- 18. Performance Monitor ---------------------
    integer mul_count;
    integer branch_count;
    
    initial begin
        mul_count = 0;
        branch_count = 0;
    end
    
    always @(posedge clk) begin
        if (!rst) begin
            // Count multiplication instructions
            if ((dut.InstrD[6:0] == 7'b0110011) && (dut.InstrD[31:25] == 7'b0000001) && (dut.InstrD[14:12] == 3'b000)) begin
                mul_count = mul_count + 1;
                $display("MUL_COUNT: Multiplication #%0d executed", mul_count);
                
                // Report expected result after each multiplication
                case (mul_count)
                    1: $display("  Expected after MUL #1: x15 should become 2 (1*2)");
                    2: $display("  Expected after MUL #2: x15 should become 6 (2*3)");
                    3: $display("  Expected after MUL #3: x15 should become 24 (6*4)");
                endcase
            end
            
            // Count taken branches
            if (dut.PCSrcE && dut.BranchE) begin
                branch_count = branch_count + 1;
                $display("BRANCH_COUNT: Branch #%0d taken", branch_count);
                $display("  Branching back to multiplication loop");
            end
        end
    end
    
    //---------------------------- 19. Third Multiplication Monitor -----------
    always @(posedge clk) begin
        if (!rst && mul_count == 3) begin
            $display("");
            $display("=== THIRD MULTIPLICATION DETECTED ===");
            $display("This should calculate: 6 * 4 = 24");
            $display("Monitoring register x15 for final result...");
        end
    end

endmodule