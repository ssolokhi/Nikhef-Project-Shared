module trg_seq(
  input             clk_i     ,
  input             rst_i     ,
  input             reg_we_i  ,
  input      [ 7:0] reg_addr_i,
  input      [15:0] reg_data_i,
  output reg [15:0] reg_data_o,
  output reg        trg_o
);

//FIXME: this seems to send two triggers always..

localparam [7:0] REGADDR_STATUS  =8'h00,
                 REGADDR_CTRL    =8'h01,
                 REGADDR_CMD     =8'h02,
                 REGADDR_NTRG_SET=8'h03,
                 REGADDR_DT_SET  =8'h04,
                 REGADDR_NTRG    =8'h05,
                 REGADDR_DT      =8'h06;
localparam [15:0] CMD_START=16'h0001,
                  CMD_STOP =16'h0000;

reg [15:0] ntrg_set;
reg [15:0] dt_set  ;
reg [15:0] ntrg    ;
reg [15:0] dt      ;
wire start;
wire stop ;
reg ntrg_load;
reg dt_load  ;
reg ntrg_dec ;
reg dt_dec   ;

localparam [1:0] IDLE=0,START=1,TRIGGER=2,WAIT=3;
reg        [1:0] nextstate,state;

always @(posedge clk_i)
  if (rst_i)
    ntrg<=0;
  else if (ntrg_load)
    ntrg<=ntrg_set;
  else if (ntrg_dec)
    ntrg<=ntrg-1'b1;

always @(posedge clk_i)
  if (rst_i)
    dt<=0;
  else if (dt_load)
    dt<=dt_set;
  else if (dt_dec)
    dt<=dt-1'b1;

always @(posedge clk_i)
  if (rst_i)
    state<=IDLE;
  else
    state<=nextstate;

always @(*) begin
  nextstate=state;
  case(state)
    IDLE   :      if (start          ) nextstate=START  ;
    START  :      if (stop           ) nextstate=IDLE   ;
             else                      nextstate=TRIGGER;
    TRIGGER:      if (stop || ntrg==1) nextstate=IDLE   ;
             else                      nextstate=WAIT   ;
    WAIT   :      if (stop           ) nextstate=IDLE   ;
             else if (dt==1          ) nextstate=TRIGGER;
  endcase
end

always @(*) begin
  ntrg_load=0;
  ntrg_dec =0;
  dt_load  =0;
  dt_dec   =0;
  trg_o    =0;
  case(state)
    START  : ntrg_load=1;
    TRIGGER: begin ntrg_dec=ntrg!=16'hFFFF;dt_load=1;trg_o=1;end
    WAIT   : dt_dec=1; 
    default:;
  endcase
end

always @(posedge clk_i)
       if(rst_i                                   ) ntrg_set<=16'h0001  ;
  else if(reg_addr_i==REGADDR_NTRG_SET && reg_we_i) ntrg_set<=reg_data_i;

always @(posedge clk_i)
       if(rst_i                                   ) dt_set  <=0         ;
  else if(reg_addr_i==REGADDR_DT_SET   && reg_we_i) dt_set  <=reg_data_i;

assign start=(reg_addr_i==REGADDR_CMD && reg_data_i==CMD_START && reg_we_i);
assign stop =(reg_addr_i==REGADDR_CMD && reg_data_i==CMD_STOP  && reg_we_i);

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS  ,
    REGADDR_CTRL    ,
    REGADDR_CMD     :reg_data_o=state   ;
    REGADDR_NTRG_SET:reg_data_o=ntrg_set;
    REGADDR_DT_SET  :reg_data_o=dt_set  ;
    REGADDR_NTRG    :reg_data_o=ntrg    ;
    REGADDR_DT      :reg_data_o=dt      ;
    default         :reg_data_o=16'hF001;
  endcase

endmodule

