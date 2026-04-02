// ============================================================
// HazardDetect.v - Hazard Detection Unit
// Detects load-use hazard -> stall 1 cycle
// Detects control hazard -> flush IF/ID, ID/EX
// ============================================================
module HazardDetect (
    // ID stage source registers
    input  [4:0]  id_rs1,
    input  [4:0]  id_rs2,
    // EX stage destination (load instruction in EX)
    input  [4:0]  ex_rd,
    input         ex_mem_read,   // 1 if EX instruction is a LOAD
    // Branch/Jump taken (from CU in ID)
    input         branch_taken,
    input         is_jal,
    input         is_jalr,
    // Outputs
    output        stall,         // stall PC + IF/ID register
    output        flush_if_id,   // flush IF/ID on branch
    output        flush_id_ex    // flush ID/EX on load-use or branch
);
    // Load-use hazard: EX stage has a LOAD and ID stage needs that register
    wire load_use_hazard = ex_mem_read &&
                           (ex_rd != 5'b0) &&
                           ((ex_rd == id_rs1) || (ex_rd == id_rs2));

    // Control hazard: branch/jump taken
    wire ctrl_hazard = branch_taken || is_jal || is_jalr;

    assign stall       = load_use_hazard;
    assign flush_if_id = ctrl_hazard;
    assign flush_id_ex = load_use_hazard || ctrl_hazard;

endmodule
