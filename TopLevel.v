// ============================================================
// TopLevel.v - RISC-V 5-Stage Pipelined Processor
// Stages: IF | ID | EX | MEM | WB
// Includes: Forwarding Unit + Hazard Detection Unit
// Based on CS61C Reference Card datapath
// ============================================================

module TopLevel (
    input clk,
    input rst
);
    // ========================================================
    // PC Register
    // ========================================================
    reg [31:0] pc;

    // ========================================================
    // IF Stage wires
    // ========================================================
    wire [31:0] inst_if;
    wire [31:0] pc_next;

    // ========================================================
    // IF/ID pipeline register outputs
    // ========================================================
    wire [31:0] pc_id, inst_id;

    // ========================================================
    // ID Stage wires
    // ========================================================
    wire [4:0]  rs1_id  = inst_id[19:15];
    wire [4:0]  rs2_id  = inst_id[24:20];
    wire [4:0]  rd_id   = inst_id[11:7];
    wire [6:0]  opcode  = inst_id[6:0];
    wire [2:0]  funct3  = inst_id[14:12];
    wire [6:0]  funct7  = inst_id[31:25];

    wire [31:0] data_a_id, data_b_id;
    wire [31:0] imm_id;

    // Control signals from CU (ID stage)
    wire [1:0]  pc_sel_id;
    wire [2:0]  imm_sel_id;
    wire        a_sel_id;
    wire        b_sel_id;
    wire [3:0]  alu_sel_id;
    wire [1:0]  mem_rw_id;
    wire [1:0]  wb_sel_id;
    wire        reg_wen_id;
    wire        br_un_id;
    wire        br_eq_id, br_lt_id;

    // ========================================================
    // ID/EX pipeline register outputs
    // ========================================================
    wire [31:0] pc_ex, data_a_ex, data_b_ex, imm_ex;
    wire [4:0]  rs1_ex, rs2_ex, rd_ex;
    wire [1:0]  pc_sel_ex;
    wire        a_sel_ex, b_sel_ex;
    wire [3:0]  alu_sel_ex;
    wire [1:0]  mem_rw_ex, wb_sel_ex;
    wire        reg_wen_ex, br_un_ex;

    // ========================================================
    // EX Stage wires
    // ========================================================
    wire [31:0] alu_a, alu_b_pre, alu_b;
    wire [31:0] alu_result_ex;
    wire        alu_zero;
    wire [1:0]  fwd_a, fwd_b;

    // ========================================================
    // EX/MEM pipeline register outputs
    // ========================================================
    wire [31:0] pc_mem, alu_mem, data_b_mem;
    wire [4:0]  rd_mem;
    wire [1:0]  mem_rw_mem, wb_sel_mem;
    wire        reg_wen_mem;

    // ========================================================
    // MEM Stage wires
    // ========================================================
    wire [31:0] mem_data_out;

    // ========================================================
    // MEM/WB pipeline register outputs
    // ========================================================
    wire [31:0] pc_wb, alu_wb, mem_data_wb;
    wire [4:0]  rd_wb;
    wire [1:0]  wb_sel_wb;
    wire        reg_wen_wb;

    // ========================================================
    // WB Stage wires
    // ========================================================
    wire [31:0] wb_data;

    // ========================================================
    // Hazard signals
    // ========================================================
    wire stall, flush_if_id, flush_id_ex;

    // ========================================================
    // Branch/Jump detection for HazardDetect
    // ========================================================
    wire is_jal  = (opcode == 7'b110_1111);
    wire is_jalr = (opcode == 7'b110_0111);
    wire branch_taken = (pc_sel_id == 2'b01) || (pc_sel_id == 2'b10);

    // ========================================================
    // WB writeback data mux (00=ALU, 01=Mem, 10=PC+4)
    // ========================================================
    assign wb_data = (wb_sel_wb == 2'b01) ? mem_data_wb :
                     (wb_sel_wb == 2'b10) ? (pc_wb + 4) :
                                            alu_wb;

    // ========================================================
    // PC next logic
    // ========================================================
    // Target addresses
    wire [31:0] branch_target = pc_id + imm_id;            // branch / JAL
    wire [31:0] jalr_target   = (data_a_id + imm_id) & ~32'h1; // JALR

    assign pc_next = (pc_sel_id == 2'b01) ? branch_target :
                     (pc_sel_id == 2'b10) ? jalr_target   :
                                            pc + 4;

    // PC register with stall
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0000_0000;
        else if (!stall)
            pc <= pc_next;
    end

    // ========================================================
    // Instantiate modules
    // ========================================================

    // -- IF: Instruction Memory --
    IMEM imem (
        .addr (pc),
        .inst (inst_if)
    );

    // -- IF/ID Register --
    IF_ID_Reg if_id (
        .clk     (clk),
        .rst     (rst),
        .stall   (stall),
        .flush   (flush_if_id),
        .pc_in   (pc),
        .inst_in (inst_if),
        .pc_out  (pc_id),
        .inst_out(inst_id)
    );

    // -- ID: Register File --
    RegFile rf (
        .clk     (clk),
        .rs1     (rs1_id),
        .rs2     (rs2_id),
        .data_a  (data_a_id),
        .data_b  (data_b_id),
        .rd      (rd_wb),
        .data_d  (wb_data),
        .reg_wen (reg_wen_wb)
    );

    // -- ID: Branch Comparator (early branch resolve) --
    BranchComp bc (
        .a     (data_a_id),
        .b     (data_b_id),
        .br_un (br_un_id),
        .br_eq (br_eq_id),
        .br_lt (br_lt_id)
    );

    // -- ID: Control Unit --
    ControlUnit cu (
        .opcode    (opcode),
        .funct3    (funct3),
        .funct7    (funct7),
        .br_eq     (br_eq_id),
        .br_lt     (br_lt_id),
        .pc_sel    (pc_sel_id),
        .imm_sel   (imm_sel_id),
        .a_sel     (a_sel_id),
        .b_sel     (b_sel_id),
        .alu_sel   (alu_sel_id),
        .mem_rw    (mem_rw_id),
        .wb_sel    (wb_sel_id),
        .reg_wen   (reg_wen_id),
        .br_un     (br_un_id)
    );

    // -- ID: Immediate Generator --
    ImmGen ig (
        .inst    (inst_id),
        .imm_sel (imm_sel_id),
        .imm     (imm_id)
    );

    // -- Hazard Detection Unit --
    HazardDetect hdu (
        .id_rs1       (rs1_id),
        .id_rs2       (rs2_id),
        .ex_rd        (rd_ex),
        .ex_mem_read  (mem_rw_ex == 2'b01),
        .branch_taken (branch_taken),
        .is_jal       (is_jal),
        .is_jalr      (is_jalr),
        .stall        (stall),
        .flush_if_id  (flush_if_id),
        .flush_id_ex  (flush_id_ex)
    );

    // -- ID/EX Register --
    ID_EX_Reg id_ex (
        .clk        (clk), .rst(rst),
        .flush      (flush_id_ex),
        .pc_in      (pc_id),
        .data_a_in  (data_a_id),
        .data_b_in  (data_b_id),
        .imm_in     (imm_id),
        .rs1_in     (rs1_id),
        .rs2_in     (rs2_id),
        .rd_in      (rd_id),
        .pc_sel_in  (pc_sel_id),
        .a_sel_in   (a_sel_id),
        .b_sel_in   (b_sel_id),
        .alu_sel_in (alu_sel_id),
        .mem_rw_in  (mem_rw_id),
        .wb_sel_in  (wb_sel_id),
        .reg_wen_in (reg_wen_id),
        .br_un_in   (br_un_id),
        // Outputs
        .pc_out     (pc_ex),
        .data_a_out (data_a_ex),
        .data_b_out (data_b_ex),
        .imm_out    (imm_ex),
        .rs1_out    (rs1_ex),
        .rs2_out    (rs2_ex),
        .rd_out     (rd_ex),
        .pc_sel_out (pc_sel_ex),
        .a_sel_out  (a_sel_ex),
        .b_sel_out  (b_sel_ex),
        .alu_sel_out(alu_sel_ex),
        .mem_rw_out (mem_rw_ex),
        .wb_sel_out (wb_sel_ex),
        .reg_wen_out(reg_wen_ex),
        .br_un_out  (br_un_ex)
    );

    // -- EX: Forwarding Unit --
    ForwardUnit fwd (
        .ex_rs1      (rs1_ex),
        .ex_rs2      (rs2_ex),
        .mem_rd      (rd_mem),
        .mem_reg_wen (reg_wen_mem),
        .wb_rd       (rd_wb),
        .wb_reg_wen  (reg_wen_wb),
        .fwd_a       (fwd_a),
        .fwd_b       (fwd_b)
    );

    // -- EX: Forwarding muxes --
    // fwd: 00=RegFile, 01=MEM(alu_mem), 10=WB(wb_data)
    wire [31:0] fwd_data_a = (fwd_a == 2'b01) ? alu_mem  :
                              (fwd_a == 2'b10) ? wb_data  : data_a_ex;
    wire [31:0] fwd_data_b = (fwd_b == 2'b01) ? alu_mem  :
                              (fwd_b == 2'b10) ? wb_data  : data_b_ex;

    // a_sel: 0=Reg[rs1], 1=PC
    assign alu_a    = a_sel_ex ? pc_ex : fwd_data_a;
    // b_sel: 0=Reg[rs2], 1=imm
    assign alu_b_pre = b_sel_ex ? imm_ex : fwd_data_b;
    assign alu_b    = alu_b_pre;

    // -- EX: ALU --
    ALU alu (
        .a       (alu_a),
        .b       (alu_b),
        .alu_sel (alu_sel_ex),
        .result  (alu_result_ex),
        .zero    (alu_zero)
    );

    // -- EX/MEM Register --
    EX_MEM_Reg ex_mem (
        .clk        (clk), .rst(rst),
        .pc_in      (pc_ex),
        .alu_in     (alu_result_ex),
        .data_b_in  (fwd_data_b),
        .rd_in      (rd_ex),
        .mem_rw_in  (mem_rw_ex),
        .wb_sel_in  (wb_sel_ex),
        .reg_wen_in (reg_wen_ex),
        .pc_out     (pc_mem),
        .alu_out    (alu_mem),
        .data_b_out (data_b_mem),
        .rd_out     (rd_mem),
        .mem_rw_out (mem_rw_mem),
        .wb_sel_out (wb_sel_mem),
        .reg_wen_out(reg_wen_mem)
    );

    // -- MEM: Data Memory --
    DMEM dmem (
        .clk     (clk),
        .addr    (alu_mem),
        .data_in (data_b_mem),
        .mem_rw  (mem_rw_mem),
        .data_out(mem_data_out)
    );

    // -- MEM/WB Register --
    MEM_WB_Reg mem_wb (
        .clk         (clk), .rst(rst),
        .pc_in       (pc_mem),
        .alu_in      (alu_mem),
        .mem_data_in (mem_data_out),
        .rd_in       (rd_mem),
        .wb_sel_in   (wb_sel_mem),
        .reg_wen_in  (reg_wen_mem),
        .pc_out      (pc_wb),
        .alu_out     (alu_wb),
        .mem_data_out(mem_data_wb),
        .rd_out      (rd_wb),
        .wb_sel_out  (wb_sel_wb),
        .reg_wen_out (reg_wen_wb)
    );

    // WB writeback goes back to RegFile (already wired above)

endmodule
