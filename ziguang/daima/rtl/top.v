//****************************************Copyright (c)***********************************//
//
// File name            : top.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 顶层模块       
//
//****************************************************************************************//

module top(
    input                               sys_clk                    ,
    input                               sys_rst_n                  ,
	//摄像头接口                       
    input                               cam_pclk                   ,//cmos 数据像素时钟
    input                               cam_vsync                  ,//cmos 场同步信号
    input                               cam_href                   ,//cmos 行同步信号
    input              [   7:0]         cam_data                   ,//cmos 数据
    output                              cam_rst_n                  ,//cmos 复位信号，低电平有效
    output                              cam_pwdn                   ,//电源休眠模式选择 0：正常模式 1：电源休眠模式
    output                              cam_scl                    ,//cmos SCCB_SCL线
    inout                               cam_sda                    ,//cmos SCCB_SDA线
	//7200接口
    input                               pixclk_in                  ,
    input                               vs_in                      ,
    input                               hs_in                      ,
    input                               de_in                      ,
    input              [   7:0]         r_in                       ,
    input              [   7:0]         g_in                       ,
    input              [   7:0]         b_in                       ,
	//配置72xx接口	
    output                              iic_tx_scl                 ,
    inout                               iic_tx_sda                 ,
    output                              iic_scl                    ,
    inout                               iic_sda                    ,
	//DDR3接口
    output                              mem_rst_n                  ,
    output                              mem_ck                     ,
    output                              mem_ck_n                   ,
    output                              mem_cke                    ,
    output                              mem_cs_n                   ,
    output                              mem_ras_n                  ,
    output                              mem_cas_n                  ,
    output                              mem_we_n                   ,
    output                              mem_odt                    ,
    output             [15-1:0]         mem_a                      ,
    output             [3-1:0]          mem_ba                     ,
    inout              [4-1:0]          mem_dqs                    ,
    inout              [4-1:0]          mem_dqs_n                  ,
    inout              [32-1:0]         mem_dq                     ,
    output             [4-1:0]          mem_dm                     ,
	//7210芯片接口
    output                              pix_clk                    ,
    output                              rstn_out                   ,
    output                              vs_out                     ,
    output                              hs_out                     ,
    output                              de_out                     ,
    output             [   7:0]         r_out                      ,
    output             [   7:0]         g_out                      ,
    output             [   7:0]         b_out                      ,
    output                              led_int                    ,
    //以太网接口
    input                               eth_rxc                    ,//RGMII接收数据时钟
    input                               eth_rx_ctl                 ,//RGMII输入数据有效信号
    input              [   3:0]         eth_rxd                    ,//RGMII输入数据
    output                              eth_txc                    ,//RGMII发送数据时钟    
    output                              eth_tx_ctl                 ,//RGMII输出数据有效信号
    output             [   3:0]         eth_txd                    ,//RGMII输出数据          
    output                              eth_rst_n                   //以太网芯片复位信号，低电平有效 
    );
	
//parameter define
//开发板MAC地址 00-11-22-33-44-55
    parameter                           BOARD_MAC = 48'h00_11_22_33_44_55;
//开发板IP地址 192.168.1.10
    parameter                           BOARD_IP  = {8'd192,8'd168,8'd1,8'd10}; 
//目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter                           DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
//目的IP地址 192.168.1.102     
    parameter                           DES_IP    = {8'd192,8'd168,8'd1,8'd102}; 

    parameter                           H_CMOS_DISP = 12'd960      ;
    parameter                           V_CMOS_DISP = 12'd540      ;
    parameter                           TOTAL_H_PIXEL = 12'd1892   ;
    parameter                           TOTAL_V_PIXEL = 12'd740    ;

//wire define
//pll
wire                                    clk_10                     ;
wire                                    clk_50                     ;
wire                                    clk_74                     ;
wire                                    clk_lock                   ;
//camera
wire                   [  31:0]         wr_data_camera             ;
wire                                    cmos_frame_vsync           ;
wire                                    cmos_frame_valid           ;
//hdmi
wire                   [  31:0]         wr_data_hdmi               ;
wire                                    scale_vs                   ;
wire                                    scale_de                   ;
//VSDMA0
wire                                    M0_AWID                    ;
wire                                    M0_AWVALID                 ;
wire                                    M0_AWREADY                 ;
wire                   [   7:0]         M0_AWLEN                   ;
wire                   [  31:0]         M0_AWADDR                  ;
wire                                    M0_WREADY                  ;
wire                   [  31:0]         M0_WSTRB                   ;
wire                                    M0_WLAST                   ;
wire                   [ 255:0]         M0_WDATA                   ;
wire                                    M0_ARID                    ;
wire                                    M0_ARVALID                 ;
wire                                    M0_ARREADY                 ;
wire                   [   7:0]         M0_ARLEN                   ;
wire                   [  31:0]         M0_ARADDR                  ;
wire                                    M0_RVALID                  ;
wire                                    M0_RLAST                   ;
wire                   [ 255:0]         M0_RDATA                   ;
wire                                    axi_wstart_locked0         ;
//VSDMA1
wire                                    M1_AWID                    ;
wire                                    M1_AWVALID                 ;
wire                                    M1_AWREADY                 ;
wire                   [   7:0]         M1_AWLEN                   ;
wire                   [  31:0]         M1_AWADDR                  ;
wire                                    M1_WREADY                  ;
wire                   [  31:0]         M1_WSTRB                   ;
wire                                    M1_WLAST                   ;
wire                   [ 255:0]         M1_WDATA                   ;
wire                                    axi_wstart_locked1         ;
//VSDMA2
wire                                    M2_AWID                    ;
wire                                    M2_AWVALID                 ;
wire                                    M2_AWREADY                 ;
wire                   [   7:0]         M2_AWLEN                   ;
wire                   [  31:0]         M2_AWADDR                  ;
wire                                    M2_WREADY                  ;
wire                   [  31:0]         M2_WSTRB                   ;
wire                                    M2_WLAST                   ;
wire                   [ 255:0]         M2_WDATA                   ;
wire                                    axi_wstart_locked2         ;
//VSDMA3
wire                                    M3_AWID                    ;
wire                                    M3_AWVALID                 ;
wire                                    M3_AWREADY                 ;
wire                   [   7:0]         M3_AWLEN                   ;
wire                   [  31:0]         M3_AWADDR                  ;
wire                                    M3_WREADY                  ;
wire                   [  31:0]         M3_WSTRB                   ;
wire                                    M3_WLAST                   ;
wire                   [ 255:0]         M3_WDATA                   ;
wire                                    axi_wstart_locked3         ;
//vsbuf
wire                   [   7:0]         bufn_i                     ;
wire                   [   7:0]         bufn_o                     ;
//ddr_ip
wire                                    ddr_init_done              ;
wire                                    ddrphy_clkin               ;
wire                   [  27:0]         axi_awaddr                 ;
wire                   [   3:0]         axi_awuser_id              ;
wire                   [   3:0]         axi_awlen                  ;
wire                                    axi_awready                ;
wire                                    axi_awvalid                ;
wire                   [ 255:0]         axi_wdata                  ;
wire                   [  31:0]         axi_wstrb                  ;
wire                                    axi_wready                 ;
wire                                    axi_wusero_last            ;
wire                   [  27:0]         axi_araddr                 ;
wire                   [   3:0]         axi_aruser_id              ;
wire                   [   3:0]         axi_arlen                  ;
wire                                    axi_arready                ;
wire                                    axi_arvalid                ;
wire                   [ 255:0]         axi_rdata                  ;
wire                   [   3:0]         axi_rid                    ;
wire                                    axi_rlast                  ;
wire                                    axi_rvalid                 ;
//video_timing_control
wire                   [  31:0]         rd_data                    ;
wire                                    o_vs                       ;
wire                                    o_hs                       ;
wire                                    de_re                      ;
wire                                    o_de                       ;
//scale
wire                                    scale_vs_out               ;//输出帧有效场同步信号
wire                                    scale_de_out               ;//图像有效信号
wire                   [  31:0]         scale_data_out             ;//图像有效数据

reg                    [  15:0]         rstn_1ms                   ;

always @(posedge clk_10)
    begin
        if(!clk_lock)
            rstn_1ms <= 16'd0;
        else
        begin
            if(rstn_1ms == 16'h2710)
                rstn_1ms <= rstn_1ms;
            else
                rstn_1ms <= rstn_1ms + 1'b1;
        end
    end
    
assign rstn_out = (rstn_1ms == 16'h2710);

assign pix_clk    = clk_74;
assign vs_out    = o_vs;
assign hs_out    = o_hs;
assign de_out    = o_de;
assign r_out    = rd_data[23:16];
assign g_out    = rd_data[15:8];
assign b_out    = rd_data[7:0];
//*****************************************************
//**                    main code
//*****************************************************

pll_clk  u_pll_clk(
    .clkin1                            (sys_clk                   ),
    .clkout0                           (clk_10                    ),
    .clkout1                           (clk_50                    ),
    .clkout2                           (clk_74                    ),
    .pll_lock                          (clk_lock                  ) 
    );

ms72xx_ctl u_ms72xx_ctl(
    .clk                               (clk_10                    ),
    .rst_n                             (rstn_out                  ),
    .init_over                         (led_int                   ),
    .iic_tx_scl                        (iic_tx_scl                ),
    .iic_tx_sda                        (iic_tx_sda                ),
    .iic_scl                           (iic_scl                   ),
    .iic_sda                           (iic_sda                   ) 
    );
	
//ov5640 驱动
ov5640_dri u_ov5640_dri(
    .clk                               (clk_50                    ),
    .rst_n                             (clk_lock                  ),
    .cam_pclk                          (cam_pclk                  ),
    .cam_vsync                         (cam_vsync                 ),
    .cam_href                          (cam_href                  ),
    .cam_data                          (cam_data                  ),
    .cam_rst_n                         (cam_rst_n                 ),
    .cam_pwdn                          (cam_pwdn                  ),
    .cam_scl                           (cam_scl                   ),
    .cam_sda                           (cam_sda                   ),
    .cmos_h_pixel                      (H_CMOS_DISP               ),
    .cmos_v_pixel                      (V_CMOS_DISP               ),
    .total_h_pixel                     (TOTAL_H_PIXEL             ),
    .total_v_pixel                     (TOTAL_V_PIXEL             ),
    .capture_start                     (ddr_init_done             ),
    .cmos_frame_vsync                  (cmos_frame_vsync          ),
    .cmos_frame_valid                  (cmos_frame_valid          ),
    .cmos_frame_href                   (                          ),
    .cmos_frame_data                   (wr_data_camera            ) 
    );

//video cut
video_scale_960_540 u_video_scale_960_540(
    .pixclk_in                         (pixclk_in                 ),
    .vs_in                             (vs_in                     ),
    .hs_in                             (hs_in                     ),
    .de_in                             (de_in                     ),
    .r_in                              (r_in                      ),
    .g_in                              (g_in                      ),
    .b_in                              (b_in                      ),
    .vs_out                            (scale_vs                  ),
    .hs_out                            (                          ),
    .de_out                            (scale_de                  ),
    .wr_data                           (wr_data_hdmi              ) 
    );

VSDMA u_VSDMA0(
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (cam_pclk                  ),
    .W_FS_i                            (cmos_frame_vsync          ),
    .W_wren_i                          (cmos_frame_valid          ),
    .W_data_i                          (wr_data_camera            ),
    .W_sync_cnt_o                      (bufn_i                    ),
    .W_buf_i                           (bufn_i                    ),
    .W_full                            (                          ),
    .R_rclk_i                          (clk_74                    ),
    .R_FS_i                            (o_vs                      ),
    .R_rden_i                          (de_re                     ),
    .R_data_o                          (rd_data                   ),
    .R_sync_cnt_o                      (                          ),
    .R_buf_i                           (bufn_o                    ),
    .R_empty                           (                          ),
    .axi_wstart_locked                 (axi_wstart_locked0        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done             ),
    .M_AXI_AWID                        (M0_AWID                   ),
    .M_AXI_AWADDR                      (M0_AWADDR                 ),
    .M_AXI_AWLEN                       (M0_AWLEN                  ),
    .M_AXI_AWVALID                     (M0_AWVALID                ),
    .M_AXI_AWREADY                     (M0_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M0_WDATA                  ),
    .M_AXI_WSTRB                       (M0_WSTRB                  ),
    .M_AXI_WLAST                       (M0_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M0_WREADY                 ),
    .M_AXI_ARID                        (M0_ARID                   ),
    .M_AXI_ARADDR                      (M0_ARADDR                 ),
    .M_AXI_ARLEN                       (M0_ARLEN                  ),
    .M_AXI_ARVALID                     (M0_ARVALID                ),
    .M_AXI_ARREADY                     (M0_ARREADY                ),
    .M_AXI_RID                         (                          ),
    .M_AXI_RDATA                       (M0_RDATA                  ),
    .M_AXI_RLAST                       (M0_RLAST                  ),
    .M_AXI_RVALID                      (M0_RVALID                 ),
    .M_AXI_RREADY                      (                          ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b0                      ),
    .W_BASEADDR                        (32'd960                   ),
    .W_XSIZE                           (960                       ),
    .W_YSIZE                           (540                       ),
    .M_AXI_ID                          (4'd1                      ) 
    )
u_VSDMA1(
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (cam_pclk                  ),
    .W_FS_i                            (cmos_frame_vsync          ),
    .W_wren_i                          (cmos_frame_valid          ),
    .W_data_i                          (wr_data_camera            ),
    .W_sync_cnt_o                      (                          ),
    .W_buf_i                           (bufn_i                    ),
    .axi_wstart_locked                 (axi_wstart_locked1        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done             ),
    .M_AXI_AWID                        (M1_AWID                   ),
    .M_AXI_AWADDR                      (M1_AWADDR                 ),
    .M_AXI_AWLEN                       (M1_AWLEN                  ),
    .M_AXI_AWVALID                     (M1_AWVALID                ),
    .M_AXI_AWREADY                     (M1_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M1_WDATA                  ),
    .M_AXI_WSTRB                       (M1_WSTRB                  ),
    .M_AXI_WLAST                       (M1_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M1_WREADY                 ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b0                      ),
    .W_BASEADDR                        (32'd1036800               ),
    .W_XSIZE                           (960                       ),
    .W_YSIZE                           (540                       ),
    .M_AXI_ID                          (4'd2                      )  
    )
u_VSDMA2(
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (pixclk_in                 ),
    .W_FS_i                            (scale_vs                  ),
    .W_wren_i                          (scale_de                  ),
    .W_data_i                          (wr_data_hdmi              ),
    .W_sync_cnt_o                      (                          ),
    .W_buf_i                           (bufn_i                    ),
    .axi_wstart_locked                 (axi_wstart_locked2        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done             ),
    .M_AXI_AWID                        (M2_AWID                   ),
    .M_AXI_AWADDR                      (M2_AWADDR                 ),
    .M_AXI_AWLEN                       (M2_AWLEN                  ),
    .M_AXI_AWVALID                     (M2_AWVALID                ),
    .M_AXI_AWREADY                     (M2_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M2_WDATA                  ),
    .M_AXI_WSTRB                       (M2_WSTRB                  ),
    .M_AXI_WLAST                       (M2_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M2_WREADY                 ) 
    );

VSDMA #(
    .ENABLE_READ                       (1'b0                      ),
    .W_BASEADDR                        (32'd1037760               ),
    .W_XSIZE                           (960                       ),
    .W_YSIZE                           (540                       ),
    .M_AXI_ID                          (4'd3                      )  
    )
u_VSDMA3(
    .ui_clk                            (ddrphy_clkin              ),
    .ui_rstn                           (ddr_init_done             ),
    .W_wclk_i                          (pixclk_in                 ),
    .W_FS_i                            (scale_vs                  ),
    .W_wren_i                          (scale_de                  ),
    .W_data_i                          (wr_data_hdmi              ),
    .W_sync_cnt_o                      (                          ),
    .W_buf_i                           (bufn_i                    ),
    .axi_wstart_locked                 (axi_wstart_locked3        ),
    .M_AXI_ACLK                        (ddrphy_clkin              ),
    .M_AXI_ARESETN                     (ddr_init_done             ),
    .M_AXI_AWID                        (M3_AWID                   ),
    .M_AXI_AWADDR                      (M3_AWADDR                 ),
    .M_AXI_AWLEN                       (M3_AWLEN                  ),
    .M_AXI_AWVALID                     (M3_AWVALID                ),
    .M_AXI_AWREADY                     (M3_AWREADY                ),
    .M_AXI_WID                         (                          ),
    .M_AXI_WDATA                       (M3_WDATA                  ),
    .M_AXI_WSTRB                       (M3_WSTRB                  ),
    .M_AXI_WLAST                       (M3_WLAST                  ),
    .M_AXI_WVALID                      (                          ),
    .M_AXI_WREADY                      (M3_WREADY                 ) 
    );

vsbuf u_vsbuf(
    .bufn_i                            (bufn_i                    ),
    .bufn_o                            (bufn_o                    ) 
    );

AXI_Interconnect u_AXI_Interconnect(
    .ACLK                              (ddrphy_clkin              ),
    .ARESETn                           (ddr_init_done             ),

    .s0_AWID                           (M0_AWID                   ),
    .s0_AWADDR                         (M0_AWADDR                 ),
    .s0_AWLEN                          (M0_AWLEN                  ),
    .s0_AWVALID                        (M0_AWVALID                ),
    .s0_AWREADY                        (M0_AWREADY                ),
    .s0_WDATA                          (M0_WDATA                  ),
    .s0_WSTRB                          (M0_WSTRB                  ),
    .s0_WLAST                          (M0_WLAST                  ),
    .s0_WREADY                         (M0_WREADY                 ),
    .axi_wstart_locked0                (axi_wstart_locked0        ),

    .s1_AWID                           (M1_AWID                   ),
    .s1_AWADDR                         (M1_AWADDR                 ),
    .s1_AWLEN                          (M1_AWLEN                  ),
    .s1_AWVALID                        (M1_AWVALID                ),
    .s1_AWREADY                        (M1_AWREADY                ),
    .s1_WDATA                          (M1_WDATA                  ),
    .s1_WSTRB                          (M1_WSTRB                  ),
    .s1_WLAST                          (M1_WLAST                  ),
    .s1_WREADY                         (M1_WREADY                 ),
    .axi_wstart_locked1                (axi_wstart_locked1        ),


    .s2_AWID                           (M2_AWID                   ),
    .s2_AWADDR                         (M2_AWADDR                 ),
    .s2_AWLEN                          (M2_AWLEN                  ),
    .s2_AWVALID                        (M2_AWVALID                ),
    .s2_AWREADY                        (M2_AWREADY                ),
    .s2_WDATA                          (M2_WDATA                  ),
    .s2_WSTRB                          (M2_WSTRB                  ),
    .s2_WLAST                          (M2_WLAST                  ),
    .s2_WREADY                         (M2_WREADY                 ),
    .axi_wstart_locked2                (axi_wstart_locked2        ),

    .s3_AWID                           (M3_AWID                   ),
    .s3_AWADDR                         (M3_AWADDR                 ),
    .s3_AWLEN                          (M3_AWLEN                  ),
    .s3_AWVALID                        (M3_AWVALID                ),
    .s3_AWREADY                        (M3_AWREADY                ),
    .s3_WDATA                          (M3_WDATA                  ),
    .s3_WSTRB                          (M3_WSTRB                  ),
    .s3_WLAST                          (M3_WLAST                  ),
    .s3_WREADY                         (M3_WREADY                 ),
    .axi_wstart_locked3                (axi_wstart_locked3        ),

    .s0_ARID                           (M0_ARID                   ),
    .s0_ARADDR                         (M0_ARADDR                 ),
    .s0_ARLEN                          (M0_ARLEN                  ),
    .s0_ARVALID                        (M0_ARVALID                ),
    .s0_ARREADY                        (M0_ARREADY                ),
    .s0_RVALID                         (M0_RVALID                 ),
    .s0_RDATA                          (M0_RDATA                  ),
    .s0_RLAST                          (M0_RLAST                  ),

    .axi_awaddr                        (axi_awaddr                ),
    .axi_awuser_ap                     (                          ),
    .axi_awuser_id                     (axi_awuser_id             ),
    .axi_awlen                         (axi_awlen                 ),
    .axi_awready                       (axi_awready               ),
    .axi_awvalid                       (axi_awvalid               ),
    .axi_wdata                         (axi_wdata                 ),
    .axi_wstrb                         (axi_wstrb                 ),
    .axi_wready                        (axi_wready                ),
    .axi_wusero_id                     (                          ),
    .axi_wusero_last                   (axi_wusero_last           ),
    .axi_araddr                        (axi_araddr                ),
    .axi_aruser_ap                     (                          ),
    .axi_aruser_id                     (axi_aruser_id             ),
    .axi_arlen                         (axi_arlen                 ),
    .axi_arready                       (axi_arready               ),
    .axi_arvalid                       (axi_arvalid               ),
    .axi_rdata                         (axi_rdata                 ),
    .axi_rid                           (axi_rid                   ),
    .axi_rlast                         (axi_rlast                 ),
    .axi_rvalid                        (axi_rvalid                ) 
    );

ddr3_ip u_ddr3_ip(
    .ref_clk                           (clk_50                    ),
    .resetn                            (clk_lock                  ),
    .ddr_init_done                     (ddr_init_done             ),
    .ddrphy_clkin                      (ddrphy_clkin              ),
    .pll_lock                          (pll_lock                  ),
    .axi_awaddr                        (axi_awaddr                ),
    .axi_awuser_ap                     (1'b1                      ),
    .axi_awuser_id                     (axi_awuser_id             ),
    .axi_awlen                         (axi_awlen                 ),
    .axi_awready                       (axi_awready               ),
    .axi_awvalid                       (axi_awvalid               ),
    .axi_wdata                         (axi_wdata                 ),
    .axi_wstrb                         (axi_wstrb                 ),
    .axi_wready                        (axi_wready                ),
    .axi_wusero_id                     (                          ),
    .axi_wusero_last                   (axi_wusero_last           ),
    .axi_araddr                        (axi_araddr                ),
    .axi_aruser_ap                     (1'b1                      ),
    .axi_aruser_id                     (axi_aruser_id             ),
    .axi_arlen                         (axi_arlen                 ),
    .axi_arready                       (axi_arready               ),
    .axi_arvalid                       (axi_arvalid               ),
    .axi_rdata                         (axi_rdata                 ),
    .axi_rid                           (axi_rid                   ),
    .axi_rlast                         (axi_rlast                 ),
    .axi_rvalid                        (axi_rvalid                ),
    .apb_clk                           (1'b0                      ),
    .apb_rst_n                         (1'b1                      ),
    .apb_sel                           (1'b0                      ),
    .apb_enable                        (1'b0                      ),
    .apb_addr                          (8'b0                      ),
    .apb_write                         (1'b0                      ),
    .apb_ready                         (                          ),
    .apb_wdata                         (16'b0                     ),
    .apb_rdata                         (                          ),
    .apb_int                           (                          ),
    .debug_data                        (                          ),
    .debug_slice_state                 (                          ),
    .debug_calib_ctrl                  (                          ),
    .ck_dly_set_bin                    (                          ),
    .force_ck_dly_en                   (1'b0                      ),
    .force_ck_dly_set_bin              (8'h05                     ),
    .dll_step                          (                          ),
    .dll_lock                          (                          ),
    .init_read_clk_ctrl                (2'b0                      ),
    .init_slip_step                    (4'b0                      ),
    .force_read_clk_ctrl               (1'b0                      ),
    .ddrphy_gate_update_en             (1'b0                      ),
    .update_com_val_err_flag           (                          ),
    .rd_fake_stop                      (1'b0                      ),
    .mem_rst_n                         (mem_rst_n                 ),
    .mem_ck                            (mem_ck                    ),
    .mem_ck_n                          (mem_ck_n                  ),
    .mem_cke                           (mem_cke                   ),
    .mem_cs_n                          (mem_cs_n                  ),
    .mem_ras_n                         (mem_ras_n                 ),
    .mem_cas_n                         (mem_cas_n                 ),
    .mem_we_n                          (mem_we_n                  ),
    .mem_odt                           (mem_odt                   ),
    .mem_a                             (mem_a                     ),
    .mem_ba                            (mem_ba                    ),
    .mem_dqs                           (mem_dqs                   ),
    .mem_dqs_n                         (mem_dqs_n                 ),
    .mem_dq                            (mem_dq                    ),
    .mem_dm                            (mem_dm                    ) 
    );

vtc u_vtc(
    .clk                               (clk_74                    ),
    .rstn                              (clk_lock                  ),
    .vs_out                            (o_vs                      ),
    .hs_out                            (o_hs                      ),
    .de_re                             (de_re                     ),
    .de_out                            (o_de                      ) 
    );

//输出分辨率裁剪模块
video_scale_640_480 u_video_scale_640_480(
    .pixclk_in                         (clk_74                    ),
    .vs_in                             (vs_out                    ),
    .hs_in                             (hs_out                    ),
    .de_in                             (de_out                    ),
    .r_in                              (r_out                     ),
    .g_in                              (g_out                     ),
    .b_in                              (b_out                     ),
    .vs_out                            (scale_vs_out              ),
    .hs_out                            (                          ),
    .de_out                            (scale_de_out              ),
    .wr_data                           (scale_data_out            ) 
    );

hdmi_in_udp_out
#(
    .BOARD_MAC                         (BOARD_MAC                 ),
    .BOARD_IP                          (BOARD_IP                  ),
    .DES_MAC                           (DES_MAC                   ),
    .DES_IP                            (DES_IP                    ) 
)
u_hdmi_in_udp_out(
    .rst_n                             (sys_rst_n                 ),
    .img_pclk                          (clk_74                    ),
    .img_vsync                         (scale_vs_out              ),
    .img_data_en                       (scale_de_out              ),
    .img_data                          (scale_data_out            ),
    .eth_rxc                           (eth_rxc                   ),
    .eth_rx_ctl                        (eth_rx_ctl                ),
    .eth_rxd                           (eth_rxd                   ),
    .eth_txc                           (eth_txc                   ),
    .eth_tx_ctl                        (eth_tx_ctl                ),
    .eth_txd                           (eth_txd                   ),
    .eth_rst_n                         (eth_rst_n                 ) 
);

endmodule