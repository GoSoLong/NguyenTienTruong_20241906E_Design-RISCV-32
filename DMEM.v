// ============================================================
// DMEM.v - Data Memory (MEM Stage)
// CS61C RISC-V 5-Stage Pipeline
// ============================================================
module DMEM (
    input        clk,
    input  [31:0] addr,
    input  [31:0] data_in,
    input  [1:0]  mem_rw,   // 00=no op, 01=read, 10=write
    output [31:0] data_out
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_rw == 2'b10)
            mem[addr[9:2]] <= data_in;
    end

    // Asynchronous read
    assign data_out = (mem_rw == 2'b01) ? mem[addr[9:2]] : 32'h0;

endmodule
