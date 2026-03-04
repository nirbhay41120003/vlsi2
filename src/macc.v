// src/macc.v
`timescale 1ns/1ps
`ifndef MACC_V
`define MACC_V
`include "fixed_point.v"

module simple_2in_macc_q15(
    input  signed [15:0] in0, // Q1.15
    input  signed [15:0] in1, // Q1.15
    input  signed [15:0] w0,  // Q1.15
    input  signed [15:0] w1,  // Q1.15
    input  signed [15:0] bias,// Q1.15
    output signed [31:0] acc_out // Q1.15 (w0*in0 + w1*in1 + bias)
);
    wire signed [31:0] p0;
    wire signed [31:0] p1;
    fixed_mul_q15 m0(.a(in0), .b(w0), .product_q15(p0));
    fixed_mul_q15 m1(.a(in1), .b(w1), .product_q15(p1));

    wire signed [31:0] sum01;
    assign sum01 = p0 + p1;
    // bias is Q1.15 (16-bit) -> extend to 32-bit before add
    assign acc_out = sum01 + {{16{bias[15]}}, bias};
endmodule`endif // MACC_V
