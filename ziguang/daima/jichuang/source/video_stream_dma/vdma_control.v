module vdma_control#(
    parameter                           integer                   VIDEO_ENABLE   = 1,
    parameter                           integer                   ENABLE_WRITE   = 1,
    parameter                           integer                   ENABLE_READ    = 1,

    parameter                           integer                   AXI_DATA_WIDTH = 256,
    parameter                           integer                   AXI_ADDR_WIDTH = 28,

    parameter                           integer                   W_BUFDEPTH     = 2048,
    parameter                           integer                   W_DATAWIDTH    = 32,
    //parameter          [AXI_ADDR_WIDTH -1'b1: 0]W_BASEADDR     = 0         ,
    parameter                           integer                   W_DSIZEBITS    = 22,
    //parameter                           integer                   W_XSIZE        = 960,
    parameter                           integer                   W_XSTRIDE      = 1920,
    //parameter                           integer                   W_YSIZE        = 540,
    parameter                           integer                   W_XDIV         = 2,
    parameter                           integer                   W_BUFSIZE      = 3,

    parameter                           integer                   R_BUFDEPTH     = 2048,
    parameter                           integer                   R_DATAWIDTH    = 32,
    parameter          [AXI_ADDR_WIDTH -1'b1: 0]R_BASEADDR     = 0         ,
    parameter                           integer                   R_DSIZEBITS    = 22,
    parameter                           integer                   R_XSIZE        = 1920,
    parameter                           integer                   R_XSTRIDE      = 1920,
    parameter                           integer                   R_YSIZE        = 1080,
    parameter                           integer                   R_XDIV         = 2,
    parameter                           integer                   R_BUFSIZE      = 3 
)
(
//全局时钟与复位模块
    input              [   9:0]         W_XSIZE                    ,
    input              [   9:0]         W_YSIZE                    ,
    input              [  27:0]         W_BASEADDR                 ,
    input              [   2:0]         cnt_pingyi                 ,
    input  wire                         ui_clk                     ,
    input  wire                         ui_rstn                    ,
    input  wire                         key                        ,
//用户写入视频信号模块
    input  wire                         W_wclk_i                   ,
    input  wire                         W_FS_i                     ,
    input  wire                         W_wren_i                   ,
    input  wire        [W_DATAWIDTH-1'b1 : 0]W_data_i                   ,
    output reg         [   7:0]         W_sync_cnt_o               ,
    input  wire        [   7:0]         W_buf_i                    ,
    output wire                         W_full                     ,
//vsdma写数据相关信号控制模块       
    output wire        [AXI_ADDR_WIDTH-1'b1: 0]vsdma_waddr                ,
    output wire                         vsdma_wareq                ,
    output wire        [  15:0]         vsdma_wsize                ,
    input  wire                         vsdma_wbusy                ,
    output wire        [AXI_DATA_WIDTH-1'b1:0]vsdma_wdata                ,
    input  wire                         vsdma_wvalid               ,
    output wire                         vsdma_wready               ,
 //用户读出视频信号模块
    input  wire                         R_rclk_i                   ,
    input  wire                         R_FS_i                     ,
    input  wire                         R_rden_i                   ,
    output wire        [R_DATAWIDTH-1'b1 : 0]R_data_o                   ,
    output reg         [   7:0]         R_sync_cnt_o =0            ,
    input  wire        [   7:0]         R_buf_i                    ,
    output wire                         R_empty                    ,
//vsdma读数据相关信号控制模块
    output wire        [AXI_ADDR_WIDTH-1'b1: 0]vsdma_raddr                ,
    output wire                         vsdma_rareq                ,
    output wire        [  15:0]         vsdma_rsize                ,
    input  wire                         vsdma_rbusy                ,
    input  wire        [AXI_DATA_WIDTH-1'b1:0]vsdma_rdata                ,
    input  wire                         vsdma_rvalid               ,
    output wire                         vsdma_rready                
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

//localparam                              WY_BURST_TIMES       = (W_YSIZE*W_XDIV);
//localparam                              VSDMA_WX_BURST       = (W_XSIZE*W_DATAWIDTH/AXI_DATA_WIDTH)/W_XDIV;
//localparam                              WX_BURST_ADDR_INC    = (W_XSIZE*(W_DATAWIDTH/32))/W_XDIV;
//localparam                              WX_LAST_ADDR_INC     = (W_XSTRIDE-W_XSIZE)*(W_DATAWIDTH/32) + WX_BURST_ADDR_INC;

wire                 [11:0]                   WY_BURST_TIMES    ;
wire                 [11:0]                   VSDMA_WX_BURST    ;
wire                 [11:0]                   WX_BURST_ADDR_INC ;
wire                 [11:0]                   WX_LAST_ADDR_INC  ;

assign                                  WY_BURST_TIMES       = (W_YSIZE*W_XDIV);
assign                                  VSDMA_WX_BURST       = (W_XSIZE*W_DATAWIDTH/AXI_DATA_WIDTH)/W_XDIV;
assign                                  WX_BURST_ADDR_INC    = (W_XSIZE*(W_DATAWIDTH/32))/W_XDIV;
assign                                  WX_LAST_ADDR_INC     = (W_XSTRIDE-W_XSIZE)*(W_DATAWIDTH/32) + WX_BURST_ADDR_INC;


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
assign vsdma_waddr = W_BASEADDR + {vsdma_wbufn,W_addr};
assign vsdma_wareq = vsdma_wareq_r;

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
         if(W_FS) begin                                             //for video is vs ; for other data is reset
           W_MS <= S_RST;
           if(W_sync_cnt_o < WYBUF_SIZE) W_sync_cnt_o <= W_sync_cnt_o + 1'b1;
           else W_sync_cnt_o <= 0;
         end
       end
       S_RST:begin                                                  //fifo reset must do it
          vsdma_wbufn <= W_buf_i;
          wrst_cnt <= wrst_cnt + 1'b1;
          if((VIDEO_ENABLE == 1) && (wrst_cnt < 15)) W_FIFO_Rst <= 1;
          else if((VIDEO_ENABLE == 1) && (wrst_cnt == 15)) W_FIFO_Rst <= 0;
          else W_MS <= S_DATA1;
       end
       S_DATA1:begin
         if(vsdma_wbusy == 1'b0 && W_REQ ) vsdma_wareq_r  <= 1'b1;
         else if(vsdma_wbusy == 1'b1) begin
            vsdma_wareq_r  <= 1'b0;
            W_MS    <= S_DATA2;
         end
       end
       S_DATA2:begin
           if(vsdma_wbusy == 1'b0) begin                            //1 burst ok=1/2 line ok
               if(W_bcnt == WY_BURST_TIMES - 1'b1) W_MS <= S_IDLE;  //1 frame burst ok
               else begin
                   W_bcnt <= W_bcnt + 1'b1;
                   W_MS    <= S_DATA1;
                   if(wdiv_cnt < W_XDIV - 1'b1)begin
                       W_addr <= W_addr +  WX_BURST_ADDR_INC;
                       wdiv_cnt <= wdiv_cnt + 1'b1;
                   end
                   else begin                                       //1 line burst ok
                       W_addr <= W_addr + WX_LAST_ADDR_INC;
                       wdiv_cnt <= 0;
                   end
               end
           end
       end
        default: W_MS <= S_IDLE;
      endcase
   end
end

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
assign vsdma_raddr = R_BASEADDR + {vsdma_rbufn,R_addr} + 259200*cnt_pingyi;
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
        begin
            if(key==0)
            R_addr       <= 22'd0;
            else
            R_addr       <= 22'd2073600;
        end
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
            begin
                if(key==0)
                R_addr       <= 22'd0;
                else
                R_addr       <= 22'd2073600;
            end
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
                    begin
                        if(key==0)
                            if(rdiv_cnt < R_XDIV - 1'b1)begin
                                R_addr <= R_addr +  RX_BURST_ADDR_INC;
                                rdiv_cnt <= rdiv_cnt + 1'b1;
                            end
                            else begin
                                R_addr <= R_addr + RX_LAST_ADDR_INC;
                                rdiv_cnt <= 0;
                            end
                        else 
                            if(rdiv_cnt < R_XDIV - 1'b1)begin
                                R_addr <= R_addr -  RX_BURST_ADDR_INC;
                                rdiv_cnt <= rdiv_cnt + 1'b1;
                            end
                            else begin
                                R_addr <= R_addr - RX_LAST_ADDR_INC;
                                rdiv_cnt <= 0;
                            end
                        end
                end
            end
         end
         default:R_MS <= S_IDLE;
      endcase
   end
end

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