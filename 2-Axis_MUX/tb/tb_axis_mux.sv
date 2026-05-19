`timescale 1ns / 1ps

module tb_axis_mux();

    parameter int NUM_PORTS = 2;
    parameter int DATA_WIDTH = 32;
    parameter int CLK_PERIOD = 10;

    logic clk;
    logic [$clog2(NUM_PORTS)-1:0] sel_i;

    // Slave interfaces
    logic [NUM_PORTS-1:0][DATA_WIDTH-1:0] s_tdata;
    logic [NUM_PORTS-1:0]                 s_tvalid;
    logic [NUM_PORTS-1:0]                 s_tready;
    logic [NUM_PORTS-1:0]                 s_tlast;

    // Master interface
    logic [DATA_WIDTH-1:0] m_tdata;
    logic                  m_tvalid;
    logic                  m_tready;
    logic                  m_tlast;

    int errors = 0;

    axis_mux #(
        .NUM_PORTS(NUM_PORTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .sel_i(sel_i),
        .s_axis_tdata(s_tdata),
        .s_axis_tvalid(s_tvalid),
        .s_axis_tready(s_tready),
        .s_axis_tlast(s_tlast),
        .m_axis_tdata(m_tdata),
        .m_axis_tvalid(m_tvalid),
        .m_axis_tready(m_tready),
        .m_axis_tlast(m_tlast)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task send_word(input int port, input logic [DATA_WIDTH-1:0] data, input logic last);
        @(negedge clk);
        s_tdata[port]  = data;
        s_tlast[port]  = last;
        s_tvalid[port] = 1'b1;
        
        while(!s_tready[port]) begin
            @(negedge clk);
        end
        
        @(negedge clk);
        s_tvalid[port] = 1'b0;
    endtask

    initial begin
        // Включаем запись VCD в локальную папку симулятора
        $dumpfile("axis_mux_waves.vcd");
        $dumpvars(0, tb_axis_mux);

        sel_i = 0;
        s_tdata = '0;
        s_tvalid = '0;
        s_tlast = '0;
        m_tready = 1'b1; 

        #100;
        $display("\n=== AXI-STREAM MUX VERIFICATION START ===");

        // ---------------------------------------------------------
        $display("\n[TEST 1] Routing Port 0...");
        sel_i = 0;
        fork
            send_word(0, 32'hAAAA_0001, 0);
            begin
                while(m_tvalid !== 1'b1) @(posedge clk); 
                
                if (m_tdata !== 32'hAAAA_0001 || m_tvalid !== 1) begin
                    $display("  -> [FAIL] Port 0 data not routed correctly!");
                    errors++;
                end else $display("  -> [PASS] Port 0 routed perfectly.");
            end
        join

        @(posedge clk);

        // ---------------------------------------------------------
        $display("\n[TEST 2] Routing Port 1...");
        sel_i = 1;
        fork
            send_word(1, 32'hBBBB_0002, 1);
            begin
                while(m_tvalid !== 1'b1) @(posedge clk);
                
                if (m_tdata !== 32'hBBBB_0002 || m_tlast !== 1) begin
                    $display("  -> [FAIL] Port 1 data/last not routed correctly!");
                    errors++;
                end else $display("  -> [PASS] Port 1 routed perfectly.");
            end
        join

        @(posedge clk);

        // ---------------------------------------------------------
        $display("\n[TEST 3] Ignored Port Test (TREADY isolation)...");
        sel_i = 0; 
        s_tvalid[1] = 1'b1; 
        s_tdata[1]  = 32'hDEAD_BEEF;
        
        #10;
        if (s_tready[1] !== 1'b0) begin
            $display("  -> [FAIL] Unselected port 1 got TREADY=1!");
            errors++;
        end else if (m_tdata === 32'hDEAD_BEEF) begin
            $display("  -> [FAIL] Unselected data leaked to output!");
            errors++;
        end else begin
            $display("  -> [PASS] Unselected port is strictly ignored (TREADY=0).");
        end
        s_tvalid[1] = 1'b0;

        // ---------------------------------------------------------
        $display("\n[TEST 4] Backpressure (Stall) Test...");
        sel_i = 0;
        m_tready = 1'b0; 
        
        s_tdata[0]  = 32'hCCCC_3333;
        s_tvalid[0] = 1'b1;
        
        #20; 
        if (s_tready[0] !== 1'b0) begin
            $display("  -> [FAIL] Mux did not stall the input!");
            errors++;
        end else if (m_tvalid !== 1'b1) begin
            $display("  -> [FAIL] Mux dropped TVALID during backpressure!");
            errors++;
        end else begin
            $display("  -> [PASS] Input stalled (TREADY=0). TVALID held at 1.");
        end

        @(negedge clk);
        m_tready = 1'b1;
        @(negedge clk);
        s_tvalid[0] = 1'b0;
        $display("  -> [PASS] Transfer completed after stall.");

        // ---------------------------------------------------------
        $display("\n==========================================");
        if (errors == 0) $display("  FINAL RESULT: SUCCESS (0 Errors)");
        else $display($sformatf("  FINAL RESULT: FAILED (%0d Errors)", errors));
        $display("==========================================\n");

        $finish;
    end

endmodule