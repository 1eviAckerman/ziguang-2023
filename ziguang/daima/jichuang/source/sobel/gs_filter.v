/*
F(x,y): (x,y) 点的像素值
G(x,y): (x,y)点经过高斯滤波处理后的值
1. 用模板（或称卷积，掩膜）确定邻域像素的加权平均灰度值代替原中心像素点的值
G(x,y)=(1/16)*(f(x-1,y-1)+2*f(x,y-i)+f(x+1,y-1)+2f(x-1,y)+4f(x,y)+2f(x+1,y)+f(x-1,y+1)+2f(x,y+1)+f(x+1,y+1))
2. 用高斯滤波模板扫描图像的每一个像素

*/
module gs_filter(
	input				clk,
	input				rst_n,
	input		[7:0]	ycbcr_y,//输入像素
	input				ycbcr_de,//LCD显示区使能信号
	input				ycbcr_hs,
	input				ycbcr_vs,	
	output	reg	[7:0]	gauss_data,//输出高斯滤波处理后的像素
	output	wire		gauss_de,
	output	wire		gauss_hs,
	output	wire		gauss_vs
);

	reg	[7:0]	r0;
	wire	[7:0]	r1;
	wire	[7:0]	r2;

	reg	[7:0]	r0_c0;	
	reg	[7:0]	r0_c1;	
	reg	[7:0]	r0_c2;
	
	reg	[7:0]	r1_c0;	
	reg	[7:0]	r1_c1;	
	reg	[7:0]	r1_c2;
	
	reg	[7:0]	r2_c0;	
	reg	[7:0]	r2_c1;	
	reg	[7:0]	r2_c2;	

reg  [1:0]  ycbcr_vs_r;
reg  [1:0]  ycbcr_hs_r;
reg  [1:0]  ycbcr_de_r;
			
	reg	[31:0]	guass_add;
	reg	[31:0]	guass_reg0;
	reg	[31:0]   guass_reg1;
	reg	[31:0]   guass_reg2;
	
//----3行像素缓存-----------------------------------------
//	shifter3_3	shifter3_3(
//		.clken(data_in_en),
//		.clock(clk),
//		.shiftin(data_in),
//		.shiftout(),
//		.taps0x(r0),
//		.taps1x(r1),
//		.taps2x(r2)
//	);
//

line_shift  line_Shift_m1
(
    .clk          (clk),
    .ycbcr_de       (ycbcr_de),
    .ycbcr_hs       (ycbcr_hs),
    
    .shiftin        (ycbcr_y),   
    .rd_data0         (r1),   
    .rd_data1         (r2)    
);

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        r0 <= 0;
    else begin
        if(ycbcr_de_r[0])
            r0 <= ycbcr_y ;
        else
            r0 <= r0;
    end
end


//-------------------------------------------------------
//----3*3 matrix from image------------------------------
//----r0---------------------------------------------
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			r0_c0	<=	16'd0;
			r0_c1	<=	16'd0;
			r0_c2	<=	16'd0;	
			r1_c0	<=	16'd0;
			r1_c1	<=	16'd0;
			r1_c2	<=	16'd0;
			r2_c0	<=	16'd0;
			r2_c1	<=	16'd0;
			r2_c2	<=	16'd0;			
		end
		else if(ycbcr_de)begin
			r0_c0	<=	r0;
			r0_c1	<=	r0_c0;
			r0_c2	<=	r0_c1;
	
			r1_c0	<=	r1;
			r1_c1	<=	r1_c0;
			r1_c2	<=	r1_c1;	

			r2_c0	<=	r2;
			r2_c1	<=	r2_c0;
			r2_c2	<=	r2_c1;		
		end
	end

assign gauss_de = ycbcr_de_r[1];
assign gauss_hs = ycbcr_hs_r[1];
assign gauss_vs = ycbcr_vs_r[1];

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ycbcr_vs_r <= 0;
        ycbcr_hs_r  <= 0;
        ycbcr_de_r <= 0;
    end
    else begin
        ycbcr_vs_r <= { ycbcr_vs_r[0],ycbcr_vs };
        ycbcr_hs_r  <= { ycbcr_hs_r[0],ycbcr_hs };
        ycbcr_de_r <= { ycbcr_de_r[0],ycbcr_de};
    end
end

//-------------------------------------------------------
//----guass filter---------------------------------------
/*
|(x-1,y-1)，(x,y-1)，(x+1,y-1) |        |r0_c0，r0_c1，r0_c2 |
|  (x-1,y)，  (x,y)， (x+1,y)  |  <-->  |r1_c0，r1_c1，r1_c2 |
|(x-1,y+1)，(x,y+1)，(x+1,y+1) |        |r2_c0，r2_c1，r2_c2 |


高斯滤波公式：G(x,y)=(1/16)*(f(x-1,y-1)+2*f(x,y-1)+f(x+1,y-1)+
									2f(x-1,y)+4f(x,y)+2f(x+1,y)+
									f(x-1,y+1)+2f(x,y+1)+f(x+1,y+1))
*/

	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			guass_reg0	<=	32'd0;
			guass_reg1	<=	32'd0;
			guass_reg2	<=	32'd0;
		end
		else if(ycbcr_de_r[0])begin
			guass_reg0	<=	r0_c0+2*r0_c1+r0_c2;
			guass_reg1	<=	2*r1_c0+4*r1_c1+2*r1_c2;
			guass_reg2	<=	r2_c0+2*r2_c1+r2_c2;
		end
		else;
	end

	always@(posedge clk or negedge rst_n)
		if(!rst_n)
			guass_add	<=	32'd0;
		else if(ycbcr_de_r[0])
			guass_add	<= guass_reg0 + guass_reg1 +guass_reg2;
		else;
	
	always@(posedge clk or negedge rst_n)
		if(!rst_n)
			gauss_data	<=	8'd0;
		else if(ycbcr_de_r[0])
			gauss_data	<= guass_add >>4;

endmodule

