module hdmi_gray_test( 
    
input wire              sys_clk         ,// input system clock 50MHz 4
input                   init_over       ,
input                   pixclk_in       , 
input                   key_flag        ,
input                   vs_in           , 
input                   hs_in           , 
input                   de_in           ,
input   [7:0]           r_in            , 
input   [7:0]           g_in            , 
input   [7:0]           b_in            , 


output                  pixclk_out      ,
output reg              vs_out          , 
output reg              hs_out          , 
output reg              de_out          , 
output reg      [7:0]   r_out           , 
output reg      [7:0]   g_out           , 
output reg      [7:0]   b_out           
);

assign      pixclk_out      =       pixclk_in;

reg [7:0]   gray    ;
reg [7:0]   value   ;
reg         vs_temp0;
reg         hs_temp0;
reg         de_temp0;
reg         vs_temp1;
reg         hs_temp1;
reg         de_temp1;

reg  [3:0]  cnt     ;

always @(posedge pixclk_out)begin
    if(!init_over)
        cnt     <=  4'd0;
    else if(key_flag)
        cnt     <=  cnt + 1'b1;
    else
        cnt     <=  cnt;
    end

always @(posedge pixclk_out)begin
    if(!init_over)
        gray    <=  8'd0;
    else 
        gray    <=  (r_in*306 + g_in*601 + b_in*117)>>10 - cnt;
end

always @(posedge pixclk_out) begin
    vs_temp0        <=  vs_in       ;
    hs_temp0        <=  hs_in       ;
    de_temp0        <=  de_in       ;
    vs_temp1        <=  vs_temp0    ;
    hs_temp1        <=  hs_temp0    ;
    de_temp1        <=  de_temp0    ;
end

always @(posedge pixclk_out) begin
    if(!init_over)begin
        vs_out  <=  1'b0;  
        hs_out  <=  1'b0;
        de_out  <=  1'b0;
        r_out   <=  1'b0;
        g_out   <=  1'b0;
        b_out   <=  1'b0;
    end
    else begin
        vs_out  <= vs_temp0;
        hs_out  <= hs_temp0;
        de_out  <= de_temp0;
        r_out   <= gray;
        g_out   <= gray;
        b_out   <= gray;
    end
end

endmodule