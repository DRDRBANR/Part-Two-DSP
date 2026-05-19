`timescale 1ns / 1ps

module tb_cdc();

    parameter int DATA_WIDTH = 32;

    logic clk_fast; // 100 MHz
    logic clk_slow; // 40 MHz
    logic rst;

    logic [DATA_WIDTH-1:0] tx_data;
    logic                  tx_valid;
    logic [DATA_WIDTH-1:0] rx_data;
    logic                  rx_valid;

    logic [DATA_WIDTH-1:0] golden_queue[$];
    int errors = 0;
    int transfers = 0;

    cdc_multibit_sync #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk_src   (clk_fast),
        .rst_src   (rst),
        .data_src  (tx_data),
        .valid_src (tx_valid),
        .clk_dest  (clk_slow),
        .rst_dest  (rst),
        .data_dest (rx_data),
        .valid_dest(rx_valid)
    );


    initial clk_fast = 0;
    always #5 clk_fast = ~clk_fast; // T 10 ns (100 MHz)

    initial clk_slow = 0;
    always #12.5 clk_slow = ~clk_slow; // Period 25 ns (40 MHz)

    // Sending data from the fast domain
    task send_data(input logic [DATA_WIDTH-1:0] data);
        @(negedge clk_fast);
        tx_data  = data;
        tx_valid = 1'b1;
        golden_queue.push_back(data);
        
        @(negedge clk_fast);
        tx_valid = 1'b0;
        
        // Pause
        #(25 * 3); 
    endtask

    always_ff @(posedge clk_slow) begin
        if (rx_valid) begin
            logic [DATA_WIDTH-1:0] expected;
            expected = golden_queue.pop_front();
            
            if (rx_data !== expected) begin
                $display("[ERROR] Time %0t: Expected %h, Got %h", $time, expected, rx_data);
                errors++;
            end else begin
                transfers++;
            end
        end
    end


    initial begin
        $dumpfile("cdc_waves.vcd");
        $dumpvars(0, tb_cdc);

        rst = 1;
        tx_data = '0;
        tx_valid = 0;
        
        #100;
        @(negedge clk_fast);
        rst = 0;
        #100;

        $display("\n=== STARTING CDC VERIFICATION ===");

        for (int i = 0; i < 10; i++) begin
            send_data($urandom());
        end

        #500;

        $display("==========================================");
        if (errors == 0 && transfers == 10) begin
            $display("  [SUCCESS] All %0d words crossed domains perfectly!", transfers);
        end else begin
            $display("  [FAILED] Errors: %0d, Transfers caught: %0d", errors, transfers);
        end
        $display("==========================================\n");
        
        $finish;
    end

endmodule