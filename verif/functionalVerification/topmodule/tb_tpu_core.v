`timescale 1ns/1ps

module tb_tpu_core;

    reg clk, rst_n;
    reg signed [7:0] a_in, b_in;
    reg valid_in, start;
    reg relu_mode, transpose_mode;

    wire signed [15:0] c_out;
    wire c_valid, busy, done;

    tpu_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_in),
        .b_in(b_in),
        .valid_in(valid_in),
        .c_out(c_out),
        .c_valid(c_valid),
        .start(start),
        .busy(busy),
        .done(done),
        .relu_mode(relu_mode),
        .transpose_mode(transpose_mode)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_tpu_core.vcd");
        $dumpvars(0, tb_tpu_core);

        clk = 0;
        rst_n = 0;
        a_in = 8'sh0;
        b_in = 8'sh0;
        valid_in = 0;
        start = 0;
        relu_mode = 0;
        transpose_mode = 0;

        // Reset
        #20 rst_n = 1;

        // Load matrix A (4 rows)
        #10 a_in = 8'sh01; valid_in = 1;
        #10 a_in = 8'sh02;
        #10 a_in = 8'sh03;
        #10 a_in = 8'sh04;

        // Load matrix B (4 columns)
        #10 b_in = 8'sh01; a_in = 8'sh0;
        #10 b_in = 8'sh02;
        #10 b_in = 8'sh03;
        #10 b_in = 8'sh04;

        #10 valid_in = 0; start = 1;
        #10 start = 0;

        // Wait for completion
        #500 $finish;
    end

endmodule
