`timescale 1ns / 1ps

module traffic_light #(
    parameter int P_BLINK_HALF_PERIOD = 5,  // Half-cycle flashing in standby mode
    parameter int P_RED_TICKS         = 20, //  lifetime red
    parameter int P_YELLOW_TICKS      = 10, // lifetime yellow
    parameter int P_GREEN_TICKS       = 30  // lifetime green
)(
    input  logic clk,
    input  logic rst,
    input  logic start,       // Control signal
    output logic [2:0] lights // Lamp outputs [2:Red, 1:Yellow, 0:Green]
);


    typedef enum logic [2:0] {
        S_IDLE     = 3'd0, // Standby (yellow light flashing)
        S_RED_1    = 3'd1, // The First Red
        S_YELLOW_1 = 3'd2, // The first yellow one
        S_GREEN    = 3'd3, // Green
        S_YELLOW_2 = 3'd4, // The second yellow (transition to red)
        S_RED_2    = 3'd5  // The second red one
    } state_t;

    typedef enum logic [2:0] {
        L_OFF    = 3'b000,
        L_GREEN  = 3'b001,
        L_YELLOW = 3'b010,
        L_RED    = 3'b100
    } light_t;


    state_t state;
    light_t light_out;
    
    int tick_cnt;         // Cycle counter for timers
    logic blink_state;    // blinker status in IDLE mode
    logic repeat_flag;    // Loop repeat flag: Yellow->Red

    assign lights = light_out;

    // FSM
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= S_IDLE;
            light_out   <= L_OFF;
            tick_cnt    <= 0;
            blink_state <= 0;
            repeat_flag <= 0;
        end else begin
            tick_cnt <= tick_cnt + 1;
            case (state)
                S_IDLE: begin
                    // blinker
                    if (tick_cnt >= P_BLINK_HALF_PERIOD - 1) begin
                        tick_cnt    <= 0;
                        blink_state <= ~blink_state;
                    end
                    light_out <= blink_state ? L_YELLOW : L_OFF;

                    // out of standby
                    if (start) begin
                        state     <= S_RED_1;
                        tick_cnt  <= 0;
                        light_out <= L_RED;
                    end
                end

                S_RED_1: begin
                    light_out <= L_RED;
                    if (tick_cnt >= P_RED_TICKS - 1) begin
                        state    <= S_YELLOW_1;
                        tick_cnt <= 0;
                    end
                end

                S_YELLOW_1: begin
                    light_out <= L_YELLOW;
                    if (tick_cnt >= P_YELLOW_TICKS - 1) begin
                        state    <= S_GREEN;
                        tick_cnt <= 0;
                    end
                end

                S_GREEN: begin
                    light_out <= L_GREEN;
                    repeat_flag <= 0; 
                    if (tick_cnt >= P_GREEN_TICKS - 1) begin
                        state    <= S_YELLOW_2;
                        tick_cnt <= 0;
                    end
                end

                S_YELLOW_2: begin
                    light_out <= L_YELLOW;
                    if (start) repeat_flag <= 1'b1;
                    
                    if (tick_cnt >= P_YELLOW_TICKS - 1) begin
                        state    <= S_RED_2;
                        tick_cnt <= 0;
                    end
                end

                S_RED_2: begin
                    light_out <= L_RED;
                    if (start) repeat_flag <= 1'b1;

                    if (tick_cnt >= P_RED_TICKS - 1) begin
                        if (repeat_flag) begin
                            state       <= S_YELLOW_2;
                            repeat_flag <= 0; 
                        end else begin
                            state       <= S_IDLE;
                            blink_state <= 1'b1; // Start flashing with the yellow light on
                        end
                        tick_cnt <= 0;
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule