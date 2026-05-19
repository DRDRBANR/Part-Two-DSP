`timescale 1ns / 1ps

module cdc_multibit_sync #(
    parameter int DATA_WIDTH = 32
)(
    input  logic                  clk_src,
    input  logic                  rst_src,
    input  logic [DATA_WIDTH-1:0] data_src,
    input  logic                  valid_src,

    input  logic                  clk_dest,
    input  logic                  rst_dest,
    output logic [DATA_WIDTH-1:0] data_dest,
    output logic                  valid_dest
);

    // Synct upd signal 
    logic update_pulse_dest;
    
    cdc_pulse_sync u_pulse_sync (
        .clk_src   (clk_src),
        .rst_src   (rst_src),
        .pulse_src (valid_src),
        .clk_dest  (clk_dest),
        .rst_dest  (rst_dest),
        .pulse_dest(update_pulse_dest)
    );

    // Save the data 
    always_ff @(posedge clk_dest or posedge rst_dest) begin
        if (rst_dest) begin
            data_dest  <= '0;
            valid_dest <= 1'b0;
        end else begin
            valid_dest <= update_pulse_dest;
            if (update_pulse_dest) begin
                data_dest <= data_src;
            end
        end
    end

endmodule