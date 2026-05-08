module BranchComp (
    input  [31:0] a,
    input  [31:0] b,
    input         br_un,   // 1 = unsigned comparison
    output        br_eq,
    output        br_lt
);
    assign br_eq = (a == b);
    assign br_lt = br_un ? (a < b) : ($signed(a) < $signed(b));
endmodule
