// Output collector for TPU
// Streams result matrix C from SRAM Port B with optional ReLU
module collector (
    input clk,
    input rst_n,

    // Input from SRAM Port B
    input signed [15:0] data_from_sram,
    input sram_valid,

    // Output streaming interface
    output reg signed [15:0] result_out,
    output reg result_valid,

    // Optional ReLU activation
    input relu_mode
);

    wire signed [15:0] activated;

    // ReLU: max(0, x)
    assign activated = relu_mode ?
                       (data_from_sram[15] ? 16'sh0 : data_from_sram) :
                       data_from_sram;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= 16'sh0;
            result_valid <= 1'b0;
        end else begin
            result_out <= activated;
            result_valid <= sram_valid;
        end
    end

endmodule
