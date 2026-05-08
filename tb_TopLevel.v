`timescale 1ns/1ps

module tb_TopLevel;

    reg clk, rst;

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    TopLevel dut (
        .clk (clk),
        .rst (rst)
    );

    // --------------------------------------------------------
    // Load test program into IMEM
    // Test program tests: ADD, SUB, LW, SW, BEQ, forwarding,
    //                     load-use stall, branch flush
    // --------------------------------------------------------
    initial begin
        // Initialize program.hex with test instructions
        // Encoding: LI x1,5 | LI x2,3 | ADD x3,x1,x2 | etc.
        $readmemh("program.hex", dut.imem.mem);
    end

    // --------------------------------------------------------
    // Reset sequence
    // --------------------------------------------------------
    initial begin
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
    end

    // --------------------------------------------------------
    // VCD Dump for waveform viewing
    // --------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_TopLevel);
    end

    // --------------------------------------------------------
    // Monitor: display pipeline state each cycle
    // --------------------------------------------------------
    integer cycle = 0;
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            $display("--- Cycle %0d ---", cycle);
            $display("  PC        = 0x%08h", dut.pc);
            $display("  IF  inst  = 0x%08h", dut.inst_if);
            $display("  ID  inst  = 0x%08h  pc=0x%08h", dut.inst_id, dut.pc_id);
            $display("  EX  rd=%0d  alu_a=0x%08h  alu_b=0x%08h  result=0x%08h",
                     dut.rd_ex, dut.alu_a, dut.alu_b, dut.alu_result_ex);
            $display("  MEM rd=%0d  alu=0x%08h  mem_rw=%0b",
                     dut.rd_mem, dut.alu_mem, dut.mem_rw_mem);
            $display("  WB  rd=%0d  wb_data=0x%08h  reg_wen=%0b",
                     dut.rd_wb, dut.wb_data, dut.reg_wen_wb);
            $display("  Hazard: stall=%0b  flush_if_id=%0b  flush_id_ex=%0b",
                     dut.stall, dut.flush_if_id, dut.flush_id_ex);
            $display("  Fwd: fwd_a=%0b  fwd_b=%0b", dut.fwd_a, dut.fwd_b);
            $display("");

            if (cycle >= 40) begin
                $display("=== Simulation complete after %0d cycles ===", cycle);
                // Dump register file
                $display("Register File:");
                begin : reg_dump
                    integer k;
                    for (k = 0; k < 32; k = k + 1)
                        $display("  x%0d = 0x%08h", k, dut.rf.regs[k]);
                end
                $finish;
            end
        end
    end

endmodule
