// Top-level TPU Core: 4x4 output-stationary systolic array of MAC units
// Computes C = A * B for signed 8-bit 4x4 matrices; C is signed 16-bit (saturating)
//
// Protocol:
//   1. Pulse start for one cycle while idle (busy low)
//   2. Stream 16 beats with valid_in high: each beat carries the next element of
//      A (a_in) and of B (b_in), both in row-major order (a_in = A[idx/4][idx%4],
//      b_in = B[idx/4][idx%4])
//   3. Wait: busy stays high; 16 results then stream out on c_out with c_valid,
//      in row-major order (or transposed when transpose_mode is set)
//   4. done pulses for one cycle together with the last c_valid; busy then drops
// relu_mode and transpose_mode must be stable from start until done.
module tpu_core (
    input clk,
    input rst_n,

    // Input streaming (one A and one B element per valid beat)
    input signed [7:0] a_in,
    input signed [7:0] b_in,
    input valid_in,

    // Output streaming (matrix C elements)
    output signed [15:0] c_out,
    output c_valid,

    // Control signals
    input start,           // Pulse to start matrix multiply
    output busy,           // Indicates computation in progress
    output done,           // One-cycle pulse with the last result
    input relu_mode,       // Enable ReLU on output
    input transpose_mode   // Stream C transposed
);

    wire clr, wr_en, rd_en, out_en;
    wire [3:0] wr_idx, out_idx;
    wire [2:0] rd_t;
    wire [31:0] a_row, b_col;
    wire [255:0] c_flat;

    control_unit ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid_in(valid_in),
        .busy(busy),
        .done(done),
        .clr(clr),
        .wr_en(wr_en),
        .wr_idx(wr_idx),
        .rd_en(rd_en),
        .rd_t(rd_t),
        .out_en(out_en),
        .out_idx(out_idx)
    );

    feeder input_feeder (
        .clk(clk),
        .wr_en(wr_en),
        .wr_idx(wr_idx),
        .a_in(a_in),
        .b_in(b_in),
        .rd_en(rd_en),
        .rd_t(rd_t),
        .a_row(a_row),
        .b_col(b_col)
    );

    systolic_array systolic (
        .clk(clk),
        .rst_n(rst_n),
        .clr(clr),
        .a_row(a_row),
        .b_col(b_col),
        .c_flat(c_flat)
    );

    collector output_collector (
        .clk(clk),
        .rst_n(rst_n),
        .c_flat(c_flat),
        .sel(out_idx),
        .en(out_en),
        .result_out(c_out),
        .result_valid(c_valid),
        .relu_mode(relu_mode),
        .transpose_mode(transpose_mode)
    );

endmodule
