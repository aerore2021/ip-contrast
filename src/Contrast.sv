`timescale 1ns / 1ps

module Contrast #(
    parameter int DATA_WIDTH = 8,
    parameter int FRAME_WIDTH = 640,
    parameter int FRAME_HEIGHT = 512,
    parameter real E = 5,
    parameter real THRESHOLD = 127
) (
    input clk,
    input rst_n,
    AxiStreamIf.Slave s_axis,
    AxiStreamIf.Master m_axis
);
    localparam int BRAM_SIZE = 2**DATA_WIDTH;
    // real E = 5;
    // real thres = 127;
    real var;
    logic [DATA_WIDTH-1:0] bram [0:BRAM_SIZE-1];

    initial begin   
        for (int input_pixel = 0; input_pixel < BRAM_SIZE; input_pixel++) begin
            var = 1/((1+thres/input_pixel)**E);
            bram[input_pixel] = $rtoi(var * 255);
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis.tvalid <= 0;
            m_axis.tdata <= '0;
            m_axis.tlast <= 0;
            m_axis.tuser <= 0;
        end
        else if (s_axis.tvalid && s_axis.tready) begin
            m_axis.tdata <= bram[s_axis.tdata];
            m_axis.tvalid <= 1;
            m_axis.tlast <= s_axis.tlast;
            m_axis.tuser <= s_axis.tuser;

            if (s_axis.tlast) begin
                m_axis.tvalid <= 0; // Reset valid after last
            end
        end
    end
endmodule