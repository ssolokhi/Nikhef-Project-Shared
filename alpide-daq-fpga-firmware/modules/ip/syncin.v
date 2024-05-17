module syncin(
  input  clk_i ,
  input  rst_i ,
  input  pin_i ,
  output data_o
);

reg pin_synced_r;
reg pin_synced_rr;
always @(posedge clk_i)
  if (rst_i) begin
    pin_synced_r <=0; // TODO: defaults!
    pin_synced_rr<=0;
  end else begin
    pin_synced_r <=pin_i;
    pin_synced_rr<=pin_synced_r;
  end

assign data_o=pin_synced_rr;

endmodule

