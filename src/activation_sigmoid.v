// src/activation_sigmoid.v
`timescale 1ns/1ps
`ifndef ACTIVATION_SIGMOID_V
`define ACTIVATION_SIGMOID_V

module sigmoid_lut_q15 (
    input  signed [31:0] x_q15,  // Q5.11 (32-bit signed)
    output reg signed [15:0] y_q15 // Q5.11 output
);
    // LUT parameters
    localparam integer LUT_SIZE = 256;
    // address computed by mapping x in [-8, +8] -> [0, LUT_SIZE-1]
    // x is Q5.11. Map: idx = round( (x + 8) * (LUT_SIZE-1) / 16 )
    wire signed [31:0] x_plus_8_q15 = x_q15 + (8 <<< 11);
    // numerator = x_plus_8_q15 * (LUT_SIZE-1)
    wire signed [47:0] numerator = x_plus_8_q15 * (LUT_SIZE-1);
    // denominator = 16 in Q0, but since x_plus_8_q15 is Q5.11, divide by 16*2^11 => shift right by (4 + 11) = 15
    wire signed [47:0] idx_w = numerator >>> 15; // safe shift
    wire [7:0] idx = (idx_w < 0) ? 0 :
                    (idx_w > (LUT_SIZE-1)) ? (LUT_SIZE-1) :
                    idx_w[7:0];

    // ROM
    reg [15:0] rom [0:LUT_SIZE-1];
    initial begin
        $readmemh("../hex/sigmoid_lut.hex", rom); // make sure relative path matches your simulation run dir
    end

    always @* begin
        y_q15 = rom[idx];
    end
endmodule
`endif // ACTIVATION_SIGMOID_V
