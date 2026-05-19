`timescale 1ns / 1ps

module traffic_light #(
    parameter int P_BLINK_HALF_PERIOD = 5,
    parameter int P_RED_TICKS         = 20,
    parameter int P_YELLOW_TICKS      = 10,
    parameter int P_GREEN_TICKS       = 30
)(
    input  logic clk,
    input  logic rst,
    input  logic start,
    output logic [2:0] lights
);

    
    // OPTIMIZATION 1: Calculate the maximum delay and timer width
    // Find the largest number
    localparam int MAX_DELAY = (P_GREEN_TICKS > P_RED_TICKS) ? 
                               ((P_GREEN_TICKS > P_YELLOW_TICKS) ? P_GREEN_TICKS : P_YELLOW_TICKS) :
                               ((P_RED_TICKS > P_YELLOW_TICKS) ? P_RED_TICKS : P_YELLOW_TICKS);
                               
    // Calculate the required number of bits (FF) for the timer
    localparam int TIMER_WIDTH = $clog2(MAX_DELAY + 1);

    // ENUM 
    (* fsm_encoding = "sequential" *)
    typedef enum logic [2:0] {
        S_IDLE     = 3'd0,
        S_RED_1    = 3'd1,
        S_YELLOW_1 = 3'd2,
        S_GREEN    = 3'd3,
        S_YELLOW_2 = 3'd4,
        S_RED_2    = 3'd5
    } state_t;

    typedef enum logic [2:0] {
        L_OFF    = 3'b000,
        L_GREEN  = 3'b001,
        L_YELLOW = 3'b010,
        L_RED    = 3'b100
    } light_t;

    state_t state;
    light_t light_out;
    
    // OPTIMIZATION 2: The timer now has a fixed width 
    logic [TIMER_WIDTH-1:0] timer; 
    logic blink_state;
    logic repeat_flag;

    assign lights = light_out;

    // OPTIMIZED FSM LOGIC (Countdown)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= S_IDLE;
            light_out   <= L_OFF;
            timer       <= P_BLINK_HALF_PERIOD[TIMER_WIDTH-1:0] - 1; 
            blink_state <= 0;
            repeat_flag <= 0;
        end else begin
            
            // A single timer decrement logic for all states (saves on LUTs)
            if (timer != 0) begin
                timer <= timer - 1;
            end

            case (state)
                S_IDLE: begin
                    if (timer == 0) begin
                        timer       <= P_BLINK_HALF_PERIOD[TIMER_WIDTH-1:0] - 1;
                        blink_state <= ~blink_state;
                    end
                    light_out <= blink_state ? L_YELLOW : L_OFF;

                    if (start) begin
                        state     <= S_RED_1;
                        timer     <= P_RED_TICKS[TIMER_WIDTH-1:0] - 1; // Загружаем новую задержку
                        light_out <= L_RED;
                    end
                end

                S_RED_1: begin
                    light_out <= L_RED;
                    if (timer == 0) begin
                        state <= S_YELLOW_1;
                        timer <= P_YELLOW_TICKS[TIMER_WIDTH-1:0] - 1;
                    end
                end

                S_YELLOW_1: begin
                    light_out <= L_YELLOW;
                    if (timer == 0) begin
                        state <= S_GREEN;
                        timer <= P_GREEN_TICKS[TIMER_WIDTH-1:0] - 1;
                    end
                end

                S_GREEN: begin
                    light_out <= L_GREEN;
                    repeat_flag <= 0; 
                    if (timer == 0) begin
                        state <= S_YELLOW_2;
                        timer <= P_YELLOW_TICKS[TIMER_WIDTH-1:0] - 1;
                    end
                end

                S_YELLOW_2: begin
                    light_out <= L_YELLOW;
                    if (start) repeat_flag <= 1'b1;
                    
                    if (timer == 0) begin
                        state <= S_RED_2;
                        timer <= P_RED_TICKS[TIMER_WIDTH-1:0] - 1;
                    end
                end

                S_RED_2: begin
                    light_out <= L_RED;
                    if (start) repeat_flag <= 1'b1;

                    if (timer == 0) begin
                        if (repeat_flag) begin
                            state       <= S_YELLOW_2;
                            timer       <= P_YELLOW_TICKS[TIMER_WIDTH-1:0] - 1;
                            repeat_flag <= 0; 
                        end else begin
                            state       <= S_IDLE;
                            timer       <= P_BLINK_HALF_PERIOD[TIMER_WIDTH-1:0] - 1;
                            blink_state <= 1'b1; 
                        end
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule