`timescale 1ns / 1ps

module sync_fifo_ramb36e2#(
        parameter int DATA_WIDTH = 32
    )(
        input  logic                  clk,
        input  logic                  rst,
    
        // Writing interface
        input  logic                  we,
        input  logic [DATA_WIDTH-1:0] din,
        output logic                  full,
    
        // Reading interface
        input  logic                  re,
        output logic [DATA_WIDTH-1:0] dout,
        output logic                  empty
    );

    localparam int DEPTH = 1024;
    localparam int ADDR_WIDTH = $clog2(DEPTH); // 10 bit

    logic [ADDR_WIDTH-1:0] wr_ptr = '0;
    logic [ADDR_WIDTH-1:0] rd_ptr = '0;
    logic [ADDR_WIDTH:0]   count  = '0;

    logic write_en;
    logic read_en;

    assign write_en = we && !full;
    assign read_en  = re && !empty;

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end else begin
            unique case ({write_en, read_en})
                2'b10: begin // Write only
                    wr_ptr <= wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end
                2'b01: begin // Read only
                    rd_ptr <= rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end
                2'b11: begin // Write&Read
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                end
                default: ;
            endcase
        end
    end

    assign full  = (count == DEPTH);
    assign empty = (count == '0);

    // 15-bit address for the RAMB36E2
    wire [14:0] ram_rd_addr = {rd_ptr, 5'b00000};
    wire [14:0] ram_wr_addr = {wr_ptr, 5'b00000};

    wire [31:0] ram_din  = {{32-DATA_WIDTH{1'b0}}, din};
    wire [31:0] ram_dout;
    assign dout = ram_dout[DATA_WIDTH-1:0];

    // Instantiation of the RAMB36E2 primitive
    RAMB36E2 #(
        .DOA_REG(0),                // Output register is disabled 
        .DOB_REG(0),
        .READ_WIDTH_A(36),          // 32 bit + 4 bit
        .READ_WIDTH_B(36),
        .WRITE_WIDTH_A(36),
        .WRITE_WIDTH_B(36),
        .WRITE_MODE_A("READ_FIRST"),
        .WRITE_MODE_B("WRITE_FIRST")
    ) RAMB36E2_inst (
        // A use for reading
        .CLKARDCLK   (clk),
        .ENARDEN     (read_en),
        .ADDRARDADDR (ram_rd_addr),
        .WEA         (4'b0000),      
        .DOUTADOUT   (ram_dout),
        .DINADIN     (32'h00000000),
        .RSTRAMARSTRAM (rst),
        
        // B use for writing
        .CLKBWRCLK   (clk),
        .ENBWREN     (write_en),
        .ADDRBWRADDR (ram_wr_addr),
        .WEBWE       (8'hFF),        
        .DINBDIN     (ram_din),
        .DOUTBDOUT   (),
        .RSTRAMB     (rst),
        
        .CASDIMUXA   (1'b0),
        .CASDIMUXB   (1'b0),
        .CASOREGIMUXA(1'b0),
        .CASOREGIMUXB(1'b0),
        .CASOREGIMUXEN_A(1'b1),
        .CASOREGIMUXEN_B(1'b1),
        .SLEEP       (1'b0)
    );

endmodule
