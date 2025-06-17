module Data_Memory
(
    input         clk,
    input         rst,
    input         WE,                 // write enable
    input  [31:0] A,                  // byte address
    input  [31:0] WD,                 // data to store
    input  [2:0]  LoadType,           // 000 LB 001 LH 010 LW 100 LBU 101 LHU
    input  [2:0]  StoreType,          // 000 SB 001 SH 010 SW
    output [31:0] RD                  // registered load data
);

    // ------------------------------------------------------------
    // Loop variable must be declared at module scope (IEEE-1364-2001)
    // ------------------------------------------------------------
    integer i;

    // ------------------------------------------------------------
    // Memory array
    // ------------------------------------------------------------
    reg [31:0] mem [0:1023];

    wire [9:0] word_addr = A[11:2];
    wire [1:0] byte_addr = A[1:0];

    reg  [31:0] rdata_raw;   // combinational word read
    reg  [31:0] rdata_q;     // 1-cycle registered load value

    // ------------------------------------------------------------
    // Combinational read of the full 32-bit word
    // ------------------------------------------------------------
    always @(*) begin
        rdata_raw = mem[word_addr];
    end

    // ------------------------------------------------------------
    // Byte-enable write logic
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (WE) begin
            case (StoreType)
                3'b000 : begin                // SB
                    case (byte_addr)
                        2'b00: mem[word_addr][ 7: 0] <= WD[7:0];
                        2'b01: mem[word_addr][15: 8] <= WD[7:0];
                        2'b10: mem[word_addr][23:16] <= WD[7:0];
                        2'b11: mem[word_addr][31:24] <= WD[7:0];
                    endcase
                end
                3'b001 : begin                // SH
                    if (byte_addr[1] == 1'b0)
                        mem[word_addr][15:0]  <= WD[15:0];
                    else
                        mem[word_addr][31:16] <= WD[15:0];
                end
                3'b010 :                      // SW
                    mem[word_addr] <= WD;
            endcase
        end
    end

    // ------------------------------------------------------------
    // Load-data extraction (combinational)
    // ------------------------------------------------------------
    wire [31:0] r_ext =
        (LoadType == 3'b000) ?                         // LB
            (byte_addr==2'b00) ? {{24{rdata_raw[ 7]}}, rdata_raw[ 7: 0]} :
            (byte_addr==2'b01) ? {{24{rdata_raw[15]}}, rdata_raw[15: 8]} :
            (byte_addr==2'b10) ? {{24{rdata_raw[23]}}, rdata_raw[23:16]} :
                                 {{24{rdata_raw[31]}}, rdata_raw[31:24]} :

        (LoadType == 3'b001) ?                         // LH
            (byte_addr[1]==1'b0) ? {{16{rdata_raw[15]}}, rdata_raw[15:0]} :
                                   {{16{rdata_raw[31]}}, rdata_raw[31:16]} :

        (LoadType == 3'b010) ? rdata_raw :             // LW

        (LoadType == 3'b100) ?                         // LBU
            (byte_addr==2'b00) ? {24'h0, rdata_raw[ 7: 0]} :
            (byte_addr==2'b01) ? {24'h0, rdata_raw[15: 8]} :
            (byte_addr==2'b10) ? {24'h0, rdata_raw[23:16]} :
                                 {24'h0, rdata_raw[31:24]} :

        (LoadType == 3'b101) ?                         // LHU
            (byte_addr[1]==1'b0) ? {16'h0, rdata_raw[15:0]} :
                                   {16'h0, rdata_raw[31:16]} :

        32'h0000_0000;

    // ------------------------------------------------------------
    // 1-cycle register so load reaches WB stage
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst)
            rdata_q <= 32'h0;
        else
            rdata_q <= r_ext;
    end

    assign RD = rdata_q;

    // ------------------------------------------------------------
    // Optional init - clear RAM for sim
    // ------------------------------------------------------------
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'h0000_0000;
    end
endmodule