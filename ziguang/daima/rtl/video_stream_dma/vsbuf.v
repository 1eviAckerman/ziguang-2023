`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//
// File name            : vsbuf.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 用于写入和读出图像帧的切换操作      
//
//****************************************************************************************//

module vsbuf#(
    parameter                           integer                  BUF_DELAY     = 1,
    parameter                           integer                  BUF_LENTH     = 3 
)
(

    input              [   7:0]         bufn_i                     ,
    output             [   7:0]         bufn_o                      
);

assign bufn_o = (bufn_i + (BUF_LENTH - 1'b1 - BUF_DELAY)) % BUF_LENTH;


endmodule

