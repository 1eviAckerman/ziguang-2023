module xiaodou_top(
         input          clk     ,
         input          rst      ,
         input [6:0]    key_in      ,

         output [6:0]   key_flag 
   );

   xiaodou u0(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[0]),
      .key_flag   (key_flag[0])
    );

xiaodou u1(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[1]),
      .key_flag   (key_flag[1])
    );

xiaodou u2(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[2]),
      .key_flag   (key_flag[2])
    );

xiaodou u3(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[3]),
      .key_flag   (key_flag[3])
    );

xiaodou u4(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[4]),
      .key_flag   (key_flag[4])
);

xiaodou u5(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[5]),
      .key_flag   (key_flag[5])
);

xiaodou u6(
      .clk        (sys_clk),
      .rst        (sys_rst_n),
      .key_in     (key_in[6]),
      .key_flag   (key_flag[6])
);
endmodule