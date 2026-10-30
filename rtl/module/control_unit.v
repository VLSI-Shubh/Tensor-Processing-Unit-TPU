// Control unit for 4x4 TPU
// FSM: IDLE -> LOAD (16 valid_in beats) -> COMPUTE (14 cycles) -> READ (16 cycles) -> FIN -> IDLE
//
// COMPUTE timing (cycle = cnt):
//   cnt 0..6   operand banks are read with skew (rd_en, rd_t = cnt)
//   cnt 1..10  data ripples through the array; PE(3,3) takes its last operands
//              on cnt 10, so every result is final from cnt 11 on
//   cnt 11..13 margin, so all 16 results are final before the first READ cycle
module control_unit (
    input clk,
    input rst_n,
    input start,           // Pulse to begin a matrix multiply
    input valid_in,        // Qualifies a_in/b_in beats during LOAD

    output busy,           // High from start until the last result is delivered
    output done,           // One-cycle pulse, coincident with the last c_valid

    // Array control
    output clr,            // Clears the array (held during LOAD)

    // Feeder control
    output wr_en,
    output [3:0] wr_idx,
    output rd_en,
    output [2:0] rd_t,

    // Collector control
    output out_en,
    output [3:0] out_idx
);

    localparam IDLE    = 3'd0;
    localparam LOAD    = 3'd1;
    localparam COMPUTE = 3'd2;
    localparam READ    = 3'd3;
    localparam FIN     = 3'd4;

    reg [2:0] state;
    reg [3:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cnt <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    cnt <= 4'd0;
                    if (start)
                        state <= LOAD;
                end
                LOAD: begin
                    if (valid_in) begin
                        if (cnt == 4'd15) begin
                            state <= COMPUTE;
                            cnt <= 4'd0;
                        end else begin
                            cnt <= cnt + 4'd1;
                        end
                    end
                end
                COMPUTE: begin
                    if (cnt == 4'd13) begin
                        state <= READ;
                        cnt <= 4'd0;
                    end else begin
                        cnt <= cnt + 4'd1;
                    end
                end
                READ: begin
                    if (cnt == 4'd15) begin
                        state <= FIN;
                        cnt <= 4'd0;
                    end else begin
                        cnt <= cnt + 4'd1;
                    end
                end
                FIN: begin
                    state <= IDLE;
                    cnt <= 4'd0;
                end
                default: begin
                    state <= IDLE;
                    cnt <= 4'd0;
                end
            endcase
        end
    end

    assign busy   = (state != IDLE);
    assign done   = (state == FIN);
    assign clr    = (state == LOAD);
    assign wr_en  = (state == LOAD) && valid_in;
    assign wr_idx = cnt;
    assign rd_en  = (state == COMPUTE) && (cnt <= 4'd6);
    assign rd_t   = cnt[2:0];
    assign out_en = (state == READ);
    assign out_idx = cnt;

endmodule
