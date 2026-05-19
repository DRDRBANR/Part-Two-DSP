`timescale 1ns / 1ps

module axis_mux #(
    parameter int NUM_PORTS = 2,
    parameter int DATA_WIDTH = 32
)(
    // Channel selection
    input  logic [$clog2(NUM_PORTS)-1:0] sel_i,

    // AXI-Stream Slaves
    input  logic [NUM_PORTS-1:0][DATA_WIDTH-1:0] s_axis_tdata,
    input  logic [NUM_PORTS-1:0]                 s_axis_tvalid,
    output logic [NUM_PORTS-1:0]                 s_axis_tready,
    input  logic [NUM_PORTS-1:0]                 s_axis_tlast,

    // AXI-Stream Master
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    input  logic                  m_axis_tready,
    output logic                  m_axis_tlast
);

    always_comb begin
        // unselected ports tready = 0
        s_axis_tready = '0;
        
        m_axis_tdata  = '0;
        m_axis_tvalid = 1'b0;
        m_axis_tlast  = 1'b0;

        if (sel_i < NUM_PORTS) begin
            m_axis_tdata         = s_axis_tdata[sel_i];
            m_axis_tvalid        = s_axis_tvalid[sel_i];
            m_axis_tlast         = s_axis_tlast[sel_i];
            
            s_axis_tready[sel_i] = m_axis_tready;
        end
    end

endmodule