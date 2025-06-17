module Instruction_Memory
(
    input         rst,
    input  [31:0] A,          // byte address from IF stage
    output [31:0] RD          // fetched instruction
);

    // 1 Ki × 32-bit ROM (only first 256 words used here)
    reg [31:0] mem [0:255];
    integer i;
    // combinational read - drive NOPs while core is in reset
    assign RD = rst ? mem[A[31:2]] : 32'h0000_0013;   // ADDI x0,x0,0

    // --------------------------------------------------------------
    //  Program image ("golden" values are checked in the TB)
    // --------------------------------------------------------------
    initial begin
        
        $display("=== FULL RV32IM SELF-TEST ROM LOADED ===");

        // -------- SECTION 0 : small GPR init ----------------------
        mem[  0] = 32'h00500513;   // addi x10,x0,5
        mem[  1] = 32'h00300593;   // addi x11,x0,3
        mem[  2] = 32'h08000613;   // addi x12,x0,128  (spare base)

        // -------- SECTION 1 : all R-type ops ----------------------
        mem[  3] = 32'h00b50833;   // add  x16,x10,x11   (=8)
        mem[  4] = 32'h40b508b3;   // sub  x17,x10,x11   (=2)
        mem[  5] = 32'h00b51933;   // sll  x18,x10,x11
        mem[  6] = 32'h00b529b3;   // slt  x19,x10,x11
        mem[  7] = 32'h00b53a33;   // sltu x20,x10,x11
        mem[  8] = 32'h00b54ab3;   // xor  x21,x10,x11
        mem[  9] = 32'h00b55b33;   // srl  x22,x10,x11
        mem[ 10] = 32'h40b55bb3;   // sra  x23,x10,x11
        mem[ 11] = 32'h00b56c33;   // or   x24,x10,x11   (=7)
        mem[ 12] = 32'h00b57cb3;   // and  x25,x10,x11   (=1)

        // -------- SECTION 2 : I-type & shifts ---------------------
        mem[ 13] = 32'h00550d13;   // addi  x26,x10,5
        mem[ 14] = 32'h00352d93;   // slti  x27,x10,3
        mem[ 15] = 32'h00353e13;   // sltiu x28,x10,3
        mem[ 16] = 32'h00754e93;   // xori  x29,x10,7
        mem[ 17] = 32'h00756f13;   // ori   x30,x10,7
        mem[ 18] = 32'h00357f93;   // andi  x31,x10,3
        mem[ 19] = 32'h00151513;   // slli  x10,x10,1   (x10 now 10)
        mem[ 20] = 32'h00155613;   // srli  x12,x10,1
        mem[ 21] = 32'h40155693;   // srai  x13,x10,1

        // -------- SECTION 3 : LUI / AUIPC -------------------------
        mem[ 22] = 32'h12345737;   // lui   x14,0x12345   // lui   x15,0x12345
        mem[ 23] = 32'h00000797;   // auipc x15,0        (PC-relative test)

        // -------- SECTION 4 : M-extension -------------------------
        mem[ 24] = 32'h02b50533;   // mul    x10,x10,x11
        mem[ 25] = 32'h02b51533;   // mulh   x10,x10,x11
        mem[ 26] = 32'h02b52533;   // mulhsu x10,x10,x11
        mem[ 27] = 32'h02b53533;   // mulhu  x10,x10,x11

        // -------- SECTION 5 : stores + loads ----------------------
        mem[ 28] = 32'h08000593;   // addi x11,x0,128           (base = 0x80)
        mem[ 29] = 32'h00e5a023;   // sw   x14,0(x11)
        mem[ 30] = 32'h00e59223;   // sh   x14,4(x11)
        mem[ 31] = 32'h00e58423;   // sb   x14,8(x11)
        mem[ 32] = 32'h0005c603;   // lb   x12,0(x11)
        mem[ 33] = 32'h0045d683;   // lh   x13,4(x11)
        mem[ 34] = 32'h0085c703;   // lbu  x14,8(x11)
        mem[ 35] = 32'h0005d783;   // lhu  x15,0(x11)
        mem[36] = 32'h0005af03;   // GOOD: lw x30,0(x11)

        // -------- SECTION 6 : branches & jumps --------------------
        mem[ 37] = 32'h00500893;   // addi x17,x0,5
        mem[ 38] = 32'h00300913;   // addi x18,x0,3
        mem[ 39] = 32'h01289463;   // bne  x17,x18,+8  (skip next instr)
        mem[ 40] = 32'h00000993;   // addi x19,x0,0    (skipped)
        mem[ 41] = 32'h00400993;   // addi x19,x0,4
        mem[ 42] = 32'h01194463;   // blt  x18,x17,+8  (skip next)
        mem[ 43] = 32'h00000A13;   // addi x20,x0,0    (skipped)
        mem[ 44] = 32'h00800A13;   // addi x20,x0,8

        mem[ 45] = 32'h00800AEF;   // jal  x21,+8      (link in x21)
        mem[ 46] = 32'h00000013;   // nop              (delay slot flushed)
        mem[ 47] = 32'h000A8067;   // jalr x0,0(x21)   (return)

        // -------- SECTION 7 : done - tight loop -------------------
        mem[ 48] = 32'h0000006F;   // jal  0           (forever)

        // fill rest with NOPs
        
        for (i = 49; i < 256; i = i + 1)
            mem[i] = 32'h00000013;
    end
endmodule