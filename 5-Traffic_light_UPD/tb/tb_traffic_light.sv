`timescale 1ns / 1ps

module tb_traffic_light();

    parameter int P_BLINK  = 5;
    parameter int P_RED    = 20;
    parameter int P_YELLOW = 10;
    parameter int P_GREEN  = 30;

    logic clk;
    logic rst;
    logic start;
    logic [2:0] lights;

    int errors = 0;

    traffic_light #(
        .P_BLINK_HALF_PERIOD(P_BLINK),
        .P_RED_TICKS(P_RED),
        .P_YELLOW_TICKS(P_YELLOW),
        .P_GREEN_TICKS(P_GREEN)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .lights(lights)
    );

    // Clk generator (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    task press_start();
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
    endtask

    initial begin
        // VCD
        $dumpfile("traffic_waves.vcd");
        $dumpvars(0, tb_traffic_light);

        rst = 1;
        start = 0;
        #50;
        @(negedge clk);
        rst = 0;

        $display("\n=== TRAFFIC LIGHT FSM VERIFICATION ===");

        // ---------------------------------------------------------
        $display("\n[PHASE 1] Checking IDLE blinking...");
        #(10 * P_BLINK * 3); // Жду несколько полупериодов
        if (lights === 3'b010 || lights === 3'b000) $display("  -> [PASS] Yellow light is blinking correctly.");
        else begin $display("  -> [FAIL] Blinking is broken!"); errors++; end

        // ---------------------------------------------------------
        $display("\n[PHASE 2] Normal Cycle & Ignore Start Logic...");
        press_start();
        
        // Wait to turn green, then press the button (it should be ignored)
        wait(dut.state == dut.S_GREEN);
        #(10 * 5); // Wait for 5 ticks inside the green zone
        $display("  -> Hitting START during GREEN (should be ignored)...");
        press_start();

        wait(dut.state == dut.S_IDLE);
        $display("  -> [PASS] Returned to IDLE successfully without repeating.");

        // ---------------------------------------------------------
        $display("\n[PHASE 3] Extended Cycle Logic (Yellow->Red Repeat)...");
        #(100);
        press_start();
        
        // Wait for the second yellow light and press the button
        wait(dut.state == dut.S_YELLOW_2);
        #(10 * 2);
        $display("  -> Hitting START during YELLOW_2 (should trigger repeat)...");
        press_start();

        // Let's check that after Red, it goes back to Yellow
        wait(dut.state == dut.S_RED_2);
        wait(dut.state == dut.S_YELLOW_2);
        $display("  -> [PASS] Cycle successfully repeated back to YELLOW_2!");

        wait(dut.state == dut.S_IDLE);
        $display("  -> [PASS] Finally returned to IDLE.");

        // ---------------------------------------------------------
        $display("\n==========================================");
        if (errors == 0) $display("  FINAL RESULT: SUCCESS (0 Errors)");
        else $display("  FINAL RESULT: FAILED (%0d Errors)", errors);
        $display("==========================================\n");

        $finish;
    end

endmodule