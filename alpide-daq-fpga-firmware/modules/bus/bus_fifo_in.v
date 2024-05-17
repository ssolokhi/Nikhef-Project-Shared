module bus_fifo_in #(
  parameter N   =128
)(
  input         clk_i           ,
  input         rst_i           ,
  input  [31:0] data_i          ,
  input         pktend_i        ,
  output [31:0] data_o          ,
  output        pktend_o        ,
  input         re_i            ,
  input         we_i            ,
  output        empty_o         ,
  output        full_o
);
scfifo #(
  .lpm_numwords           (N             ),
  .add_ram_output_register("OFF"         ),
  .intended_device_family ("Cyclone IV E"),
  .lpm_showahead          ("OFF"         ),
  .lpm_type               ("scfifo"      ),
  .lpm_width              (33            ),
  .overflow_checking      ("OFF"         ),
  .underflow_checking     ("OFF"         ),
  .use_eab                ("ON"          )
)fifo(
  .clock       (clk_i            ),
  .sclr        (rst_i            ),
  .data        ({pktend_i,data_i}),
  .q           ({pktend_o,data_o}),
  .wrreq       (we_i             ),
  .rdreq       (re_i             ),
  .empty       (empty_o          ),
  .full        (full_o           )
);

endmodule

