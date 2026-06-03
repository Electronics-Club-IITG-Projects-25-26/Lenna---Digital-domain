`timescale 1ns / 1ps
module conv(
    input wire [71:0] data,
    input wire clk, rst, inp_valid, 
    input wire sel,sel2,sel3,
    output reg out_valid,
    output reg [7:0] pixel
    );
    reg mulvalid,sumvalid;
    wire signed [7:0] kernel [8:0];
    reg  signed [22:0] muldata [8:0];
    integer i;
    assign kernel[0]=0;
    assign kernel[1]=-1;
    assign kernel[2]=0;
    assign kernel[3]=-1;
    assign kernel[4]=5;
    assign kernel[5]=-1;
    assign kernel[6]=0;
    assign kernel[7]=-1;
    assign kernel[8]=0;
   
    
    always @ (posedge clk)begin
    
        for(i=0;i<9;i=i+1)begin
            muldata[i]<=kernel[i]* $signed({1'b0,data[i*8+:8]});
        end
        mulvalid<=inp_valid;
    end
    reg signed [24:0]sumData,sumDataint;
    always @ (*)begin
        sumDataint=0;
        for(i=0;i<9;i=i+1)begin
            sumDataint=sumDataint + muldata[i];
        end
    end
    
    always @(posedge clk) begin
    if ($signed(sumDataint) < 0)
        sumData <= 0;
    else if ($signed(sumDataint) > 25'sd255)
        sumData <= 255;
    else
        sumData <= sumDataint;
    sumvalid <= mulvalid;
end
always @(posedge clk) begin
    pixel <= sumData[7:0];
    out_valid <= sumvalid;
end


endmodule
