// Input feeder for TPU: banked operand memory plus skewed read-out
//
// Load (wr_en): one A element and one B element per beat, both row-major.
//   A[r][k] -> A bank r,  address k      (bank = row of A)
//   B[k][c] -> B bank c,  address k      (bank = column of B)
//
// Compute (rd_en, rd_t = 0..6): bank n is read at address k = rd_t - n when
// 0 <= k <= 3. This is the systolic skew: row i / column j is delayed by i / j.
// sram_dp returns zero when not read, so out-of-window cycles feed zeros.
// The read data appears one cycle after rd_t (synchronous SRAM read).
module feeder (
    input clk,

    // Load side
    input wr_en,
    input [3:0] wr_idx,                // 0..15, row-major element index
    input signed [7:0] a_in,
    input signed [7:0] b_in,

    // Compute side
    input rd_en,
    input [2:0] rd_t,                  // 0..6
    output [31:0] a_row,               // row i at [8*i +: 8]
    output [31:0] b_col                // column j at [8*j +: 8]
);

    genvar n;
    generate
        for (n = 0; n < 4; n = n + 1) begin : bank
            wire [3:0] k = {1'b0, rd_t} - n;        // negative sets k[3]
            wire in_window = rd_en && !k[3] && !k[2];

            sram_dp #(.depth(4), .width(8)) mem_a (
                .data_inA(a_in),
                .clk_A(clk),
                .we_A(wr_en && (wr_idx[3:2] == n)),
                .re_A(1'b0),
                .cs_A(1'b1),
                .add_A(wr_idx[1:0]),
                .data_outA(),
                .data_inB(8'h00),
                .clk_B(clk),
                .we_B(1'b0),
                .re_B(in_window),
                .cs_B(1'b1),
                .add_B(k[1:0]),
                .data_outB(a_row[8*n +: 8])
            );

            sram_dp #(.depth(4), .width(8)) mem_b (
                .data_inA(b_in),
                .clk_A(clk),
                .we_A(wr_en && (wr_idx[1:0] == n)),
                .re_A(1'b0),
                .cs_A(1'b1),
                .add_A(wr_idx[3:2]),
                .data_outA(),
                .data_inB(8'h00),
                .clk_B(clk),
                .we_B(1'b0),
                .re_B(in_window),
                .cs_B(1'b1),
                .add_B(k[1:0]),
                .data_outB(b_col[8*n +: 8])
            );
        end
    endgenerate

endmodule
