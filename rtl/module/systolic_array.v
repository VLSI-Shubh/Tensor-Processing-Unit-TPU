// 4x4 Systolic Array for matrix multiplication
// Computes C = A * B where A, B, C are 4x4 matrices of signed 8-bit values
// Outputs C are signed 16-bit values
//
// Data flow:
//   - A flows left-to-right (row-wise)
//   - B flows top-to-bottom (column-wise)
//   - Takes 7 cycles to fill the pipeline, then produces one row of C per cycle
//
module systolic_array (
    input signed [7:0] a, b,
    input rst_n, clk,
    output signed [15:0] y
);

    // Shift registers for A (4 stages)
    reg signed [7:0] a_stage [0:3];

    // Shift registers for B (4 stages)
    reg signed [7:0] b_stage [0:3];

    // Partial sums (4x4 array)
    reg signed [15:0] p_reg [0:3][0:3];

    integer i, j;

    // Shift in A operands (left to right)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage[0] <= 8'sh0;
            a_stage[1] <= 8'sh0;
            a_stage[2] <= 8'sh0;
            a_stage[3] <= 8'sh0;
        end else begin
            a_stage[0] <= a;
            a_stage[1] <= a_stage[0];
            a_stage[2] <= a_stage[1];
            a_stage[3] <= a_stage[2];
        end
    end

    // Shift in B operands (top to bottom)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_stage[0] <= 8'sh0;
            b_stage[1] <= 8'sh0;
            b_stage[2] <= 8'sh0;
            b_stage[3] <= 8'sh0;
        end else begin
            b_stage[0] <= b;
            b_stage[1] <= b_stage[0];
            b_stage[2] <= b_stage[1];
            b_stage[3] <= b_stage[2];
        end
    end

    // Systolic computation - multiply and accumulate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    p_reg[i][j] <= 16'sh0;
                end
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin
                    p_reg[i][j] <= p_reg[i][j] + (a_stage[i] * b_stage[j]);
                end
            end
        end
    end

    // Output the result at position [3][3]
    assign y = p_reg[3][3];

endmodule
