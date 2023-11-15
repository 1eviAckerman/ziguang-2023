`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//
// File name            : fs_cap.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 用于捕获帧上升沿操作      
//
//****************************************************************************************//

module fs_cap#(
    parameter                           integer  VIDEO_ENABLE   = 1 
)
(
    input                               clk_i                      ,
    input                               rstn_i                     ,
    input                               vs_i                       ,
    output reg                          fs_cap_o                    
);
    

reg                    [   4:0]         CNT_FS   = 6'b0            ;
reg                    [   4:0]         CNT_FS_n = 6'b0            ;
reg                                     FS       = 1'b0            ;
reg                                     vs_i_r1                    ;
reg                                     vs_i_r2                    ;
reg                                     vs_i_r3                    ;
reg                                     vs_i_r4                    ;

always@(posedge clk_i) begin
      vs_i_r1 <= vs_i;
      vs_i_r2 <= vs_i_r1;
      vs_i_r3 <= vs_i_r2;
      vs_i_r4 <= vs_i_r3;
end

//检测输入帧同步信号的上升沿
always@(posedge clk_i) begin
   if(!rstn_i)begin
      fs_cap_o <= 1'd0;
   end
   else if(VIDEO_ENABLE == 1)begin
      if({vs_i_r4,vs_i_r3} == 2'b01)begin
         fs_cap_o <= 1'b1;
      end
      else begin
         fs_cap_o <= 1'b0;
      end
   end
   else begin
         fs_cap_o <= vs_i_r4;
   end
end
        
endmodule
