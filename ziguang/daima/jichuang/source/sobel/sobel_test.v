module sobel_test
(
    input   clk,    
    input   rst_n, 
    input  [20:0] threshold,
    
   
    input        ycbcr_vs, //预图像数据列有效信号  
    input        ycbcr_hs,  //预图像数据行有效信号  
    input        ycbcr_de, //预图像数据输入使能效信号
    input [7:0]  ycbcr_y, 
        
    output       sobel_vs, //处理后的图像数据列有效信号  
    output       sobel_hs,  //处理后的图像数据行有效信号  
    output       sobel_de, //处理后的图像数据输出使能效信号
    output     [7:0]  sobel_data    
   
);
 
reg [9:0]  Gx_temp2; //第三列值
reg [9:0]  Gx_temp1; //第一列值
reg [9:0]  Gx_data;  
reg [9:0]  Gy_temp1; //第一行值
reg [9:0]  Gy_temp2; //第三行值
reg [9:0]  Gy_data;  
reg [20:0] Gxy_square;
reg [8:0]  ycbcr_vs_r;
reg [8:0]  ycbcr_hs_r; 
reg [8:0]  ycbcr_de_r;


wire        matrix_vs; 
wire        matrix_hs;  
wire        matrix_de; 


wire [7:0]  matrix_p11; 
wire [7:0]  matrix_p12; 
wire [7:0]  matrix_p13; 
wire [7:0]  matrix_p21; 
wire [7:0]  matrix_p22; 
wire [7:0]  matrix_p23;
wire [7:0]  matrix_p31; 
wire [7:0]  matrix_p32; 
wire [7:0]  matrix_p33;

assign sobel_vs = ycbcr_vs_r[8];
assign sobel_hs  = ycbcr_hs_r[8] ;
assign sobel_de = ycbcr_de_r[8];
assign sobel_data     = sobel_hs ? sobel_data_r : 8'h00;


Matrix_3X3  Matrixe_3X3_m0 (
    .clk(clk),                // input
    .matrix_de(matrix_de),    // output
    .matrix_hs(matrix_hs),    // output
    .matrix_vs(matrix_vs),    // output
    .rst_n(rst_n),            // input
    .ycbcr_de(ycbcr_de),      // input
    .ycbcr_hs(ycbcr_hs),      // input
    .ycbcr_vs(ycbcr_vs),      // input
    .matrix_p11(matrix_p11),  // output[7:0] 
    .matrix_p12(matrix_p12),  // output[7:0] 
    .matrix_p13(matrix_p13),  // output[7:0] 
    .matrix_p21(matrix_p21),  // output[7:0] 
    .matrix_p22(matrix_p22),  // output[7:0] 
    .matrix_p23(matrix_p23),  // output[7:0] 
    .matrix_p31(matrix_p31),  // output[7:0] 
    .matrix_p32(matrix_p32),  // output[7:0] 
    .matrix_p33(matrix_p33),  // output[7:0] 
    .ycbcr_y(ycbcr_y)        // input[7:0]
);
//Gx  -1  0  +1     Gy  +1  +2  +1      P  P11  P12  P13
//    -2  0  +2          0   0   0         P21  P22  P23
//    -1  0  +1         -1  -2  -1         P31  P32  P33
//
//|Gx| = |(P13+2*P23+P33)-(P11+2*P21+P31)|
//|Gy| = |(P11+2*P12+P13)-(P31+2*P32+P33)|
//|G| = |Gx|+ |Gy| 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Gy_temp1 <= 10'd0;
        Gy_temp2 <= 10'd0;
        Gy_data <=  10'd0;
    end
    else begin
        Gy_temp1 <= matrix_p13 + (matrix_p23 << 1) + matrix_p33; 
        Gy_temp2 <= matrix_p11 + (matrix_p21 << 1) + matrix_p31; 
        Gy_data <= (Gy_temp1 >= Gy_temp2) ? (Gy_temp1 - Gy_temp2) : 
                   (Gy_temp2 - Gy_temp1);
    end
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Gx_temp1 <= 10'd0;
        Gx_temp2 <= 10'd0;
        Gx_data <=  10'd0;
    end
    else begin
        Gx_temp1 <= matrix_p11 + (matrix_p12 << 1) + matrix_p13; 
        Gx_temp2 <= matrix_p31 + (matrix_p32 << 1) + matrix_p33; 
        Gx_data <= (Gx_temp1 >= Gx_temp2) ? (Gx_temp1 - Gx_temp2) : 
                   (Gx_temp2 - Gx_temp1);
    end
end



always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        Gxy_square <= 21'd0;
    else
        Gxy_square <= Gx_data + Gy_data;
end


reg [7:0]sobel_data_r;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
       sobel_data_r <= 8'b0; 
    else if(Gxy_square >= threshold)
        sobel_data_r <= 8'h00; 
    else
        sobel_data_r <= 8'hff; 
end

//延迟9个周期同步
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ycbcr_vs_r <= 0;
        ycbcr_hs_r <= 0;
        ycbcr_de_r <= 0;
    end
    else begin
        ycbcr_vs_r  <=  {ycbcr_vs_r[7:0],matrix_vs};
        ycbcr_hs_r  <=  {ycbcr_hs_r[7:0],matrix_hs};
        ycbcr_de_r  <=  {ycbcr_de_r[7:0],matrix_de};
    end
end
endmodule 