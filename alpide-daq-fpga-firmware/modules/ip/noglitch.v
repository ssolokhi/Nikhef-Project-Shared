module noglitch(
  input  clk_i ,
  input  rst_i ,
  input  data_i,
  output data_o
);

reg data_synced_r;
always @(posedge clk_i)
  if(rst_i) data_synced_r<=0;     //TODO: configurable default
  else      data_synced_r<=data_i;
assign data_o=data_synced_r;

endmodule

