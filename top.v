`timescale 1ns / 1ps
`default_nettype none

module top
    (   input wire i_top_clk,       // 100MHz system clock
        input wire i_top_rst,       // Physical Reset Button
        input wire [6:0] kernel_sel,
        input wire  i_top_cam_start, 
        output wire o_top_cam_done, 
        
        // I/O to camera (OV7670)
        input wire       i_top_pclk, 
        input wire [7:0] i_top_pix_byte,
        input wire       i_top_pix_vsync,
        input wire       i_top_pix_href,
        output wire      o_top_reset,
        output wire      o_top_pwdn,
        output wire      o_top_xclk,
        output wire      o_top_siod,
        output wire      o_top_sioc,
        
        // I/O to VGA 
        output wire [3:0] o_top_vga_red,
        output wire [3:0] o_top_vga_green,
        output wire [3:0] o_top_vga_blue,
        output wire       o_top_vga_vsync,
        output wire       o_top_vga_hsync
    );

    // --- Signal Declarations ---
    wire [11:0] cam_pix_data;
    wire [18:0] cam_pix_addr;
    wire [11:0] bram_out_data;
    wire [18:0] vga_pix_addr;
    
    // Outputs from the 3 processors
   wire [7:0] proc_res_r, proc_res_g, proc_res_b;
    wire       valid_r, valid_g, valid_b;
    
    // VGA Internal Signals
    wire vga_hsync_int, vga_vsync_int, vga_video_active;
    
    // Reset synchronizers
    reg r1_rstn_top_clk,    r2_rstn_top_clk;
    reg r1_rstn_pclk,       r2_rstn_pclk;
    reg r1_rstn_clk25m,     r2_rstn_clk25m; 
        
    wire w_clk25m; 
    
    // --- Clock Generation ---
wire clk_out3; 
      clk_wiz_0 clock_gen
   (
    // Clock out ports
    .clk_vga(w_clk25m),     // output clk_vga
    .xclk(o_top_xclk),
    .clk_out3(clk_out3),      // output xclk
   // Clock in ports
    .clk_in1(i_top_clk)      // input clk_in1
);

    // Debounce the reset button (Assuming Active Low button)
    wire w_rst_btn_db; 
    localparam DELAY_TOP_TB = 240_000; 
    debouncer #( .DELAY(DELAY_TOP_TB) ) top_btn_db (
        .i_clk(i_top_clk),
        .i_btn_in(~i_top_rst), // Invert if your button is active-low
        .o_btn_db(w_rst_btn_db)
    ); 
    
    // --- Synchronization Logic (Active Low Reset) ---
    always @(posedge i_top_clk) begin
        {r2_rstn_top_clk, r1_rstn_top_clk} <= {r1_rstn_top_clk, w_rst_btn_db};
    end 
    always @(posedge w_clk25m) begin
        {r2_rstn_clk25m, r1_rstn_clk25m} <= {r1_rstn_clk25m, w_rst_btn_db};
    end
    always @(posedge i_top_pclk) begin
        {r2_rstn_pclk, r1_rstn_pclk} <= {r1_rstn_pclk, w_rst_btn_db};
    end 
    
    // --- Camera Interface ---
    cam_top #( .CAM_CONFIG_CLK(100_000_000) ) OV7670_cam (
        .i_clk(i_top_clk),
        .i_rstn_clk(r2_rstn_top_clk),
        .i_rstn_pclk(r2_rstn_pclk),
        .i_cam_start(i_top_cam_start),
        .o_cam_done(o_top_cam_done), 
        .i_pclk(i_top_pclk),
        .i_pix_byte(i_top_pix_byte), 
        .i_vsync(i_top_pix_vsync), 
        .i_href(i_top_pix_href),
        .o_reset(o_top_reset),
        .o_pwdn(o_top_pwdn),
        .o_siod(o_top_siod),
        .o_sioc(o_top_sioc), 
        .o_pix_data(cam_pix_data),
        .o_pix_addr(cam_pix_addr)
    );
 
    // --- Frame Buffer (Dual Port BRAM) ---
    mem_bram #(.WIDTH(12), .DEPTH(640*480)) pixel_memory (
        .i_wclk(i_top_pclk),
        .i_wr(1'b1),
        .i_wr_addr(cam_pix_addr),
        .i_bram_data(cam_pix_data),
        .i_bram_en(1'b1),
        .i_rclk(w_clk25m),
        .i_rd(1'b1),
        .i_rd_addr(vga_pix_addr),
        .o_bram_data(bram_out_data)
    );

    // RED CHANNEL
    imgprocon processor_R (
    .kernel_sel(kernel_sel),
        .clk(w_clk25m),
        .dataready(1'b1),
        .reset(~r2_rstn_clk25m), // Convert Active-Low to Active-High for processor
        .imagedata({bram_out_data[11:8], 4'h0}), // 4-bit to 8-bit
        .data_valid(vga_video_active),
        .outputimage(proc_res_r),
        .o_data_valid(valid_r),
        .o_intr()
    );

    // GREEN CHANNEL
   imgprocon processor_G (
   .kernel_sel(kernel_sel),
     .clk(w_clk25m),
       .dataready(1'b1),
       .reset(~r2_rstn_clk25m), // Convert Active-Low to Active-High for processor
       .imagedata({bram_out_data[7:4], 4'h0}), // 4-bit to 8-bit
        .data_valid(vga_video_active),
        .outputimage(proc_res_g),
       .o_data_valid(valid_g),
       .o_intr()
    );

    // BLUE CHANNEL
    imgprocon processor_B (
    .kernel_sel(kernel_sel),
        .clk(w_clk25m),
        .dataready(1'b1),
        .reset(~r2_rstn_clk25m), // Convert Active-Low to Active-High for processor
        .imagedata({bram_out_data[3:0], 4'h0}), // 4-bit to 8-bit
        .data_valid(vga_video_active),
        .outputimage(proc_res_b),
        .o_data_valid(valid_b),
        .o_intr()
    );
   

    // --- VGA Controller ---
    vga_top display_interface (
        .i_clk25m(w_clk25m),
        .i_rstn_clk25m(r2_rstn_clk25m),
        .o_VGA_vsync(vga_vsync_int),
        .o_VGA_hsync(vga_hsync_int),
        .o_VGA_video(vga_video_active), 
        .o_VGA_red(),   
        .o_VGA_green(), 
        .o_VGA_blue(),  
        .i_pix_data(12'b0), 
        .o_pix_addr(vga_pix_addr)
    );
    

     localparam LATENCY_TAP = 1450; 
    reg [1999:0] d_hsync, d_vsync, d_active;
    
    always @(posedge w_clk25m) begin
        if(!r2_rstn_clk25m) begin
            d_hsync  <= 2000'hFFFFFFFF;
            d_vsync  <= 2000'hFFFFFFFF;
            d_active <= 2000'h0;
        end else begin
            d_hsync  <= {d_hsync[1998:0],  vga_hsync_int};
            d_vsync  <= {d_vsync[1998:0],  vga_vsync_int};
            d_active <= {d_active[1998:0], vga_video_active};
        end
    end


    // --- Physical Output Assignments ---
    assign o_top_vga_hsync = d_hsync[LATENCY_TAP];
    assign o_top_vga_vsync = d_vsync[LATENCY_TAP];
    
    // Truncate 8-bit processed results back to 4-bit for VGA DAC
    assign o_top_vga_red   = (d_active[LATENCY_TAP]) ? proc_res_r[7:4] : 4'h0;
    assign o_top_vga_green = (d_active[LATENCY_TAP]) ? proc_res_g[7:4] : 4'h0;
    assign o_top_vga_blue  = (d_active[LATENCY_TAP]) ? proc_res_b[7:4] : 4'h0;
    
    
    
endmodule
