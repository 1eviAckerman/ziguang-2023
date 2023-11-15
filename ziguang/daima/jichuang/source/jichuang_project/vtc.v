`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//
// File name            : vtc.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 视频时序生成模块       
//
//****************************************************************************************//
`define UD #1
`define VIDEO_1920_1080
//`define VIDEO_1280_720

module vtc#(
    parameter                           X_BITS=12                  ,
    parameter                           Y_BITS=12                   
)(
    input                               clk                        ,
    input                               rstn                       ,
    output reg                          vs_out                     ,
    output reg                          hs_out                     ,
    output reg                          de_out                     ,
    output reg                          de_re                      ,
    output reg         [X_BITS-1:0]     x_act                      ,
    output reg         [Y_BITS-1:0]     y_act                       
);

`ifdef VIDEO_1920_1080
    parameter                           V_TOTAL = 12'd1125         ;
    parameter                           V_FP = 12'd4               ;
    parameter                           V_BP = 12'd36              ;
    parameter                           V_SYNC = 12'd5             ;
    parameter                           V_ACT = 12'd1080           ;

    parameter                           H_TOTAL = 12'd2200         ;
    parameter                           H_FP = 12'd88              ;
    parameter                           H_BP = 12'd148             ;
    parameter                           H_SYNC = 12'd44            ;
    parameter                           H_ACT = 12'd1920           ;
    parameter                           HV_OFFSET = 12'd0          ;
`endif

`ifdef VIDEO_1280_720
    parameter                           V_TOTAL = 12'd750          ;
    parameter                           V_FP = 12'd5               ;
    parameter                           V_BP = 12'd20              ;
    parameter                           V_SYNC = 12'd5             ;
    parameter                           V_ACT = 12'd72             ;

    parameter                           H_TOTAL = 12'd1650         ;
    parameter                           H_FP = 12'd110             ;
    parameter                           H_BP = 12'd220             ;
    parameter                           H_SYNC = 12'd40            ;
    parameter                           H_ACT = 12'd1280           ;
    parameter                           HV_OFFSET = 12'd0          ;
`endif

reg                    [X_BITS-1:0]     h_count                    ;
reg                    [Y_BITS-1:0]     v_count                    ;

/* horizontal counter */
always @(posedge clk)
begin
    if (!rstn)
        h_count <= `UD 0;
    else
    begin
        if (h_count < H_TOTAL - 1)
            h_count <= `UD h_count + 1;
        else
            h_count <= `UD 0;
    end
end

/* vertical counter */
always @(posedge clk)
begin
    if (!rstn)
        v_count <= `UD 0;
    else
    if (h_count == H_TOTAL - 1)
    begin
        if (v_count == V_TOTAL - 1)
            v_count <= `UD 0;
        else
            v_count <= `UD v_count + 1;
    end
end

always @(posedge clk)
begin
    if (!rstn)
        hs_out <= `UD 4'b0;
    else
        hs_out <= `UD ((h_count < H_SYNC));
end

always @(posedge clk)
begin
    if (!rstn)
        vs_out <= `UD 4'b0;
    else
    begin
        if ((v_count == 0) && (h_count == HV_OFFSET))
            vs_out <= `UD 1'b1;
        else if ((v_count == V_SYNC) && (h_count == HV_OFFSET))
            vs_out <= `UD 1'b0;
        else
            vs_out <= `UD vs_out;
    end
end

always @(posedge clk)
begin
    if (!rstn)
        de_out <= `UD 4'b0;
    else
        de_out <= (((v_count >= V_SYNC + V_BP) && (v_count <= V_TOTAL - V_FP - 1)) &&
                  ((h_count >= H_SYNC + H_BP) && (h_count <= H_TOTAL - H_FP - 1)));
end

always @(posedge clk)
begin
    if (!rstn)
        de_re <= `UD 4'b0;
    else
        de_re <= (((v_count >= V_SYNC + V_BP) && (v_count <= V_TOTAL - V_FP - 1)) &&
                  ((h_count >= H_SYNC + H_BP-2'd1) && (h_count <= H_TOTAL - H_FP - 2'd2)));
end
// active pixels counter output
always @(posedge clk)
begin
    if (!rstn)
        x_act <= `UD 'd0;
    else
    begin
    /* X coords – for a backend pattern generator */
        if(h_count > (H_SYNC + H_BP - 1'b1))
            x_act <= `UD (h_count - (H_SYNC + H_BP));
        else
            x_act <= `UD 'd0;
    end
end

always @(posedge clk)
begin
    if (!rstn)
        y_act <= `UD 'd0;
    else
    begin
        /* Y coords – for a backend pattern generator */
        if(v_count > (V_SYNC + V_BP - 1'b1))
            y_act <= `UD (v_count - (V_SYNC + V_BP));
        else
            y_act <= `UD 'd0;
    end
end
    
endmodule
