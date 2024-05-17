module data_fifo #(
  parameter N   =1024
)(
  input         clk_i           ,
  input         rst_i           ,
  input  [32:0] data_i          ,
  output [32:0] data_o          ,
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
  .clock       (clk_i           ),
  .sclr        (rst_i           ),
  .data        (data_i          ),
  .q           (data_o          ),
  .wrreq       (we_i            ),
  .rdreq       (re_i            ),
  .empty       (empty_o         ),
  .full        (full_o          )
);

endmodule

