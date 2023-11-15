//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           rgmii_rx
// Last modified Date:  2020/2/13 9:20:14
// Last Version:        V1.0
// Descriptions:        RGMII接收模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/13 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rgmii_rx(
    //以太网RGMII接口
    input              rgmii_rxc      , //RGMII接收时钟
    input              rgmii_rx_ctl   , //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd      , //RGMII接收数据    

    //以太网GMII接口
    output             gmii_rx_clk    , //GMII接收时钟
    output  reg        gmii_rx_dv     , //GMII接收数据有效信号
    output  reg [7:0]  gmii_rxd       , //GMII接收数据 
    output             gmii_tx_clk_deg,
    output             pll_lock
    );

wire            gmii_rx_dv_s;
wire  [ 7:0]    gmii_rxd_s;
//*****************************************************
//**                    main code
//*****************************************************
pll_sft U_pll_phase_shift(   
    .clkout0   (gmii_rx_clk    ),   //125MHz   gmii_rx_clk
    .clkout1   (gmii_tx_clk_deg),
    .clkin1    (rgmii_rxc      ),
    .clkfb     (gmii_rx_clk    ),
    .pll_rst   (1'b0           ),
    .pll_lock  (pll_lock       )
    );
    
always @(posedge gmii_rx_clk)
begin
    gmii_rxd   <= gmii_rxd_s;
    gmii_rx_dv <= gmii_rx_dv_s;
end

wire [5:0] nc1;
GTP_ISERDES #(
    .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
    .GRS_EN          ("TRUE"),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE")   //"TRUE"; "FALSE"
) igddr1(         
    .DI              (rgmii_rxd[0]),
    .ICLK            (1'd0        ),
    .DESCLK          (gmii_rx_clk ),
    .RCLK            (gmii_rx_clk ),
    .WADDR           (3'd0        ),
    .RADDR           (3'd0        ),
    .RST             (1'b0        ),
    .DO              ({gmii_rxd_s[4],gmii_rxd_s[0],nc1})
);

wire [5:0] nc2;
GTP_ISERDES #(
    .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
    .GRS_EN          ("TRUE"),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE")   //"TRUE"; "FALSE"
) igddr2(
    .DI              (rgmii_rxd[1]),
    .ICLK            (1'd0        ),
    .DESCLK          (gmii_rx_clk ),
    .RCLK            (gmii_rx_clk ),
    .WADDR           (3'd0        ),
    .RADDR           (3'd0        ),
    .RST             (1'b0        ),
    .DO              ({gmii_rxd_s[5],gmii_rxd_s[1],nc2})
);

wire [5:0] nc3;
GTP_ISERDES #(
    .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
    .GRS_EN          ("TRUE"),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE")   //"TRUE"; "FALSE"
) igddr3(
    .DI              (rgmii_rxd[2]),
    .ICLK            (1'd0        ),
    .DESCLK          (gmii_rx_clk ),
    .RCLK            (gmii_rx_clk ),
    .WADDR           (3'd0        ),
    .RADDR           (3'd0        ),
    .RST             (1'b0        ),
    .DO              ({gmii_rxd_s[6],gmii_rxd_s[2],nc3})
);

wire [5:0] nc4;
GTP_ISERDES #(
    .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
    .GRS_EN          ("TRUE"),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE")   //"TRUE"; "FALSE"
) igddr4(
    .DI              (rgmii_rxd[3]),
    .ICLK            (1'd0        ),
    .DESCLK          (gmii_rx_clk ),
    .RCLK            (gmii_rx_clk ),
    .WADDR           (3'd0        ),
    .RADDR           (3'd0        ),
    .RST             (1'b0        ),
    .DO              ({gmii_rxd_s[7],gmii_rxd_s[3],nc4})
);

wire [5:0] nc5;
GTP_ISERDES #(
    .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
    .GRS_EN          ("TRUE"),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE")   //"TRUE"; "FALSE"
) igddr5(
    .DI              (rgmii_rx_ctl),
    .ICLK            (1'd0        ),
    .DESCLK          (gmii_rx_clk ),
    .RCLK            (gmii_rx_clk ),
    .WADDR           (3'd0        ),
    .RADDR           (3'd0        ),
    .RST             (1'b0        ),
    .DO              ({rgmii_rx_ctl_s,gmii_rx_dv_s,nc5})
);

endmodule