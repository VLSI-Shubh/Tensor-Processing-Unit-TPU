// Output collector for TPU
// Selects one of the 16 results held in the array (row-major, or transposed)
// and registers it with optional ReLU. result_valid is aligned with result_out.
module collector (
    input clk,
    input rst_n,

    input [255:0] c_flat,           // C[i][j] at [16*(4*i+j) +: 16]
    input [3:0] sel,                // Output element index 0..15
    input en,                       // sel is valid this cycle

    // Output streaming interface
    output reg signed [15:0] result_out,
    output reg result_valid,

    input relu_mode,
    input transpose_mode            // Stream C^T instead of C
);

    wire [3:0] idx = transpose_mode ? {sel[1:0], sel[3:2]} : sel;
    wire signed [15:0] raw = c_flat[16*idx +: 16];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= 16'sh0;
            result_valid <= 1'b0;
        end else begin
            result_out <= (relu_mode && raw[15]) ? 16'sh0 : raw;
            result_valid <= en;
        end
    end

endmodule
