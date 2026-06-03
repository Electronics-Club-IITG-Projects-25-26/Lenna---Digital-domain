`timescale 1ns / 1ps

module line_buffers(
    input wire [7:0] in,
    input wire clk, rst, valid,
    output wire [23:0] out,
    input wire read
    );
reg [7:0] lines [639:0];
reg [9:0] pointer;
always @ (posedge clk)begin
    if(valid)begin
        lines[pointer]<=in;
    end
end

//always @(posedge clk)begin
//    if(rst)begin
//        pointer<=0;
//    end else if (valid)begin
//        pointer<=pointer+1;
//    end
//end
always @(posedge clk) begin
    if (rst)
        pointer <= 0;
    else if (valid) begin
        if (pointer == 639)
            pointer <= 0;
        else
            pointer <= pointer + 1;
    end
end
reg [9:0] readpointer;
assign out={lines[readpointer],lines[readpointer+1],lines[readpointer+2]};

//always @(posedge clk)begin
//    if(rst)begin
//        readpointer<=0;
//    end else if (read) begin
//        readpointer<=readpointer+1;
//    end
//end
always @(posedge clk) begin
    if (rst)
        readpointer <= 0;
    else if (read) begin
        if (readpointer == 639)
            readpointer<= 0;
        else
            readpointer<= readpointer+ 1;
    end
end

endmodule
