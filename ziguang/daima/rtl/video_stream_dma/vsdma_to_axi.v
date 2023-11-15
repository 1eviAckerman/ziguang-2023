
`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//
// File name            : vsdma_to_axi.v
// Created by           : guoraoliu           
// Last modified Date   : 2023/05/25
// Created date         : 2023/05/19  
// Descriptions         : vsdma_to_axi模块，用于将vsdma数据转换为axi接口标准数据       
//
//****************************************************************************************//

module vsdma_to_axi#
(
    parameter                           integer         M_AXI_ID_WIDTH			    = 4,
    parameter                           integer         M_AXI_ID			        = 0,
    parameter                           integer         M_AXI_ADDR_WIDTH			= 28,
    parameter                           integer         M_AXI_DATA_WIDTH			= 256,
    parameter                           integer		  	M_AXI_MAX_BURST_LEN       	= 16 
)
(
    input  wire        [M_AXI_ADDR_WIDTH-1 : 0]	vsdma_waddr                ,
    input                               		vsdma_wareq                ,
    input  wire        [  15:0]         		vsdma_wsize                ,
    output                              		vsdma_wbusy                ,
				
    input  wire        [M_AXI_DATA_WIDTH-1 :0]	vsdma_wdata                ,
    output wire                         		vsdma_wvalid               ,
    input  wire                         		vsdma_wready               ,

    input  wire        [M_AXI_ADDR_WIDTH-1 : 0]	vsdma_raddr                ,
    input                              			vsdma_rareq                ,
    input  wire        [  15:0]         		vsdma_rsize                ,
    output                              		vsdma_rbusy                ,
				
    output wire        [M_AXI_DATA_WIDTH-1 :0]	vsdma_rdata                ,
    output wire                         		vsdma_rvalid               ,
    input  wire                         		vsdma_rready               ,

    output reg                          		axi_wstart_locked          ,
    output reg                                  axi_rstart_locked          ,
		
    input  wire                         		M_AXI_ACLK                 ,
    input  wire                         		M_AXI_ARESETN              ,
    output wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_AWID                 ,
    output wire        [M_AXI_ADDR_WIDTH-1 : 0]	M_AXI_AWADDR               ,
    output wire        [   7:0]        			M_AXI_AWLEN                ,
    output wire                        			M_AXI_AWVALID              ,
    input  wire                         		M_AXI_AWREADY              ,
    output wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_WID                  ,
    output wire        [M_AXI_DATA_WIDTH-1 : 0]	M_AXI_WDATA                ,
    output wire        [M_AXI_DATA_WIDTH/8-1 : 0]M_AXI_WSTRB               ,
    output wire                         		M_AXI_WLAST                ,
    output wire                         		M_AXI_WVALID               ,
    input  wire                        			M_AXI_WREADY               ,
 
    output wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_ARID                 ,
    output wire        [M_AXI_ADDR_WIDTH-1 : 0]	M_AXI_ARADDR               ,
    output wire        [   7:0]         		M_AXI_ARLEN                ,
    output wire                         		M_AXI_ARVALID              ,
    input  wire                         		M_AXI_ARREADY              ,
	 
    input  wire        [M_AXI_ID_WIDTH-1 : 0]	M_AXI_RID                  ,
    input  wire        [M_AXI_DATA_WIDTH-1 : 0]	M_AXI_RDATA                ,
    output wire                         		M_AXI_RLAST                ,
    input  wire                         		M_AXI_RVALID               ,
    output wire                         		M_AXI_RREADY                
    );

//实现log2函数
function integer clogb2 (input integer bit_depth);
    begin
        bit_depth = bit_depth - 1;
        for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        	bit_depth = bit_depth >> 1;
    end
endfunction

localparam                              AXI_UNITS =  M_AXI_DATA_WIDTH/32;//单个AXI数据所需的地址单元数量
localparam             [   3:0]         MAX_BURST_LEN_SIZE = clogb2(M_AXI_MAX_BURST_LEN);
                                                    
//vsdma axi write----------------------------------------------
wire                                    		w_next      = (M_AXI_WVALID & M_AXI_WREADY);//当valid和ready信号都有效，代表AXI4数据传输有效
wire                   [M_AXI_DATA_WIDTH-1 : 0]	axi_wdata                  ;//AXI4写数据
wire                                    		axi_wlast                  ;//AXI4写LAST信号
reg                    [M_AXI_ADDR_WIDTH-1 : 0]	axi_awaddr	= 0            ;//AXI4写地址
reg                                     		axi_awvalid	= 1'b0         ;//AXI4写地址有效
reg                                     		axi_wvalid	= 1'b0         ;//AXI4写数据有效
reg                    [   8:0]         		wburst_len  = 1            ;//写传输的AXI突发传输长度
reg                    [   8:0]         		wburst_cnt  = 0            ;//AXI突发传输计数器
reg                    [  15:0]         		wvsdma_cnt  = 0            ;//vsdma写数据计数器
wire                   [  15:0]         		axi_wburst_size = wburst_len * AXI_UNITS;//AXI传输地址长度计算

assign axi_wdata        	= vsdma_wdata;
assign M_AXI_WID        	= 0;
assign M_AXI_AWID        	= M_AXI_ID;
assign M_AXI_AWADDR        	= axi_awaddr;
assign M_AXI_AWLEN        	= wburst_len - 1;
assign M_AXI_AWVALID        = axi_awvalid;
assign M_AXI_WDATA        	= axi_wdata;
assign M_AXI_WSTRB        	= {(32){1'b1}};
assign M_AXI_WLAST       	= axi_wlast;
assign M_AXI_WVALID        	= axi_wvalid & vsdma_wready;

//----------------------------------------------------------------------------	
//AXI4 FULL Write
wire                                    vsdma_wstart                ;
wire                                    vsdma_wend                  ;
reg                                     vsdma_wstart_locked = 1'b0  ;

assign  vsdma_wvalid      	= w_next;
assign  vsdma_wbusy 		= vsdma_wstart_locked ;
assign  vsdma_wstart 		= (vsdma_wstart_locked == 1'b0 && vsdma_wareq == 1'b1);

//整个vsdma传输过程vsdma_wstart_locked都将拉高，直至传输结束
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0 || vsdma_wend == 1'b1 )
        vsdma_wstart_locked <= 1'b0;
    else if(vsdma_wstart)
        vsdma_wstart_locked <= 1'b1;

//AXI4 write burst lenth busrt addr ------------------------------
/*当vsdma_wstart拉高时，代表一次新的vsdma传输，首先会把本次vsdma突发的的地址寄存到axi_awaddr作为
第一次AXI突发传输的地址，如果传输数据长度大于用户给定的最大突发数据量，那么当axi_wlast有效时，会自
动计算下次AXI的突发地址
*/
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)begin
        axi_awaddr <= 0;
    end
    else if(vsdma_wstart)
        axi_awaddr <= vsdma_waddr;
    else if(axi_wlast == 1'b1)
        axi_awaddr <= axi_awaddr + axi_wburst_size ;

//AXI4 write cycle -----------------------------------------------
reg                                     axi_wstart_locked_r1 = 1'b0;
reg                                     axi_wstart_locked_r2 = 1'b0;

always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        axi_wstart_locked_r1 <= 1'b0;
        axi_wstart_locked_r2 <= 1'b0;
    end
    else begin
        axi_wstart_locked_r1 <= axi_wstart_locked;
        axi_wstart_locked_r2 <= axi_wstart_locked_r1;
    end
end
//axi_wstart_locked拉高表示一次AXI突发传输正在进行
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)begin
        axi_wstart_locked <= 1'b0;
    end
    else if((vsdma_wstart_locked == 1'b1) &&  axi_wstart_locked == 1'b0)
        axi_wstart_locked <= 1'b1;
    else if(axi_wlast == 1'b1 || vsdma_wstart == 1'b1)
        axi_wstart_locked <= 1'b0;	    
//AXI4 addr valid and write addr-----------------------------------	
always @(posedge M_AXI_ACLK)
     if(M_AXI_ARESETN == 1'b0)begin
         axi_awvalid <= 1'b0;
     end
     else if((axi_wstart_locked_r1 == 1'b1) &&  axi_wstart_locked_r2 == 1'b0)
         axi_awvalid <= 1'b1;
     else if((axi_wstart_locked == 1'b1 && M_AXI_AWREADY == 1'b1)|| axi_wstart_locked == 1'b0)
         axi_awvalid <= 1'b0;
//AXI4 write data---------------------------------------------------		
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)begin
        axi_wvalid <= 1'b0;
	end
    else if((axi_wstart_locked_r1 == 1'b1) && (axi_wstart_locked_r2 == 1'b0))
        axi_wvalid <= 1'b1;
    else if(axi_wlast == 1'b1 || axi_wstart_locked == 1'b0)
        axi_wvalid <= 1'b0;                                         	
//AXI4 write data burst len counter----------------------------------
always @(posedge M_AXI_ACLK)
    if(axi_wstart_locked == 1'b0)
        wburst_cnt <= 0;
    else if(w_next)
        wburst_cnt <= wburst_cnt + 1'b1;

assign axi_wlast = (w_next == 1'b1) && (wburst_cnt == M_AXI_AWLEN);		   	
//vsdma write data burst len counter----------------------------------
reg                                     wburst_len_req = 1'b0      ;
reg                    [  15:0]         vsdma_wleft_cnt =16'd0     ;

//wburst_len_req是每次AXI突发传输长度的切换信号
always @(posedge M_AXI_ACLK)
    wburst_len_req <= vsdma_wstart|axi_wlast;

//vsdma_wleft_cnt用于记录一次vsdma传输剩余的数据总量。         
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)begin
        wvsdma_cnt <= 0;
        vsdma_wleft_cnt <= 0;
    end
    else if( vsdma_wstart )begin
        wvsdma_cnt <= 0;
        vsdma_wleft_cnt <= vsdma_wsize;
    end
    else if(w_next)begin
        wvsdma_cnt <= wvsdma_cnt + 1'b1;
        vsdma_wleft_cnt <= (vsdma_wsize - 1'b1) - wvsdma_cnt;
    end

//vsdma传输最后一个数据时。产生vsdma_wend代表本次vsdma传输结束
assign  vsdma_wend = w_next && (vsdma_wleft_cnt == 1 );

//DDR3支持的最大突发长度为16，因此当突发长度大于16时，自动拆分成多次传输
always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        wburst_len <= 1;
    end
    else if(wburst_len_req)begin
        if(vsdma_wleft_cnt[15:MAX_BURST_LEN_SIZE] >0)
            wburst_len <= M_AXI_MAX_BURST_LEN;
        else
            wburst_len <= vsdma_wleft_cnt[MAX_BURST_LEN_SIZE-1:0];
    end
    else wburst_len <= wburst_len;
end

//vsdma axi read----------------------------------------------
wire                                    		r_next      = (M_AXI_RVALID && M_AXI_RREADY);
wire                                    		axi_rlast                  ;
reg                    [M_AXI_ADDR_WIDTH-1 : 0]	axi_araddr  = 0            ;
reg                                     		axi_arvalid = 1'b0         ;
reg                                     		axi_rready	= 1'b0         ;
reg                    [   8:0]         		rburst_len  = 1            ;
reg                    [   8:0]         		rburst_cnt  = 0            ;
reg                    [  15:0]         		rvsdma_cnt	= 0            ;
wire                   [  15:0]        			axi_rburst_size = rburst_len * AXI_UNITS;

assign M_AXI_ARID        	= M_AXI_ID;
assign M_AXI_ARADDR       	= axi_araddr;
assign M_AXI_ARLEN        	= rburst_len - 1;
assign M_AXI_ARVALID        = axi_arvalid;
assign M_AXI_RREADY        	= axi_rready && vsdma_rready;
assign M_AXI_RLAST      	= axi_rlast;                                
assign vsdma_rdata       	= M_AXI_RDATA;
assign vsdma_rvalid      	= r_next;

//AXI4 FULL Read----------------------------------------- 	
wire                                    vsdma_rstart                ;
wire                                    vsdma_rend                  ;
reg                                     vsdma_rstart_locked = 1'b0  ;

assign vsdma_rbusy = vsdma_rstart_locked ;
assign vsdma_rstart = (vsdma_rstart_locked == 1'b0 && vsdma_rareq == 1'b1);

always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0 || vsdma_rend == 1'b1)
        vsdma_rstart_locked <= 1'b0;
    else if(vsdma_rstart)
        vsdma_rstart_locked <= 1'b1;

//AXI4 read burst lenth busrt addr ------------------------------
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)
        axi_araddr <= 0;
    else if(vsdma_rstart == 1'b1)
        axi_araddr <= vsdma_raddr;
    else if(axi_rlast == 1'b1)
        axi_araddr <= axi_araddr + axi_rburst_size ;
//AXI4 r_cycle_flag------------------------------------- 	
reg                                     axi_rstart_locked_r1 = 1'b0;
reg                                     axi_rstart_locked_r2 = 1'b0;

always @(posedge M_AXI_ACLK)begin
    if(M_AXI_ARESETN == 1'b0)begin
        axi_rstart_locked_r1 <= 1'b0;
        axi_rstart_locked_r2 <= 1'b0;
    end
    else begin
        axi_rstart_locked_r1 <= axi_rstart_locked;
        axi_rstart_locked_r2 <= axi_rstart_locked_r1;
    end
end
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)
        axi_rstart_locked <= 1'b0;
    else if((vsdma_rstart_locked == 1'b1) &&  axi_rstart_locked == 1'b0)
        axi_rstart_locked <= 1'b1;
    else if(axi_rlast == 1'b1 || vsdma_rstart == 1'b1)
        axi_rstart_locked <= 1'b0;
	    
//AXI4 addr valid and read addr-----------------------------------	
always @(posedge M_AXI_ACLK)
     if(M_AXI_ARESETN == 1'b0)
         axi_arvalid <= 1'b0;
     else if((axi_rstart_locked_r1 == 1'b1) &&  axi_rstart_locked_r2 == 1'b0)
         axi_arvalid <= 1'b1;
     else if((axi_rstart_locked == 1'b1 && M_AXI_ARREADY == 1'b1)|| axi_rstart_locked == 1'b0)
         axi_arvalid <= 1'b0;
//AXI4 read data---------------------------------------------------		
always @(posedge M_AXI_ACLK)
    if(M_AXI_ARESETN == 1'b0)
         axi_rready <= 1'b0;
    else if((axi_rstart_locked_r1 == 1'b1) &&  axi_rstart_locked_r2 == 1'b0)
        axi_rready <= 1'b1;
    else if(axi_rlast == 1'b1 || axi_rstart_locked == 1'b0)
        axi_rready <= 1'b0;                                         //	
		
//AXI4 read data burst len counter----------------------------------
always @(posedge M_AXI_ACLK)
    if(axi_rstart_locked == 1'b0)
        rburst_cnt <= 0;
    else if(r_next)
        rburst_cnt <= rburst_cnt + 1'b1;

assign axi_rlast = (r_next == 1'b1) && (rburst_cnt == M_AXI_ARLEN);
//vsdma read data burst len counter----------------------------------
reg                                     rburst_len_req = 1'b0      ;
reg                    [  15:0]         vsdma_rleft_cnt = 16'd0    ;
  
always @(posedge M_AXI_ACLK)
        rburst_len_req <= vsdma_rstart | axi_rlast;
        
always @(posedge M_AXI_ACLK)
	if(M_AXI_ARESETN == 1'b0)begin
        rvsdma_cnt <= 0;
        vsdma_rleft_cnt <=0;
    end
    else if(vsdma_rstart )begin
        rvsdma_cnt <= 0;
        vsdma_rleft_cnt <= vsdma_rsize;
    end
    else if(r_next)begin
        rvsdma_cnt <= rvsdma_cnt + 1'b1;
        vsdma_rleft_cnt <= (vsdma_rsize - 1'b1) - rvsdma_cnt;
    end

assign  vsdma_rend = r_next && (vsdma_rleft_cnt == 1 );
//axi auto burst len caculate-----------------------------------------

always @(posedge M_AXI_ACLK)begin
     if(M_AXI_ARESETN == 1'b0)begin
        rburst_len <= 1;
     end
     else if(rburst_len_req)begin
        if(vsdma_rleft_cnt[15:MAX_BURST_LEN_SIZE] >0)
            rburst_len <= M_AXI_MAX_BURST_LEN;
        else
            rburst_len <= vsdma_rleft_cnt[MAX_BURST_LEN_SIZE-1:0];
     end
     else rburst_len <= rburst_len;
end
					              		   
endmodule


