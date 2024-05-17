module alpideio(
  input  clk_i      ,
  output reg alpide_phase_o, // internal reg (compensate for IOreg)
  input  oe_i       ,
  input  rst_i      , // TODO: naming
  input  forcezero_i,
  input  dctrl_i    ,
  input  dctrl_oe_i ,
  output reg mclk_o     , // TODO: ensure IOreg
  output reg mclk_oe_o  , // TODO: ensure IOreg
  output pordis_n_o ,
  output rst_n_o    ,
  output dctrl_o    ,
  output dctrl_oe_o
);

reg alpide_clk;
always @(posedge clk_i) alpide_clk<=~alpide_clk;
always @(posedge clk_i) begin 
  mclk_o        <=forcezero_i?1'b0:alpide_clk;
  mclk_oe_o     <=oe_i;
  alpide_phase_o<=alpide_clk;
end

assign pordis_n_o=0;
assign rst_n_o   =forcezero_i||!oe_i?1'b0:~rst_i;
assign dctrl_oe_o=oe_i&dctrl_oe_i;
assign dctrl_o   =forcezero_i?1'b0:dctrl_i;

endmodule

