// ============================================================
// ForwardUnit.v - Data Forwarding Unit
// Resolves EX-EX and MEM-EX data hazards
// ============================================================
module ForwardUnit (
    // EX stage source registers
    input  [4:0]  ex_rs1,
    input  [4:0]  ex_rs2,
    // MEM stage destination (X/M pipeline reg)
    input  [4:0]  mem_rd,
    input         mem_reg_wen,
    // WB stage destination (M/W pipeline reg)
    input  [4:0]  wb_rd,
    input         wb_reg_wen,
    // Forwarding mux selects
    // 00 = no forward (use RegFile)
    // 01 = forward from MEM stage (ALU result)
    // 10 = forward from WB stage (wb_data)
    output reg [1:0] fwd_a,
    output reg [1:0] fwd_b
);
    always @(*) begin
        // Forward A (rs1)
        if (mem_reg_wen && (mem_rd != 5'b0) && (mem_rd == ex_rs1))
            fwd_a = 2'b01; // EX-EX forward from MEM stage
        else if (wb_reg_wen && (wb_rd != 5'b0) && (wb_rd == ex_rs1))
            fwd_a = 2'b10; // MEM-EX forward from WB stage
        else
            fwd_a = 2'b00;

        // Forward B (rs2)
        if (mem_reg_wen && (mem_rd != 5'b0) && (mem_rd == ex_rs2))
            fwd_b = 2'b01;
        else if (wb_reg_wen && (wb_rd != 5'b0) && (wb_rd == ex_rs2))
            fwd_b = 2'b10;
        else
            fwd_b = 2'b00;
    end

endmodule
