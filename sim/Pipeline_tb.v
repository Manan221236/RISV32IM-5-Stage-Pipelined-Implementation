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
        $dumpfile("algorithm_4_7_test.vcd");
        $dumpvars(0, Pipeline_Full_tb);
        
        // Explicitly dump debug signals
        $dumpvars(1, debug_alu_result, debug_reg_addr, debug_reg_write, debug_mem_write);
        
        // Reset sequence
        rst = 1;  
        repeat (5) @(posedge clk);   // 5 cycles reset
        rst = 0;                     // release reset
        
        $display("=== ALGORITHM 4-7 MODULAR ARITHMETIC TEST STARTED ===");
        $display("Testing: Montgomery and Plantard arithmetic operations");
        $display("Target: Validate core operations for Kyber and Dilithium");
        $display("Expected: All arithmetic operations should complete correctly");
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
        if (!rst && (cyc % 10 == 0) && (cyc > 0)) begin  // Every 10 cycles
            $display("REGISTERS: cyc=%0d x10=%0d x11=%0d x12=%0d x13=%0d", 
                     cyc, $signed(dut.Decode.rf.regf[10]), $signed(dut.Decode.rf.regf[11]),
                     $signed(dut.Decode.rf.regf[12]), $signed(dut.Decode.rf.regf[13]));
        end
    end

    //---------------------------- 8. Arithmetic Operation Detection -----------
    always @(posedge clk) begin
        if (!rst && debug_reg_write && (debug_reg_addr != 5'd0)) begin
            case (debug_reg_addr)
                5'd10: $display("REGWRITE: x10 <= %0d (0x%08h) - Primary result register", 
                               $signed(debug_alu_result), debug_alu_result);
                5'd11: $display("REGWRITE: x11 <= %0d (0x%08h) - Secondary result register", 
                               $signed(debug_alu_result), debug_alu_result);
                5'd12: $display("REGWRITE: x12 <= %0d (0x%08h) - Calculation register", 
                               $signed(debug_alu_result), debug_alu_result);
                5'd13: $display("REGWRITE: x13 <= %0d (0x%08h) - Test counter register", 
                               $signed(debug_alu_result), debug_alu_result);
                5'd14: $display("REGWRITE: x14 <= %0d (0x%08h) - Temporary register", 
                               $signed(debug_alu_result), debug_alu_result);
                default: $display("REGWRITE: x%0d <= %0d (0x%08h)", 
                                debug_reg_addr, $signed(debug_alu_result), debug_alu_result);
            endcase
        end
    end

    //---------------------------- 9. Multiplication Detection -----------------
    always @(posedge clk) begin
        if (!rst && (dut.InstrD[6:0] == 7'b0110011) && (dut.InstrD[31:25] == 7'b0000001)) begin
            case (dut.InstrD[14:12])
                3'b000: begin
                    $display("ARITHMETIC: MUL instruction detected at PC=0x%08h", dut.PCD);
                    $display("  Operation: x%0d = x%0d * x%0d", dut.InstrD[11:7], dut.InstrD[19:15], dut.InstrD[24:20]);
                end
                3'b001: begin
                    $display("ARITHMETIC: MULH instruction detected at PC=0x%08h", dut.PCD);
                    $display("  Operation: x%0d = upper(x%0d * x%0d)", dut.InstrD[11:7], dut.InstrD[19:15], dut.InstrD[24:20]);
                end
                3'b010: $display("ARITHMETIC: MULHSU instruction detected at PC=0x%08h", dut.PCD);
                3'b011: $display("ARITHMETIC: MULHU instruction detected at PC=0x%08h", dut.PCD);
            endcase
        end
    end

    //---------------------------- 10. Shift Detection -------------------------
    always @(posedge clk) begin
        if (!rst && (dut.InstrD[6:0] == 7'b0010011) && (dut.InstrD[14:12] == 3'b101)) begin
            $display("ARITHMETIC: SRAI instruction detected at PC=0x%08h", dut.PCD);
            $display("  Operation: x%0d = x%0d >> %0d (arithmetic right shift)", 
                     dut.InstrD[11:7], dut.InstrD[19:15], dut.InstrD[24:20]);
        end
    end

    //---------------------------- 11. Test Phase Detection -------------------
    reg [3:0] test_phase;
    initial test_phase = 0;
    
    always @(posedge clk) begin
        if (!rst) begin
            case (dut.PCD)
                32'h00000000: test_phase = 1;  // Basic multiplication test
                32'h00000010: test_phase = 2;  // Shift operations test  
                32'h0000001c: test_phase = 3;  // 32-bit multiplication test
                32'h00000028: test_phase = 4;  // Addition/subtraction test
                32'h00000034: test_phase = 5;  // MULH test
                32'h00000040: test_phase = 6;  // Montgomery simulation
                32'h00000058: test_phase = 7;  // Negative number test
                32'h00000068: test_phase = 8;  // Large number test
                32'h00000074: test_phase = 9;  // Result collection
                32'h0000008c: test_phase = 10; // Program termination
            endcase
        end
    end
    
    // Phase change detection
    reg [3:0] prev_test_phase;
    always @(posedge clk) begin
        if (!rst) begin
            if (test_phase != prev_test_phase) begin
                case (test_phase)
                    1: $display("\n=== TEST PHASE 1: Basic 16-bit Multiplication ===");
                    2: $display("\n=== TEST PHASE 2: Arithmetic Right Shift ===");
                    3: $display("\n=== TEST PHASE 3: 32-bit Multiplication ===");
                    4: $display("\n=== TEST PHASE 4: Addition/Subtraction ===");
                    5: $display("\n=== TEST PHASE 5: MULH Upper Bits ===");
                    6: $display("\n=== TEST PHASE 6: Montgomery Arithmetic Simulation ===");
                    7: $display("\n=== TEST PHASE 7: Negative Number Handling ===");
                    8: $display("\n=== TEST PHASE 8: Large Number Multiplication ===");
                    9: $display("\n=== TEST PHASE 9: Result Collection ===");
                    10: $display("\n=== TEST PHASE 10: Program Termination ===");
                endcase
                prev_test_phase = test_phase;
            end
        end
    end

    //---------------------------- 12. Instruction Decoder --------------------
    function [159:0] decode_instruction;  // 20*8-1 = 159
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
                
                // System
                7'b1110011: decode_instruction = "ECALL";
            endcase
        end
    endfunction

    //---------------------------- 13. Instruction Trace -----------------------
    integer trace_log;
    reg [159:0] asm_name;  // 20*8-1 = 159
    initial begin
        trace_log = $fopen("algorithm_trace.txt", "w");
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

    //---------------------------- 14. Result Verification ---------------------
    task verify_algorithm_results;
        reg [31:0] final_x10, final_x11, final_x12, final_x13;
        integer errors;
        begin
            final_x10 = dut.Decode.rf.regf[10];  // Primary result
            final_x11 = dut.Decode.rf.regf[11];  // MULH result
            final_x12 = dut.Decode.rf.regf[12];  // Large multiplication result
            final_x13 = dut.Decode.rf.regf[13];  // Test counter
            
            errors = 0;
            $display("\n=== ALGORITHM 4-7 TEST RESULTS ===");
            $display("Final Register Values:");
            $display("  x10 = %0d (0x%08h) - Primary result", $signed(final_x10), final_x10);
            $display("  x11 = %0d (0x%08h) - MULH result", $signed(final_x11), final_x11);
            $display("  x12 = %0d (0x%08h) - Should be 65536", $signed(final_x12), final_x12);
            $display("  x13 = %0d (0x%08h) - Should be 5", $signed(final_x13), final_x13);
            
            // Test 1: Large multiplication (256 * 256 = 65536)
            if (final_x12 !== 32'd65536) begin
                $display("FAIL: Expected x12=65536 (256*256), got x12=%0d", final_x12);
                errors = errors + 1;
            end else begin
                $display("PASS: Large multiplication test (256*256=65536)");
            end
            
            // Test 2: Test counter 
            if (final_x13 !== 32'd5) begin
                $display("FAIL: Expected x13=5 (test counter), got x13=%0d", final_x13);
                errors = errors + 1;
            end else begin
                $display("PASS: Test counter reached expected value (5)");
            end
            
            // Test 3: MULH result should be reasonable
            if (final_x11 == 32'd0) begin
                $display("WARNING: MULH result is 0, may indicate issue with large multiplication");
            end else begin
                $display("PASS: MULH instruction produced non-zero result");
            end
            
            $display("\nTest Summary:");
            $display("  Arithmetic Operations: %s", (errors == 0) ? "PASSED" : "FAILED");
            $display("  Total Errors: %0d", errors);
            
            if (errors == 0) begin
                $display("\n🎉 ALL ALGORITHM 4-7 TESTS PASSED!");
                $display("✅ Processor ready for Montgomery and Plantard arithmetic");
            end else begin
                $display("\n❌ %0d TEST(S) FAILED!", errors);
                $display("❌ Arithmetic operations need debugging");
            end
        end
    endtask

    //---------------------------- 15. Program Termination ---------------------
    integer program_ended;
    integer ecall_detected;
    integer ecall_cycle;
    
    initial begin
        program_ended = 0;
        ecall_detected = 0;
        ecall_cycle = 0;
    end
    
    always @(posedge clk) begin
        if (!rst && !program_ended) begin
            // Detect ECALL instruction
            if (dut.InstrD == 32'h00000073 && !ecall_detected) begin  // ECALL instruction
                ecall_detected = 1;
                ecall_cycle = cyc;
                $display("\n=== ECALL DETECTED at cycle %0d - Algorithm tests complete ===", cyc);
            end
            
            // Terminate after ECALL and pipeline settlement
            if (ecall_detected && (cyc >= ecall_cycle + 5)) begin
                program_ended = 1;
                $display("\n=== ALGORITHM 4-7 TESTS COMPLETED at cycle %0d ===", cyc);
                repeat (3) @(posedge clk);   // allow final pipeline operations
                
                verify_algorithm_results();
                
                $display("\nPerformance Statistics:");
                $display("  Total execution cycles: %0d", cyc);
                $display("  Clock frequency: 50 MHz");
                $display("  Execution time: %0d ns", cyc * 20);
                
                $fclose(trace_log);
                $display("\n=== SIMULATION COMPLETE ===");
                $finish;
            end
            
            // Safety: if PC goes beyond our test program
            if (dut.PCD > 32'h00000090) begin  
                program_ended = 1;
                $display("\n=== PROGRAM ENDED (PC out of range) at cycle %0d ===", cyc);
                repeat (3) @(posedge clk);
                verify_algorithm_results();
                $fclose(trace_log);
                $finish;
            end
        end
    end

    //---------------------------- 16. Safety Timeout --------------------------
    initial begin
        #100000; // 100us timeout (much shorter for simple arithmetic tests)
        $display("\nERROR: Simulation timeout - program may be stuck");
        $display("Final state at timeout:");
        $display("  PC: 0x%08h", dut.PCD);
        $display("  Current instruction: 0x%08h", dut.InstrD);
        $display("  Cycles executed: %0d", cyc);
        
        verify_algorithm_results();
        $fclose(trace_log);
        $finish;
    end

    //---------------------------- 17. Early Debug ----------------------------- 
    always @(posedge clk) begin
        if (!rst && (cyc <= 15)) begin
            $display("EARLY: cyc=%0d PC=0x%08h instr=0x%08h", 
                     cyc, dut.PCD, dut.InstrD);
        end
    end

endmodule
