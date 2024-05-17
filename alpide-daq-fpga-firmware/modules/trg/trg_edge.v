module trg_edge(
  input      rst_i,
  input      clk_i,
  input      trg_i,
  output reg trg_o
);

//TODO: rst_i?

reg trg_i_r;
always @(posedge clk_i)
  trg_i_r<=trg_i;

assign trg_o=trg_i&&!trg_i_r;

endmodule
