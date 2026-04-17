module imageprocessingcontrol(
input wire clk,
input wire reset,
input wire [7:0]   pixelidata,
input             wire       pixeldatavalidi,
output reg [71:0]        o_pixel_data,
output            wire       pixeldatavalido,
output reg               intr
    );
    wire [23:0] lb0data;
wire [23:0] lb1data;
wire [23:0] lb2data;
wire [23:0] lb3data;
    reg [1:0] counter1;
    reg [1:0] counter2;
    reg rd_line_buffer;
    
    reg [3:0] lineBuffRdData;
    reg [3:0] lineBuffwrData;
    reg [11:0] bigpixelcounter; // will be used for the fsm 
    reg [9:0] wrcounter;
    //reg  [3:0] read;
reg [9:0] pixelcounter ;
parameter FILLPIXELS=1'b0; // yha write hota h line buffers me 
parameter READPIXELS=1'b1;
reg state;
assign pixeldatavalido= rd_line_buffer;
always @(posedge clk) begin 
if (reset) begin 
state <=  FILLPIXELS;
rd_line_buffer<=1'b0;
intr <=1'b0;
end 
else begin 
case(state)  
FILLPIXELS: begin 
intr<=1'b0;
rd_line_buffer<=1'b0;
if (bigpixelcounter>=1920) begin 
 rd_line_buffer <= 1'b1;
state <= READPIXELS;
end 
end
READPIXELS: begin
rd_line_buffer <= 1'b1;
if (pixelcounter==639) begin 
 rd_line_buffer <= 1'b0;
 intr<=1'b1;
state <= FILLPIXELS;
end 
end 
endcase
end
end 

always @(posedge clk) begin 
if (reset) begin 
bigpixelcounter<=0;
end 
else if ((pixeldatavalidi) & (~rd_line_buffer))  
bigpixelcounter<=bigpixelcounter+1;
else if (~(pixeldatavalidi)& rd_line_buffer)
bigpixelcounter<=bigpixelcounter-1; // reading 9 pixels convloves to be for 1 data only thats why -1 and not -9
end 





// ******* read part *********  \\
always @(posedge clk) begin 
if (reset) begin 
pixelcounter <=0;
end
else if(pixelcounter==639) begin 
pixelcounter <=0;
end 
else if (rd_line_buffer) begin 
pixelcounter<=pixelcounter+9'b1;
end 
end

always @(posedge clk) begin 
if (reset) begin 
wrcounter <=0;
end
else if (wrcounter==639) begin 
wrcounter <=0;
end 
else if (pixeldatavalidi) begin 
wrcounter<=wrcounter+9'b1;
end 
end
// this is for the reading  
always @(posedge clk) begin 
if (reset) begin 
counter1 <=0;
end
else if((pixelcounter==639) & rd_line_buffer) begin 
counter1<= counter1+2'b1;
end 
end 
always @(*) begin 
lineBuffRdData = 4'b0000;
case(counter1) 
   0:begin
            lineBuffRdData[0] = rd_line_buffer;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = 1'b0;
        end
       1:begin
            lineBuffRdData[0] = 1'b0;
            lineBuffRdData[1] = rd_line_buffer;
            lineBuffRdData[2] = rd_line_buffer;
            lineBuffRdData[3] = rd_line_buffer;
        end
       2:begin
             lineBuffRdData[0] = rd_line_buffer;
             lineBuffRdData[1] = 1'b0;
             lineBuffRdData[2] = rd_line_buffer;
             lineBuffRdData[3] = rd_line_buffer;
       end  
      3:begin
             lineBuffRdData[0] = rd_line_buffer;
             lineBuffRdData[1] = rd_line_buffer;
             lineBuffRdData[2] = 1'b0;
             lineBuffRdData[3] = rd_line_buffer;
       end        
    endcase
    end 
always @(*) begin 
case(counter1) 
  0:begin
            o_pixel_data = {lb2data,lb1data,lb0data};
        end
        1:begin
            o_pixel_data = {lb3data,lb2data,lb1data};
        end
        2:begin
            o_pixel_data = {lb0data,lb3data,lb2data};
        end
        3:begin
            o_pixel_data = {lb1data,lb0data,lb3data};
        end     
        endcase 
        end   
  // ****** write ******** \\       
 // now we will write for the writing into the line buffers        
 always @(posedge clk) begin 
 
 if( reset) begin 
counter2<=2'b0;
 end 
 else if((wrcounter==639) & pixeldatavalidi) begin 
    counter2<=counter2 +2'b01;
    end 
    end     
        
 always @(*) begin 
 lineBuffwrData = 4'b0000;
        case(counter2) 
        0:begin
            lineBuffwrData[0] = pixeldatavalidi;
            lineBuffwrData[1] = 1'b0;
            lineBuffwrData[2] = 1'b0;
            lineBuffwrData[3] = 1'b0;
        end
       1:begin
            lineBuffwrData[0] = 1'b0;
            lineBuffwrData[1] = pixeldatavalidi;
            lineBuffwrData[2] = 1'b0;
            lineBuffwrData[3] = 1'b0;
        end
       2:begin
             lineBuffwrData[0] = 1'b0;
             lineBuffwrData[1] = 1'b0;
             lineBuffwrData[2] = pixeldatavalidi;
             lineBuffwrData[3] = 1'b0;
       end  
      3:begin
             lineBuffwrData[0] = 1'b0;
             lineBuffwrData[1] = 1'b0;
             lineBuffwrData[2] = 1'b0;
             lineBuffwrData[3] = pixeldatavalidi;
       end        
    endcase
    end 
        
           
linebuffer lb0(
 .clk(clk),
 .reset(reset),
.read(lineBuffRdData[0]),
 .datavalid(lineBuffwrData[0]) ,
.rgbinpixel(pixelidata),
 .rgboutpixel(lb0data)
    );
         linebuffer lb1(
 .clk(clk),
 .reset(reset),
.read(lineBuffRdData[1]), // this is the reading part 
 .datavalid(lineBuffwrData[1]) ,// this is for the writnig part 
.rgbinpixel(pixelidata),
 .rgboutpixel(lb1data)
    );
         linebuffer lb2(
 .clk(clk),
 .reset(reset),
.read(lineBuffRdData[2]),
 .datavalid(lineBuffwrData[2]) ,
.rgbinpixel(pixelidata),
 .rgboutpixel(lb2data)
    );
         linebuffer lb3(
 .clk(clk),
 .reset(reset),
.read(lineBuffRdData[3]),
 .datavalid(lineBuffwrData[3]) ,
.rgbinpixel(pixelidata),
 .rgboutpixel(lb3data)
    );
endmodule