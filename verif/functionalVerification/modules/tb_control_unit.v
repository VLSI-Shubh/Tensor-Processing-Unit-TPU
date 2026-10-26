`timescale 1ns/1ps

module tb_control_unit;

    reg clk, rst_n, start;
    wire busy, done;
    wire we_A, re_A, cs_A;
    wire [3:0] addr_A;
    wire we_B, re_B, cs_B;
    wire [3:0] addr_B;
    wire sys_rst_n;
    wire load_phase;

    control_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .we_A(we_A), .re_A(re_A), .cs_A(cs_A), .addr_A(addr_A),
        .we_B(we_B), .re_B(re_B), .cs_B(cs_B), .addr_B(addr_B),
        .sys_rst_n(sys_rst_n),
        .load_phase(load_phase)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        clk = 0;
        rst_n = 0;
        start = 0;

        // Reset
        #20 rst_n = 1;

        // Start matrix multiply
        #10 start = 1;
        #10 start = 0;

        // Wait for completion
        #500 $finish;
    end

endmodule
