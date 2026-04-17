`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.01.2026 23:27:13
// Design Name: 
// Module Name: linebuffer
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

// this is something which allows both read and write 
module linebuffer(
input wire clk,
input wire reset,
input wire read,
input wire datavalid ,
input wire [7:0] rgbinpixel,
output wire [23:0] rgboutpixel
    );
    integer i;
    reg [7:0] linebuffer [639:0]; // this is the real line buffer 
reg [9:0] wrpointer;
    reg [9:0] rdpointer;
    always @(posedge clk) begin 

     if (datavalid)  begin 
    linebuffer[wrpointer] <= rgbinpixel;
    end 
    end 
    always @(posedge clk) begin 
    if (reset) begin 
    wrpointer <=0;
    end 
    else if (wrpointer==639) begin 
    wrpointer <=0;
    end 
    else if (datavalid) begin 
    wrpointer <= wrpointer+1;
    end 
    end
    assign rgboutpixel= read? { linebuffer[rdpointer],linebuffer[rdpointer+9'd1],linebuffer[rdpointer+9'd2]}:24'b0;
         always @(posedge clk) begin 
    if (reset) begin 
    rdpointer <=0;
    end 
    else if (rdpointer==639) begin 
    rdpointer<=0;
    end 
    else if (read) begin 
    rdpointer <= rdpointer+1;
    end 
    end
endmodule
