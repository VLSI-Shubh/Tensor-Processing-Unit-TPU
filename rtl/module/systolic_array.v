// 4x4 output-stationary systolic array built from 16 mac processing elements
// Computes C = A * B; PE(i,j) accumulates C[i][j] = sum_k A[i][k] * B[k][j]
//
// Data flow:
//   - A values enter on the left (a_row[i] feeds row i) and move right
//   - B values enter on the top (b_col[j] feeds column j) and move down
//   - Inputs must already be skewed: row i / column j delayed by i / j cycles,
//     so A[i][k] and B[k][j] meet at PE(i,j) on the same cycle (see feeder.v)
//   - All 16 accumulators are exposed on c_flat; c_flat[16*(4*i+j) +: 16] = C[i][j]
module systolic_array (
    input clk,
    input rst_n,
    input clr,                    // synchronous clear of all PEs
    input [31:0] a_row,           // 4 x signed 8-bit, row i at [8*i +: 8]
    input [31:0] b_col,           // 4 x signed 8-bit, column j at [8*j +: 8]
    output [255:0] c_flat
);

    // a_h: 4 rows x 5 taps, tap j is the input of PE(i,j), tap 4 is unused
    // b_v: 5 rows x 4 columns, row i is the input of PE(i,j), row 4 is unused
    wire [159:0] a_h;
    wire [159:0] b_v;

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : row
            assign a_h[8*(5*i) +: 8] = a_row[8*i +: 8];
            for (j = 0; j < 4; j = j + 1) begin : col
                if (i == 0) begin : top_edge
                    assign b_v[8*j +: 8] = b_col[8*j +: 8];
                end
                mac pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .clr(clr),
                    .a(a_h[8*(5*i + j) +: 8]),
                    .b(b_v[8*(4*i + j) +: 8]),
                    .a_out(a_h[8*(5*i + j + 1) +: 8]),
                    .b_out(b_v[8*(4*(i + 1) + j) +: 8]),
                    .acc(c_flat[16*(4*i + j) +: 16])
                );
            end
        end
    endgenerate

endmodule
