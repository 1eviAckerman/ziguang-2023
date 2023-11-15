module line_shift(
    input clk,
    input rst_n,
    input          ycbcr_de,
    input          ycbcr_hs,
    
    input   [7:0]  shiftin,  
    output  [7:0]  rd_data0,   
    output  [7:0]  rd_data1    
);

reg             wr_en0          ;
reg [8  -1:0]   wr_data0        ;
wire            rd_en0          ;
wire[8  -1:0]   rd_data0        ;
wire            almost_full0    ;
wire            almost_full1    ;
reg             wr_en1          ;
wire[8  -1:0]   wr_data1        ;
wire            rd_en1          ;
wire[8  -1:0]   rd_data1        ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_en0 <= 0;
    else
        wr_en0 <= ycbcr_de;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_data0 <= 0;
    else
        wr_data0 <= shiftin;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_en1 <= 0;
    else
        wr_en1 <= rd_en0;
end

assign wr_data1 = rd_data0;

assign rd_en0 = almost_full0 && wr_en0;
assign rd_en1 = almost_full1 && wr_en1;

fifo_shift          u_fifo_shift0   (
    .clk            (clk            ),
    .rst            (~rst_n         ),
    .wr_en          (wr_en0         ),
    .wr_data        (wr_data0       ),
    .wr_full        (               ),
    .almost_full    (almost_full0   ), // set this value to HOR_PIXELS-1
    .rd_en          (rd_en0         ),
    .rd_data        (rd_data0       ),
    .rd_empty       (               ),
    .almost_empty   (               )
);

fifo_shift          u_fifo_shift1   (
    .clk            (clk            ),
    .rst            (~rst_n         ),
    .wr_en          (wr_en1         ),
    .wr_data        (wr_data1       ),
    .wr_full        (               ),
    .almost_full    (almost_full1   ), // set this value to HOR_PIXELS-1
    .rd_en          (rd_en1         ),
    .rd_data        (rd_data1       ),
    .rd_empty       (               ),
    .almost_empty   (               )
);

endmodule 