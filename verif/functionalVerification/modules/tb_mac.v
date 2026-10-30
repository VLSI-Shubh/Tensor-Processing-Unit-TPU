`timescale 1ns/1ps

// Self-checking unit test for the mac processing element
module tb_mac;

    reg clk, rst_n, clr;
    reg signed [7:0] a, b;
    wire signed [7:0] a_out, b_out;
    wire signed [15:0] acc;

    mac dut (.clk(clk), .rst_n(rst_n), .clr(clr), .a(a), .b(b),
             .a_out(a_out), .b_out(b_out), .acc(acc));

    always #5 clk = ~clk;

    integer errors;

    task step;
        input signed [7:0] ia;
        input signed [7:0] ib;
        input signed [15:0] expect_acc;
        begin
            a = ia; b = ib;
            @(posedge clk); #1;
            if (acc !== expect_acc) begin
                $display("FAIL: %0d*%0d acc=%0d expected %0d", ia, ib, acc, expect_acc);
                errors = errors + 1;
            end
            if (a_out !== ia || b_out !== ib) begin
                $display("FAIL: operand forwarding a_out=%0d b_out=%0d expected %0d %0d", a_out, b_out, ia, ib);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_mac.vcd");
        $dumpvars(0, tb_mac);
        clk = 0; rst_n = 0; clr = 0; a = 0; b = 0; errors = 0;
        #12 rst_n = 1;
        if (acc !== 0) begin $display("FAIL: acc not zero after reset"); errors = errors + 1; end

        step(2, 3, 6);
        step(4, 5, 26);
        step(-3, 7, 5);            // negative product
        step(-8, -8, 69);          // negative * negative
        step(0, 99, 69);           // zero operand keeps acc

        clr = 1; @(posedge clk); #1; clr = 0;
        if (acc !== 0 || a_out !== 0 || b_out !== 0) begin
            $display("FAIL: clr did not clear acc/operands"); errors = errors + 1;
        end

        // Positive saturation: 127*127 = 16129 added until it clips at 32767
        step(127, 127, 16129);
        step(127, 127, 32258);
        step(127, 127, 32767);
        step(127, 127, 32767);
        step(-1, 1, 32766);        // leaves saturation correctly

        clr = 1; @(posedge clk); #1; clr = 0;
        // Negative saturation: -128*127 = -16256
        step(-128, 127, -16256);
        step(-128, 127, -32512);
        step(-128, 127, -32768);
        step(-128, 127, -32768);
        step(1, 1, -32767);
        // Largest single product (-128*-128 = 16384) from zero
        clr = 1; @(posedge clk); #1; clr = 0;
        step(-128, -128, 16384);

        // Async reset
        a = 5; b = 5; @(posedge clk); #1;
        rst_n = 0; #1;
        if (acc !== 0) begin $display("FAIL: async reset did not clear acc"); errors = errors + 1; end
        rst_n = 1;

        if (errors == 0) $display("PASS: tb_mac, 0 errors");
        else $display("FAIL: tb_mac, %0d errors", errors);
        $finish;
    end

endmodule
