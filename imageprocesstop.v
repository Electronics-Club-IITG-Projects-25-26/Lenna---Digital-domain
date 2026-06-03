`timescale 1ns / 1ps

module imageprocesstop(
    input wire clk, rst,
    input wire sel,sel2,sel3,
    input wire valid_in, 
    input wire [7:0] in_pixel,
    output wire out_ready,
    output wire out_valid,
    output wire [7:0] out_pixel,
    input wire in_ready,
    output wire interupt 
    
    );
    wire [71:0] controlout;
    wire [7:0] convolve_pixel;
    wire convolve_valid;
    wire  out_valid_ctrl;
    wire axis_prog_full;
    assign out_ready=(!axis_prog_full);
    
    control ctrl(
        .rst(!rst),
        .clk(clk),
        .inp_valid(valid_in),
        .out_valid(out_valid_ctrl),
        .in_pixel(in_pixel),
        .out_pixel(controlout),
        .intr(interupt)
    );
    
    conv convolver(
    .sel(sel),
    .sel2(sel2),
    .sel3(sel3),
    .data(controlout),
    .clk(clk), 
    .rst(!rst), 
    .inp_valid(out_valid_ctrl), 
    .out_valid(convolve_valid),
    .pixel(convolve_pixel)
    );
    
    fifo_generator_0 OB (
  .wr_rst_busy(),        // output wire wr_rst_busy
  .rd_rst_busy(),        // output wire rd_rst_busy
  .s_aclk(clk),                  // input wire s_aclk
  .s_aresetn(rst),            // input wire s_aresetn
  .s_axis_tvalid(convolve_valid),    // input wire s_axis_tvalid
  .s_axis_tready(),    // output wire s_axis_tready
  .s_axis_tdata(convolve_pixel),      // input wire [7 : 0] s_axis_tdata
  .m_axis_tvalid(out_valid),    // output wire m_axis_tvalid
  .m_axis_tready(in_ready),    // input wire m_axis_tready
  .m_axis_tdata(out_pixel),      // output wire [7 : 0] m_axis_tdata
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
);

endmodule
