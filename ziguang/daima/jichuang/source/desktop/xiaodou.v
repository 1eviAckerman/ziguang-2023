`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:37:41 04/04/2022 
// Design Name: 
// Module Name:    s 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module xiaodou(
	input	clk,
	input	rst,
	input	key_in,
	
	output	reg 	key_flag		//滤波后的信号（脉冲信号）
    );
	
		localparam
		IDEL	= 4'b0001,
		FILTER0	= 4'b0010,
		DOWN	= 4'b0100,
		FILTER1	= 4'b1000;
		
	reg [3:0] state;
	
	reg 	key_tem0;
	reg 	key_tem1;
	
	wire 	nedge;
	wire 	pedge;
	
	reg [19:0]	cnt;	//二十毫秒计数器
	reg			en_cnt;	//计数器使能信号
	reg 		cnt_full;//计数器记满信号
	
//边沿检测	
	always@(posedge clk or negedge rst) begin
		if(rst==0) begin
			key_tem0<=0;
			key_tem1<=0;
		end
		else begin
			key_tem0 <= key_in;
			key_tem1 <= key_tem0;
		end
	end
	
	assign	nedge = !key_tem0 & key_tem1;		//下降沿
	assign	pedge =  key_tem0 & (!key_tem1);	//上升沿
	
//一段式状态机
	always@(posedge clk or negedge rst )begin
	if(rst==0)  begin
		state <= IDEL;
		en_cnt <= 1'b0;
		key_flag<=1'd0;
	end
	else 
		case(state)
			IDEL:
				begin
					key_flag<=1'b0;
					if(nedge) begin
						state <=	FILTER0;
						en_cnt <= 1'b1; //计数器记数
					end
					else	
						state <=	IDEL;
				end
			FILTER0:
				if(cnt_full) begin
					state<= DOWN;
					en_cnt<=1'b0;
					key_flag<=1'b1;
				end
				else if(pedge) begin
					state<= IDEL;
					en_cnt <= 1'b0;
				end
				else
					state<= FILTER0;
			DOWN:
				begin
					key_flag<=1'b0;
					if(pedge)	begin
						state<=FILTER1;
						en_cnt<=1'b1;
					end
					else
						state<= DOWN;
				end
			FILTER1:
				if(cnt_full) begin
					state<= IDEL;
					en_cnt<=1'b0;
					key_flag<=1'b0;
				end
				else if(nedge) begin
					state<= DOWN;
					en_cnt <= 1'b0;
				end
				else
					state<= FILTER1;
			default: begin
				state<=IDEL;
				en_cnt<=1'b0;
				key_flag<=1'b0;
			end
		endcase		
	end
	
//二十毫秒计数器
	always@(posedge clk or negedge rst) begin
		if(rst==0)
			cnt <= 20'd0;
		else if(en_cnt)
			cnt <= cnt + 1'b1;
		else
			cnt<= 20'd0;
	end
	always@(posedge clk or negedge rst) begin
		if(rst==0)
			cnt_full <= 1'b0;
		else if(cnt == 'd999_999)
			cnt_full <= 1'b1;
		else
			cnt_full <= 1'b0;
	end
 
endmodule
