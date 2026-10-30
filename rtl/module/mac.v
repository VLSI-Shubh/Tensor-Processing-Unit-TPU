// Signed 8-bit multiply-accumulate processing element (output-stationary)
// acc <= sat16(acc + a*b) every cycle; a and b are forwarded one cycle later
// to the right / lower neighbour, so zero operands simply add nothing.
// clr is synchronous and zeroes the accumulator and the forwarded operands.
module mac (
    input clk,
    input rst_n,
    input clr,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [7:0] a_out,
    output reg signed [7:0] b_out,
    output reg signed [15:0] acc
);

    wire signed [15:0] product = a * b;
    wire signed [16:0] sum = acc + product;

    // 17-bit sum overflows 16 bits when its top two bits differ
    wire signed [15:0] sum_sat = (sum[16] == sum[15]) ? sum[15:0] :
                                 (sum[16] ? 16'sh8000 : 16'sh7FFF);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= 8'sh0;
            b_out <= 8'sh0;
            acc   <= 16'sh0;
        end else if (clr) begin
            a_out <= 8'sh0;
            b_out <= 8'sh0;
            acc   <= 16'sh0;
        end else begin
            a_out <= a;
            b_out <= b;
            acc   <= sum_sat;
        end
    end

endmodule
