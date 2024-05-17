module busmaster(
  input         clk_i      ,
  input         rst_i      ,

  output        in_empty_o ,
  output [31:0] in_data_o  ,
  output        in_pktend_o,
  input         in_re_i    ,
  output        out_full_o ,
  input  [31:0] out_data_i ,
  input         out_we_i   ,

  output [ 5:0] modaddr_o  ,
  output [ 7:0] regaddr_o  ,
  output [15:0] regdata_o  ,
  output        we_o       ,
  input  [15:0] regdata_i  
);

wire in_full  ;
wire in_we    ;
wire in_pktend;
bus_fifo_in fifo_in(
  .clk_i   (clk_i               ),
  .rst_i   (rst_i               ),
  .data_i  ({16'hDAD1,regdata_i}), // TODO: this is a bit wastefull
  .pktend_i(in_pktend           ),
  .data_o  (in_data_o           ),
  .pktend_o(in_pktend_o         ),
  .re_i    (in_re_i             ),
  .we_i    (in_we               ),
  .empty_o (in_empty_o          ),
  .full_o  (in_full             )
);

wire        out_empty;
wire [31:0] out_do   ;
wire        out_re   ;
bus_fifo_out fifo_out(
  .clk_i  (clk_i     ),
  .rst_i  (rst_i     ),
  .data_i (out_data_i),
  .data_o (out_do    ),
  .re_i   (out_re    ),
  .we_i   (out_we_i  ),
  .empty_o(out_empty ),
  .full_o (out_full_o)
);

wire cmd_read ;
wire cmd_write;
wire cmd_wait ;
wire cmd_readx;

reg [29:0] waitcnt;
always @(posedge clk_i)
       if(rst_i     ) waitcnt<=0           ;
  else if(cmd_wait  ) waitcnt<=out_do[29:0];
  else if(waitcnt!=0) waitcnt<=waitcnt-1'b1;

wire waiting;

wire cmd_re=(!out_empty && !in_full && !waiting);
reg  cmd_strb;
always @(posedge clk_i)
  if(rst_i) cmd_strb<=0     ;
  else      cmd_strb<=cmd_re;
assign out_re=cmd_re;

assign cmd_read =out_do[31:30]==2'b00 && cmd_strb;
assign cmd_write=out_do[31:30]==2'b10 && cmd_strb;
assign cmd_wait =out_do[31:30]==2'b01 && cmd_strb;
assign cmd_readx=out_do[31:30]==2'b11 && cmd_strb;

assign waiting=cmd_wait || waitcnt!=0;

assign      we_o=cmd_write;
assign modaddr_o=out_do[29:24];
assign regaddr_o=out_do[23:16];
assign regdata_o=out_do[15: 0];

assign in_we    =cmd_read||cmd_readx;
assign in_pktend=cmd_read           ; // TODO: ZLPs.

endmodule

