module ALU_Decoder
#(
    parameter ADD  = 5'b00000,
    parameter SUB  = 5'b00001,
    parameter AND_ = 5'b00010,
    parameter OR_  = 5'b00011,
    parameter XOR_ = 5'b00100,
    parameter SLT  = 5'b00101,
    parameter SLTU = 5'b00110,
    parameter SLL  = 5'b00111,
    parameter SRL  = 5'b01000,
    parameter SRA  = 5'b01001,
    parameter MUL  = 5'b01010,
    parameter MULH = 5'b01011,
    parameter MULHSU = 5'b01100,
    parameter MULHU  = 5'b01101,
    parameter LUI  = 5'b01110,
    parameter AUIPC= 5'b01111
)
(
    input  [2:0] ALUOp,
    input  [2:0] funct3,
    input  [6:0] funct7,
    input  [6:0] op,
    output reg [4:0] ALUControl
);

    always @(*) begin
        case (ALUOp)

        //----------------------------------------------------------
        // 000 : address-calc / JALR  (always ADD)
        //----------------------------------------------------------
        3'b000 : ALUControl = ADD;

        //----------------------------------------------------------
        // 001 : branch compares
        //----------------------------------------------------------
        3'b001 : begin
            case (funct3)
                3'b000, 3'b001: ALUControl = SUB;   // BEQ, BNE
                3'b100, 3'b101: ALUControl = SLT;   // BLT, BGE
                3'b110, 3'b111: ALUControl = SLTU;  // BLTU, BGEU
                default        : ALUControl = SUB;
            endcase
        end

        //----------------------------------------------------------
        // 010 : R-type  & I-type  ALU
        //----------------------------------------------------------
        3'b010 : begin
            // M-extension ops are signalled by funct7[0] = 1
            if (funct7 == 7'b0000001) begin
                case (funct3)
                    3'b000: ALUControl = MUL;
                    3'b001: ALUControl = MULH;
                    3'b010: ALUControl = MULHSU;
                    3'b011: ALUControl = MULHU;
                    default: ALUControl = ADD;
                endcase
            end
            else begin
                case (funct3)
                    3'b000: ALUControl =
                             (funct7[5] & op[5]) ? SUB : ADD;  // ADD / SUB
                    3'b001: ALUControl = SLL;
                    3'b010: ALUControl = SLT;
                    3'b011: ALUControl = SLTU;
                    3'b100: ALUControl = XOR_;
                    3'b101: ALUControl = (funct7[5]) ? SRA : SRL;
                    3'b110: ALUControl = OR_;
                    3'b111: ALUControl = AND_;
                    default: ALUControl = ADD;
                endcase
            end
        end

        //----------------------------------------------------------
        // 011 : LUI (places upper imm into dest)
        //----------------------------------------------------------
        3'b100 : ALUControl = LUI;

        //----------------------------------------------------------
        // 101 : AUIPC  (ADD PC + imm)
        //----------------------------------------------------------
        3'b101 : ALUControl = AUIPC;

        //----------------------------------------------------------
        // 110 : JAL / JALR use ADD to compute PC+4 for link reg
        //----------------------------------------------------------
        3'b110 : ALUControl = ADD;

        //----------------------------------------------------------
        // default
        //----------------------------------------------------------
        default: ALUControl = ADD;
        endcase
    end
endmodule
