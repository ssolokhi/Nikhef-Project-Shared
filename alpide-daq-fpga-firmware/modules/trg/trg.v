module trg(
  input             clk_i        ,
  input             rst_i        ,
  input             reg_we_i     ,
  input      [ 7:0] reg_addr_i   ,
  input      [15:0] reg_data_i   ,
  output reg [15:0] reg_data_o   ,
  
  output reg [ 7:0] ctrl_opcode_o,
  output            ctrl_cmd_o   ,
  input             ctrl_ack_i   ,
 
  output            trg_o        , // for rdo via ctrl
  input             rdo_done_i   , // for bsy generation, TODO: move somehwere else

// for monitoring module
  output            trg_req_o    ,
  output            trg_acc_o    ,
  output            bsy_o        ,
  output            bsy_ext_o    ,
  output            bsy_fix_o    ,
  output            bsy_past_o   ,
  output            bsy_rdo_o    ,
  output            bsy_send_o   ,
  output            bsy_force_o  ,

  input             softtrg_i    ,
  input             watermark_low_i,

  input             exttrg_i     ,
  input             extbsy_i     ,
  output            exttrg_o     ,
  output            extbsy_o     
);
 
localparam [7:0] REGADDR_STATUS        =8'h00,
                 REGADDR_CTRL          =8'h01,
                 REGADDR_CMD           =8'h02,
                 REGADDR_OPCODE        =8'h03,
                 REGADDR_FIXEDBUSY0    =8'h04,
                 REGADDR_FIXEDBUSY1    =8'h05,
                 REGADDR_MINSPACING0   =8'h06,
                 REGADDR_MINSPACING1   =8'h07;
localparam [15:0] CMD_RSTRDOBSY=16'h0000;


reg mastermode; // for first DAQ board in the chain
reg intbsy_msk; // possiblity to mask internal bsy
reg extbsy_msk; // possiblity to mask external bsy
reg exttrg_msk; // possiblity to mask trigger bsy

// BUSY logic
// TODO the place where ext busy is masked is not consistent
wire bsy_ext   ; // external busy
wire bsy_fix   ; // future protection
wire bsy_past  ; // past protection
reg  bsy_rdo   ; // readout is busy
reg  bsy_send  ; // busy sending data to PC
reg  bsy_force ; // forces busy
wire bsy_int   ; // all internal busy sources togeter
wire bsy_int_noglitch; // all internal busy sources togeter
wire bsy       ; // final
assign   bsy_int=bsy_fix||bsy_past||bsy_rdo||bsy_send||bsy_force;
syncin   bsy_sync        (.clk_i(clk_i),.rst_i(rst_i),.pin_i (extbsy_i),.data_o(bsy_ext         ));
noglitch noglitch_bsy_int(.clk_i(clk_i),.rst_i(rst_i),.data_i(bsy_int ),.data_o(bsy_int_noglitch));
assign extbsy_o= bsy_int_noglitch&&!intbsy_msk||(extbsy_i&&!extbsy_msk); // assume this OR is glitch-free
assign bsy     = bsy_int&&!intbsy_msk         ||(bsy_ext &&!extbsy_msk);

// TRG logic
// busy is only handled in master mode to reject triggers
// TODO the place where ext trg is masked is not consistent
wire trg_ext_synced     ; // input synchroniser (+2clk)
wire trg_ext_edge       ; // edge detected, single clk pulse (+1clk)
wire trg_int            ; // (trg_ext | internal sequencer) passed through a single register to avoid glitches on the output
wire trg_int_conditioned; // nice and 4-clk long pulses (+0clk)
wire trg_int_req_delayed; // mimics for sync delay of trg_ext
wire trg_int_acc_delayed; // mimics for sync delay of trg_ext
wire trg_req            ; // this is eventually what is used further on as the trigger request
wire trg_acc            ; //
syncin   trg_sync        (.clk_i(clk_i),.rst_i(rst_i),.pin_i (exttrg_i                            ),.data_o(trg_ext_synced     ));
trg_edge trg_edge        (.clk_i(clk_i),.rst_i(rst_i),.trg_i (trg_ext_synced                      ),.trg_o (trg_ext_edge       ));
noglitch nogltich_trg_int(.clk_i(clk_i),.rst_i(rst_i),.data_i(trg_ext_edge&&!exttrg_msk||softtrg_i),.data_o(trg_int            ));
syncin   trg_req_delay   (.clk_i(clk_i),.rst_i(rst_i),.pin_i (trg_int                             ),.data_o(trg_int_req_delayed));
syncin   trg_acc_delay   (.clk_i(clk_i),.rst_i(rst_i),.pin_i (trg_int&&!bsy                       ),.data_o(trg_int_acc_delayed));
trg_cond trg_cond        (.clk_i(clk_i),.rst_i(rst_i),.trg_i (trg_int&&!bsy                       ),.trg_o (trg_int_conditioned));
assign exttrg_o=mastermode?trg_int_conditioned:exttrg_i&&!exttrg_msk;
assign trg_req=mastermode?trg_int_req_delayed    :trg_ext_edge;
assign trg_acc=mastermode?trg_int_acc_delayed    :trg_ext_edge;

assign ctrl_cmd_o=trg_acc; //FIXME: add ctrl handshake: what if the ctrl module is busy...?

reg [31:0] fixedbusytime;
reg [31:0] minspacing   ;

// BUSY GENERATION
// past protection (=min busy time after last trg input)
reg [31:0] dt_past;
assign bsy_past=dt_past!=0;
always @(posedge clk_i)
  if (rst_i || trg_req)
    dt_past<=minspacing;
  else if(bsy_past)
    dt_past<=dt_past-1'b1;

// rate limitation (= min busy time after last accepted trigger)
reg [31:0] dt_fix;
assign bsy_fix=dt_fix!=0;
always @(posedge clk_i)
  if (rst_i || trg_acc)
    dt_fix<=fixedbusytime;
  else if(bsy_fix)
    dt_fix<=dt_fix-1'b1;

// readout based busy (depending on mode)
// TODO: anything more complex than ping pong
// FIXME: be busy while sending XOFF/XON (event could complete while sending the XOFF command)
wire rstrdobsy;
always @(posedge clk_i)
  if (rst_i || rstrdobsy)
    bsy_rdo<=0;
  else if (trg_acc)
    bsy_rdo<=1;
  else if (rdo_done_i)
    bsy_rdo<=0;

always @(posedge clk_i)
  if (rst_i)
    bsy_send<=0;
  else if (trg_acc)
    bsy_send<=1;
  else if (!bsy_rdo && watermark_low_i)
    bsy_send<=0;

always @(posedge clk_i)
       if(rst_i                                      ) fixedbusytime       <=0              ; // FIXME: naming + defaults?
  else if(reg_addr_i==REGADDR_FIXEDBUSY0  && reg_we_i) fixedbusytime[15: 0]<=reg_data_i     ;
  else if(reg_addr_i==REGADDR_FIXEDBUSY1  && reg_we_i) fixedbusytime[31:16]<=reg_data_i     ;

always @(posedge clk_i)
       if(rst_i                                      ) minspacing          <=0              ; // FIXME: naming + defaults?
  else if(reg_addr_i==REGADDR_MINSPACING0 && reg_we_i) minspacing   [15: 0]<=reg_data_i     ;
  else if(reg_addr_i==REGADDR_MINSPACING1 && reg_we_i) minspacing   [31:16]<=reg_data_i     ;

always @(posedge clk_i)
       if(rst_i                                      ) ctrl_opcode_o       <=8'h55          ; // a nice TRG command 
  else if(reg_addr_i==REGADDR_OPCODE      && reg_we_i) ctrl_opcode_o       <=reg_data_i[7:0];

always @(posedge clk_i)
  if (rst_i) begin
    bsy_force <=1;
    extbsy_msk<=0;
    intbsy_msk<=0;
    exttrg_msk<=0;
    mastermode<=0; // FIXME: naming + defaults?
  end else if (reg_addr_i==REGADDR_CTRL && reg_we_i) begin
    bsy_force <=reg_data_i[0];
    extbsy_msk<=reg_data_i[1];
    exttrg_msk<=reg_data_i[2];
    mastermode<=reg_data_i[3];
    intbsy_msk<=reg_data_i[4];
  end

always @(*)
  case(reg_addr_i)
    REGADDR_CMD       ,
    REGADDR_CTRL      ,
    REGADDR_STATUS    :reg_data_o={11'b0,intbsy_msk,mastermode,exttrg_msk,extbsy_msk,bsy_force};
    REGADDR_OPCODE    :reg_data_o={8'b0,ctrl_opcode_o};
    REGADDR_FIXEDBUSY0 :reg_data_o=fixedbusytime[15: 0];
    REGADDR_FIXEDBUSY1 :reg_data_o=fixedbusytime[31:16];
    REGADDR_MINSPACING0:reg_data_o=minspacing   [15: 0];
    REGADDR_MINSPACING1:reg_data_o=minspacing   [31:16];
    default           :reg_data_o=16'hF001;
  endcase

assign rstrdobsy=(reg_addr_i==REGADDR_CMD && reg_data_i==CMD_RSTRDOBSY && reg_we_i);

assign trg_o      =trg_acc  ;
assign trg_req_o  =trg_req  ;
assign trg_acc_o  =trg_acc  ;
assign bsy_o      =bsy      ;
assign bsy_ext_o  =bsy_ext  ;
assign bsy_fix_o  =bsy_fix  ;
assign bsy_past_o =bsy_past ;
assign bsy_rdo_o  =bsy_rdo  ;
assign bsy_send_o =bsy_send ;
assign bsy_force_o=bsy_force;

endmodule

