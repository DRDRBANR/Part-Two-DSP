`timescale 1ns / 1ps

module cdc_pulse_sync (
    input  logic clk_src,
    input  logic rst_src,
    input  logic pulse_src,

    input  logic clk_dest,
    input  logic rst_dest,
    output logic pulse_dest
);


    logic toggle_src;
    always_ff @(posedge clk_src or posedge rst_src) begin
        if (rst_src) begin
            toggle_src <= 1'b0;
        end else if (pulse_src) begin
            toggle_src <= ~toggle_src; // change state with every tick
        end
    end

   
    // 2-FF Synchronizer
    logic sync_meta, sync_dest;
    always_ff @(posedge clk_dest or posedge rst_dest) begin
        if (rst_dest) begin
            sync_meta <= 1'b0;
            sync_dest <= 1'b0;
        end else begin
            sync_meta <= toggle_src;
            sync_dest <= sync_meta;
        end
    end

    // Delay the signal by one tick
    logic sync_dest_d;
    always_ff @(posedge clk_dest or posedge rst_dest) begin
        if (rst_dest) begin
            sync_dest_d <= 1'b0;
        end else begin
            sync_dest_d <= sync_dest;
        end
    end 
  
    assign pulse_dest = sync_dest ^ sync_dest_d;

endmodule