module rdoctrl(
  input             clk_i        ,
  input             rst_i        ,

  input             reg_we_i     ,
  input      [ 7:0] reg_addr_i   ,
  input      [15:0] reg_data_i   ,
  output reg [15:0] reg_data_o   ,

  input             trg_i        , // << this is differnt wrt data port rdo: we need to know when we can start reading...
  input             rdo_stop_i   , // << the decoder will tell us (async) when to stop
  output reg        rdo_done_o   ,

  output     [ 7:0] ctrl_opcode_o,
  output reg [ 7:0] ctrl_chipid_o,
  output reg [15:0] ctrl_addr_o  ,  
  output reg        ctrl_rd_o    ,
  input      [15:0] ctrl_data_i  ,
  input             ctrl_ack_i   ,

  output     [23:0] evt_data_o   ,
  output reg        evt_we_o     ,
  input             evt_full_i    // << this is differnt wrt data port rdo, we can pause, but also, we cannot trigger durign rdo
);

localparam [7:0] REGADDR_STATUS    =8'h00,
                 REGADDR_CTRL      =8'h01,
                 REGADDR_CMD       =8'h02,
                 REGADDR_CHIPID    =8'h03,
                 REGADDR_DELAY0    =8'h04,
                 REGADDR_DELAY1    =8'h05,
                 REGADDR_DELAY_SET0=8'h06,
                 REGADDR_DELAY_SET1=8'h07;
localparam [15:0] CMD_RST  =16'h0000,
                  CMD_START=16'h0001;

reg        [2:0] nextstate,state;
localparam [2:0] IDLE=0,DELAY=1,LSB=2,MSB=3,WAIT=4;

wire soft_rst,soft_start;
reg enable;

always @(posedge clk_i)
  if (rst_i||soft_rst||!enable)
    state<=IDLE;
  else
    state<=nextstate;

reg [31:0] rdo_delay_set ;
reg [31:0] rdo_delay     ;
reg        rdo_delay_load;
always @(posedge clk_i)
       if(rst_i         ) rdo_delay<=0             ;
  else if(rdo_delay_load) rdo_delay<=rdo_delay_set ;
  else                    rdo_delay<=rdo_delay-1'b1;

always @(*) begin
  nextstate=state;
  case(state)
    IDLE : if(trg_i||soft_start)  nextstate=DELAY;
    DELAY: if(rdo_delay==0)
             if(!evt_full_i)      nextstate=LSB ;
             else                 nextstate=WAIT;
    WAIT : if(!evt_full_i)        nextstate=LSB ;
    LSB  : if(ctrl_ack_i)         nextstate=MSB ;
    MSB  : if(ctrl_ack_i)
                  if(rdo_stop_i)  nextstate=IDLE;
             else if(!evt_full_i) nextstate=LSB ;
               else               nextstate=WAIT;
    default:;
  endcase
end

reg storelsb;
always @(*) begin
  rdo_delay_load=1;
  storelsb =0;
  evt_we_o =0;
  ctrl_rd_o=0;
  ctrl_addr_o=16'hXXXX;
  rdo_done_o=0;
  case(state)
    DELAY: rdo_delay_load=0;
    LSB : begin ctrl_rd_o=!ctrl_ack_i;ctrl_addr_o=16'h0012;storelsb=ctrl_ack_i; end
    MSB : begin ctrl_rd_o=!ctrl_ack_i;ctrl_addr_o=16'h0013;evt_we_o=ctrl_ack_i;rdo_done_o=ctrl_ack_i&&rdo_stop_i; end
    default:;
  endcase
end
assign ctrl_opcode_o=8'h4E; // RDOP

reg  [15:0] lsb;
always @(posedge clk_i)
  if (storelsb)
    lsb<=ctrl_data_i;

assign evt_data_o={ctrl_data_i[7:0],lsb};

always @(posedge clk_i)
       if(rst_i                                 ) ctrl_chipid_o<=8'h10          ; // TODO: these defaults should be collected...
  else if(reg_addr_i==REGADDR_CHIPID && reg_we_i) ctrl_chipid_o<=reg_data_i[7:0];
always @(posedge clk_i)
       if(rst_i                                     ) rdo_delay_set[15: 0]<=00        ;
  else if(reg_addr_i==REGADDR_DELAY_SET0 && reg_we_i) rdo_delay_set[15: 0]<=reg_data_i;
always @(posedge clk_i)
       if(rst_i                                     ) rdo_delay_set[31:16]<=00        ;
  else if(reg_addr_i==REGADDR_DELAY_SET1 && reg_we_i) rdo_delay_set[31:16]<=reg_data_i;
always @(posedge clk_i)
       if(rst_i                                     ) enable<=0            ;
  else if(reg_addr_i==REGADDR_CTRL       && reg_we_i) enable<=reg_data_i[0];

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS    ,
    REGADDR_CTRL      ,
    REGADDR_CMD       :reg_data_o={state,enable};
    REGADDR_CHIPID    :reg_data_o={8'b0,ctrl_chipid_o};
    REGADDR_DELAY_SET0:reg_data_o=rdo_delay_set[15: 0];
    REGADDR_DELAY_SET1:reg_data_o=rdo_delay_set[31:16];
    REGADDR_DELAY0    :reg_data_o=rdo_delay    [15: 0];
    REGADDR_DELAY1    :reg_data_o=rdo_delay    [31:16];
    default           :reg_data_o=16'hF001;
  endcase

assign soft_rst  =(reg_addr_i==REGADDR_CMD && reg_data_i==CMD_RST   && reg_we_i);
assign soft_start=(reg_addr_i==REGADDR_CMD && reg_data_i==CMD_START && reg_we_i);

endmodule

