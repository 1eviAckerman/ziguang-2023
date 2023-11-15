//****************************************Copyright (c)***********************************//
//
// File name            : AXI_Arbiter.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/19
// Created date         : 2023/05/19  
// Descriptions         : 实现AXI多从机仲裁       
//
//****************************************************************************************//
module AXI_Arbiter_W (
    /**********时钟复位**********/
    input                               ACLK                       ,
    input                               ARESETn                    ,
    /********** 0号主控 **********/
    input                               s0_AWVALID                 ,
    input                               s0_AWREADY                 ,
    input                               s0_WLAST                   ,
    input                               axi_wstart_locked0         ,
    /********** 1号主控 **********/
    input                               s1_AWVALID                 ,
    input                               s1_AWREADY                 ,
    input                               s1_WLAST                   ,
    input                               axi_wstart_locked1         ,
    /********** 2号主控 **********/
    input                               s2_AWVALID                 ,
    input                               s2_AWREADY                 ,
    input                               s2_WLAST                   ,
    input                               axi_wstart_locked2         ,
    /********** 3号主控 **********/
    input                               s3_AWVALID                 ,
    input                               s3_AWREADY                 ,
    input                               s3_WLAST                   ,
    input                               axi_wstart_locked3         ,
    
    output reg                          s0_wgrnt                   ,
    output reg                          s1_wgrnt                   ,
    output reg                          s2_wgrnt                   ,
    output reg                          s3_wgrnt                    
);

    parameter                           AXI_MASTER_0 = 3'b000      ;
    parameter                           AXI_MASTER_1 = 3'b001      ;
    parameter                           AXI_MASTER_2 = 3'b010      ;
    parameter                           AXI_MASTER_3 = 3'b100      ;

reg                    [   2:0]         state                      ;
reg                    [   2:0]         next_state                 ;

    //---------------------------------------------------------
    //状态译码
    always @(*) begin
        case (state)
            AXI_MASTER_0: begin
                if(s1_AWVALID && ~axi_wstart_locked0)
                    next_state = AXI_MASTER_1;
                else if(s2_AWVALID && ~axi_wstart_locked0)
                    next_state = AXI_MASTER_2;
                else if(s3_AWVALID && ~axi_wstart_locked0)
                    next_state = AXI_MASTER_3;
                else
                    next_state = AXI_MASTER_0;
            end
            AXI_MASTER_1: begin
                if(s2_AWVALID && ~axi_wstart_locked1)
                    next_state = AXI_MASTER_2;
                else if(s3_AWVALID && ~axi_wstart_locked1)
                    next_state = AXI_MASTER_3;
                else if(s0_AWVALID && ~axi_wstart_locked1)
                    next_state = AXI_MASTER_0;
                else
                    next_state = AXI_MASTER_1;
            end
            AXI_MASTER_2: begin
                if(s3_AWVALID && ~axi_wstart_locked2)
                    next_state = AXI_MASTER_3;
                else if(s0_AWVALID && ~axi_wstart_locked2)
                    next_state = AXI_MASTER_0;
                else if(s1_AWVALID && ~axi_wstart_locked2)
                    next_state = AXI_MASTER_1;
                else
                    next_state = AXI_MASTER_2;
            end
            AXI_MASTER_3: begin
                if(s0_AWVALID && ~axi_wstart_locked3)
                    next_state = AXI_MASTER_0;
                else if(s1_AWVALID && ~axi_wstart_locked3)
                    next_state = AXI_MASTER_1;
                else if(s2_AWVALID && ~axi_wstart_locked3)
                    next_state = AXI_MASTER_2;
                else
                    next_state = AXI_MASTER_3;
            end
            default:
                next_state = AXI_MASTER_0;
        endcase
    end


    //---------------------------------------------------------
    //更新状态寄存器
    always @(posedge ACLK, negedge ARESETn)begin
        if(!ARESETn)
            state <= AXI_MASTER_0;
        else
            state <= next_state;
    end

    //---------------------------------------------------------
    //利用状态寄存器控制输出结果
    always @(*) begin
        case (state)
            AXI_MASTER_0: {s0_wgrnt,s1_wgrnt,s2_wgrnt,s3_wgrnt} = 4'b1000;
            AXI_MASTER_1: {s0_wgrnt,s1_wgrnt,s2_wgrnt,s3_wgrnt} = 4'b0100;
            AXI_MASTER_2: {s0_wgrnt,s1_wgrnt,s2_wgrnt,s3_wgrnt} = 4'b0010;
            AXI_MASTER_3: {s0_wgrnt,s1_wgrnt,s2_wgrnt,s3_wgrnt} = 4'b0001;
            default:      {s0_wgrnt,s1_wgrnt,s2_wgrnt,s3_wgrnt} = 4'b0000;
        endcase
    end

endmodule