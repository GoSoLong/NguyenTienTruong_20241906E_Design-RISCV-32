// ============================================================
// RegFile.v - Register File (ID / WB Stage)
// 32 x 32-bit registers, x0 hardwired to 0
// Two async read ports, one sync write port
// ============================================================
module RegFile (
    input         clk,
    // Read ports (ID stage)
    input  [4:0]  rs1,
    input  [4:0]  rs2,
    output [31:0] data_a,
    output [31:0] data_b,
    // Write port (WB stage)
    input  [4:0]  rd,
    input  [31:0] data_d,
    input         reg_wen
);
    reg [31:0] regs [0:31];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0;
    end

    // Synchronous write (x0 always stays 0)
    always @(posedge clk) begin
        if (reg_wen && rd != 5'b0)
            regs[rd] <= data_d;
    end

    // Asynchronous read with write-through for x0
    assign data_a = (rs1 == 5'b0) ? 32'h0 : regs[rs1];
    assign data_b = (rs2 == 5'b0) ? 32'h0 : regs[rs2];

endmodule
