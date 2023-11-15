module  Matrix_3X3
(
    input            clk,  
    input            rst_n,
         
    input            ycbcr_vs,
    input            ycbcr_hs,
    input            ycbcr_de,
    input [7:0]      ycbcr_y,
    
    output           matrix_vs,
    output           matrix_hs,
    output           matrix_de,
    output reg [7:0] matrix_p11,
    output reg [7:0] matrix_p12, 
    output reg [7:0] matrix_p13,
    output reg [7:0] matrix_p21, 
    output reg [7:0] matrix_p22, 
    output reg [7:0] matrix_p23,
    output reg [7:0] matrix_p31, 
    output reg [7:0] matrix_p32, 
    output reg [7:0] matrix_p33
);


wire [7:0] row1_data;  
wire [7:0] row2_data;  
wire       read_vs;
wire       read_de;


reg  [7:0]  row3_data;  
reg  [1:0]  ycbcr_vs_r;
reg  [1:0]  ycbcr_hs_r;
reg  [1:0]  ycbcr_de_r;



assign read_vs    = ycbcr_hs_r[0] ;
assign read_de   = ycbcr_de_r[0];
assign matrix_vs = ycbcr_vs_r[1];
assign matrix_hs  = ycbcr_hs_r[1] ;
assign matrix_de = ycbcr_de_r[1];


always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        row3_data <= 0;
    else begin
        if(ycbcr_de)
            row3_data <= ycbcr_y ;
        else
            row3_data <= row3_data ;
    end
end


//line_shift  line_Shift_m0
//(
//    .clk          (clk),
//    .ycbcr_de       (ycbcr_de),
//    //.ycbcr_hs       (ycbcr_hs),
//    
//    .shiftin        (ycbcr_y),   
//    .taps0x         (row2_data),   
//    .taps1x         (row1_data)    
//);

line_shift line_Shift_m0 (
    .clk(clk), 
    .rst_n(rst_n),           // input
    .ycbcr_de(ycbcr_de),  // input
    .rd_data0(row2_data),  // output[7:0] 
    .rd_data1(row1_data),  // output[7:0] 
    .shiftin(ycbcr_y)    // input[7:0]
);
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


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        {matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
    end
    else if(read_vs) begin
        if(read_de) begin
            {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p12, matrix_p13, row1_data};
            {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p22, matrix_p23, row2_data};
            {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p32, matrix_p33, row3_data};
        end
        else begin
            {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p11, matrix_p12, matrix_p13};
            {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p21, matrix_p22, matrix_p23};
            {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p31, matrix_p32, matrix_p33};
        end	
    end
    else begin
        {matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
    end
end

endmodule 