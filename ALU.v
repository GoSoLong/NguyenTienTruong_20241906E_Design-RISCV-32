module ALU (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_sel,
    output reg [31:0] result,
    output        zero
);
    // ALUSel encoding
    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam AND  = 4'b0010;
    localparam OR   = 4'b0011;
    localparam XOR  = 4'b0100;
    localparam SLL  = 4'b0101;
    localparam SRL  = 4'b0110;
    localparam SRA  = 4'b0111;
    localparam SLT  = 4'b1000;
    localparam SLTU = 4'b1001;
    localparam BSEL = 4'b1010; // Pass B (for LUI/AUIPC)
    localparam MUL  = 4'b1011;

    always @(*) begin
        case (alu_sel)
            ADD:  result = a + b;
            SUB:  result = a - b;
            AND:  result = a & b;
            OR:   result = a | b;
            XOR:  result = a ^ b;
            SLL:  result = a << b[4:0];
            SRL:  result = a >> b[4:0];
            SRA:  result = $signed(a) >>> b[4:0];
            SLT:  result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;
            SLTU: result = (a < b) ? 32'h1 : 32'h0;
            BSEL: result = b;
            MUL:  result = a * b;
            default: result = 32'h0;
        endcase
    end

    assign zero = (result == 32'h0);

endmodule
