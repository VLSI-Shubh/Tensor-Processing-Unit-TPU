`timescale 1ns/1ps

module tb_systolic_array;

    reg clk;
    reg rst_n;
    reg signed [7:0] a, b;
    wire signed [15:0] y;

    systolic_array dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .y(y)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);

        clk = 0;
        rst_n = 0;
        a = 8'sh0;
        b = 8'sh0;

        // Reset
        #20 rst_n = 1;

        // Test case 1: 2 x 3
        #10 a = 8'sh02; b = 8'sh03;
        #10 a = 8'sh04; b = 8'sh05;
        #10 a = 8'sh06; b = 8'sh07;
        #10 a = 8'sh08; b = 8'sh09;

        // Wait for pipeline to fill
        #80;

        // Reset accumulators
        #10 rst_n = 0;
        #10 rst_n = 1;

        // Test case 2: 5 x 7
        #10 a = 8'sh05; b = 8'sh07;
        #10 a = 8'sh0A; b = 8'sh0B;
        #10 a = 8'sh03; b = 8'sh04;
        #10 a = 8'sh02; b = 8'sh01;

        #80 $finish;
    end

endmodule
