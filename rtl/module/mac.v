/* This is a simple implementation of a multiply-accumulate (MAC) unit in Verilog. 
The MAC unit takes two inputs, `a` and `b`, and produces an output `y` which is the accumulated product of `a` and `b`. 
The accumulation can be reset using the `rst` signal, and the operation is synchronized with the clock signal `clk`.
*/
module mac(
    input [7:0]a,b,
    input rst, clk,
    output [15:0]y,
    output [7:0] a_out, b_out
);

wire yin;

always @(posedge clk) begin
    if (rst) begin
        yin <=0;
    end
    else begin
        yin <= yin + a*b;
    end
    y <= yin;
    a_out <= a;
    b_out <= b;
end
endmodule
