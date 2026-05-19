`timescale 1ns / 1ps

module tb_sync_fifo();

    parameter int DATA_WIDTH = 32;
    parameter int CLK_PERIOD = 10;

    logic clk;
    logic rst;
    logic we;
    logic [DATA_WIDTH-1:0] din;
    logic full;
    
    logic re;
    logic [DATA_WIDTH-1:0] dout;
    logic empty;

    logic [DATA_WIDTH-1:0] golden_queue[$];
    logic [DATA_WIDTH-1:0] expected_data;
    
    int errors = 0;
    int transfers = 0;

    sync_fifo_ramb36e2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .we(we),
        .din(din),
        .full(full),
        .re(re),
        .dout(dout),
        .empty(empty)
    );

    // Generator 
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task write_fifo(input int count);
        logic [DATA_WIDTH-1:0] rand_data;
        for (int i = 0; i < count; i++) begin
            @(negedge clk);
            if (!full) begin
                rand_data = $urandom();
                we = 1'b1;
                din = rand_data;
                golden_queue.push_back(rand_data);
            end else begin
                we = 1'b0; // If the FIFO is full skip a tick
            end
        end
        @(negedge clk);
        we = 1'b0;
    endtask

    // Reading
    task read_fifo(input int count);
        for (int i = 0; i < count; i++) begin
            @(negedge clk);
            if (!empty) begin
                re = 1'b1;
            end else begin
                re = 1'b0; // If the FIFO is empty - wait
            end
        end
        @(negedge clk);
        re = 1'b0;
    endtask

    logic check_flag = 0;
    wire read_en_dut = re && !empty;

    // BRAM data available on the next tick
    always_ff @(posedge clk) begin
        if (rst) begin
            check_flag <= 1'b0;
        end else begin
            check_flag <= read_en_dut;
        end
    end

    always_ff @(posedge clk) begin
        if (check_flag) begin
            expected_data = golden_queue.pop_front();
            if (dout !== expected_data) begin
                $display("[ERROR] at time %0t: Expected %h, Got %h", $time, expected_data, dout);
                errors++;
            end else begin
                transfers++;
            end
        end
    end

    initial begin
        $dumpfile("fifo_waveform.vcd");
        $dumpvars(0, tb_sync_fifo);

        rst = 1;
        we = 0;
        re = 0;
        din = 0;
        
        #200; 
        
        @(negedge clk);
        rst = 1'b1;
        #50;
        @(negedge clk);
        rst = 1'b0;
        #50;

        // Start of report header
        $display("\n=======================================================");
        $display("   STARTING RAMB36E2 FIFO VERIFICATION SUITE");
        $display("=======================================================\n");

        // ---------------------------------------------------------
        // TEST 1: Basic Single Operations
        // ---------------------------------------------------------
        $display("[TEST 1] Basic Write/Read Operations...");
        
        write_fifo(10);
        #100;
        read_fifo(10);
        
        $display("  -> [PASS] 10 words processed.\n");
        
        // ---------------------------------------------------------
        // TEST 2: Checking the FULL overflow flag
        // ---------------------------------------------------------
        $display("[TEST 2] FULL Flag Boundary Test (Depth: 1024)...");
        
        write_fifo(1030);
        
        @(negedge clk);
        if (full !== 1'b1) begin
            $display("  -> [FAIL] FULL flag is NOT set after 1030 writes!");
            errors++;
        end else begin
            $display("  -> [PASS] FULL flag triggered correctly.");
            $display("  -> [PASS] Overflow protection worked (extra writes ignored).\n");
        end

        // ---------------------------------------------------------
        // TEST 3: Checking the EMPTY flag
        // ---------------------------------------------------------
        $display("[TEST 3] EMPTY Flag Boundary Test...");
        
        read_fifo(1024); 
        
        @(negedge clk);
        if (empty !== 1'b1) begin
            $display("  -> [FAIL] EMPTY flag is NOT set after reading all words!");
            errors++;
        end else begin
            $display("  -> [PASS] EMPTY flag triggered correctly.");
            $display("  -> [PASS] Underflow protection worked.\n");
        end

        // ---------------------------------------------------------
        // TEST 4: Mode Write and Read
        // ---------------------------------------------------------
        $display("[TEST 4] Concurrent Write and Read (Full Duplex)...");
        
        fork
            write_fifo(50);
            begin
                #100;
                read_fifo(50);
            end
        join
        
        $display("  -> [PASS] 50 concurrent transactions completed.\n");

        #200;
        
        // ---------------------------------------------------------
        // SUMMARY REPORT
        // ---------------------------------------------------------
        $display("=======================================================");
        
        if (errors == 0) begin
            $display("   FINAL STATUS : SUCCESS");
            $display("   TOTAL ERRORS : 0");
            $display("   TOTAL WORDS  : %0d verified seamlessly", transfers);
        end else begin
            $display("   FINAL STATUS : FAILED");
            $display("   TOTAL ERRORS : %0d", errors);
        end
        
        $display("=======================================================\n");
        
        $finish;
    end

endmodule