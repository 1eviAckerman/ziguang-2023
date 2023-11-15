module VDMA#(
    parameter                           integer                   VIDEO_ENABLE   = 1,
    parameter                           integer                   ENABLE_WRITE   = 1,
    parameter                           integer                   ENABLE_READ    = 1,

    parameter                           integer                   AXI_DATA_WIDTH = 256,
    parameter                           integer                   AXI_ADDR_WIDTH = 28,

    parameter                           integer                   W_BUFDEPTH     = 2048,
    parameter                           integer                   W_DATAWIDTH    = 32,
    //parameter          [AXI_ADDR_WIDTH -1'b1: 0]W_BASEADDR     = 0         ,
    parameter                           integer                   W_DSIZEBITS    = 22,
   // parameter                           integer                   W_XSIZE        = 960,
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
    parameter                           integer                   R_BUFSIZE      = 3,
    parameter                           integer         M_AXI_ID_WIDTH			    = 4,
    parameter                           integer         M_AXI_ID			        = 0,
    parameter                           integer         M_AXI_ADDR_WIDTH			= 28,
    parameter                           integer         M_AXI_DATA_WIDTH			= 256,
    parameter                           integer		  	M_AXI_MAX_BURST_LEN       	= 16 
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
    output wire        [   7:0]         W_sync_cnt_o               ,
    input  wire        [   7:0]         W_buf_i                    ,
    output wire                         W_full                     ,
 //用户读出视频信号模块
    input  wire                         R_rclk_i                   ,
    input  wire                         R_FS_i                     ,
    input  wire                         R_rden_i                   ,
    output wire        [R_DATAWIDTH-1'b1 : 0]R_data_o                   ,
    output wire        [   7:0]         R_sync_cnt_o               ,
    input  wire        [   7:0]         R_buf_i                    ,
    output wire                         R_empty                    ,
    
    output wire                         axi_wstart_locked          ,
		
    input  wire                         		M_AXI_ACLK                 ,
    input  wire                         		M_AXI_ARESETN              ,
    output wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID                 ,
    output wire        [M_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR               ,
    output wire        [   7:0]        			M_AXI_AWLEN                ,
    output wire                        			M_AXI_AWVALID              ,
    input  wire                         		M_AXI_AWREADY              ,
    output wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_WID                  ,
    output wire        [M_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA                ,
    output wire        [M_AXI_DATA_WIDTH/8-1 : 0]M_AXI_WSTRB               ,
    output wire                         		M_AXI_WLAST                ,
    output wire                         		M_AXI_WVALID               ,
    input  wire                        			M_AXI_WREADY               ,
 
    output wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID                 ,
    output wire        [M_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR               ,
    output wire        [   7:0]         		M_AXI_ARLEN                ,
    output wire                         		M_AXI_ARVALID              ,
    input  wire                         		M_AXI_ARREADY              ,
	 
    input  wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_RID                  ,
    input  wire        [M_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA                ,
    output wire                         		M_AXI_RLAST                ,
    input  wire                         		M_AXI_RVALID               ,
    output wire                         		M_AXI_RREADY 
);

//wire define
wire                   [  27:0]         vsdma_waddr                 ;
wire                                    vsdma_wareq                 ;
wire                   [  15:0]         vsdma_wsize                 ;
wire                                    vsdma_wbusy                 ;
wire                   [ 255:0]         vsdma_wdata                 ;
wire                                    vsdma_wvalid                ;
wire                                    vsdma_wready                ;
wire                   [  27:0]         vsdma_raddr                 ;
wire                                    vsdma_rareq                 ;
wire                   [  15:0]         vsdma_rsize                 ;
wire                                    vsdma_rbusy                 ;
wire                   [ 255:0]         vsdma_rdata                 ;
wire                                    vsdma_rvalid                ;
wire                                    vsdma_rready                ;

vsdma_control
#(
    .VIDEO_ENABLE                      (VIDEO_ENABLE              ),
    .ENABLE_WRITE                      (ENABLE_WRITE              ),
    .ENABLE_READ                       (ENABLE_READ               ),
    .AXI_DATA_WIDTH                    (AXI_DATA_WIDTH            ),
    .AXI_ADDR_WIDTH                    (AXI_ADDR_WIDTH            ),
    .W_BUFDEPTH                        (W_BUFDEPTH                ),
    .W_DATAWIDTH                       (W_DATAWIDTH               ),
    //.W_BASEADDR                        (W_BASEADDR                ),
    .W_DSIZEBITS                       (W_DSIZEBITS               ),
    //.W_XSIZE                           (W_XSIZE                   ),
    .W_XSTRIDE                         (W_XSTRIDE                 ),
    //.W_YSIZE                           (W_YSIZE                   ),
    .W_XDIV                            (W_XDIV                    ),
    .W_BUFSIZE                         (W_BUFSIZE                 ),
    .R_BUFDEPTH                        (R_BUFDEPTH                ),
    .R_DATAWIDTH                       (R_DATAWIDTH               ),
    .R_BASEADDR                        (R_BASEADDR                ),
    .R_DSIZEBITS                       (R_DSIZEBITS               ),
    .R_XSIZE                           (R_XSIZE                   ),
    .R_XSTRIDE                         (R_XSTRIDE                 ),
    .R_YSIZE                           (R_YSIZE                   ),
    .R_XDIV                            (R_XDIV                    ),
    .R_BUFSIZE                         (R_BUFSIZE                 ) 
)
u_vsdma_control(
    .W_XSIZE                           (W_XSIZE                   ),
    .W_YSIZE                           (W_YSIZE                   ),
    .W_BASEADDR                        (W_BASEADDR                ),
    .cnt_pingyi                        (cnt_pingyi                ),
    .ui_clk                            (ui_clk                    ),
    .ui_rstn                           (ui_rstn                   ),
    .key                               (key                       ),
    .W_wclk_i                          (W_wclk_i                  ),
    .W_FS_i                            (W_FS_i                    ),
    .W_wren_i                          (W_wren_i                  ),
    .W_data_i                          (W_data_i                  ),
    .W_sync_cnt_o                      (W_sync_cnt_o              ),
    .W_buf_i                           (W_buf_i                   ),
    .W_full                            (W_full                    ),
    .vsdma_waddr                       (vsdma_waddr               ),
    .vsdma_wareq                       (vsdma_wareq               ),
    .vsdma_wsize                       (vsdma_wsize               ),
    .vsdma_wbusy                       (vsdma_wbusy               ),
    .vsdma_wdata                       (vsdma_wdata               ),
    .vsdma_wvalid                      (vsdma_wvalid              ),
    .vsdma_wready                      (vsdma_wready              ),
    .R_rclk_i                          (R_rclk_i                  ),
    .R_FS_i                            (R_FS_i                    ),
    .R_rden_i                          (R_rden_i                  ),
    .R_data_o                          (R_data_o                  ),
    .R_sync_cnt_o                      (R_sync_cnt_o              ),
    .R_buf_i                           (R_buf_i                   ),
    .R_empty                           (R_empty                   ),
    .vsdma_raddr                       (vsdma_raddr               ),
    .vsdma_rareq                       (vsdma_rareq               ),
    .vsdma_rsize                       (vsdma_rsize               ),
    .vsdma_rbusy                       (vsdma_rbusy               ),
    .vsdma_rdata                       (vsdma_rdata               ),
    .vsdma_rvalid                      (vsdma_rvalid              ),
    .vsdma_rready                      (vsdma_rready              ) 
);

vsdma_to_axi
#(
    .M_AXI_ID_WIDTH                    (M_AXI_ID_WIDTH            ),
    .M_AXI_ID                          (M_AXI_ID                  ),
    .M_AXI_ADDR_WIDTH                  (M_AXI_ADDR_WIDTH          ),
    .M_AXI_DATA_WIDTH                  (M_AXI_DATA_WIDTH          ),
    .M_AXI_MAX_BURST_LEN               (M_AXI_MAX_BURST_LEN       ) 
)
u_vsdma_to_axi(
    .vsdma_waddr                       (vsdma_waddr               ),
    .vsdma_wareq                       (vsdma_wareq               ),
    .vsdma_wsize                       (vsdma_wsize               ),
    .vsdma_wbusy                       (vsdma_wbusy               ),
    .vsdma_wdata                       (vsdma_wdata               ),
    .vsdma_wvalid                      (vsdma_wvalid              ),
    .vsdma_wready                      (vsdma_wready              ),
    .vsdma_raddr                       (vsdma_raddr               ),
    .vsdma_rareq                       (vsdma_rareq               ),
    .vsdma_rsize                       (vsdma_rsize               ),
    .vsdma_rbusy                       (vsdma_rbusy               ),
    .vsdma_rdata                       (vsdma_rdata               ),
    .vsdma_rvalid                      (vsdma_rvalid              ),
    .vsdma_rready                      (vsdma_rready              ),
    .axi_wstart_locked                 (axi_wstart_locked         ),
    .M_AXI_ACLK                        (M_AXI_ACLK                ),
    .M_AXI_ARESETN                     (M_AXI_ARESETN             ),
    .M_AXI_AWID                        (M_AXI_AWID                ),
    .M_AXI_AWADDR                      (M_AXI_AWADDR              ),
    .M_AXI_AWLEN                       (M_AXI_AWLEN               ),
    .M_AXI_AWVALID                     (M_AXI_AWVALID             ),
    .M_AXI_AWREADY                     (M_AXI_AWREADY             ),
    .M_AXI_WID                         (M_AXI_WID                 ),
    .M_AXI_WDATA                       (M_AXI_WDATA               ),
    .M_AXI_WSTRB                       (M_AXI_WSTRB               ),
    .M_AXI_WLAST                       (M_AXI_WLAST               ),
    .M_AXI_WVALID                      (M_AXI_WVALID              ),
    .M_AXI_WREADY                      (M_AXI_WREADY              ),
    .M_AXI_ARID                        (M_AXI_ARID                ),
    .M_AXI_ARADDR                      (M_AXI_ARADDR              ),
    .M_AXI_ARLEN                       (M_AXI_ARLEN               ),
    .M_AXI_ARVALID                     (M_AXI_ARVALID             ),
    .M_AXI_ARREADY                     (M_AXI_ARREADY             ),
    .M_AXI_RID                         (M_AXI_RID                 ),
    .M_AXI_RDATA                       (M_AXI_RDATA               ),
    .M_AXI_RLAST                       (M_AXI_RLAST               ),
    .M_AXI_RVALID                      (M_AXI_RVALID              ),
    .M_AXI_RREADY                      (M_AXI_RREADY              ) 
);


endmodule