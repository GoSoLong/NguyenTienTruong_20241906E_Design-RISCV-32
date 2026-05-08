module ControlUnit (
    input  [6:0]  opcode,
    input  [2:0]  funct3,
    input  [6:0]  funct7,
    input         br_eq,
    input         br_lt,
    // Outputs
    output reg [1:0]  pc_sel,    // 00=PC+4, 01=branch/JAL, 10=JALR
    output reg [2:0]  imm_sel,   // immediate type
    output reg        a_sel,     // 0=Reg[rs1], 1=PC
    output reg        b_sel,     // 0=Reg[rs2], 1=imm
    output reg [3:0]  alu_sel,
    output reg [1:0]  mem_rw,    // 00=none, 01=read, 10=write
    output reg [1:0]  wb_sel,    // 00=ALU, 01=Mem, 10=PC+4
    output reg        reg_wen,
    output reg        br_un      // unsigned branch compare
);
    // Opcodes
    localparam R_TYPE  = 7'b011_0011;
    localparam I_ARITH = 7'b001_0011;
    localparam LOAD    = 7'b000_0011;
    localparam STORE   = 7'b010_0011;
    localparam BRANCH  = 7'b110_0011;
    localparam JAL     = 7'b110_1111;
    localparam JALR    = 7'b110_0111;
    localparam AUIPC   = 7'b001_0111;
    localparam LUI     = 7'b011_0111;
    localparam SYSTEM  = 7'b111_0011;

    // ALUSel encodings (must match ALU.v)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;
    localparam ALU_BSEL = 4'b1010;
    localparam ALU_MUL  = 4'b1011;

    // Branch taken logic
    reg branch_taken;
    always @(*) begin
        case (funct3)
            3'b000: branch_taken =  br_eq;           // BEQ
            3'b001: branch_taken = !br_eq;           // BNE
            3'b100: branch_taken =  br_lt;           // BLT
            3'b101: branch_taken = !br_lt || br_eq;  // BGE
            3'b110: branch_taken =  br_lt;           // BLTU
            3'b111: branch_taken = !br_lt || br_eq;  // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    always @(*) begin
        // Defaults
        pc_sel  = 2'b00;
        imm_sel = 3'b000;
        a_sel   = 1'b0;
        b_sel   = 1'b0;
        alu_sel = ALU_ADD;
        mem_rw  = 2'b00;
        wb_sel  = 2'b00;
        reg_wen = 1'b0;
        br_un   = 1'b0;

        case (opcode)
            R_TYPE: begin
                reg_wen = 1'b1;
                wb_sel  = 2'b00;
                case ({funct7, funct3})
                    10'b000_0000_000: alu_sel = ALU_ADD;
                    10'b010_0000_000: alu_sel = ALU_SUB;
                    10'b000_0000_111: alu_sel = ALU_AND;
                    10'b000_0000_110: alu_sel = ALU_OR;
                    10'b000_0000_100: alu_sel = ALU_XOR;
                    10'b000_0000_001: alu_sel = ALU_SLL;
                    10'b000_0000_101: alu_sel = ALU_SRL;
                    10'b010_0000_101: alu_sel = ALU_SRA;
                    10'b000_0000_010: alu_sel = ALU_SLT;
                    10'b000_0000_011: alu_sel = ALU_SLTU;
                    10'b000_0001_000: alu_sel = ALU_MUL;
                    default:          alu_sel = ALU_ADD;
                endcase
            end

            I_ARITH: begin
                imm_sel = 3'b000; // I-type
                b_sel   = 1'b1;
                reg_wen = 1'b1;
                wb_sel  = 2'b00;
                case (funct3)
                    3'b000: alu_sel = ALU_ADD;
                    3'b111: alu_sel = ALU_AND;
                    3'b110: alu_sel = ALU_OR;
                    3'b100: alu_sel = ALU_XOR;
                    3'b001: alu_sel = ALU_SLL;
                    3'b101: alu_sel = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    3'b010: alu_sel = ALU_SLT;
                    3'b011: alu_sel = ALU_SLTU;
                    default: alu_sel = ALU_ADD;
                endcase
            end

            LOAD: begin
                imm_sel = 3'b000; // I-type
                b_sel   = 1'b1;
                alu_sel = ALU_ADD;
                mem_rw  = 2'b01;
                reg_wen = 1'b1;
                wb_sel  = 2'b01; // from memory
            end

            STORE: begin
                imm_sel = 3'b001; // S-type
                b_sel   = 1'b1;
                alu_sel = ALU_ADD;
                mem_rw  = 2'b10;
                reg_wen = 1'b0;
            end

            BRANCH: begin
                imm_sel = 3'b010; // B-type
                br_un   = (funct3 == 3'b110 || funct3 == 3'b111);
                alu_sel = ALU_ADD;  // ALU unused for branch result
                pc_sel  = branch_taken ? 2'b01 : 2'b00;
                reg_wen = 1'b0;
            end

            JAL: begin
                imm_sel = 3'b100; // J-type
                a_sel   = 1'b1;   // PC
                b_sel   = 1'b1;   // imm
                alu_sel = ALU_ADD;
                pc_sel  = 2'b01;
                reg_wen = 1'b1;
                wb_sel  = 2'b10; // PC+4
            end

            JALR: begin
                imm_sel = 3'b000; // I-type
                b_sel   = 1'b1;
                alu_sel = ALU_ADD;
                pc_sel  = 2'b10;
                reg_wen = 1'b1;
                wb_sel  = 2'b10; // PC+4
            end

            AUIPC: begin
                imm_sel = 3'b011; // U-type
                a_sel   = 1'b1;   // PC
                b_sel   = 1'b1;
                alu_sel = ALU_ADD;
                reg_wen = 1'b1;
                wb_sel  = 2'b00;
            end

            LUI: begin
                imm_sel = 3'b011; // U-type
                b_sel   = 1'b1;
                alu_sel = ALU_BSEL; // pass imm through
                reg_wen = 1'b1;
                wb_sel  = 2'b00;
            end

            SYSTEM: begin
                // ecall/ebreak - NOP in this implementation
                reg_wen = 1'b0;
            end

            default: begin
                reg_wen = 1'b0;
            end
        endcase
    end

endmodule
