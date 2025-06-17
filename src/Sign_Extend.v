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

    // optional debug (kept as-is)
    always @(*) begin
        if (In[6:0] == 7'b0010011 && ImmSrc == 3'b000) begin
            $display("DEBUG Sign_Extend: Instr=0x%08h, In[31:20]=%012b (%0d), Output=0x%08h (%0d)",
                     In, In[31:20], $signed(In[31:20]), Imm_Ext, $signed(Imm_Ext));
        end
    end
endmodule
