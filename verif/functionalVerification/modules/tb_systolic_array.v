`timescale 1ns/1ps

// Self-checking unit test for the 4x4 systolic array.
// The TB applies the skew itself (row i / column j delayed by i / j cycles)
// and compares all 16 accumulators against a software C = A*B.
module tb_systolic_array;

    reg clk, rst_n, clr;
    reg [31:0] a_row, b_col;
    wire [255:0] c_flat;

    systolic_array dut (.clk(clk), .rst_n(rst_n), .clr(clr),
                        .a_row(a_row), .b_col(b_col), .c_flat(c_flat));

    always #5 clk = ~clk;

    reg signed [7:0] A [0:15];
    reg signed [7:0] B [0:15];
    integer errors, checks, seed;
    integer i, j, k, t, r, n, acc;
    reg signed [15:0] got;

    task run;
        begin
            @(negedge clk) clr = 1;
            @(negedge clk) clr = 0;
            for (t = 0; t < 7; t = t + 1) begin
                a_row = 32'h0;
                b_col = 32'h0;
                for (n = 0; n < 4; n = n + 1) begin
                    k = t - n;
                    if (k >= 0 && k < 4) begin
                        a_row[8*n +: 8] = A[4*n + k];   // A[row n][k]
                        b_col[8*n +: 8] = B[4*k + n];   // B[k][col n]
                    end
                end
                @(negedge clk);
            end
            a_row = 32'h0;
            b_col = 32'h0;
            repeat (10) @(negedge clk);

            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1) begin
                    acc = 0;
                    for (k = 0; k < 4; k = k + 1) begin
                        acc = acc + A[4*i+k] * B[4*k+j];
                        if (acc > 32767)  acc = 32767;
                        if (acc < -32768) acc = -32768;
                    end
                    got = c_flat[16*(4*i+j) +: 16];
                    checks = checks + 1;
                    if (got !== acc) begin
                        $display("FAIL: C[%0d][%0d] got %0d expected %0d", i, j, got, acc);
                        errors = errors + 1;
                    end
                end
        end
    endtask

    initial begin
        $dumpfile("tb_systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);
        clk = 0; rst_n = 0; clr = 0; a_row = 0; b_col = 0;
        errors = 0; checks = 0; seed = 7;
        #20 rst_n = 1;

        // A = 1..16, B = identity -> C = A
        for (i = 0; i < 16; i = i + 1) begin
            A[i] = i + 1;
            B[i] = (i % 5 == 0) ? 1 : 0;
        end
        run;

        // Random matrices, back-to-back
        for (r = 0; r < 20; r = r + 1) begin
            for (i = 0; i < 16; i = i + 1) begin
                A[i] = $random(seed);
                B[i] = $random(seed);
            end
            run;
        end

        // Saturation
        for (i = 0; i < 16; i = i + 1) begin A[i] = -128; B[i] = -128; end
        run;

        if (errors == 0) $display("PASS: tb_systolic_array, %0d checks, 0 errors", checks);
        else $display("FAIL: tb_systolic_array, %0d errors in %0d checks", errors, checks);
        $finish;
    end

endmodule
