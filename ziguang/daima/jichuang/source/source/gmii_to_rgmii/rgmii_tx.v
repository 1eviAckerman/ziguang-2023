//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           rgmii_tx
// Last modified Date:  2020/2/13 9:20:14
// Last Version:        V1.0
// Descriptions:        RGMII����ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/2/13 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module rgmii_tx(
    input              reset,
    //GMII���Ͷ˿�
    input              gmii_tx_er     ,
    input              gmii_tx_clk    , //GMII����ʱ��    
    input              gmii_tx_en     , //GMII���������Ч�ź�
    input       [7:0]  gmii_txd       , //GMII�������    
    input              gmii_tx_clk_deg,//GMII����ʱ����λƫ��45��
    //RGMII���Ͷ˿�
    output             rgmii_txc      , //RGMII��������ʱ��    
    output             rgmii_tx_ctl   , //RGMII���������Ч�ź�
    output      [3:0]  rgmii_txd        //RGMII�������
    );
// registers
reg             tx_reset_d1    ;
reg             tx_reset_sync  ;
reg             rx_reset_d1    ;

reg   [ 7:0]    gmii_txd_r     ;
reg   [ 7:0]    gmii_txd_r_d1  ;

reg             gmii_tx_en_r   ;
reg             gmii_tx_en_r_d1;

reg             gmii_tx_er_r   ;

reg             rgmii_tx_ctl_r ;
reg   [ 3:0]    gmii_txd_low   ;

// wire
wire            padt1   ;
wire            padt2   ;
wire            padt3   ;
wire            padt4   ;
wire            padt5   ;
wire            padt6   ;
wire            stx_txc ;
wire            stx_ctr ;
wire  [3:0]     stxd_rgm;
//*****************************************************
//**                    main code
//*****************************************************


always @(posedge gmii_tx_clk) begin
    tx_reset_d1   <= reset;
    tx_reset_sync <= tx_reset_d1;
end

always @(posedge gmii_tx_clk) begin
    if (tx_reset_sync == 1'b1) begin
        gmii_txd_r   <= 8'h0;
        gmii_tx_en_r <= 1'b0;
        gmii_tx_er_r <= 1'b0;
    end
    else
    begin
        gmii_txd_r      <= gmii_txd;
        gmii_tx_en_r    <= gmii_tx_en;
        gmii_tx_er_r    <= gmii_tx_er;
        gmii_txd_r_d1   <= gmii_txd_r;
        gmii_tx_en_r_d1 <= gmii_tx_en_r;
    end
end

always @(posedge gmii_tx_clk)
begin
    rgmii_tx_ctl_r <= gmii_tx_en_r ^ gmii_tx_er_r;
    gmii_txd_low   <= gmii_txd_r[7:4];               //�����޸���
end

//���˫�ز����Ĵ��� (rgmii_txd)
GTP_OSERDES #(
    .OSERDES_MODE    ("ODDR" ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND       ("FALSE"),  //"TRUE"; "FALSE"
    .GRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .TSDDR_INIT      (1'b0   )   //1'b0;1'b1
) gtp_ogddr6(     
    .DO              (stx_txc        ),
    .TQ              (padt6          ),
    .DI              ({7'd0,1'b1}    ),
    .TI              (4'd0           ),
    .RCLK            (gmii_tx_clk_deg),
    .SERCLK          (gmii_tx_clk_deg),
    .OCLK            (1'd0           ),
    .RST             (tx_reset_sync  )
);
GTP_OUTBUFT  gtp_outbuft6
(
    .I    (stx_txc  ),
    .T    (padt6    ),
    .O    ( )   //������һ��  rgmii_txc
);

assign  rgmii_txc=gmii_tx_clk;
GTP_OSERDES #(
    .OSERDES_MODE    ("ODDR" ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND       ("FALSE"),  //"TRUE"; "FALSE"
    .GRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .TSDDR_INIT      (1'b0   )   //1'b0;1'b1
) gtp_ogddr2(     
    .DO              (stxd_rgm[3]  ),
    .TQ              (padt2        ),
    .DI              ({6'd0,gmii_txd_low[3],gmii_txd_r_d1[3]}),
    .TI              (4'd0         ),
    .RCLK            (gmii_tx_clk  ),
    .SERCLK          (gmii_tx_clk  ),
    .OCLK            (1'd0         ),
    .RST             (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft2
(
    .I    (stxd_rgm[3]),
    .T    (padt2      ),
    .O    (rgmii_txd[3])
);


GTP_OSERDES #(
    .OSERDES_MODE    ("ODDR" ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND       ("FALSE"),  //"TRUE"; "FALSE"
    .GRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .TSDDR_INIT      (1'b0   )   //1'b0;1'b1
) gtp_ogddr3(     
    .DO              (stxd_rgm[2]  ),
    .TQ              (padt3        ),
    .DI              ({6'd0,gmii_txd_low[2],gmii_txd_r_d1[2]}),
    .TI              (4'd0         ),
    .RCLK            (gmii_tx_clk  ),
    .SERCLK          (gmii_tx_clk  ),
    .OCLK            (1'd0         ),
    .RST             (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft3
(    
    .I    (stxd_rgm[2]),
    .T    (padt3      ),
    .O    (rgmii_txd[2])
);


GTP_OSERDES #(
    .OSERDES_MODE    ("ODDR" ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND       ("FALSE"),  //"TRUE"; "FALSE"
    .GRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .TSDDR_INIT      (1'b0   )   //1'b0;1'b1
) gtp_ogddr4(     
    .DO              (stxd_rgm[1]  ),
    .TQ              (padt4        ),
    .DI              ({6'd0,gmii_txd_low[1],gmii_txd_r_d1[1]}),
    .TI              (4'd0         ),
    .RCLK            (gmii_tx_clk  ),
    .SERCLK          (gmii_tx_clk  ),
    .OCLK            (1'd0         ),
    .RST             (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft4
(
    .I    (stxd_rgm[1]),
    .T    (padt4      ),
    .O    (rgmii_txd[1])
);


GTP_OSERDES #(
    .OSERDES_MODE    ("ODDR" ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND       ("FALSE"),  //"TRUE"; "FALSE"
    .GRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .TSDDR_INIT      (1'b0   )   //1'b0;1'b1
) gtp_ogddr5(     
    .DO              (stxd_rgm[0]  ),
    .TQ              (padt5        ),
    .DI              ({6'd0,gmii_txd_low[0],gmii_txd_r_d1[0]}),
    .TI              (4'd0         ),
    .RCLK            (gmii_tx_clk  ),
    .SERCLK          (gmii_tx_clk  ),
    .OCLK            (1'd0         ),
    .RST             (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft5
(
    .I    (stxd_rgm[0]),
    .T    (padt5      ),
    .O    (rgmii_txd[0])
);


//���˫�ز����Ĵ��� (rgmii_tx_ctl)
GTP_OSERDES #( 
    .OSERDES_MODE    ("ODDR" ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND       ("FALSE"),  //"TRUE"; "FALSE"
    .GRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .LRS_EN          ("TRUE" ),  //"TRUE"; "FALSE"
    .TSDDR_INIT      (1'b0   )   //1'b0;1'b1
) gtp_ogddr1(     
    .DO              (stx_ctr      ),
    .TQ              (padt1        ),
    .DI              ({6'd0,rgmii_tx_ctl_r,gmii_tx_en_r_d1}),
    .TI              (4'd0         ),
    .RCLK            (gmii_tx_clk  ),
    .SERCLK          (gmii_tx_clk  ),
    .OCLK            (1'd0         ),
    .RST             (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft1
(
    .I    (stx_ctr     ),
    .T    (padt1       ),
    .O    (rgmii_tx_ctl)
);

endmodule