// True Dual Port SRAM - Synchronous Read
// Allows simultaneous independent read/write on two ports with separate clocks
module sram_dp #(
    parameter depth = 16,
    parameter width = 16
) (
    // Port A - typically for write/input streaming
    input [width-1:0] data_inA,
    input clk_A, we_A, re_A, cs_A,
    input [$clog2(depth)-1:0] add_A,
    output reg [width-1:0] data_outA,

    // Port B - typically for read/output streaming
    input [width-1:0] data_inB,
    input clk_B, we_B, re_B, cs_B,
    input [$clog2(depth)-1:0] add_B,
    output reg [width-1:0] data_outB
);

    reg [width-1:0] mem [0:depth-1];

    // Port A
    always @(posedge clk_A) begin
        if (cs_A && we_A) begin
            mem[add_A] <= data_inA;
        end
        if (cs_A && re_A) begin
            data_outA <= mem[add_A];
        end else begin
            data_outA <= {width{1'b0}};
        end
    end

    // Port B
    always @(posedge clk_B) begin
        if (cs_B && we_B) begin
            mem[add_B] <= data_inB;
        end
        if (cs_B && re_B) begin
            data_outB <= mem[add_B];
        end else begin
            data_outB <= {width{1'b0}};
        end
    end

endmodule
