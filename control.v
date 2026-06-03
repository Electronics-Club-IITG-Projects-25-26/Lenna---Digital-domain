`timescale 1ns / 1ps


module control(
    input wire [7:0] in_pixel,
    input wire rst, clk, inp_valid,
    output wire out_valid,
    output reg [71:0] out_pixel,
    output reg intr
    );
reg [9:0] pixcount;
reg [9:0] rdcount;
reg [3:0] read;
reg readvalid, readstate;
wire [23:0] out1,out2,out3,out4;

always @ (posedge clk)begin
    if(rst)begin
        pixcount<=0;
    end 
    else if(inp_valid)begin
        if (pixcount == 639)
            pixcount <= 0;
        else
            pixcount <= pixcount + 1;
    end
end

reg [1:0] buff_sel;
reg [1:0] read_buff_sel;    
always @ (posedge clk)begin
    if (rst) begin
        buff_sel<=0;
    end else if (pixcount==639 && inp_valid)begin
        buff_sel<=buff_sel+1;
    end
end

always @ (posedge clk)begin
    if(rst)begin
        rdcount<=0;
    end else if (readvalid) begin
        if (rdcount == 639)
            rdcount <= 0;
        else
            rdcount <= rdcount + 1;
    end
end

always @ (posedge clk)begin
    if(rst)begin
        read_buff_sel<=0;
    end else if (rdcount==639 && readvalid) begin
        read_buff_sel<=read_buff_sel+1;
    end
end
reg [12:0] totalpixcount;
always @ (posedge clk)begin
    if(rst)begin
        totalpixcount<=0;
    end 
    else if(inp_valid && !readvalid)begin
        totalpixcount<=totalpixcount+1;
    end else if (!inp_valid && readvalid)begin
        totalpixcount<=totalpixcount-1;
    end
end

always @ (posedge clk)begin
    if(rst)begin
        readstate<=0;
        readvalid<=0;
        intr<=0;
    end else begin
        case (readstate)
            0:begin
                intr<=0;
                if(totalpixcount>=1920)begin
                    readvalid<=1;
                    readstate<=1;
                end
            end
            1:begin
                if(rdcount==639)begin
                    readstate<=0;
                    readvalid<=0;
                    intr<=1;
                end
            end
        endcase
    end
end

wire valid1,valid2,valid3,valid4;
assign valid1 = inp_valid && (buff_sel==0);
assign valid2 = inp_valid && (buff_sel==1);
assign valid3 = inp_valid && (buff_sel==2);
assign valid4 = inp_valid && (buff_sel==3);

always @ (*)begin
    case (read_buff_sel)
        0:out_pixel={out3,out2,out1};
        1:out_pixel={out4,out3,out2};
        2:out_pixel={out1,out4,out3};
        3:out_pixel={out2,out1,out4};
    endcase
end 

always @ (*)begin
    case (read_buff_sel)
        0:read={1'b0,readvalid,readvalid,readvalid};
        1:read={readvalid,readvalid,readvalid,1'b0};
        2:read={readvalid,readvalid,1'b0,readvalid};
        3:read={readvalid,1'b0,readvalid,readvalid}; 
    endcase
end

line_buffers l1(
    .in(in_pixel),
    .clk(clk), 
    .rst(rst), 
    .valid(valid1),
    .out(out1),
    .read(read[0])
);
line_buffers l2(
    .in(in_pixel),
    .clk(clk), 
    .rst(rst), 
    .valid(valid2),
    .out(out2),
    .read(read[1])
);
line_buffers l3(
    .in(in_pixel),
    .clk(clk), 
    .rst(rst), 
    .valid(valid3),
    .out(out3),
    .read(read[2])
);
line_buffers l4(
    .in(in_pixel),
    .clk(clk), 
    .rst(rst), 
    .valid(valid4),
    .out(out4),
    .read(read[3])
);

assign out_valid=readvalid;
endmodule
