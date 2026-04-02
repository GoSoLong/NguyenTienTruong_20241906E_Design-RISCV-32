// ============================================================
// ImmGen.v - Immediate Generator
// Supports I, S, B, U, J types
// ============================================================
module ImmGen (
    input  [31:0] inst,
    input  [2:0]  imm_sel, // 000=I, 001=S, 010=B, 011=U, 100=J
    output reg [31:0] imm
);
    always @(*) begin
        case (imm_sel)
            3'b000: // I-type
                imm = {{20{inst[31]}}, inst[31:20]};
            3'b001: // S-type
                imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            3'b010: // B-type
                imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            3'b011: // U-type
                imm = {inst[31:12], 12'b0};
            3'b100: // J-type
                imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            default:
                imm = 32'h0;
        endcase
    end
endmodule
