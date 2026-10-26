// Input feeder for TPU
// Multiplexes matrix A and B rows onto SRAM Port A during load phase
module feeder (
    // Input streaming interface (row-wise for A, column-wise for B)
    input signed [7:0] a_in,
    input signed [7:0] b_in,

    // Mux control from control unit
    input [3:0] addr_ctrl,  // Address from control unit (bit 3: 0=A, 1=B)

    // Output to SRAM Port A
    output signed [7:0] data_to_sram,
    output [3:0] addr_out
);

    // Route input data to SRAM
    // During LOAD_A: pass a_in
    // During LOAD_B: pass b_in
    assign data_to_sram = (addr_ctrl[3] == 1'b0) ? a_in : b_in;
    assign addr_out = addr_ctrl;

endmodule
