module fetch_cycle(clk, rst, PCSrcE, PCTargetE, JALR_TargetE, JumpE, InstrD, PCD, PCPlus4D, is_jalr_E);
    // Declare input & outputs
    input clk, rst;
    input PCSrcE, JumpE, is_jalr_E;
    input [31:0] PCTargetE, JALR_TargetE;
    output [31:0] InstrD;
    output [31:0] PCD, PCPlus4D;
    
    // Declaring interim wires
    wire [31:0] PC_F, PCF, PCPlus4F;
    wire [31:0] InstrF;
    wire [31:0] PC_Next;
    
    // Declaration of Register
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;
    
    // PC Next selection: JALR has priority, then other jumps/branches, then PC+4
    assign PC_Next = (JumpE & is_jalr_E) ? JALR_TargetE :
                     PCSrcE ? PCTargetE :
                     PCPlus4F;
    
    // Initiation of Modules
    // Declare PC Counter
    PC_Module Program_Counter (
        .clk(clk),
        .rst(rst),
        .PC(PCF),
        .PC_Next(PC_Next)
    );
    
    // Declare Instruction Memory
    Instruction_Memory IMEM (
        .rst(rst),
        .A(PCF),
        .RD(InstrF)
    );
    
    // Declare PC adder
    PC_Adder PC_adder (
        .a(PCF),
        .b(32'h00000004),
        .c(PCPlus4F)
    );
    
    // FIXED: Fetch Cycle Register Logic with correct reset
    always @(posedge clk) begin
        if (rst == 1'b1) begin          // rst=1 means reset (active-HIGH)
            InstrF_reg <= 32'h00000013;    // FIXED: Reset to NOP instead of 0
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000004;  // FIXED: Reset to 4 instead of 0
            $display("FETCH_REG: RESET - All registers cleared");
        end
        else begin                      // rst=0 means normal operation
            InstrF_reg <= InstrF;       // Pass fetched instruction to decode
            PCF_reg <= PCF;             // Pass PC to decode
            PCPlus4F_reg <= PCPlus4F;   // Pass PC+4 to decode
            $display("FETCH_REG: InstrF=0x%08h -> InstrF_reg=0x%08h, PCF=0x%08h -> PCF_reg=0x%08h", 
                     InstrF, InstrF, PCF, PCF);  // FIXED: Show input values, not old register values
        end
    end
    
    // CRITICAL FIX: Remove reset muxes from outputs
    // The reset logic should ONLY be in the register, not the outputs
    assign InstrD = InstrF_reg;      // ✅ Always output register value
    assign PCD = PCF_reg;           // ✅ Always output register value  
    assign PCPlus4D = PCPlus4F_reg; // ✅ Always output register value
    
    // Debug output
    always @(posedge clk) begin
        if (!rst) begin // During normal operation
            $display("FETCH_OUTPUT: InstrD=0x%08h, PCD=0x%08h, PCPlus4D=0x%08h", 
                     InstrD, PCD, PCPlus4D);
        end
    end
    
    // ADDED: Enhanced debug output for control signals and PC_Next calculation
    always @(posedge clk) begin
        if (!rst) begin // During normal operation
            $display("FETCH_CONTROL: PCSrcE=%b, JumpE=%b, is_jalr_E=%b", 
                     PCSrcE, JumpE, is_jalr_E);
            $display("FETCH_CONTROL: PCTargetE=0x%08h, JALR_TargetE=0x%08h, PCPlus4F=0x%08h", 
                     PCTargetE, JALR_TargetE, PCPlus4F);
            $display("FETCH_CONTROL: PC_Next decision - Final PC_Next=0x%08h", PC_Next);
            
            // Show which path was taken for PC_Next
            if (JumpE & is_jalr_E) begin
                $display("FETCH_CONTROL: PC_Next source = JALR_TargetE (0x%08h)", JALR_TargetE);
            end else if (PCSrcE) begin
                $display("FETCH_CONTROL: PC_Next source = PCTargetE (0x%08h)", PCTargetE);
            end else begin
                $display("FETCH_CONTROL: PC_Next source = PCPlus4F (0x%08h)", PCPlus4F);
            end
        end
    end
    
    // ADDED: Special debug for potential JAL execution
    always @(posedge clk) begin
        if (!rst && PCSrcE && !is_jalr_E) begin // JAL should set PCSrcE=1 and is_jalr_E=0
            $display("FETCH_JAL_DEBUG: JAL execution detected!");
            $display("FETCH_JAL_DEBUG: Current PCF=0x%08h, Target PCTargetE=0x%08h", 
                     PCF, PCTargetE);
            $display("FETCH_JAL_DEBUG: Should jump from 0x%08h to 0x%08h", 
                     PCF, PCTargetE);
        end
    end
    
    // ADDED: Debug for control signal timing
    always @(*) begin
        if (!rst && (PCSrcE || JumpE)) begin
            $display("FETCH_TIMING: Control signals active - PCSrcE=%b, JumpE=%b at time %0t", 
                     PCSrcE, JumpE, $time);
        end
    end
    
endmodule