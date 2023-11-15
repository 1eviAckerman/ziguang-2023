//****************************************Copyright (c)***********************************//
//
// File name            : hdmi_in_udp_out.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 将输入的视频数据通过udp协议传输给上位机       
//
//****************************************************************************************//

module hdmi_in_udp_out(
    input                               rst_n                      ,
    input                               img_pclk                   ,
    input                               img_vsync                  ,
    input                               img_data_en                ,
    input              [  31:0]         img_data                   ,
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

//wire define
wire                                    eth_tx_clk                 ;//以太网发送时钟
wire                                    eth_rx_clk                 ;//以太网接收时钟
wire                                    udp_tx_start_en            ;//以太网开始发送信号
wire                   [  15:0]         udp_tx_byte_num            ;//以太网发送的有效字节数
wire                   [  31:0]         udp_tx_data                ;//以太网发送的数据
wire                                    udp_tx_req                 ;//以太网发送请求数据信号
wire                                    udp_tx_done                ;//以太网发送完成信号

//*****************************************************
//**                    main code
//*****************************************************

//图像封装模块
img_data_pkt u_img_data_pkt(
    .rst_n                             (rst_n                     ),
   
    .cam_pclk                          (img_pclk                  ),
    .img_vsync                         (img_vsync                 ),
    .img_data_en                       (img_data_en               ),
    .img_data                          (img_data                  ),
    .transfer_flag                     (1'b1                      ),
    .eth_tx_clk                        (eth_tx_clk                ),
    .udp_tx_req                        (udp_tx_req                ),
    .udp_tx_done                       (udp_tx_done               ),
    .udp_tx_start_en                   (udp_tx_start_en           ),
    .udp_tx_data                       (udp_tx_data               ),
    .udp_tx_byte_num                   (udp_tx_byte_num           ) 
    );

//以太网顶层模块    
eth_top  #(
    .BOARD_MAC                         (BOARD_MAC                 ),//参数例化
    .BOARD_IP                          (BOARD_IP                  ),
    .DES_MAC                           (DES_MAC                   ),
    .DES_IP                            (DES_IP                    ) 
    )
    u_eth_top(
    .sys_rst_n                         (rst_n                     ),//系统复位信号，低电平有效           
    //以太网RGMII接口             
    .eth_rxc                           (eth_rxc                   ),//RGMII接收数据时钟
    .eth_rx_ctl                        (eth_rx_ctl                ),//RGMII输入数据有效信号
    .eth_rxd                           (eth_rxd                   ),//RGMII输入数据
    .eth_txc                           (eth_txc                   ),//RGMII发送数据时钟    
    .eth_tx_ctl                        (eth_tx_ctl                ),//RGMII输出数据有效信号
    .eth_txd                           (eth_txd                   ),//RGMII输出数据          
    .eth_rst_n                         (eth_rst_n                 ),//以太网芯片复位信号，低电平有效 

    .gmii_rx_clk                       (eth_rx_clk                ),
    .gmii_tx_clk                       (eth_tx_clk                ),
    .udp_tx_start_en                   (udp_tx_start_en           ),
    .tx_data                           (udp_tx_data               ),
    .tx_byte_num                       (udp_tx_byte_num           ),
    .udp_tx_done                       (udp_tx_done               ),
    .tx_req                            (udp_tx_req                ),
    .rec_pkt_done                      (                          ),
    .rec_en                            (                          ),
    .rec_data                          (                          ),
    .rec_byte_num                      (                          ) 
    );

endmodule