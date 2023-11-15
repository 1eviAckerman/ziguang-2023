//****************************************Copyright (c)***********************************//
//
// File name            : vsdma_control.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/25
// Created date         : 2023/05/19  
// Descriptions         : vsdma控制模块，用于控制其读写       
//
//****************************************************************************************//

module vsdma_control#(
    parameter                           integer                   VIDEO_ENABLE   = 1,
    parameter                           integer                   ENABLE_WRITE   = 1,//使能写通道
    parameter                           integer                   ENABLE_READ    = 1,//使能读通道

    parameter                           integer                   AXI_DATA_WIDTH = 256,//AXI总线数据宽度
    parameter                           integer                   AXI_ADDR_WIDTH = 28,//AXI总线地址宽度

    parameter                           integer                   W_BUFDEPTH     = 2048,//写通道设置FIFO大小
    parameter                           integer                   W_DATAWIDTH    = 32,//输入图像数位宽
    parameter          [AXI_ADDR_WIDTH -1'b1: 0]                  W_BASEADDR     = 0,//写通道内存起始地址
    parameter                           integer                   W_DSIZEBITS    = 22,//写通道缓存数据增量地址大小
    parameter                           integer                   W_XSIZE        = 960,//写通道水平方向有效数据大小，代表每次vsdma传输数据量
    parameter                           integer                   W_XSTRIDE      = 1920,//写通道水平方向实际数据大小
    parameter                           integer                   W_YSIZE        = 540,//写通道垂直行数大小
    parameter                           integer                   W_XDIV         = 2,//对写通道水平方向拆分为XDIV次传输，减少FIFO缓存大小
    parameter                           integer                   W_BUFSIZE      = 3,//写通道帧缓存大小

    parameter                           integer                   R_BUFDEPTH     = 2048,//读通道设置FIFO大小
    parameter                           integer                   R_DATAWIDTH    = 32,//输出图像数位宽
    parameter          [AXI_ADDR_WIDTH -1'b1: 0]                  R_BASEADDR     = 0,//读通道内存起始地址
    parameter                           integer                   R_DSIZEBITS    = 22,//读通道缓存数据增量地址大小
    parameter                           integer                   R_XSIZE        = 1920,//读通道水平方向有效数据大小，代表每次vsdma传输数据量
    parameter                           integer                   R_XSTRIDE      = 1920,//读通道水平方向实际数据大小
    parameter                           integer                   R_YSIZE        = 1080,//读通道垂直行数大小
    parameter                           integer                   R_XDIV         = 2,//对读通道水平方向拆分为XDIV次传输，减少FIFO缓存大小
    parameter                           integer                   R_BUFSIZE      = 3 //写通道帧缓存大小
)
(
//全局时钟与复位模块
    input  wire                         ui_clk                     ,
    input  wire                         ui_rstn                    ,
//用户写入视频信号模块
    input  wire                         W_wclk_i                   ,//写像素时钟输入
    input  wire                         W_FS_i                     ,//写帧同步信号输入
    input  wire                         W_wren_i                   ,//写数据有效信号
    input  wire        [W_DATAWIDTH-1'b1 : 0]W_data_i              ,//写有效数据
    output reg         [   7:0]         W_sync_cnt_o =0            ,//写通道帧同步输出
    input  wire        [   7:0]         W_buf_i                    ,//写通道帧同步输入
    output wire                         W_full                     ,
//vsdma写数据相关信号控制模块       
    output wire        [AXI_ADDR_WIDTH-1'b1: 0]vsdma_waddr         ,//vsdma写通道地址
    output wire                         vsdma_wareq                ,//vsdma写通道请求
    output wire        [  15:0]         vsdma_wsize                ,//vsdma一次写传输大小
    input  wire                         vsdma_wbusy                ,//vsdma写传输忙
    output wire        [AXI_DATA_WIDTH-1'b1:0]vsdma_wdata          ,//vsdma写数据
    input  wire                         vsdma_wvalid               ,//vsdma写有效
    output wire                         vsdma_wready               ,//vsdma写就绪
 //用户读出视频信号模块
    input  wire                         R_rclk_i                   ,//读像素时钟输入
    input  wire                         R_FS_i                     ,//读帧同步信号输入
    input  wire                         R_rden_i                   ,//读数据有效信号
    output wire        [R_DATAWIDTH-1'b1 : 0]R_data_o              ,//读有效数据
    output reg         [   7:0]         R_sync_cnt_o =0            ,//读通道帧同步输出
    input  wire        [   7:0]         R_buf_i                    ,//读通道帧同步输入
    output wire                         R_empty                    ,
//vsdma读数据相关信号控制模块
    output wire        [AXI_ADDR_WIDTH-1'b1: 0]vsdma_raddr         ,//vsdma读通道地址
    output wire                         vsdma_rareq                ,//vsdma读通道请求
    output wire        [  15:0]         vsdma_rsize                ,//vsdma一次读传输大小
    input  wire                         vsdma_rbusy                ,//vsdma读传输忙
    input  wire        [AXI_DATA_WIDTH-1'b1:0]vsdma_rdata          ,//vsdma读数据
    input  wire                         vsdma_rvalid               ,//vsdma读有效
    output wire                         vsdma_rready                //vsdma读就绪
);

//实现log2函数
function integer clog2;
    input                               integer value              ;
  begin
    value = value-1;
    for (clog2=0; value>0; clog2=clog2+1)
      value = value>>1;
    end
  endfunction
  
localparam                              S_IDLE  =  2'd0            ;
localparam                              S_RST   =  2'd1            ;
localparam                              S_DATA1 =  2'd2            ;
localparam                              S_DATA2 =  2'd3            ;

generate  if(ENABLE_WRITE == 1)begin : VSDMA_WRITE_ENABLE

localparam                              WFIFO_DEPTH = W_BUFDEPTH   ;
localparam                              W_WR_DATA_COUNT_WIDTH = clog2(WFIFO_DEPTH)+1;
localparam                              W_RD_DATA_COUNT_WIDTH = clog2(WFIFO_DEPTH*W_DATAWIDTH/AXI_DATA_WIDTH)+1;

localparam                              WYBUF_SIZE           = (W_BUFSIZE - 1'b1);
localparam                              WY_BURST_TIMES       = (W_YSIZE*W_XDIV);//写通道需要完成的vsdma突发次数
localparam                              VSDMA_WX_BURST       = (W_XSIZE*W_DATAWIDTH/AXI_DATA_WIDTH)/W_XDIV;//一次vsdma突发长度大小
localparam                              WX_BURST_ADDR_INC    = (W_XSIZE*(W_DATAWIDTH/32))/W_XDIV;//vsdma每次突发后的地址增加量
localparam                              WX_LAST_ADDR_INC     = (W_XSTRIDE-W_XSIZE)*(W_DATAWIDTH/32) + WX_BURST_ADDR_INC;//最后一次地址增加值

//wire define
wire                                    W_FS                       ;
wire                   [W_RD_DATA_COUNT_WIDTH-1'b1 :0]W_rcnt                     ;

//reg define
reg                                     pre_read_cnt,pre_read_cnt_d;
reg                                     pre_read                   ;
reg                                     W_FIFO_Rst =0              ;
reg                    [   1:0]         W_MS = 0                   ;
reg                    [   1:0]         W_MS_r = 0                 ;
reg                    [W_DSIZEBITS-1'b1:0]W_addr= 0                  ;
reg                    [  15:0]         W_bcnt = 0                 ;
reg                    [   3:0]         wdiv_cnt = 0               ;
reg                    [   7:0]         wrst_cnt = 0               ;
reg                    [   7:0]         vsdma_wbufn                ;
reg                                     vsdma_wareq_r = 1'b0       ;
reg                                     W_REQ = 0                  ;

assign vsdma_wready = 1'b1;
assign vsdma_wsize = VSDMA_WX_BURST;
assign vsdma_waddr = W_BASEADDR + {vsdma_wbufn,W_addr};//利用高位地址切换实现帧缓存设置
assign vsdma_wareq = vsdma_wareq_r;

//对帧同步信号进行捕捉
fs_cap #
(
    .VIDEO_ENABLE                      (VIDEO_ENABLE              ) 
)
fs_cap_W0
(
    .clk_i                             (ui_clk                    ),
    .rstn_i                            (ui_rstn                   ),
    .vs_i                              (W_FS_i                    ),
    .fs_cap_o                          (W_FS                      ) 
);

//实现FIFO预读数据的功能，实现数据和有效信号的对齐
always@(posedge ui_clk) begin
    if(W_FS)
        pre_read_cnt <= 1'b0;
    else if(vsdma_wareq && vsdma_wbusy)
        pre_read_cnt <= pre_read_cnt + 1'b1;
    else
        pre_read_cnt <= pre_read_cnt;
end
always@(posedge ui_clk) begin
    pre_read_cnt_d <= pre_read_cnt;
end
always@(posedge ui_clk) begin
    if(W_FS)
        pre_read <= 1'b0;
    else if(~pre_read_cnt_d && pre_read_cnt)
        pre_read <= 1'b1;
    else
        pre_read <= 1'b0;
end

always @(posedge ui_clk)
    W_MS_r <= W_MS;
  
always @(posedge ui_clk) begin
    if(!ui_rstn)begin
       W_MS         <= S_IDLE;
       W_FIFO_Rst   <= 0     ;
       W_addr       <= 0     ;
       W_sync_cnt_o <= 0     ;
       W_bcnt       <= 0     ;
       wrst_cnt     <= 0     ;
       wdiv_cnt     <= 0     ;
       vsdma_wbufn   <= 0     ;
       vsdma_wareq_r <= 1'd0  ;
   end
   else begin
     case(W_MS)
       S_IDLE:begin
         W_addr <= 0;
         W_bcnt <= 0;
         wrst_cnt <= 0;
         wdiv_cnt <=0;
         if(W_FS) begin
           W_MS <= S_RST;
           if(W_sync_cnt_o < WYBUF_SIZE) W_sync_cnt_o <= W_sync_cnt_o + 1'b1;
           else W_sync_cnt_o <= 0;
         end
       end
       S_RST:begin                                                  //切换缓存地址，复位数据FIFO
          vsdma_wbufn <= W_buf_i;
          wrst_cnt <= wrst_cnt + 1'b1;
          if((VIDEO_ENABLE == 1) && (wrst_cnt < 15)) W_FIFO_Rst <= 1;
          else if((VIDEO_ENABLE == 1) && (wrst_cnt == 15)) W_FIFO_Rst <= 0;
          else W_MS <= S_DATA1;
       end
       S_DATA1:begin //发送vsdma写请求
         if(vsdma_wbusy == 1'b0 && W_REQ ) vsdma_wareq_r  <= 1'b1;
         else if(vsdma_wbusy == 1'b1) begin
            vsdma_wareq_r  <= 1'b0;
            W_MS    <= S_DATA2;
         end
       end
       S_DATA2:begin //开始vsdma写数据
           if(vsdma_wbusy == 1'b0) begin                            
               if(W_bcnt == WY_BURST_TIMES - 1'b1) W_MS <= S_IDLE;  //判断传输是否完毕
               else begin
                   W_bcnt <= W_bcnt + 1'b1;
                   W_MS    <= S_DATA1;
                   if(wdiv_cnt < W_XDIV - 1'b1)begin //对XSIZE做了分次传输后，一个XSIZE需要XDIV次vsdma传输
                       W_addr <= W_addr +  WX_BURST_ADDR_INC;
                       wdiv_cnt <= wdiv_cnt + 1'b1;
                   end
                   else begin                                       
                       W_addr <= W_addr + WX_LAST_ADDR_INC;//计算最后一次地址增量
                       wdiv_cnt <= 0;
                   end
               end
           end
       end
        default: W_MS <= S_IDLE;
      endcase
   end
end

//写通道数据FIFO，当FIFO存储数据量达到一定量，一般满足一次FDMA突发传输数据量
always@(posedge ui_clk) W_REQ  <= (W_rcnt > VSDMA_WX_BURST - 2)&&((ui_rstn == 1'b1) || (W_FIFO_Rst == 1'b0));

fifoin u_fifoin (
    .wr_clk                            (W_wclk_i                  ),// input         
    .wr_rst                            ((ui_rstn == 1'b0) || (W_FIFO_Rst == 1'b1)),// input         
    .wr_en                             (W_wren_i                  ),// input         
    .wr_data                           (W_data_i                  ),// input [31:0]  
    .wr_full                           (W_full                    ),// output        
    .wr_water_level                    (                          ),// output [12:0] 
    .almost_full                       (                          ),// output        
    .rd_clk                            (ui_clk                    ),// input         
    .rd_rst                            ((ui_rstn == 1'b0) || (W_FIFO_Rst == 1'b1)),// input         
    .rd_en                             (vsdma_wvalid||pre_read    ),// input         
    .rd_data                           (vsdma_wdata               ),// output [256:0]
    .rd_empty                          (                          ),// output        
    .rd_water_level                    (W_rcnt                    ),// output [9:0] 
    .almost_empty                      (                          ) // output        
);

end
else begin : VSDMA_WRITE_DISABLE

assign vsdma_waddr = 0;
assign vsdma_wareq = 0;
assign vsdma_wsize = 0;
assign vsdma_wdata = 0;
assign vsdma_wready = 0;
assign vsdma_wirq = 0;
assign W_full = 0;

end
endgenerate


generate  if(ENABLE_READ == 1)begin : VSDMA_READ_ENABLE

localparam                              RFIFO_DEPTH = R_BUFDEPTH*R_DATAWIDTH/AXI_DATA_WIDTH;
localparam                              R_WR_DATA_COUNT_WIDTH = clog2(RFIFO_DEPTH)+1;
localparam                              R_RD_DATA_COUNT_WIDTH = clog2(R_BUFDEPTH)+1;

localparam                              RYBUF_SIZE           = (R_BUFSIZE - 1'b1);
localparam                              RY_BURST_TIMES       = (R_YSIZE*R_XDIV);
localparam                              VSDMA_RX_BURST       = (R_XSIZE*R_DATAWIDTH/AXI_DATA_WIDTH)/R_XDIV;
localparam                              RX_BURST_ADDR_INC    = (R_XSIZE*(R_DATAWIDTH/32))/R_XDIV;
localparam                              RX_LAST_ADDR_INC     = (R_XSTRIDE-R_XSIZE)*(R_DATAWIDTH/32) + RX_BURST_ADDR_INC;

//wire define
wire                                    R_FS                       ;
wire                   [R_WR_DATA_COUNT_WIDTH-1'b1 :0]R_wcnt                     ;

//reg define;
reg                                     R_FIFO_Rst=0               ;
reg                    [   1:0]         R_MS=0                     ;
reg                    [   1:0]         R_MS_r =0                  ;
reg                    [R_DSIZEBITS-1'b1:0]R_addr=0                   ;
reg                    [  15:0]         R_bcnt=0                   ;
reg                    [   3:0]         rdiv_cnt =0                ;
reg                    [   7:0]         rrst_cnt =0                ;
reg                    [   7:0]         vsdma_rbufn                ;
reg                                     vsdma_rareq_r= 1'b0        ;
reg                                     R_REQ=0                    ;

assign vsdma_rready = 1'b1;
assign vsdma_rsize = VSDMA_RX_BURST;
assign vsdma_raddr = R_BASEADDR + {vsdma_rbufn,R_addr};
assign vsdma_rareq = vsdma_rareq_r;

fs_cap #
(
    .VIDEO_ENABLE                      (VIDEO_ENABLE              ) 
)
fs_cap_R0
(
    .clk_i                             (ui_clk                    ),
    .rstn_i                            (ui_rstn                   ),
    .vs_i                              (R_FS_i                    ),
    .fs_cap_o                          (R_FS                      ) 
);

always @(posedge ui_clk)
    R_MS_r <= R_MS;

 always @(posedge ui_clk) begin
   if(!ui_rstn)begin
        R_MS          <= S_IDLE;
        R_FIFO_Rst   <= 0;
        R_addr       <= 0;
        R_sync_cnt_o <= 0;
        R_bcnt       <= 0;
        rrst_cnt     <= 0;
        rdiv_cnt      <= 0;
        vsdma_rbufn    <= 0;
        vsdma_rareq_r  <= 1'd0;
    end
    else begin
      case(R_MS)
        S_IDLE:begin
          R_addr <= 0;
          R_bcnt <= 0;
          rrst_cnt <= 0;
          rdiv_cnt <=0;
          if(R_FS) begin
            R_MS <= S_RST;
            if(R_sync_cnt_o < RYBUF_SIZE) R_sync_cnt_o <= R_sync_cnt_o + 1'b1;
            else R_sync_cnt_o <= 0;
          end
       end
       S_RST:begin
           vsdma_rbufn <= R_buf_i;
           rrst_cnt <= rrst_cnt + 1'b1;
           if((VIDEO_ENABLE == 1) && (rrst_cnt < 15)) R_FIFO_Rst <= 1;
           else if((VIDEO_ENABLE == 1) && (rrst_cnt == 15)) R_FIFO_Rst <= 0;
           else R_MS <= S_DATA1;
       end
       S_DATA1:begin
         if(vsdma_rbusy == 1'b0 && R_REQ) vsdma_rareq_r  <= 1'b1;
         else if(vsdma_rbusy == 1'b1) begin
            vsdma_rareq_r  <= 1'b0;
            R_MS    <= S_DATA2;
         end
        end
        S_DATA2:begin
            if(vsdma_rbusy == 1'b0)begin
                if(R_bcnt == RY_BURST_TIMES - 1'b1) R_MS <= S_IDLE;
                else begin
                    R_bcnt <= R_bcnt + 1'b1;
                    R_MS    <= S_DATA1;
                    if(rdiv_cnt < R_XDIV - 1'b1)begin
                        R_addr <= R_addr +  RX_BURST_ADDR_INC;
                        rdiv_cnt <= rdiv_cnt + 1'b1;
                     end
                    else begin
                        R_addr <= R_addr + RX_LAST_ADDR_INC;
                        rdiv_cnt <= 0;
                    end

                end
            end
         end
         default:R_MS <= S_IDLE;
      endcase
   end
end

//读数据通道FIFO，当FIFO储存数据量小于一次突发传输数据量时，则进行传输
always@(posedge ui_clk) R_REQ  <= (R_wcnt < VSDMA_RX_BURST - 2)&&((ui_rstn == 1'b1) || (R_FIFO_Rst == 1'b0));

fifoout u_fifoout (
    .wr_clk                            (ui_clk                    ),// input
    .wr_rst                            ((ui_rstn == 1'b0) || (R_FIFO_Rst == 1'b1)),// input
    .wr_en                             (vsdma_rvalid              ),// input
    .wr_data                           (vsdma_rdata               ),// input [256:0]
    .wr_full                           (                          ),// output
    .wr_water_level                    (R_wcnt                    ),// output [9:0]
    .almost_full                       (                          ),// output
    .rd_clk                            (R_rclk_i                  ),// input
    .rd_rst                            ((ui_rstn == 1'b0) || (R_FIFO_Rst == 1'b1)),// input
    .rd_en                             (R_rden_i                  ),// input
    .rd_data                           (R_data_o                  ),// output [31:0]
    .rd_empty                          (R_empty                   ),// output
    .rd_water_level                    (                          ),// output [12:0]
    .almost_empty                      (                          ) // output
);

end
else begin : VSDMA_READ_DISABLE
   
assign vsdma_raddr = 0;
assign vsdma_rareq = 0;
assign vsdma_rsize = 0;
assign vsdma_rdata = 0;
assign vsdma_rready = 0;
assign vsdma_rirq = 0;
assign R_empty = 1'b0;
assign R_data_o =0;
end
endgenerate

endmodule