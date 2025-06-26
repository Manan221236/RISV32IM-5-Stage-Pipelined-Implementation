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
    // EXPANDED Memory array - 4KB (1024 words)
    // ------------------------------------------------------------
    reg [31:0] mem [0:1023];

    // SAFE memory access with bounds checking
    wire [9:0] word_addr = (A[31:2] < 1024) ? A[11:2] : 10'd0;
    wire [1:0] byte_addr = A[1:0];

    reg  [31:0] rdata_raw;   // combinational word read
    reg  [31:0] rdata_q;     // 1-cycle registered load value

    // ------------------------------------------------------------
    // Combinational read of the full 32-bit word with bounds checking
    // ------------------------------------------------------------
    always @(*) begin
        if (A[31:12] != 20'h0 && A[31:12] != 20'hFFFFF) begin
            // Address out of bounds - return 0
            rdata_raw = 32'h0000_0000;
            $display("DMEM WARNING: Address 0x%08h out of bounds, returning 0", A);
        end else begin
            // Valid address - read from memory
            rdata_raw = mem[word_addr];
        end
    end

    // ------------------------------------------------------------
    // Byte-enable write logic with bounds checking
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (WE) begin
            if (A[31:12] != 20'h0 && A[31:12] != 20'hFFFFF) begin
                // Address out of bounds - ignore write
                $display("DMEM WARNING: Write to address 0x%08h ignored (out of bounds)", A);
            end else begin
                // Valid address - perform write
                case (StoreType)
                    3'b000 : begin                // SB
                        case (byte_addr)
                            2'b00: mem[word_addr][ 7: 0] <= WD[7:0];
                            2'b01: mem[word_addr][15: 8] <= WD[7:0];
                            2'b10: mem[word_addr][23:16] <= WD[7:0];
                            2'b11: mem[word_addr][31:24] <= WD[7:0];
                        endcase
                        $display("DMEM: SB addr=0x%08h data=0x%02h", A, WD[7:0]);
                    end
                    3'b001 : begin                // SH
                        if (byte_addr[1] == 1'b0)
                            mem[word_addr][15:0]  <= WD[15:0];
                        else
                            mem[word_addr][31:16] <= WD[15:0];
                        $display("DMEM: SH addr=0x%08h data=0x%04h", A, WD[15:0]);
                    end
                    3'b010 : begin                // SW
                        mem[word_addr] <= WD;
                        $display("DMEM: SW addr=0x%08h data=0x%08h", A, WD);
                    end
                    default: begin
                        $display("DMEM ERROR: Invalid StoreType=0x%h", StoreType);
                    end
                endcase
            end
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
    // 1-cycle register with Active-HIGH reset
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (rst)                 // rst=1 means reset (active-HIGH)
            rdata_q <= 32'h0;
        else
            rdata_q <= r_ext;
    end

    assign RD = rdata_q;

    // ------------------------------------------------------------
    // Initialize memory to zeros
    // ------------------------------------------------------------
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'h0000_0000;
        $display("DMEM: Initialized 4KB data memory (1024 words)");
    end
    
    // Debug output for memory accesses
    always @(posedge clk) begin
        if (!rst && (WE || (LoadType != 3'b000))) begin
            $display("DMEM ACCESS: addr=0x%08h word_addr=%0d WE=%b LoadType=0x%h StoreType=0x%h", 
                     A, word_addr, WE, LoadType, StoreType);
        end
    end
endmodule