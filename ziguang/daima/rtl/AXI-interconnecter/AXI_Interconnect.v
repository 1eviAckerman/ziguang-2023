//****************************************Copyright (c)***********************************//
//
// File name            : AXI_Interconnect.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 实现AXI多主机多从机互联       
//
//****************************************************************************************//

module AXI_Interconnect#(
    parameter                           DATA_WIDTH  = 256          ,
    parameter                           ADDR_WIDTH  = 32           ,
    parameter                           ID_WIDTH    = 4             
)(
	//时钟和复位
    input                               ACLK                       ,
    input                               ARESETn                    ,
    /********** 0号主控 **********/
    //写地址通道
    input              [ID_WIDTH-1:0]   s0_AWID                    ,
    input              [ADDR_WIDTH-1:0] s0_AWADDR                  ,
    input              [   7:0]         s0_AWLEN                   ,
    input                               s0_AWVALID                 ,
    output                              s0_AWREADY                 ,
    //写数据通道
    input              [DATA_WIDTH-1:0] s0_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s0_WSTRB                   ,
    input                               s0_WLAST                   ,
    output                              s0_WREADY                  ,
    //仲裁控制
    input                               axi_wstart_locked0         ,
    //读地址通道
    input              [ID_WIDTH-1:0]   s0_ARID                    ,
    input              [ADDR_WIDTH-1:0] s0_ARADDR                  ,
    input              [   7:0]         s0_ARLEN                   ,
    input                               s0_ARVALID                 ,
    output                              s0_ARREADY                 ,
    //读数据通道
    output                              s0_RVALID                  ,
    output             [DATA_WIDTH-1:0] s0_RDATA                   ,
    input                               s0_RLAST                   ,
    /********** 1号主控 **********/
    //写地址通道
    input              [ID_WIDTH-1:0]   s1_AWID                    ,
    input              [ADDR_WIDTH-1:0] s1_AWADDR                  ,
    input              [   7:0]         s1_AWLEN                   ,
    input                               s1_AWVALID                 ,
    output                              s1_AWREADY                 ,
    //写数据通道
    input              [DATA_WIDTH-1:0] s1_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s1_WSTRB                   ,
    input                               s1_WLAST                   ,
    output                              s1_WREADY                  ,
    //仲裁控制
    input                               axi_wstart_locked1         ,
    /********** 2号主控 **********/
    //写地址通道
    input              [ID_WIDTH-1:0]   s2_AWID                    ,
    input              [ADDR_WIDTH-1:0] s2_AWADDR                  ,
    input              [   7:0]         s2_AWLEN                   ,
    input                               s2_AWVALID                 ,
    output                              s2_AWREADY                 ,
    //写数据通道               
    input              [DATA_WIDTH-1:0] s2_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s2_WSTRB                   ,
    input                               s2_WLAST                   ,
    output                              s2_WREADY                  ,
    //仲裁控制
    input                               axi_wstart_locked2         ,
    /********** 3号主控 **********/
    //写地址通道
    input              [ID_WIDTH-1:0]   s3_AWID                    ,
    input              [ADDR_WIDTH-1:0] s3_AWADDR                  ,
    input              [   7:0]         s3_AWLEN                   ,
    input                               s3_AWVALID                 ,
    output                              s3_AWREADY                 ,
    //写数据通道               
    input              [DATA_WIDTH-1:0] s3_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s3_WSTRB                   ,
    input                               s3_WLAST                   ,
    output                              s3_WREADY                  ,
    //仲裁控制
    input                               axi_wstart_locked3         ,
    /********** 从机 **********/
    //写地址通道
    output             [28-1:0]         axi_awaddr                 ,
    output                              axi_awuser_ap              ,
    output             [   3:0]         axi_awuser_id              ,
    output             [   3:0]         axi_awlen                  ,
    input                               axi_awready                ,
    output                              axi_awvalid                ,
    //写数据通道
    output             [32*8-1:0]       axi_wdata                  ,
    output             [32-1:0]         axi_wstrb                  ,
    input                               axi_wready                 ,
    input              [   3:0]         axi_wusero_id              ,
    input                               axi_wusero_last            ,
    //读地址通道
    output             [28-1:0]         axi_araddr                 ,
    output                              axi_aruser_ap              ,
    output             [   3:0]         axi_aruser_id              ,
    output             [   3:0]         axi_arlen                  ,
    input                               axi_arready                ,
    output                              axi_arvalid                ,
    //读数据通道
    input              [32*8-1:0]       axi_rdata                  ,
    input              [   3:0]         axi_rid                    ,
    input                               axi_rlast                  ,
    input                               axi_rvalid                  
);

wire                   [   3:0]         rid = axi_rid              ;
wire                   [   3:0]         wid = axi_wusero_id        ;
wire                                    w_axi_wlast = axi_wusero_last;
wire                                    w_axi_rlast = axi_rlast    ;
assign axi_awuser_ap = 1'b1;
assign axi_aruser_ap = 1'b1;

//=========================================================
//wire define
wire                                    s0_wgrnt                   ;
wire                                    s1_wgrnt                   ;
wire                                    s2_wgrnt                   ;
wire                                    s3_wgrnt                   ;

//=========================================================
//写通道仲裁器例化
AXI_Arbiter_W u_AXI_Arbiter_W(
    .ACLK                              (ACLK                      ),
    .ARESETn                           (ARESETn                   ),

    .s0_AWVALID                        (s0_AWVALID                ),
    .s0_AWREADY                        (s0_AWREADY                ),
    .s0_WLAST                          (s0_WLAST                  ),
    .axi_wstart_locked0                (axi_wstart_locked0        ),

    .s1_AWVALID                        (s1_AWVALID                ),
    .s1_AWREADY                        (s1_AWREADY                ),
    .s1_WLAST                          (s1_WLAST                  ),
    .axi_wstart_locked1                (axi_wstart_locked1        ),

    .s2_AWVALID                        (s2_AWVALID                ),
    .s2_AWREADY                        (s2_AWREADY                ),
    .s2_WLAST                          (s2_WLAST                  ),
    .axi_wstart_locked2                (axi_wstart_locked2        ),

    .s3_AWVALID                        (s3_AWVALID                ),
    .s3_AWREADY                        (s3_AWREADY                ),
    .s3_WLAST                          (s3_WLAST                  ),
    .axi_wstart_locked3                (axi_wstart_locked3        ),
		
    .s0_wgrnt                          (s0_wgrnt                  ),
    .s1_wgrnt                          (s1_wgrnt                  ),
    .s2_wgrnt                          (s2_wgrnt                  ),
    .s3_wgrnt                          (s3_wgrnt                  ) 
    );

 //=========================================================
//写通道主机多路复用器
AXI_Master_Mux_W #(
    .DATA_WIDTH                        (DATA_WIDTH                ),
    .ADDR_WIDTH                        (ADDR_WIDTH                ),
    .ID_WIDTH                          (ID_WIDTH                  ) 
    )u_AXI_Master_Mux_W(
    .s0_AWID                           (s0_AWID                   ),
    .s0_AWADDR                         (s0_AWADDR                 ),
    .s0_AWLEN                          (s0_AWLEN                  ),
    .s0_AWVALID                        (s0_AWVALID                ),
    .s0_AWREADY                        (s0_AWREADY                ),
    
    .s0_WDATA                          (s0_WDATA                  ),
    .s0_WSTRB                          (s0_WSTRB                  ),
    .s0_WREADY                         (s0_WREADY                 ),
   
    .s1_AWID                           (s1_AWID                   ),
    .s1_AWADDR                         (s1_AWADDR                 ),
    .s1_AWLEN                          (s1_AWLEN                  ),
    .s1_AWVALID                        (s1_AWVALID                ),
    .s1_AWREADY                        (s1_AWREADY                ),
   
    .s1_WDATA                          (s1_WDATA                  ),
    .s1_WSTRB                          (s1_WSTRB                  ),
    .s1_WREADY                         (s1_WREADY                 ),
		
    .s2_AWID                           (s2_AWID                   ),
    .s2_AWADDR                         (s2_AWADDR                 ),
    .s2_AWLEN                          (s2_AWLEN                  ),
    .s2_AWVALID                        (s2_AWVALID                ),
    .s2_AWREADY                        (s2_AWREADY                ),
		
    .s2_WDATA                          (s2_WDATA                  ),
    .s2_WSTRB                          (s2_WSTRB                  ),
    .s2_WREADY                         (s2_WREADY                 ),

    .s3_AWID                           (s3_AWID                   ),
    .s3_AWADDR                         (s3_AWADDR                 ),
    .s3_AWLEN                          (s3_AWLEN                  ),
    .s3_AWVALID                        (s3_AWVALID                ),
    .s3_AWREADY                        (s3_AWREADY                ),
   
    .s3_WDATA                          (s3_WDATA                  ),
    .s3_WSTRB                          (s3_WSTRB                  ),
    .s3_WREADY                         (s3_WREADY                 ),
    
    .axi_awuser_id                     (axi_awuser_id             ),
    .axi_awaddr                        (axi_awaddr                ),
    .axi_awlen                         (axi_awlen                 ),
    .axi_awvalid                       (axi_awvalid               ),
    .axi_awready                       (axi_awready               ),
    .axi_wdata                         (axi_wdata                 ),
    .axi_wstrb                         (axi_wstrb                 ),
    .axi_wready                        (axi_wready                ),

    .s0_wgrnt                          (s0_wgrnt                  ),
    .s1_wgrnt                          (s1_wgrnt                  ),
    .s2_wgrnt                          (s2_wgrnt                  ),
    .s3_wgrnt                          (s3_wgrnt                  ) 
    );

assign axi_aruser_id    = s0_ARID;
assign axi_araddr       = s0_ARADDR;
assign axi_arlen        = s0_ARLEN;
assign axi_arvalid      = s0_ARVALID;

assign s0_ARREADY       = axi_arready;
assign s0_RDATA         = axi_rdata;
assign s0_RLAST         = axi_rlast;
assign s0_RVALID        = axi_rvalid;

endmodule