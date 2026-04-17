`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.01.2026 13:00:58
// Design Name: 
// Module Name: topmodule
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module imgprocon(
input wire clk,
input wire reset,
// slave interface here the dma 
input wire data_valid,// this comes from the dma // when its sharing data to the ip
input wire [7:0] imagedata ,// this too comes from the dma 
output wire sdataready,// this tells the dma i have space 
// master interface (here the ip image processor )
output wire o_data_valid,
output wire [7:0] outputimage,
input wire dataready, // this comes from the dma(slave here) here 
output wire  o_intr // this tells the processor when reading one line buffer takes place :)
    );
    wire axis_prog_full;
  wire [71:0] betweenimage ; 
  wire  pixeldatavalido; 
  wire [7:0] convolved_data;
  wire validconvolvedata;
  assign sdataready=!axis_prog_full;
   
     imageprocessingcontrol IC (
.clk(clk),
.reset(reset),
.pixelidata(imagedata),
.pixeldatavalidi(data_valid),// when the dma sends data be ready to take it :)
.o_pixel_data(betweenimage), // connecting wire to convolver 
.pixeldatavalido(pixeldatavalido),
.intr(o_intr)
    );
   
convolver C0(
.clk(clk),
.matrixrgb(betweenimage),// u cant take io pin as 2Dmatrix
.validdata(pixeldatavalido), // talking to the imagecontroll saying okkk if u have data i am always ready to accept 
.convolvedrgb(convolved_data),
.validconvolvedata(validconvolvedata) // this is saying i have data to the dma
);
fifo_generator_0 OB (
  .wr_rst_busy(),        // output wire wr_rst_busy
  .rd_rst_busy(),        // output wire rd_rst_busy
  .s_aclk(clk),                  // input wire s_aclk
  .s_aresetn(!reset),            // input wire s_aresetn
  .s_axis_tvalid(validconvolvedata),    // input wire s_axis_tvalid 
  .s_axis_tready(),    // output wire s_axis_tready 
  .s_axis_tdata(convolved_data),      // input wire [7 : 0] s_axis_tdata
  .m_axis_tvalid(o_data_valid),    // output wire m_axis_tvalid
  .m_axis_tready(dataready),    // input wire m_axis_tready
  .m_axis_tdata(outputimage),      // output wire [7 : 0] m_axis_tdata
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
);
endmodule
