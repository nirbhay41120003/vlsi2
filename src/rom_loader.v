// src/rom_loader.v
`timescale 1ns/1ps

module rom_loader_example;
    // Parameters for sizes (change to match your network)
    parameter IN_DIM = 2;
    parameter HIDDEN = 2;
    parameter OUT_DIM = 1;

    // Storage (16-bit signed per entry)
    reg [15:0] W1_mem [0:(HIDDEN*IN_DIM)-1];
    reg [15:0] B1_mem [0:HIDDEN-1];
    reg [15:0] W2_mem [0:(OUT_DIM*HIDDEN)-1];
    reg [15:0] B2_mem [0:OUT_DIM-1];

    initial begin
        $readmemh("../hex/W1.hex", W1_mem);
        $readmemh("../hex/B1.hex", B1_mem);
        $readmemh("../hex/W2.hex", W2_mem);
        $readmemh("../hex/B2.hex", B2_mem);
        $display("W1[0]=%h B1[0]=%h W2[0]=%h B2[0]=%h", W1_mem[0], B1_mem[0], W2_mem[0], B2_mem[0]);
        $finish;
    end
endmodule