// Control unit for 4x4 TPU
// Manages state machine for: load A, load B, compute, read C
module control_unit (
    input clk,
    input rst_n,
    input start,           // Start signal to begin matrix multiply
    output reg busy,       // Indicates TPU is busy
    output reg done,       // Signals when result is ready

    // SRAM Port A control (inputs - A then B)
    output reg we_A, re_A, cs_A,
    output reg [3:0] addr_A,

    // SRAM Port B control (outputs - C)
    output reg we_B, re_B, cs_B,
    output reg [3:0] addr_B,

    // Systolic array control
    output reg sys_rst_n,

    // Data mux control
    output reg load_phase   // 0=loading, 1=reading
);

    localparam IDLE = 3'd0;
    localparam LOAD_A = 3'd1;
    localparam LOAD_B = 3'd2;
    localparam COMPUTE = 3'd3;
    localparam READ = 3'd4;

    reg [2:0] state, next_state;
    reg [3:0] cycle_count;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cycle_count <= 4'h0;
        end else begin
            state <= next_state;
            if (state != next_state)
                cycle_count <= 4'h0;
            else if (state != COMPUTE && state != IDLE)
                cycle_count <= cycle_count + 1'b1;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD_A;
            end
            LOAD_A: begin
                if (cycle_count == 3)
                    next_state = LOAD_B;
            end
            LOAD_B: begin
                if (cycle_count == 3)
                    next_state = COMPUTE;
            end
            COMPUTE: begin
                // Wait for 11 cycles (7 fill + 4 to read)
                if (cycle_count == 10)
                    next_state = READ;
            end
            READ: begin
                if (cycle_count == 3)
                    next_state = IDLE;
            end
        endcase
    end

    // Output control signals
    always @(*) begin
        busy = (state != IDLE);
        done = (state == IDLE && ~start);
        we_A = 1'b0;
        re_A = 1'b0;
        cs_A = 1'b0;
        we_B = 1'b0;
        re_B = 1'b0;
        cs_B = 1'b0;
        sys_rst_n = (state != IDLE);
        load_phase = 1'b0;
        addr_A = 4'h0;
        addr_B = 4'h0;

        case (state)
            LOAD_A: begin
                cs_A = 1'b1;
                we_A = 1'b1;
                re_A = 1'b0;
                addr_A = cycle_count;
                load_phase = 1'b1;
            end
            LOAD_B: begin
                cs_A = 1'b1;
                we_A = 1'b1;
                re_A = 1'b0;
                addr_A = {1'b1, cycle_count[2:0]};  // Address 4-7 for B
                load_phase = 1'b1;
            end
            READ: begin
                cs_B = 1'b1;
                we_B = 1'b0;
                re_B = 1'b1;
                addr_B = cycle_count;
                load_phase = 1'b0;
            end
        endcase
    end

endmodule
