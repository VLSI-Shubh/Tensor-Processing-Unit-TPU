`timescale 1ns/1ps

module tb_sram_dp;

    reg clk_A, clk_B;
    reg we_A, we_B, re_A, re_B, cs_A, cs_B;
    reg [3:0] add_A, add_B;
    reg [15:0] data_inA, data_inB;
    wire [15:0] data_outA, data_outB;

    sram_dp #(.depth(16), .width(16)) dut (
        .clk_A(clk_A), .clk_B(clk_B),
        .we_A(we_A), .we_B(we_B),
        .re_A(re_A), .re_B(re_B),
        .cs_A(cs_A), .cs_B(cs_B),
        .add_A(add_A), .add_B(add_B),
        .data_inA(data_inA), .data_inB(data_inB),
        .data_outA(data_outA), .data_outB(data_outB)
    );

    // Clock generation
    always #5 clk_A = ~clk_A;
    always #7 clk_B = ~clk_B;

    initial begin
        $dumpfile("tb_sram_dp.vcd");
        $dumpvars(0, tb_sram_dp);

        clk_A = 0;
        clk_B = 0;
        cs_A = 0;
        cs_B = 0;
        we_A = 0;
        we_B = 0;
        re_A = 0;
        re_B = 0;

        // Test 1: Write to address 0 via Port A
        #10 cs_A = 1; we_A = 1; add_A = 4'd0; data_inA = 16'hAAAA;
        #10 we_A = 0;

        // Test 2: Write to address 1 via Port B
        #10 cs_B = 1; we_B = 1; add_B = 4'd1; data_inB = 16'hBBBB;
        #14 we_B = 0;

        // Test 3: Read from address 0 via Port A
        #10 re_A = 1;
        #10 re_A = 0;

        // Test 4: Read from address 1 via Port B
        #10 re_B = 1;
        #14 re_B = 0;

        // Test 5: Simultaneous write and read
        #10 cs_A = 1; we_A = 1; add_A = 4'd2; data_inA = 16'hCCCC;
        #0 cs_B = 1; re_B = 1; add_B = 4'd0;

        #10 we_A = 0; re_B = 0;

        #50 $finish;
    end

endmodule
