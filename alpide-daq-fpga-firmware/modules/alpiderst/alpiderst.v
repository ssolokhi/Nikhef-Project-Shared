module alpiderst(
  input             clk_i       ,
  input             rst_i       ,
  input             reg_we_i    ,
  input      [ 7:0] reg_addr_i  ,
  input      [15:0] reg_data_i  ,
  output reg [15:0] reg_data_o  ,
  input             ldo_en_i    ,
  output reg        rst_o       ,
  output reg        forcezero_o ,
  output reg        oe_o        
);

// TODO: add software commands

localparam [7:0] REGADDR_STATUS=8'h00,
                 REGADDR_TRST  =8'h02,
                 REGADDR_TOEN  =8'h03,
                 REGADDR_TZERO =8'h04;

reg [15:0] trst_set ;
reg [15:0] trst     ;
reg [15:0] toen     ;
reg [15:0] toen_set ;
reg [15:0] tzero    ;
reg [15:0] tzero_set;
reg load;

always @(posedge clk_i)
       if(rst_i  ) trst<=16'hFFFF;
  else if(load   ) trst<=trst_set;
  else if(trst!=0) trst<=trst-1'b1;
always @(posedge clk_i)
       if(rst_i  ) toen<=16'hFFFF;
  else if(load   ) toen<=toen_set;
  else if(toen!=0) toen<=toen-1'b1;
always @(posedge clk_i)
       if(rst_i   ) tzero<=16'hFFFF;
  else if(load    ) tzero<=tzero_set;
  else if(tzero!=0) tzero<=tzero-1'b1;

reg [1:0] nextstate,state;
localparam [1:0] OFF=0,POWERING=1,ON=2;
always @(posedge clk_i)
  if   (rst_i) state<=OFF;
  else         state<=nextstate;

always @(*) begin
  nextstate=state;
  case(state)
    OFF     :      if(ldo_en_i==1) nextstate=POWERING;
    POWERING:      if(ldo_en_i==0) nextstate=OFF;
              else if(trst==0&&toen==0&&tzero==0) nextstate=ON;
    ON      :      if(ldo_en_i==0) nextstate=OFF;
    default:;
  endcase
end

always @(*) begin
  rst_o      =1;
  forcezero_o=1;
  oe_o       =0;
  load       =0;
  if (ldo_en_i)
    case(state)
      OFF     :load=1; 
      POWERING:begin rst_o=!(trst==0);forcezero_o=!(tzero==0);oe_o=!(toen==0);end
      ON      :begin rst_o=0         ;forcezero_o=0          ;oe_o=1         ;end
      default:;
    endcase
end

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS:reg_data_o={state,rst_o,forcezero_o,oe_o};
    REGADDR_TRST  :reg_data_o=trst_set ;
    REGADDR_TOEN  :reg_data_o=toen_set ;
    REGADDR_TZERO :reg_data_o=tzero_set;
    default       :reg_data_o=16'hF001 ;
  endcase

always @(posedge clk_i)
       if(rst_i                                ) trst_set <=16'hFFFF  ;
  else if(reg_addr_i==REGADDR_TRST  && reg_we_i) trst_set <=reg_data_i;
always @(posedge clk_i)
       if(rst_i                                ) toen_set <=16'hFFFF  ;
  else if(reg_addr_i==REGADDR_TOEN  && reg_we_i) toen_set <=reg_data_i;
always @(posedge clk_i)
       if(rst_i                                ) tzero_set<=16'hFFFF  ;
  else if(reg_addr_i==REGADDR_TZERO && reg_we_i) tzero_set<=reg_data_i;

endmodule

