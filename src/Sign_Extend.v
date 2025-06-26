module Sign_Extend (
    input  [31:0] In,
    input  [2:0]  ImmSrc,   // 3 bits
    output [31:0] Imm_Ext
);
    assign Imm_Ext =
        (ImmSrc == 3'b000) ? {{20{In[31]}},  In[31:20]}                                        : // I
        (ImmSrc == 3'b001) ? {{20{In[31]}},  In[31:25], In[11:7]}                              : // S
        (ImmSrc == 3'b010) ? {{19{In[31]}},  In[31], In[7], In[30:25], In[11:8], 1'b0}         : // B
        (ImmSrc == 3'b011) ? {             In[31:12]                       , 12'b0}           : // U
        (ImmSrc == 3'b100) ? {{11{In[31]}}, In[31], In[19:12], In[20], In[30:21], 1'b0}        : // J
                             32'h0000_0000;

    // Enhanced debug output specifically for branch instructions
    always @(*) begin
        if (In[6:0] == 7'b0010011 && ImmSrc == 3'b000) begin  // I-type
            $display("DEBUG Sign_Extend: I-type Instr=0x%08h, In[31:20]=%012b (%0d), Output=0x%08h (%0d)",
                     In, In[31:20], $signed(In[31:20]), Imm_Ext, $signed(Imm_Ext));
        end
        else if (In[6:0] == 7'b1100011 && ImmSrc == 3'b010) begin  // B-type
            $display("DEBUG Sign_Extend: B-type Instr=0x%08h", In);
            $display("  Raw bits: [31]=%b [7]=%b [30:25]=%06b [11:8]=%04b", 
                     In[31], In[7], In[30:25], In[11:8]);
            $display("  B-format: {%b, %b, %b, %06b, %04b, 1'b0}", 
                     {19{In[31]}}, In[31], In[7], In[30:25], In[11:8]);
            $display("  Calculated offset: 0x%08h (%0d)", Imm_Ext, $signed(Imm_Ext));
            
            // Manual verification for the specific instruction 0xfee7c4e3
            if (In == 32'hfee7c4e3) begin
                $display("  SPECIFIC DEBUG for blt instruction:");
                $display("    Expected: branch back to 0x08 from PC=0x0C, offset=-4");
                $display("    Bit breakdown:");
                $display("      In[31]   = %b (sign bit)", In[31]);
                $display("      In[7]    = %b (imm[11])", In[7]); 
                $display("      In[30:25]= %06b (imm[10:5])", In[30:25]);
                $display("      In[11:8] = %04b (imm[4:1])", In[11:8]);
                $display("    Should form: offset = -4 = 0xFFFFFFFC");
            end
        end
    end
endmodule