// Simulates the TinyFPGA BX top level (16 MHz) and checks the LED reports a pass
`timescale 1ns/1ps
module tb_main;
    reg CLK = 0;
    wire LED, USBPU;
    main dut (.CLK(CLK), .LED(LED), .USBPU(USBPU));
    always #31.25 CLK = ~CLK;

    initial begin
        #20000;   // ~320 clocks, far more than the ~70 the test needs
        if (LED === 1'b1 && dut.fail === 1'b0 && dut.out_idx === 4'd0 && dut.finished)
            $display("PASS: tb_main - self-test passed, LED on");
        else
            $display("FAIL: tb_main - LED=%b fail=%b finished=%b", LED, dut.fail, dut.finished);
        $finish;
    end
endmodule
