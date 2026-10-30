// TinyFPGA BX top level: power-on self-test of the TPU core.
//
// On power-up this streams a fixed pair of 4x4 matrices through tpu_core, compares the
// 16 results with precomputed expected values and reports on the user LED:
//   LED off          test running (a few microseconds)
//   LED solid on     all 16 results correct
//   LED blinking     at least one result wrong
// The USB bootloader pull-up is kept enabled so the board stays programmable.
module main (
    input  CLK,      // 16 MHz oscillator
    output LED,
    output USBPU
);
    assign USBPU = 1'b1;

    // A and B in row-major order, element 0 in the lowest byte; C likewise, 16 bits each
    localparam [127:0] A_MAT = 128'h0afd0df50602f80f04ec09ff0c07fb03;
    localparam [127:0] B_MAT = 128'h0ef40006fc0bfe08f90503f701fa0402;
    localparam [255:0] C_EXP = 256'h0032ffea0001ff990093ff4c0020009a0048ff27003fff2500b2ff92ffef00b3;

    // power-on reset: hold rst_n low for 16 clocks
    reg [3:0] rst_cnt = 4'd0;
    wire rst_n = &rst_cnt;
    always @(posedge CLK)
        if (!rst_n) rst_cnt <= rst_cnt + 4'd1;

    // stimulus sequencer: S_START pulses start, S_FEED sends 16 beats, S_WAIT waits for done
    localparam S_START = 2'd0, S_FEED = 2'd1, S_WAIT = 2'd2, S_END = 2'd3;
    reg [1:0] state = S_START;
    reg [3:0] beat = 4'd0;
    reg start = 1'b0;
    reg valid_in = 1'b0;
    reg signed [7:0] a_in = 8'sd0;
    reg signed [7:0] b_in = 8'sd0;

    always @(posedge CLK) begin
        if (!rst_n) begin
            state <= S_START;
            beat <= 4'd0;
            start <= 1'b0;
            valid_in <= 1'b0;
            a_in <= 8'sd0;
            b_in <= 8'sd0;
        end else begin
            start <= 1'b0;
            valid_in <= 1'b0;
            case (state)
                S_START: begin
                    start <= 1'b1;
                    state <= S_FEED;
                end
                S_FEED: begin
                    valid_in <= 1'b1;
                    a_in <= A_MAT[beat*8 +: 8];
                    b_in <= B_MAT[beat*8 +: 8];
                    beat <= beat + 4'd1;
                    if (beat == 4'd15) state <= S_WAIT;
                end
                S_WAIT: if (done) state <= S_END;
                default: ;
            endcase
        end
    end

    wire signed [15:0] c_out;
    wire c_valid, busy, done;

    tpu_core tpu (
        .clk(CLK),
        .rst_n(rst_n),
        .a_in(a_in),
        .b_in(b_in),
        .valid_in(valid_in),
        .c_out(c_out),
        .c_valid(c_valid),
        .start(start),
        .busy(busy),
        .done(done),
        .relu_mode(1'b0),
        .transpose_mode(1'b0)
    );

    // checker: compare each streamed result with the expected one
    reg [3:0] out_idx = 4'd0;
    reg fail = 1'b0;
    always @(posedge CLK) begin
        if (!rst_n) begin
            out_idx <= 4'd0;
            fail <= 1'b0;
        end else if (c_valid) begin
            out_idx <= out_idx + 4'd1;
            if (c_out !== C_EXP[out_idx*16 +: 16]) fail <= 1'b1;
        end
    end

    // LED: off while running, solid on = pass, ~1 Hz blink = fail
    reg [23:0] blink = 24'd0;
    always @(posedge CLK) blink <= blink + 24'd1;
    wire finished = (state == S_END);
    assign LED = finished && (!fail || blink[23]);
endmodule
