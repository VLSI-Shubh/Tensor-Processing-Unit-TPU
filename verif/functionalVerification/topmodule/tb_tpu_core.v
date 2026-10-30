`timescale 1ns/1ps

// Self-checking top-level testbench: compares every output against a software
// C = A*B reference (same sequential saturation as the PE) and checks the
// busy / done / c_valid protocol. Prints PASS or FAIL counts at the end.
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

    reg signed [7:0]  A [0:15];
    reg signed [7:0]  B [0:15];
    integer           C   [0:15];      // reference C, row-major, pre-ReLU
    integer           exp [0:15];      // expected stream order
    reg signed [15:0] got [0:15];

    integer errors, checks, seed;
    integer n_valid, n_done;
    integer i, j, k, t, acc, idx, gaps;
    reg seen_done_busy_ok;

    // ---- protocol monitors ----
    always @(posedge clk) begin
        if (c_valid) begin
            if (n_valid < 16) got[n_valid] = c_out;
            n_valid = n_valid + 1;
        end
        if (done) begin
            n_done = n_done + 1;
            if (!busy) begin
                $display("FAIL: done pulsed while busy low at %0t", $time);
                errors = errors + 1;
            end
        end
        if (c_valid && !busy) begin
            $display("FAIL: c_valid while busy low at %0t", $time);
            errors = errors + 1;
        end
    end

    task compute_reference;
        input relu;
        input transp;
        begin
            for (i = 0; i < 4; i = i + 1)
                for (j = 0; j < 4; j = j + 1) begin
                    acc = 0;
                    for (k = 0; k < 4; k = k + 1) begin
                        acc = acc + A[4*i+k] * B[4*k+j];
                        if (acc > 32767)  acc = 32767;
                        if (acc < -32768) acc = -32768;
                    end
                    C[4*i+j] = acc;
                end
            for (idx = 0; idx < 16; idx = idx + 1) begin
                t = transp ? (4*(idx%4) + idx/4) : idx;
                exp[idx] = (relu && C[t] < 0) ? 0 : C[t];
            end
        end
    endtask

    // Runs one full multiply on the current A/B; gaps != 0 inserts idle load beats
    task run;
        input relu;
        input transp;
        input with_gaps;
        integer w, timeout;
        begin
            compute_reference(relu, transp);
            relu_mode = relu;
            transpose_mode = transp;
            n_valid = 0;
            n_done = 0;

            if (busy) begin
                $display("FAIL: busy high before start at %0t", $time);
                errors = errors + 1;
            end

            @(negedge clk) start = 1;
            @(negedge clk) start = 0;
            if (!busy) begin
                $display("FAIL: busy not high after start at %0t", $time);
                errors = errors + 1;
            end

            for (w = 0; w < 16; w = w + 1) begin
                if (with_gaps != 0 && (w % 3 == 1)) begin
                    valid_in = 0;
                    a_in = 8'sh55;           // junk, must be ignored
                    b_in = 8'shAA;
                    @(negedge clk);
                end
                valid_in = 1;
                a_in = A[w];
                b_in = B[w];
                @(negedge clk);
            end
            valid_in = 0;
            a_in = 8'sh7F;                   // junk after load, must be ignored
            b_in = 8'sh7F;

            timeout = 0;
            while (busy && timeout < 200) begin
                @(negedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 200) begin
                $display("FAIL: busy never dropped (stuck FSM)");
                errors = errors + 1;
            end
            repeat (3) @(negedge clk);

            if (n_valid !== 16) begin
                $display("FAIL: expected 16 c_valid beats, got %0d", n_valid);
                errors = errors + 1;
            end
            if (n_done !== 1) begin
                $display("FAIL: expected 1 done pulse, got %0d", n_done);
                errors = errors + 1;
            end
            for (i = 0; i < 16; i = i + 1) begin
                checks = checks + 1;
                if (got[i] !== exp[i]) begin
                    $display("FAIL: element %0d got %0d expected %0d", i, got[i], exp[i]);
                    errors = errors + 1;
                end
            end
        end
    endtask

    task load_random;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                A[i] = $random(seed);
                B[i] = $random(seed);
            end
        end
    endtask

    integer r;

    initial begin
        $dumpfile("tb_tpu_core.vcd");
        $dumpvars(0, tb_tpu_core);

        clk = 0;
        rst_n = 0;
        a_in = 0; b_in = 0;
        valid_in = 0; start = 0;
        relu_mode = 0; transpose_mode = 0;
        errors = 0; checks = 0; seed = 32'h1234ABCD;
        n_valid = 0; n_done = 0;

        #20 rst_n = 1;
        repeat (3) @(negedge clk);

        if (busy || done || c_valid) begin
            $display("FAIL: outputs not idle after reset (busy=%b done=%b c_valid=%b)", busy, done, c_valid);
            errors = errors + 1;
        end

        // 1. A = 1..16, B = identity -> C = A
        for (i = 0; i < 16; i = i + 1) begin
            A[i] = i + 1;
            B[i] = (i % 5 == 0) ? 1 : 0;
        end
        run(0, 0, 0);

        // 2. Small known values: A = 1..16, B = 16..1
        for (i = 0; i < 16; i = i + 1) begin
            A[i] = i + 1;
            B[i] = 16 - i;
        end
        run(0, 0, 0);

        // 3. Random, back-to-back without reset (checks clear between runs)
        for (r = 0; r < 20; r = r + 1) begin
            load_random;
            run(0, 0, 0);
        end

        // 4. Random with ReLU, with transpose, with both
        for (r = 0; r < 5; r = r + 1) begin load_random; run(1, 0, 0); end
        for (r = 0; r < 5; r = r + 1) begin load_random; run(0, 1, 0); end
        for (r = 0; r < 5; r = r + 1) begin load_random; run(1, 1, 0); end

        // 5. valid_in gaps during load
        for (r = 0; r < 5; r = r + 1) begin load_random; run(0, 0, 1); end

        // 6. Saturation: (-128)*(-128)*4 = 65536 -> +32767
        for (i = 0; i < 16; i = i + 1) begin A[i] = -128; B[i] = -128; end
        run(0, 0, 0);
        // (-128)*127*4 = -65024 -> -32768
        for (i = 0; i < 16; i = i + 1) begin A[i] = -128; B[i] = 127; end
        run(0, 0, 0);
        run(1, 0, 0);

        // 7. All zeros and all max
        for (i = 0; i < 16; i = i + 1) begin A[i] = 0; B[i] = 0; end
        run(0, 0, 0);
        for (i = 0; i < 16; i = i + 1) begin A[i] = 127; B[i] = 127; end
        run(0, 0, 0);

        // 8. start while busy must be ignored: re-pulse start mid-load
        load_random;
        compute_reference(0, 0);
        n_valid = 0; n_done = 0;
        relu_mode = 0; transpose_mode = 0;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        for (i = 0; i < 16; i = i + 1) begin
            if (i == 5) start = 1; else start = 0;
            valid_in = 1; a_in = A[i]; b_in = B[i];
            @(negedge clk);
        end
        start = 0; valid_in = 0;
        while (busy) @(negedge clk);
        repeat (3) @(negedge clk);
        for (i = 0; i < 16; i = i + 1) begin
            checks = checks + 1;
            if (got[i] !== exp[i]) begin
                $display("FAIL: (start-while-busy) element %0d got %0d expected %0d", i, got[i], exp[i]);
                errors = errors + 1;
            end
        end
        if (n_valid !== 16 || n_done !== 1) begin
            $display("FAIL: start-while-busy produced %0d beats, %0d done", n_valid, n_done);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_tpu_core, %0d output checks, 0 errors", checks);
        else
            $display("FAIL: tb_tpu_core, %0d errors in %0d checks", errors, checks);
        $finish;
    end

    // Global watchdog
    initial begin
        #5000000;
        $display("FAIL: watchdog timeout");
        $finish;
    end

endmodule
