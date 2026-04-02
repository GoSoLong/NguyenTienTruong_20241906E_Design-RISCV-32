// ============================================================
// PipelineRegs.v - All 4 pipeline stage registers
// IF/ID  |  ID/EX  |  EX/MEM  |  MEM/WB
// ============================================================

// ----------------------------------------------------------
// IF/ID Pipeline Register
// ----------------------------------------------------------
module IF_ID_Reg (
    input        clk, rst,
    input        stall,      // hold current value
    input        flush,      // insert NOP
    input  [31:0] pc_in,
    input  [31:0] inst_in,
    output reg [31:0] pc_out,
    output reg [31:0] inst_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out   <= 32'h0;
            inst_out <= 32'h0000_0013; // NOP (addi x0,x0,0)
        end else if (!stall) begin
            pc_out   <= pc_in;
            inst_out <= inst_in;
        end
    end
endmodule

// ----------------------------------------------------------
// ID/EX Pipeline Register
// ----------------------------------------------------------
module ID_EX_Reg (
    input        clk, rst,
    input        flush,
    // Data
    input  [31:0] pc_in,
    input  [31:0] data_a_in,
    input  [31:0] data_b_in,
    input  [31:0] imm_in,
    input  [4:0]  rs1_in,
    input  [4:0]  rs2_in,
    input  [4:0]  rd_in,
    // Control signals
    input  [1:0]  pc_sel_in,
    input         a_sel_in,
    input         b_sel_in,
    input  [3:0]  alu_sel_in,
    input  [1:0]  mem_rw_in,
    input  [1:0]  wb_sel_in,
    input         reg_wen_in,
    input         br_un_in,
    // Outputs
    output reg [31:0] pc_out,
    output reg [31:0] data_a_out,
    output reg [31:0] data_b_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,
    output reg [1:0]  pc_sel_out,
    output reg        a_sel_out,
    output reg        b_sel_out,
    output reg [3:0]  alu_sel_out,
    output reg [1:0]  mem_rw_out,
    output reg [1:0]  wb_sel_out,
    output reg        reg_wen_out,
    output reg        br_un_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out      <= 32'h0;
            data_a_out  <= 32'h0;
            data_b_out  <= 32'h0;
            imm_out     <= 32'h0;
            rs1_out     <= 5'h0;
            rs2_out     <= 5'h0;
            rd_out      <= 5'h0;
            pc_sel_out  <= 2'b00;
            a_sel_out   <= 1'b0;
            b_sel_out   <= 1'b0;
            alu_sel_out <= 4'b0;
            mem_rw_out  <= 2'b00;
            wb_sel_out  <= 2'b00;
            reg_wen_out <= 1'b0;
            br_un_out   <= 1'b0;
        end else begin
            pc_out      <= pc_in;
            data_a_out  <= data_a_in;
            data_b_out  <= data_b_in;
            imm_out     <= imm_in;
            rs1_out     <= rs1_in;
            rs2_out     <= rs2_in;
            rd_out      <= rd_in;
            pc_sel_out  <= pc_sel_in;
            a_sel_out   <= a_sel_in;
            b_sel_out   <= b_sel_in;
            alu_sel_out <= alu_sel_in;
            mem_rw_out  <= mem_rw_in;
            wb_sel_out  <= wb_sel_in;
            reg_wen_out <= reg_wen_in;
            br_un_out   <= br_un_in;
        end
    end
endmodule

// ----------------------------------------------------------
// EX/MEM Pipeline Register
// ----------------------------------------------------------
module EX_MEM_Reg (
    input        clk, rst,
    input  [31:0] pc_in,
    input  [31:0] alu_in,
    input  [31:0] data_b_in,   // rs2 for store
    input  [4:0]  rd_in,
    input  [1:0]  mem_rw_in,
    input  [1:0]  wb_sel_in,
    input         reg_wen_in,
    output reg [31:0] pc_out,
    output reg [31:0] alu_out,
    output reg [31:0] data_b_out,
    output reg [4:0]  rd_out,
    output reg [1:0]  mem_rw_out,
    output reg [1:0]  wb_sel_out,
    output reg        reg_wen_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out      <= 32'h0;
            alu_out     <= 32'h0;
            data_b_out  <= 32'h0;
            rd_out      <= 5'h0;
            mem_rw_out  <= 2'b00;
            wb_sel_out  <= 2'b00;
            reg_wen_out <= 1'b0;
        end else begin
            pc_out      <= pc_in;
            alu_out     <= alu_in;
            data_b_out  <= data_b_in;
            rd_out      <= rd_in;
            mem_rw_out  <= mem_rw_in;
            wb_sel_out  <= wb_sel_in;
            reg_wen_out <= reg_wen_in;
        end
    end
endmodule

// ----------------------------------------------------------
// MEM/WB Pipeline Register
// ----------------------------------------------------------
module MEM_WB_Reg (
    input        clk, rst,
    input  [31:0] pc_in,
    input  [31:0] alu_in,
    input  [31:0] mem_data_in,
    input  [4:0]  rd_in,
    input  [1:0]  wb_sel_in,
    input         reg_wen_in,
    output reg [31:0] pc_out,
    output reg [31:0] alu_out,
    output reg [31:0] mem_data_out,
    output reg [4:0]  rd_out,
    output reg [1:0]  wb_sel_out,
    output reg        reg_wen_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out       <= 32'h0;
            alu_out      <= 32'h0;
            mem_data_out <= 32'h0;
            rd_out       <= 5'h0;
            wb_sel_out   <= 2'b00;
            reg_wen_out  <= 1'b0;
        end else begin
            pc_out       <= pc_in;
            alu_out      <= alu_in;
            mem_data_out <= mem_data_in;
            rd_out       <= rd_in;
            wb_sel_out   <= wb_sel_in;
            reg_wen_out  <= reg_wen_in;
        end
    end
endmodule
