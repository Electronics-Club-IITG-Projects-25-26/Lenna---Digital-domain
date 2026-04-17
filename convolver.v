`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.01.2026 23:35:21
// Design Name: 
// Module Name: convolver
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


module convolver(
input wire clk,
input wire[71:0] matrixrgb,// u cant take io pin as 2Dmatrix
input wire validdata,
output reg [7:0] convolvedrgb,
output reg validconvolvedata
    );
    integer i;
    reg [7:0] kernel [8:0];
  reg [15:0]  multidata [8:0];
  reg [15:0] sumdataint;
  reg [15:0] sumdata; 
  // this is making it pipelined for efficiency
  reg multivalid;
  reg sumdatavalid;
    initial begin

        kernel[0] = 8'd1; kernel[1] = 8'd2; kernel[2] = 8'd1;
    // Row 1
    kernel[3] = 8'd2; kernel[4] = 8'd4; kernel[5] = 8'd2;
    // Row 2
    kernel[6] = 8'd1; kernel[7] = 8'd2; kernel[8] = 8'd1;
    end
    
    always @(posedge clk) begin // this is the multicplication stage 
     for(i=0;i<=8;i=i+1) begin 
      multidata[i] <= kernel[i]*matrixrgb[i*8+:8];
      end 
     multivalid <=validdata;
      
end  
always @(*) begin 
sumdataint =0;
for(i=0;i<=8;i=i+1) begin 
      sumdataint  = sumdataint +multidata[i] ;
      end 
      end 
 always @(posedge clk) begin 
         
      sumdata <= sumdataint ;
      
      sumdatavalid<=multivalid;
      end 
 always @(posedge clk) begin 
     convolvedrgb <= sumdata/16;
     validconvolvedata<=sumdatavalid;
     end 
     
endmodule
