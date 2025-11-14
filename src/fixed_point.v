// src/fixed_point.v
`timescale 1ns/1ps

module fixed_mul_q15 (
    input  signed [15:0] a,   // Q1.15
    input  signed [15:0] b,   // Q1.15
    output signed [31:0] product_q15 // Q1.15 in 32-bit signed (after shift)
);
    // multiply => 32-bit signed product in Q2.30 (effectively)
    wire signed [31:0] mult = a * b; // full product
    // shift right by 15 to get back to Q1.15. Keep 32-bit signed result to avoid overflow
    assign product_q15 = mult >>> 15;
endmodule

// saturating adder (simple version) for 32-bit signed
module sat_add32 (
    input signed [31:0] a,
    input signed [31:0] b,
    output signed [31:0] sum
);
    wire signed [32:0] tmp = a + b;
    assign sum = (tmp > 32'sh7fffffff) ? 32'sh7fffffff :
                 (tmp < -32'sh80000000) ? -32'sh80000000 :
                 tmp[31:0];
endmodule