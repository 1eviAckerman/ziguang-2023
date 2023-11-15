//****************************************Copyright (c)***********************************//
//
// File name            : hdmi_in_udp_out.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : ���������Ƶ����ͨ��udpЭ�鴫�����λ��       
//
//****************************************************************************************//

module hdmi_in_udp_out(
    input                               rst_n                      ,
    input                               img_pclk                   ,
    input                               img_vsync                  ,
    input                               img_data_en                ,
    input              [  31:0]         img_data                   ,
    //��̫���ӿ�
    input                               eth_rxc                    ,//RGMII��������ʱ��
    input                               eth_rx_ctl                 ,//RGMII����������Ч�ź�
    input              [   3:0]         eth_rxd                    ,//RGMII��������
    output                              eth_txc                    ,//RGMII��������ʱ��    
    output                              eth_tx_ctl                 ,//RGMII���������Ч�ź�
    output             [   3:0]         eth_txd                    ,//RGMII�������          
    output                              eth_rst_n                   //��̫��оƬ��λ�źţ��͵�ƽ��Ч 
);

//parameter define
//������MAC��ַ 00-11-22-33-44-55
    parameter                           BOARD_MAC = 48'h00_11_22_33_44_55;
//������IP��ַ 192.168.1.10
    parameter                           BOARD_IP  = {8'd192,8'd168,8'd1,8'd10}; 
//Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
    parameter                           DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
//Ŀ��IP��ַ 192.168.1.102     
    parameter                           DES_IP    = {8'd192,8'd168,8'd1,8'd102}; 

//wire define
wire                                    eth_tx_clk                 ;//��̫������ʱ��
wire                                    eth_rx_clk                 ;//��̫������ʱ��
wire                                    udp_tx_start_en            ;//��̫����ʼ�����ź�
wire                   [  15:0]         udp_tx_byte_num            ;//��̫�����͵���Ч�ֽ���
wire                   [  31:0]         udp_tx_data                ;//��̫�����͵�����
wire                                    udp_tx_req                 ;//��̫���������������ź�
wire                                    udp_tx_done                ;//��̫����������ź�

//*****************************************************
//**                    main code
//*****************************************************

//ͼ���װģ��
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

//��̫������ģ��    
eth_top  #(
    .BOARD_MAC                         (BOARD_MAC                 ),//��������
    .BOARD_IP                          (BOARD_IP                  ),
    .DES_MAC                           (DES_MAC                   ),
    .DES_IP                            (DES_IP                    ) 
    )
    u_eth_top(
    .sys_rst_n                         (rst_n                     ),//ϵͳ��λ�źţ��͵�ƽ��Ч           
    //��̫��RGMII�ӿ�             
    .eth_rxc                           (eth_rxc                   ),//RGMII��������ʱ��
    .eth_rx_ctl                        (eth_rx_ctl                ),//RGMII����������Ч�ź�
    .eth_rxd                           (eth_rxd                   ),//RGMII��������
    .eth_txc                           (eth_txc                   ),//RGMII��������ʱ��    
    .eth_tx_ctl                        (eth_tx_ctl                ),//RGMII���������Ч�ź�
    .eth_txd                           (eth_txd                   ),//RGMII�������          
    .eth_rst_n                         (eth_rst_n                 ),//��̫��оƬ��λ�źţ��͵�ƽ��Ч 

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