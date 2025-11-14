// tb/tb_nn.v
`timescale 1ns/1ps
module tb_nn;
    initial begin
        $display("Starting XOR NN simulation...");
        // instantiate top
        top_nn uut();
    end
endmodule