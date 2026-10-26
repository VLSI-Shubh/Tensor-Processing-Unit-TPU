// 8-bit signed multiply-accumulate unit with pipelining
// Input: signed 8-bit operands (a, b)
// Output: signed 16-bit accumulator (y) + pipelined operands
module mac(
    input signed [7:0] a, b,
    input rst, clk,
    output signed [15:0] y,
    output reg signed [7:0] a_out, b_out
);

    reg signed [15:0] yin;
    wire signed [15:0] product;
    wire signed [16:0] sum;

    assign product = a * b;
    assign sum = yin + product;

    // Saturate to 16-bit signed range
    assign y = (sum > 16'h7FFF) ? 16'h7FFF :
               (sum < 16'h8000) ? 16'h8000 : sum[15:0];

    always @(posedge clk) begin
        if (rst) begin
            yin <= 16'h0;
        end else begin
            yin <= y;
        end
        a_out <= a;
        b_out <= b;
    end

endmodule
