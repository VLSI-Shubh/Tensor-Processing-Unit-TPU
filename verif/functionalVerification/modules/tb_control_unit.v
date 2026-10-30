`timescale 1ns/1ps

// Self-checking unit test for the control FSM: counts the cycles spent in each
// phase and checks busy / done / clr / enable behaviour.
module tb_control_unit;

    reg clk, rst_n, start, valid_in;
    wire busy, done, clr, wr_en, rd_en, out_en;
    wire [3:0] wr_idx, out_idx;
    wire [2:0] rd_t;

    control_unit dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid_in(valid_in),
        .busy(busy), .done(done), .clr(clr),
        .wr_en(wr_en), .wr_idx(wr_idx),
        .rd_en(rd_en), .rd_t(rd_t),
        .out_en(out_en), .out_idx(out_idx)
    );

    always #5 clk = ~clk;

    integer errors;
    integer n_wr, n_rd, n_out, n_done, n_busy, run, w;
    integer cyc;

    // Monitor
    always @(posedge clk) begin
        if (wr_en) begin
            if (wr_idx !== n_wr[3:0]) begin
                $display("FAIL: wr_idx %0d expected %0d", wr_idx, n_wr); errors = errors + 1;
            end
            n_wr = n_wr + 1;
        end
        if (rd_en) begin
            if (rd_t !== n_rd[2:0]) begin
                $display("FAIL: rd_t %0d expected %0d", rd_t, n_rd); errors = errors + 1;
            end
            n_rd = n_rd + 1;
        end
        if (out_en) begin
            if (out_idx !== n_out[3:0]) begin
                $display("FAIL: out_idx %0d expected %0d", out_idx, n_out); errors = errors + 1;
            end
            n_out = n_out + 1;
        end
        if (done) n_done = n_done + 1;
        if (busy) n_busy = n_busy + 1;
        if (done && !busy) begin $display("FAIL: done without busy"); errors = errors + 1; end
    end

    initial begin
        $dumpfile("tb_control_unit.vcd");
        $dumpvars(0, tb_control_unit);

        clk = 0; rst_n = 0; start = 0; valid_in = 0; errors = 0;
        n_wr = 0; n_rd = 0; n_out = 0; n_done = 0; n_busy = 0;
        #22 rst_n = 1;
        repeat (3) @(negedge clk);

        if (busy || done || clr || wr_en || rd_en || out_en) begin
            $display("FAIL: not idle after reset"); errors = errors + 1;
        end

        // valid_in without start must be ignored
        valid_in = 1; repeat (3) @(negedge clk); valid_in = 0;
        if (n_wr !== 0) begin $display("FAIL: wrote while idle"); errors = errors + 1; end

        for (run = 0; run < 2; run = run + 1) begin
            n_wr = 0; n_rd = 0; n_out = 0; n_done = 0; n_busy = 0;
            @(negedge clk) start = 1;
            @(negedge clk) start = 0;
            if (!busy) begin $display("FAIL: busy low after start"); errors = errors + 1; end
            if (!clr)  begin $display("FAIL: clr not asserted during load"); errors = errors + 1; end

            // 16 valid beats with a stall every third beat
            for (w = 0; w < 16; w = w + 1) begin
                if (w % 3 == 1) begin valid_in = 0; @(negedge clk); end
                valid_in = 1; @(negedge clk);
            end
            valid_in = 0;

            cyc = 0;
            while (busy && cyc < 100) begin @(negedge clk); cyc = cyc + 1; end
            repeat (2) @(negedge clk);

            if (n_wr  !== 16) begin $display("FAIL: %0d writes, expected 16", n_wr);  errors = errors + 1; end
            if (n_rd  !== 7)  begin $display("FAIL: %0d reads, expected 7", n_rd);    errors = errors + 1; end
            if (n_out !== 16) begin $display("FAIL: %0d outs, expected 16", n_out);   errors = errors + 1; end
            if (n_done !== 1) begin $display("FAIL: %0d done pulses, expected 1", n_done); errors = errors + 1; end
            if (busy)         begin $display("FAIL: busy stuck high");                 errors = errors + 1; end
        end

        if (errors == 0) $display("PASS: tb_control_unit, 0 errors");
        else $display("FAIL: tb_control_unit, %0d errors", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("FAIL: watchdog timeout");
        $finish;
    end

endmodule
