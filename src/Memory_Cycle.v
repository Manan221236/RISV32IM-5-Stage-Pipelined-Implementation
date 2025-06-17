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
    
    // Memory Stage Register Logic
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            RegWriteM_r <= 1'b0; 
            ResultSrcM_r <= 2'b00;
            RD_M_r <= 5'h00;
            PCPlus4M_r <= 32'h00000000; 
            ALU_ResultM_r <= 32'h00000000; 
            ReadDataM_r <= 32'h00000000;
            LoadTypeM_r <= 3'b000;
            StoreTypeM_r <= 3'b000;
        end
        else begin
            RegWriteM_r <= RegWriteM; 
            ResultSrcM_r <= ResultSrcM;
            RD_M_r <= RD_M;
            PCPlus4M_r <= PCPlus4M; 
            ALU_ResultM_r <= ALU_ResultM; 
            ReadDataM_r <= ReadDataM;
            LoadTypeM_r <= LoadTypeM;
            StoreTypeM_r <= StoreTypeM;
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
endmodule