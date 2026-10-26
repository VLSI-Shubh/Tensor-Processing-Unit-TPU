// Top-level TPU Core: 4x4 Systolic Array with SRAM, Control, and I/O
// Input: 8-bit signed, Output: 16-bit signed
// Supports streaming of matrices with optional ReLU activation
module tpu_core (
    input clk,
    input rst_n,

    // Input streaming (matrix A rows, then B columns)
    input signed [7:0] a_in,
    input signed [7:0] b_in,
    input valid_in,

    // Output streaming (matrix C rows)
    output signed [15:0] c_out,
    output c_valid,

    // Control signals
    input start,           // Pulse to start matrix multiply
    output busy,           // Indicates computation in progress
    output done,           // Signals result ready
    input relu_mode,       // Enable ReLU on output
    input transpose_mode   // Enable transpose (optional)
);

    // Internal signals
    wire signed [7:0] feeder_data;
    wire [3:0] feeder_addr;
    wire signed [7:0] systolic_a_in, systolic_b_in;
    wire systolic_rst_n;
    wire signed [15:0] systolic_out;

    wire we_A, re_A, cs_A;
    wire [3:0] addr_A;
    wire signed [15:0] sram_a_out;

    wire we_B, re_B, cs_B;
    wire [3:0] addr_B;
    wire signed [15:0] sram_b_out;

    wire load_phase;

    // ===== CONTROL UNIT =====
    control_unit ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .we_A(we_A),
        .re_A(re_A),
        .cs_A(cs_A),
        .addr_A(addr_A),
        .we_B(we_B),
        .re_B(re_B),
        .cs_B(cs_B),
        .addr_B(addr_B),
        .sys_rst_n(systolic_rst_n),
        .load_phase(load_phase)
    );

    // ===== INPUT FEEDER =====
    feeder input_feeder (
        .a_in(a_in),
        .b_in(b_in),
        .addr_ctrl(addr_A),
        .data_to_sram(feeder_data),
        .addr_out(feeder_addr)
    );

    // ===== DUAL PORT SRAM (16 words x 16-bit) =====
    // Addresses 0-3: Matrix A (4 rows)
    // Addresses 4-7: Matrix B (4 columns)
    // Addresses 8-15: Results C (4 rows)
    sram_dp #(
        .depth(16),
        .width(16)
    ) memory (
        // Port A: Input streaming
        .data_inA({{8{feeder_data[7]}}, feeder_data}),  // Sign-extend 8-bit to 16-bit
        .clk_A(clk),
        .we_A(we_A),
        .re_A(re_A),
        .cs_A(cs_A),
        .add_A(feeder_addr),
        .data_outA(sram_a_out),

        // Port B: Output streaming
        .data_inB(systolic_out),
        .clk_B(clk),
        .we_B(we_B),
        .re_B(re_B),
        .cs_B(cs_B),
        .add_B(addr_B),
        .data_outB(sram_b_out)
    );

    // ===== SYSTOLIC ARRAY =====
    // Reads from SRAM Port A (addresses 0-7 for A and B)
    // Note: In a real design, would need separate logic to multiplex systolic inputs
    // For now, simplified: directly connect to streaming inputs during compute
    assign systolic_a_in = a_in;
    assign systolic_b_in = b_in;

    systolic_array systolic (
        .a(systolic_a_in),
        .b(systolic_b_in),
        .rst_n(systolic_rst_n),
        .clk(clk),
        .y(systolic_out)
    );

    // ===== OUTPUT COLLECTOR =====
    collector output_collector (
        .clk(clk),
        .rst_n(rst_n),
        .data_from_sram(sram_b_out),
        .sram_valid(re_B),
        .result_out(c_out),
        .result_valid(c_valid),
        .relu_mode(relu_mode)
    );

endmodule
