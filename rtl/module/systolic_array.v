module systolic_array (
    input [7:0] a, b,
    input rst, clk,
    output [15:0] y,
);
    reg [7:0] a_reg [0:3];
    reg [7:0] b_reg [0:3];
    reg [15:0] p_reg [0:3][0:3];

    integer i, j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                a_reg[i] <= 8'b0;
                b_reg[i] <= 8'b0;
                for (j = 0; j < 4; j = j + 1) begin
                    p_reg[i][j] <= 16'b0;
                end
            end
        end else begin
            a_reg[0] <= a;
            b_reg[0] <= b;
            for (i = 1; i < 4; i = i + 1) begin
                a_reg[i] <= a_reg[i-1];
                b_reg[i] <= b_reg[i-1];
            end
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    p_reg[i][j] <= p_reg[i][j] + a_reg[i] * b_reg[j];
                end
            end
        end
    end

    assign y = p_reg[3][3]; 
endmodule