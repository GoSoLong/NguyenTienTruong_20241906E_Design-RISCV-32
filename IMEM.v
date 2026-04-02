// ============================================================
// IMEM.v - Instruction Memory (IF Stage)
// CS61C RISC-V 5-Stage Pipeline
// ============================================================
module IMEM (
    input  [31:0] addr,
    output [31:0] inst
);
    reg [31:0] mem [0:255]; // 256 words = 1KB

    initial begin
        $readmemh("program.hex", mem);
    end

    // Word-aligned read
    assign inst = mem[addr[9:2]];

endmodule
