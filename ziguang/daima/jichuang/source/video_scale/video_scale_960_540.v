`timescale 1ns / 1ps

module video_scale_960_540(
    
    input                               pixclk_in                  ,
    input              [   9:0]         cnt_x                      ,
    input              [   9:0]         cnt_y                      ,
    input                               vs_in                      ,
    input                               hs_in                      ,
    input                               de_in                      ,
    input              [   7:0]         r_in                       ,
    input              [   7:0]         g_in                       ,
    input              [   7:0]         b_in                       ,

    output                              pixclk_out                 ,
    output                              vs_out                     ,
    output reg                          hs_out                     ,
    output reg                          de_out                     ,
    output             [  31:0]         wr_data                     

);
///////////////////////////////////////////////////////
reg                    [   7:0]         r_out                      ;
reg                    [   7:0]         g_out                      ;
reg                    [   7:0]         b_out                      ;

wire                    [12:0]       vin_xres    =1920          ;
wire                    [12:0]       vin_yres    =1080          ;

wire                    [   9:0]         vout_xres                  ;
wire                    [   9:0]         vout_yres                  ;

assign  vout_xres   = 10'd960 - cnt_x;
assign  vout_yres   = 10'd540 - cnt_y;
     
 
assign pixclk_out   =  pixclk_in    ;
assign vs_out       =  vs_in;
assign wr_data      =  {8'b0,r_out,g_out,b_out};
///////////////////////////////////////////////////////////////
wire                    [  31:0]         scaler_height;//��ֱ����ϵ����[31:16]��16λ����������16λ��С��
wire                    [  31:0]         scaler_width;//ˮƽ����ϵ����[31:16]��16λ����������16λ��С��
assign                                   scaler_height	=   ((vin_yres << 16 )/vout_yres) + 1;
assign                                   scaler_width	=   ((vin_xres << 16 )/vout_xres) + 1;	
reg                    [  15:0]         vin_x			= 0                ;//������Ƶˮƽ����
reg                    [  15:0]         vin_y			= 0                ;//������Ƶ��ֱ����
reg                    [  31:0]         vout_x			= 0               ;//�����Ƶˮƽ����,��������,[31:16]��16λ����������
reg                    [  31:0]         vout_y			= 0               ;//�����Ƶ��ֱ����,��������,[31:16]��16λ����������
always@(posedge pixclk_in)
begin                                                               //������Ƶˮƽ�����ʹ�ֱ�����������ظ���������
    if(vs_in )begin
        vin_x            <= 0;
        vin_y            <= 0;
    end
    else if (de_in == 1 )begin                                      //��ǰ������Ƶ������Ч
        if( vin_x < vin_xres -1 )begin                              //vin_xres = ������Ƶ����
            vin_x    <= vin_x + 1;
        end
        else begin
            vin_x        <= 0;
            vin_y        <= vin_y + 1;
        end
    end
end                                                                 //always

always@(posedge pixclk_in)
begin                                                               //�ٽ���С�㷨�����Ǽ����Ҫ���������ر����������������������������ص�ˮƽ����ʹ�ֱ����
    if(vs_in)begin
        vout_x        <= 0;
        vout_y        <= 0;
    end
    else if (de_in == 1 )begin                                      //��ǰ������Ƶ������Ч
        if(vin_x < vin_xres -1)begin                                //vin_xres = ������Ƶ����
            if (vout_x[31:16] <= vin_x)begin                        //[31:16]��16λ����������
                vout_x    <= vout_x + scaler_width;                 //vout_x ��Ҫ���������ص� x ����
            end
        end
        else begin
            vout_x        <= 0;
            if (vout_y[31:16] <= vin_y)begin                        //[31:16]��16λ����������
                vout_y    <= vout_y + scaler_height;                //vout_y ��Ҫ���������ص� y ����
            end
        end
    end
end                                                                 //	always
//vin_x,vin_y һֱ�ڱ仯������������Ƶ��ɨ�裬һ����һ���еı仯
//�� vin_x == vout_x && vin_y == vout_y �õ����ر�����������������õ����ء�
always@(posedge pixclk_in)
begin
    if(vs_in)begin
	  
        hs_out       <=  0   ;
        de_out       <=  0   ;
        r_out        <=  0   ;
        g_out        <=  0   ;
        b_out        <=  0   ;
    end
    else begin                                                      //��ǰ������Ƶ������Ч
        if(vout_x[31:16] == vin_x && vout_y[31:16] == vin_y)begin   //[31:16]��16λ����������,�ж��Ƿ���������
				//�������Ч
        r_out        <=  r_in         ;
        g_out        <=  g_in         ;
        b_out        <=  b_in         ;
        hs_out       <=  hs_in        ;
        de_out       <=  de_in        ;
			//�õ����ر������
        end
        else begin
			
					//�������Ч�������õ����ء�
            r_out        <=  0        ;
            g_out        <=  0        ;
            b_out        <=  0        ;
            hs_out       <=  hs_in    ;
            de_out       <=  0        ;
        end
    end
end                                                                 //	always
	 
endmodule