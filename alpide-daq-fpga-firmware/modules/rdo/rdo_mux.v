module rdo_mux(
  input             clk_i            ,
  input             rst_i            ,

  input             reg_we_i         ,
  input      [ 7:0] reg_addr_i       ,
  input      [15:0] reg_data_i       ,
  output reg [15:0] reg_data_o       ,

  input      [ 7:0] rdopar_data_i    ,
  input             rdopar_evtdone_i ,
  input             rdopar_we_i      ,
  input             rdopar_done_i    ,
  input      [ 7:0] rdoctrl_data_i   ,
  input             rdoctrl_evtdone_i,
  input             rdoctrl_we_i     ,
  input             rdoctrl_done_i   ,

  output     [ 7:0] rdo_data_o       ,
  output            rdo_evtdone_o    ,
  output            rdo_we_o         ,   
  output            rdo_done_o       
);

localparam [7:0] REGADDR_STATUS        =8'h00,
                 REGADDR_CTRL          =8'h01;

localparam [1:0] SEL_NONE=0,SEL_PAR=1,SEL_CTRL=2;
reg        [1:0] sel;

always @* begin
  case(sel)
    SEL_PAR :begin rdo_data_o=rdopar_data_i ;rdo_evtdone_o=rdopar_evtdone_i ;rdo_we_o=rdopar_we_i ;rdo_done_o=rdopar_done_i ;end
    SEL_CTRL:begin rdo_data_o=rdoctrl_data_i;rdo_evtdone_o=rdoctrl_evtdone_i;rdo_we_o=rdoctrl_we_i;rdo_done_o=rdoctrl_done_i;end
    default :begin rdo_data_o=8'hXX         ;rdo_evtdone_o=1'bX             ;rdo_we_o=0           ;rdo_done_o=1             ;end
  endcase
end

always @(posedge clk_i)
       if(rst_i                               ) sel<=SEL_NONE       ;
  else if(reg_addr_i==REGADDR_CTRL && reg_we_i) sel<=reg_data_i[1:0];

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS,
    REGADDR_CTRL  :reg_data_o={14'b0,sel};
    default       :reg_data_o=16'hF001   ;
  endcase

endmodule

