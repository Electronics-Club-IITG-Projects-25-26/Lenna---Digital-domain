`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2026 19:30:26
// Design Name: 
// Module Name: sobelcon
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


module sobelcon(
input wire clk,
input wire[71:0] matrixrgb,// u cant take io pin as 2Dmatrix
input wire validdata,
output reg [7:0] convolvedrgb,
output reg validconvolvedata
    );
    integer i;
    reg [7:0] kernel1 [8:0];
    reg [7:0] kernel2 [8:0];
  reg [10:0]  multidata1 [8:0];
  reg [10:0]  multidata2 [8:0];
  reg [10:0] sumdataint1;
  reg [10:0] sumdataint2; 
  reg [20:0] convolved_data_int1;
  reg [20:0] convolved_data_int2;
  // this is making it pipelined for efficiency
  reg multivalid;
  reg sumdatavalid;
  reg convolved_data_int_valid;
initial
begin
    kernel1[0] =  1;
    kernel1[1] =  0;
    kernel1[2] = -1;
    kernel1[3] =  2;
    kernel1[4] =  0;
    kernel1[5] = -2;
    kernel1[6] =  1;
    kernel1[7] =  0;
    kernel1[8] = -1;
    
    kernel2[0] =  1;
    kernel2[1] =  2;
    kernel2[2] =  1;
    kernel2[3] =  0;
    kernel2[4] =  0;
    kernel2[5] =  0;
    kernel2[6] = -1;
    kernel2[7] = -2;
    kernel2[8] = -1;
end    
    
    always @(posedge clk) begin // this is the multicplication stage 
     for(i=0;i<=8;i=i+1) begin 
      multidata1[i] <= $signed(kernel1[i])*$signed({1'b0,matrixrgb[i*8+:8]});
      multidata2[i] <= $signed(kernel2[i])*$signed({1'b0,matrixrgb[i*8+:8]});
      end 
     multivalid <=validdata;
      
end  
always @(*) begin 
sumdataint1 =0;
sumdataint2 =0;
for(i=0;i<=8;i=i+1) begin 
      sumdataint1  = $signed(sumdataint1) + $signed(multidata1[i]) ;
      sumdataint2  = $signed(sumdataint2) + $signed(multidata2[i]) ;
      end 
      end 
always @(posedge clk)
begin
    convolved_data_int1 <= $signed(sumdataint1)*$signed(sumdataint1);
    convolved_data_int2 <= $signed(sumdataint2)*$signed(sumdataint2);
    convolved_data_int_valid <= multivalid;
end 

 wire [21:0] sumdata = $signed(convolved_data_int1)+$signed(convolved_data_int2);
 always @(posedge clk) begin 
      if(sumdata > 4000)
        convolvedrgb <= 8'hff;
    else
        convolvedrgb <= 8'h00;
     validconvolvedata<=convolved_data_int_valid;
     end 
     
endmodule
