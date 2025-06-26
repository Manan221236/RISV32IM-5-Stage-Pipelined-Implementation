module memory_cycle(clk, rst, RegWriteM, MemWriteM, ResultSrcM, RD_M, PCPlus4M, WriteDataM, 
    ALU_ResultM, RegWriteW, ResultSrcW, RD_W, PCPlus4W, ALU_ResultW, ReadDataW, LoadTypeM, StoreTypeM, LoadTypeW, StoreTypeW);
    
    // Declaration of I/Os
    input clk, rst, RegWriteM, MemWriteM;
    input [1:0] ResultSrcM;
    input [4:0] RD_M; 
    input [31:0] PCPlus4M, WriteDataM, ALU_ResultM;
    input [2:0] LoadTypeM, StoreTypeM;
    output RegWriteW;
    output [1:0] ResultSrcW; 
    output [4:0] RD_W;
    output [31:0] PCPlus4W, ALU_ResultW, ReadDataW;
    output [2:0] LoadTypeW, StoreTypeW;
    
    // Declaration of Interim Wires
    wire [31:0] ReadDataM;
    
    // Declaration of Interim Registers
    reg RegWriteM_r;
    reg [1:0] ResultSrcM_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, ALU_ResultM_r, ReadDataM_r;
    reg [2:0] LoadTypeM_r, StoreTypeM_r;
    
    // Declaration of Module Initiation
    Data_Memory dmem (
        .clk(clk),
        .rst(rst),
        .WE(MemWriteM),
        .WD(WriteDataM),
        .A(ALU_ResultM),
        .RD(ReadDataM),
        .LoadType(LoadTypeM),
        .StoreType(StoreTypeM)
    );
    
    // FIXED: Memory Stage Register Logic with Active-HIGH Reset
    always @(posedge clk) begin  // FIXED: Removed edge sensitivity
        if (rst) begin           // FIXED: rst=1 means reset (active-HIGH)
            RegWriteM_r <= 1'b0; 
            ResultSrcM_r <= 2'b00;
            RD_M_r <= 5'h00;
            PCPlus4M_r <= 32'h00000000; 
            ALU_ResultM_r <= 32'h00000000; 
            ReadDataM_r <= 32'h00000000;
            LoadTypeM_r <= 3'b000;
            StoreTypeM_r <= 3'b000;
            $display("MEMORY_REG: RESET - All pipeline registers cleared");
        end
        else begin               // rst=0 means normal operation
            RegWriteM_r <= RegWriteM; 
            ResultSrcM_r <= ResultSrcM;
            RD_M_r <= RD_M;
            PCPlus4M_r <= PCPlus4M; 
            ALU_ResultM_r <= ALU_ResultM; 
            ReadDataM_r <= ReadDataM;
            LoadTypeM_r <= LoadTypeM;
            StoreTypeM_r <= StoreTypeM;
            
            $display("MEMORY_REG: RegWriteM=%b->RegWriteM_r=%b, RD_M=x%0d->RD_M_r=x%0d, ALU_ResultM=0x%08h", 
                     RegWriteM, RegWriteM_r, RD_M, RD_M_r, ALU_ResultM);
                     
            // ENHANCED PIPELINE DEBUG
            if (RegWriteM && RD_M != 0) begin
                $display("MEMORY_PIPELINE: Instruction writing to x%0d with value 0x%08h flowing to writeback", 
                         RD_M, ALU_ResultM);
                if (RD_M == 15 || RD_M == 14) begin
                    $display("MEMORY_CRITICAL: Writing to factorial register x%0d with value %0d", 
                             RD_M, $signed(ALU_ResultM));
                end
            end
        end
    end 
    
    // Declaration of output assignments
    assign RegWriteW = RegWriteM_r;
    assign ResultSrcW = ResultSrcM_r;
    assign RD_W = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign ALU_ResultW = ALU_ResultM_r;
    assign ReadDataW = ReadDataM_r;
    assign LoadTypeW = LoadTypeM_r;
    assign StoreTypeW = StoreTypeM_r;
    
    // Debug output for memory operations
    always @(posedge clk) begin
        if (!rst && MemWriteM) begin
            $display("MEMORY DEBUG: Store operation - Address=0x%08h, Data=0x%08h", 
                     ALU_ResultM, WriteDataM);
        end
        if (!rst && RegWriteM && RD_M != 0) begin
            $display("MEMORY DEBUG: Register write setup - RD_M=x%0d, ALU_ResultM=0x%08h", 
                     RD_M, ALU_ResultM);
        end
    end
    
    // CRITICAL DEBUG: Track what goes to writeback
    always @(posedge clk) begin
        if (!rst && RegWriteM_r && RD_M_r != 0) begin
            $display("MEMORY_TO_WB: Sending to writeback - RegWrite=%b, RD=x%0d, ALU_Result=0x%08h, ResultSrc=%b", 
                     RegWriteM_r, RD_M_r, ALU_ResultM_r, ResultSrcM_r);
        end
    end
endmodule