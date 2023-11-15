module AXI_Master_Mux_W#(
    parameter                           DATA_WIDTH  = 256          ,
    parameter                           ADDR_WIDTH  = 32           ,
    parameter                           ID_WIDTH    = 4             
)(
    /********** 0号主控 **********/
    //写地址通道
    input              [ID_WIDTH-1:0]   s0_AWID                    ,
    input              [ADDR_WIDTH-1:0] s0_AWADDR                  ,
    input              [   7:0]         s0_AWLEN                   ,
    input                               s0_AWVALID                 ,
    output reg                          s0_AWREADY                 ,
    //写数据通道
    input              [DATA_WIDTH-1:0] s0_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s0_WSTRB                   ,
    output reg                          s0_WREADY                  ,
    /********** 1号主控 **********/
    //写地址通道
    input              [ID_WIDTH-1:0]   s1_AWID                    ,
    input              [ADDR_WIDTH-1:0] s1_AWADDR                  ,
    input              [   7:0]         s1_AWLEN                   ,
    input                               s1_AWVALID                 ,
    output reg                          s1_AWREADY                 ,
    //写数据通道
    input              [DATA_WIDTH-1:0] s1_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s1_WSTRB                   ,
    output reg                          s1_WREADY                  ,
    /********** 2号主控 **********/
	//写地址通道
    input              [ID_WIDTH-1:0]   s2_AWID                    ,
    input              [ADDR_WIDTH-1:0] s2_AWADDR                  ,
    input              [   7:0]         s2_AWLEN                   ,
    input                               s2_AWVALID                 ,
    output reg                          s2_AWREADY                 ,
    //写数据通道
    input              [DATA_WIDTH-1:0] s2_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s2_WSTRB                   ,
    output reg                          s2_WREADY                  ,
    /********** 3号主控 **********/
	//写地址通道
    input              [ID_WIDTH-1:0]   s3_AWID                    ,
    input              [ADDR_WIDTH-1:0] s3_AWADDR                  ,
    input              [   7:0]         s3_AWLEN                   ,
    input                               s3_AWVALID                 ,
    output reg                          s3_AWREADY                 ,
    //写数据通道
    input              [DATA_WIDTH-1:0] s3_WDATA                   ,
    input              [(DATA_WIDTH/8)-1:0]s3_WSTRB                   ,
    output reg                          s3_WREADY                  ,
    /******** 从机信号 ********/
    //写地址通道
    output reg         [   3:0]         axi_awuser_id              ,
    output reg         [28-1:0]         axi_awaddr                 ,
    output reg         [   3:0]         axi_awlen                  ,
    output reg                          axi_awvalid                ,
    input                               axi_awready                ,
    //写数据通道
    output reg         [32*8-1:0]       axi_wdata                  ,
    output reg         [32-1:0]         axi_wstrb                  ,
    input                               axi_wready                 ,
    
    input                               s0_wgrnt                   ,
    input                               s1_wgrnt                   ,
    input                               s2_wgrnt                   ,
    input                               s3_wgrnt                    
);

always @(*) begin
    case({s0_wgrnt,s1_wgrnt, s2_wgrnt, s3_wgrnt})                   //判断写入通路的仲裁结果
        4'b1000: begin
            axi_awuser_id      =  s0_AWID;
            axi_awaddr    =  s0_AWADDR;
            axi_awlen     =  s0_AWLEN[3:0];
            axi_wdata     =  s0_WDATA;
            axi_wstrb     =  s0_WSTRB;
            axi_awvalid   =  s0_AWVALID;
        end
        4'b0100: begin
            axi_awuser_id      =  s1_AWID;
            axi_awaddr    =  s1_AWADDR;
            axi_awlen     =  s1_AWLEN[3:0];
            axi_wdata     =  s1_WDATA;
            axi_wstrb     =  s1_WSTRB;
            axi_awvalid   =  s1_AWVALID;
        end
        4'b0010: begin
            axi_awuser_id      =  s2_AWID;
            axi_awaddr    =  s2_AWADDR;
            axi_awlen     =  s2_AWLEN[3:0];
            axi_wdata     =  s2_WDATA;
            axi_wstrb     =  s2_WSTRB;
            axi_awvalid   =  s2_AWVALID;
        end
        4'b0001: begin
            axi_awuser_id      =  s3_AWID;
            axi_awaddr    =  s3_AWADDR;
            axi_awlen     =  s3_AWLEN[3:0];
            axi_wdata     =  s3_WDATA;
            axi_wstrb     =  s3_WSTRB;
            axi_awvalid   =  s3_AWVALID;
        end
        default: begin
            axi_awuser_id      =  0;
            axi_awaddr    =  0;
            axi_awlen     =  0;
            axi_wdata     =  0;
            axi_wstrb     =  0;
            axi_awvalid   =  0;
        end
    endcase
end

//AWREADY信号复用
always @(*) begin
    case({s0_wgrnt,s1_wgrnt, s2_wgrnt, s3_wgrnt})
        4'b1000: begin
            s0_AWREADY = axi_awready;
            s1_AWREADY = 0;
            s2_AWREADY = 0;
            s3_AWREADY = 0;
        end
        4'b0100: begin
            s0_AWREADY = 0;
            s1_AWREADY = axi_awready;
            s2_AWREADY = 0;
            s3_AWREADY = 0;
        end
        4'b0010: begin
            s0_AWREADY = 0;
            s1_AWREADY = 0;
            s2_AWREADY = axi_awready;
            s3_AWREADY = 0;
        end
        4'b0001: begin
            s0_AWREADY = 0;
            s1_AWREADY = 0;
            s2_AWREADY = 0;
            s3_AWREADY = axi_awready;
        end
        default: begin
            s0_AWREADY = 0;
            s1_AWREADY = 0;
            s2_AWREADY = 0;
            s3_AWREADY = 0;
        end
    endcase
end

//WREADY信号复用
always @(*) begin
    case({s0_wgrnt,s1_wgrnt, s2_wgrnt, s3_wgrnt})
        4'b1000: begin
            s0_WREADY = axi_wready;
            s1_WREADY = 0;
            s2_WREADY = 0;
            s3_WREADY = 0;
        end
        4'b0100: begin
            s0_WREADY = 0;
            s1_WREADY = axi_wready;
            s2_WREADY = 0;
            s3_WREADY = 0;
        end
        4'b0010: begin
            s0_WREADY = 0;
            s1_WREADY = 0;
            s2_WREADY = axi_wready;
            s3_WREADY = 0;
        end
        4'b0001: begin
            s0_WREADY = 0;
            s1_WREADY = 0;
            s2_WREADY = 0;
            s3_WREADY = axi_wready;
        end
        default: begin
            s0_WREADY = 0;
            s1_WREADY = 0;
            s2_WREADY = 0;
            s3_WREADY = 0;
        end
    endcase
end

endmodule