// src/top_nn.v
`timescale 1ns/1ps
`include "fixed_point.v"
`include "macc.v"
`include "activation_sigmoid.v"

module top_nn();
    // Sizes
    localparam IN_DIM = 2;
    localparam HIDDEN = 2;
    localparam OUT_DIM = 1;

    // ROMs (weights/biases) - 16-bit Q1.15 stored as hex (two's complement)
    reg signed [15:0] W1 [0:(HIDDEN*IN_DIM)-1];
    reg signed [15:0] B1 [0:HIDDEN-1];
    reg signed [15:0] W2 [0:(OUT_DIM*HIDDEN)-1];
    reg signed [15:0] B2 [0:OUT_DIM-1];

    initial begin
        $readmemh("../hex/W1.hex", W1);
        $readmemh("../hex/B1.hex", B1);
        $readmemh("../hex/W2.hex", W2);
        $readmemh("../hex/B2.hex", B2);
    end

    // helper to expand binary 0/1 to Q1.15 signed representation
    function signed [15:0] bin_to_q15;
        input bit v;
        begin
            if (v) bin_to_q15 = 16'sh7fff; // ~ +0.99997
            else   bin_to_q15 = 16'sh0000;
        end
    endfunction

    // We'll iterate through the 4 XOR inputs and compute outputs
    integer i;
    reg [1:0] inputs [0:3];

    initial begin
        inputs[0] = 2'b00;
        inputs[1] = 2'b01;
        inputs[2] = 2'b10;
        inputs[3] = 2'b11;

        #5;
        for (i=0; i<4; i=i+1) begin
            // input conversion
            signed [15:0] in0 = bin_to_q15(inputs[i][1]); // MSB is inputs[i][1]
            signed [15:0] in1 = bin_to_q15(inputs[i][0]);

            // compute hidden neurons (2 of them)
            signed [31:0] acc_h0;
            signed [31:0] acc_h1;

            // W1 stored column-major as produced by python: index = hid_index*IN_DIM + in_index
            simple_2in_macc_q15 mac_h0 (
                .in0(in0), .in1(in1),
                .w0(W1[0]), .w1(W1[1]),
                .bias(B1[0]), .acc_out(acc_h0)
            );

            simple_2in_macc_q15 mac_h1 (
                .in0(in0), .in1(in1),
                .w0(W1[2]), .w1(W1[3]),
                .bias(B1[1]), .acc_out(acc_h1)
            );

            // apply tanh-like activation: for simplicity we map the acc to sigmoid LUT then convert
            // You can use separate tanh LUT; for simplicity we'll pass hidden outputs through tanh approximation:
            // Here we just use sigmoid LUT on the accumulator as an example for output neuron activation
            wire signed [15:0] h0_act;
            wire signed [15:0] h1_act;

            sigmoid_lut_q15 s0(.x_q15(acc_h0), .y_q15(h0_act));
            sigmoid_lut_q15 s1(.x_q15(acc_h1), .y_q15(h1_act));

            // output neuron: 2 inputs -> 1 output
            signed [31:0] acc_out;
            simple_2in_macc_q15 mac_out(
                .in0(h0_act), .in1(h1_act),
                .w0(W2[0]), .w1(W2[1]),
                .bias(B2[0]),
                .acc_out(acc_out)
            );

            // final activation (sigmoid)
            wire signed [15:0] out_act;
            sigmoid_lut_q15 sout(.x_q15(acc_out), .y_q15(out_act));

            // interpret out_act > 0.5 as logic 1
            integer out_int;
            if (out_act > 16'sh4000) out_int = 1; else out_int = 0;

            $display("IN=%b -> OUT_q15=%h -> OUT_bin=%0d", inputs[i], out_act, out_int);
            #10;
        end
        $finish;
    end
endmodule