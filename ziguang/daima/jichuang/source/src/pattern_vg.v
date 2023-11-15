`define UD #1
module pattern_vg # (
    parameter                            COCLOR_DEPP=8, // number of bits per channel
    parameter                            X_BITS=13,
    parameter                            Y_BITS=13,
    parameter                            H_ACT = 12'd1280,
    parameter                            V_ACT = 12'd720
  )(
    input                                rstn,
    input                                pix_clk,
    input                                udp_clk,
    input            [9:0]               W_XSIZE,
    input            [9:0]               W_YSIZE,
    input [X_BITS-1:0]                   act_x,
    input [X_BITS-1:0]                   act_y,
    input                                vs_in,
    input                                hs_in,
    input                                de_in,
    input [23:0] rd_pix_data,
    output reg                           vs_out,
    output reg                           hs_out,
    output reg                           de_out,
    output wire [COCLOR_DEPP-1:0]         r_out,
    output wire [COCLOR_DEPP-1:0]         g_out,
    output wire [COCLOR_DEPP-1:0]         b_out,
    input                                 rec_en,
    input  [31:0]                         rec_data
  );
  reg [23:0]pix_data;
  assign r_out=pix_data[23:16];
  assign g_out=pix_data[15:8];
  assign b_out=pix_data[7:0];
  //参数定义
  parameter   CHAR_B_H = 13'd1575 ,//字符开始横坐标
              CHAR_B_V = 13'd50 ;//字符开始纵坐标

  parameter   CHAR_W   = 13'd256 ,//字符宽度
              CHAR_H   = 13'd64  ;//字符深度

  //颜色参数  RGB565格式
  parameter   BLACK    = 24'h0,//黑色（背景色）
              PURPLR   = 24'hff00ff,
              WHITE   = 24'hffffff;//金色（字符颜色）

  //信号定义
  wire    [9:0]    char_x    ;//字符横坐标
  wire    [7:0]    char_y    ;//字符纵坐标


  //char_x
  assign char_x = (((act_x >= CHAR_B_H)&&(act_x < (CHAR_B_H + CHAR_W)))
                   &&((act_y >= CHAR_B_V)&&(act_y < (CHAR_B_V + CHAR_H))))
         ? (13'd255-(act_x - CHAR_B_H)) : 13'd0;
  //char_yh3
  assign char_y = (((act_x >= CHAR_B_H)&&(act_x < (CHAR_B_H + CHAR_W)))
                   &&((act_y >= CHAR_B_V)&&(act_y < (CHAR_B_V + CHAR_H))))
         ? (act_y - CHAR_B_V) : 8'd0;



  reg [10:0] wr_addr ;
  wire [255:0]rd_data;

  always@(posedge udp_clk or negedge rstn)
  begin
    if(~rstn)
      wr_addr <= 11'd0;
    else if (rec_en==1)
      wr_addr <= wr_addr + 11'd1;
  end
  wire [255:0] char_data;

  ram_32to256 u0 (
                .wr_data(rec_data),  // input [31:0]
                .wr_addr(wr_addr),   // input [10:0]
                .wr_en(rec_en),      // input
                .wr_clk(udp_clk),    // input
                .wr_rst(~rstn),      // input
                .rd_addr(char_y),    // input [7:0]
                .rd_data(rd_data),   // output [255:0]]
                .rd_clk(pix_clk),    // input
                .rd_rst(~rstn)       // input
              );

  assign char_data = {rd_data[31:0],rd_data[63:32],rd_data[95:64],rd_data[127:96],rd_data[159:128],rd_data[191:160],rd_data[223:192],rd_data[255:224]};
  //pix_data  &&(char_data[char_x] == 1'b1)
  always @(posedge pix_clk )
  begin
    if(((act_x >= CHAR_B_H-1)&&(act_x < (CHAR_B_H + CHAR_W-1)))
        &&(char_data[char_x] == 1'b1))
    begin
      if ((act_y >= CHAR_B_V)&&(act_y < (CHAR_B_V + 13'd33)))
      begin
        pix_data <= PURPLR;
      end
      else if ((act_y >= CHAR_B_V + 13'd33)&&(act_y < (CHAR_B_V + CHAR_H)))
      begin
        pix_data <= WHITE;
      end
    end
    else if(act_y <= 2*W_YSIZE && act_x <= 2*W_XSIZE)
    begin
      pix_data <= rd_pix_data;
    end
    else
      pix_data  <= 'd0;
  end



  always @(posedge pix_clk)
  begin
    vs_out <= `UD vs_in;
    hs_out <= `UD hs_in;
    de_out <= `UD de_in;
  end


endmodule
