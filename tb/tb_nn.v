// tb/tb_nn.v  –  Testbench for the XOR neural-network (Verilog-2005 compatible)
`timescale 1ns/1ps

module tb_nn;

    // ---------------------------------------------------------------
    // Weight / bias ROMs  (Q5.11, 16-bit signed, stored as hex)
    // ---------------------------------------------------------------
    reg signed [15:0] W1 [0:3];   // 2×2 = 4 entries
    reg signed [15:0] B1 [0:1];   // 2 entries
    reg signed [15:0] W2 [0:1];   // 2 entries
    reg signed [15:0] B2 [0:0];   // 1 entry

    initial begin
        $readmemh("../hex/W1.hex", W1);
        $readmemh("../hex/B1.hex", B1);
        $readmemh("../hex/W2.hex", W2);
        $readmemh("../hex/B2.hex", B2);
    end

    // ---------------------------------------------------------------
    // Inputs (registered so they can be driven from the initial block)
    // ---------------------------------------------------------------
    reg signed [15:0] in0_r, in1_r;

    // ---------------------------------------------------------------
    // Hidden layer – MACC outputs
    // ---------------------------------------------------------------
    wire signed [31:0] acc_h0, acc_h1;

    simple_2in_macc_q15 mac_h0 (
        .in0(in0_r), .in1(in1_r),
        .w0(W1[0]),  .w1(W1[1]),
        .bias(B1[0]),
        .acc_out(acc_h0)
    );

    simple_2in_macc_q15 mac_h1 (
        .in0(in0_r), .in1(in1_r),
        .w0(W1[2]),  .w1(W1[3]),
        .bias(B1[1]),
        .acc_out(acc_h1)
    );

    // ---------------------------------------------------------------
    // Hidden layer – sigmoid activations
    // ---------------------------------------------------------------
    wire signed [15:0] h0_act, h1_act;

    sigmoid_lut_q15 s0 (.x_q15(acc_h0), .y_q15(h0_act));
    sigmoid_lut_q15 s1 (.x_q15(acc_h1), .y_q15(h1_act));

    // ---------------------------------------------------------------
    // Output layer – MACC
    // ---------------------------------------------------------------
    wire signed [31:0] acc_out;

    simple_2in_macc_q15 mac_out (
        .in0(h0_act), .in1(h1_act),
        .w0(W2[0]),   .w1(W2[1]),
        .bias(B2[0]),
        .acc_out(acc_out)
    );

    // ---------------------------------------------------------------
    // Output layer – sigmoid activation
    // ---------------------------------------------------------------
    wire signed [15:0] out_act;

    sigmoid_lut_q15 sout (.x_q15(acc_out), .y_q15(out_act));

    // ---------------------------------------------------------------
    // Test stimulus
    // ---------------------------------------------------------------
    integer pass_count;
    integer i;
    reg [1:0] test_in  [0:3];
    reg [0:0] test_exp [0:3];
    integer   out_bin;

    initial begin
        // XOR truth table
        test_in[0] = 2'b00;  test_exp[0] = 1'b0;
        test_in[1] = 2'b01;  test_exp[1] = 1'b1;
        test_in[2] = 2'b10;  test_exp[2] = 1'b1;
        test_in[3] = 2'b11;  test_exp[3] = 1'b0;

        pass_count = 0;
        $display("XOR Neural Network Simulation");
        $display("==============================");

        #5; // wait for ROMs to initialise

        for (i = 0; i < 4; i = i + 1) begin
            // Convert binary input to Q5.11  (0 → 0x0000, 1 → 0x0800 = 2048)
            in0_r = test_in[i][1] ? 16'sh0800 : 16'sh0000;
            in1_r = test_in[i][0] ? 16'sh0800 : 16'sh0000;

            #10; // propagation delay

            // Threshold at 0.5  (0x0400 in Q5.11 = 1024)
            out_bin = (out_act > 16'sh0400) ? 1 : 0;

            $display("IN=%b%b  OUT_q15=0x%04h  OUT_bin=%0d  (expected %0d)  %s",
                     test_in[i][1], test_in[i][0],
                     out_act, out_bin, test_exp[i],
                     (out_bin == test_exp[i]) ? "PASS" : "FAIL");

            if (out_bin == test_exp[i])
                pass_count = pass_count + 1;
        end

        $display("==============================");
        if (pass_count == 4) begin
            $display("All 4 XOR test cases PASSED");
        end else begin
            $display("%0d/4 XOR test cases PASSED – check hex/ weights", pass_count);
        end
        $display("Simulation finished.");
        $finish;
    end

endmodule
