module trg_mon(
  input             clk_i     ,
  input             rst_i     ,
  input      [63:0] tsys_i    ,
  input             reg_we_i  ,
  input      [ 7:0] reg_addr_i,
  input      [15:0] reg_data_i,
  output reg [15:0] reg_data_o,
  
  input             trg_req_i  ,
  input             trg_acc_i  ,
  input             bsy_i      ,
  input             bsy_ext_i  ,
  input             bsy_fix_i  ,
  input             bsy_past_i ,
  input             bsy_rdo_i  ,
  input             bsy_send_i ,
  input             bsy_force_i,

  input             exttrg_i,
  input             extbsy_i,
  input             exttrg_o, // TODO: naming...
  input             extbsy_o
);
 
localparam [7:0] REGADDR_STATUS        =8'h00,
                 REGADDR_CMD           =8'h02,
                 REGADDR_TSYS0         =8'h04,REGADDR_TSYS1         =8'h05,REGADDR_TSYS2         =8'h06,REGADDR_TSYS3         =8'h07,
                 REGADDR_TTRGREQ0      =8'h08,REGADDR_TTRGREQ1      =8'h09,REGADDR_TTRGREQ2      =8'h0A,REGADDR_TTRGREQ3      =8'h0B,
                 REGADDR_TTRGACC0      =8'h0C,REGADDR_TTRGACC1      =8'h0D,REGADDR_TTRGACC2      =8'h0E,REGADDR_TTRGACC3      =8'h0F,
                 REGADDR_NTRGREQ0      =8'h10,REGADDR_NTRGREQ1      =8'h11,REGADDR_NTRGREQ2      =8'h12,REGADDR_NTRGREQ3      =8'h13,
                 REGADDR_NTRGACC0      =8'h14,REGADDR_NTRGACC1      =8'h15,REGADDR_NTRGACC2      =8'h16,REGADDR_NTRGACC3      =8'h17,
                 REGADDR_NTRGBSY_EXT0  =8'h18,REGADDR_NTRGBSY_EXT1  =8'h19,REGADDR_NTRGBSY_EXT2  =8'h1A,REGADDR_NTRGBSY_EXT3  =8'h1B,
                 REGADDR_NTRGBSY_FIX0  =8'h1C,REGADDR_NTRGBSY_FIX1  =8'h1D,REGADDR_NTRGBSY_FIX2  =8'h1E,REGADDR_NTRGBSY_FIX3  =8'h1F,
                 REGADDR_NTRGBSY_PAST0 =8'h20,REGADDR_NTRGBSY_PAST1 =8'h21,REGADDR_NTRGBSY_PAST2 =8'h22,REGADDR_NTRGBSY_PAST3 =8'h23,
                 REGADDR_NTRGBSY_RDO0  =8'h24,REGADDR_NTRGBSY_RDO1  =8'h25,REGADDR_NTRGBSY_RDO2  =8'h26,REGADDR_NTRGBSY_RDO3  =8'h27,
                 REGADDR_NTRGBSY_SEND0 =8'h28,REGADDR_NTRGBSY_SEND1 =8'h29,REGADDR_NTRGBSY_SEND2 =8'h2A,REGADDR_NTRGBSY_SEND3 =8'h2B,
                 REGADDR_NTRGBSY_FORCE0=8'h2C,REGADDR_NTRGBSY_FORCE1=8'h2D,REGADDR_NTRGBSY_FORCE2=8'h2E,REGADDR_NTRGBSY_FORCE3=8'h2F,
                 REGADDR_TTOT0         =8'h30,REGADDR_TTOT1         =8'h31,REGADDR_TTOT2         =8'h32,REGADDR_TTOT3         =8'h33,
                 REGADDR_TBSY0         =8'h34,REGADDR_TBSY1         =8'h35,REGADDR_TBSY2         =8'h36,REGADDR_TBSY3         =8'h37,
                 REGADDR_TBSY_EXT0     =8'h38,REGADDR_TBSY_EXT1     =8'h39,REGADDR_TBSY_EXT2     =8'h3A,REGADDR_TBSY_EXT3     =8'h3B,
                 REGADDR_TBSY_FIX0     =8'h3C,REGADDR_TBSY_FIX1     =8'h3D,REGADDR_TBSY_FIX2     =8'h3E,REGADDR_TBSY_FIX3     =8'h3F,
                 REGADDR_TBSY_PAST0    =8'h40,REGADDR_TBSY_PAST1    =8'h41,REGADDR_TBSY_PAST2    =8'h42,REGADDR_TBSY_PAST3    =8'h43,
                 REGADDR_TBSY_RDO0     =8'h44,REGADDR_TBSY_RDO1     =8'h45,REGADDR_TBSY_RDO2     =8'h46,REGADDR_TBSY_RDO3     =8'h47,
                 REGADDR_TBSY_SEND0    =8'h48,REGADDR_TBSY_SEND1    =8'h49,REGADDR_TBSY_SEND2    =8'h4A,REGADDR_TBSY_SEND3    =8'h4B,
                 REGADDR_TBSY_FORCE0   =8'h4C,REGADDR_TBSY_FORCE1   =8'h4D,REGADDR_TBSY_FORCE2   =8'h4E,REGADDR_TBSY_FORCE3   =8'h4F;

localparam [15:0] CMD_LAT=16'h0001,
                  CMD_CLR=16'h0002;

reg [63:0] ttrgreq      ;
reg [63:0] ttrgacc      ;
reg [63:0] ntrgreq      ;
reg [63:0] ntrgacc      ;
reg [63:0] ntrgbsy_ext  ;
reg [63:0] ntrgbsy_fix  ;
reg [63:0] ntrgbsy_past ;
reg [63:0] ntrgbsy_rdo  ;
reg [63:0] ntrgbsy_send ;
reg [63:0] ntrgbsy_force;
reg [63:0] ttot         ;
reg [63:0] tbsy         ;
reg [63:0] tbsy_ext     ;
reg [63:0] tbsy_fix     ;
reg [63:0] tbsy_past    ;
reg [63:0] tbsy_rdo     ;
reg [63:0] tbsy_send    ;
reg [63:0] tbsy_force   ;

reg [63:0] tsys_lat         ;
reg [63:0] ttrgreq_lat      ;
reg [63:0] ttrgacc_lat      ;
reg [63:0] ntrgreq_lat      ;
reg [63:0] ntrgacc_lat      ;
reg [63:0] ntrgbsy_ext_lat  ;
reg [63:0] ntrgbsy_fix_lat  ;
reg [63:0] ntrgbsy_past_lat ;
reg [63:0] ntrgbsy_rdo_lat  ;
reg [63:0] ntrgbsy_send_lat ;
reg [63:0] ntrgbsy_force_lat;
reg [63:0] ttot_lat         ;
reg [63:0] tbsy_lat         ;
reg [63:0] tbsy_ext_lat     ;
reg [63:0] tbsy_fix_lat     ;
reg [63:0] tbsy_past_lat    ;
reg [63:0] tbsy_rdo_lat     ;
reg [63:0] tbsy_send_lat    ;
reg [63:0] tbsy_force_lat   ;

wire clr,lat;
always @(posedge clk_i)
  if (rst_i || clr) begin
    ttrgreq      <=0;
    ttrgacc      <=0;
    ntrgreq      <=0;
    ntrgacc      <=0;
    ntrgbsy_ext  <=0;
    ntrgbsy_fix  <=0;
    ntrgbsy_past <=0;
    ntrgbsy_rdo  <=0;
    ntrgbsy_send <=0;
    ntrgbsy_force<=0;
    ttot         <=0;
    tbsy         <=0;
    tbsy_ext     <=0;
    tbsy_fix     <=0;
    tbsy_past    <=0;
    tbsy_rdo     <=0;
    tbsy_send    <=0;
    tbsy_force   <=0;
  end else begin
    if (trg_req_i               ) ttrgreq      <=tsys_i;
    if (trg_acc_i               ) ttrgacc      <=tsys_i;
    if (trg_req_i               ) ntrgreq      <=ntrgreq      +1'b1;
    if (trg_acc_i               ) ntrgacc      <=ntrgacc      +1'b1;
    if (trg_req_i && bsy_ext_i  ) ntrgbsy_ext  <=ntrgbsy_ext  +1'b1;
    if (trg_req_i && bsy_fix_i  ) ntrgbsy_fix  <=ntrgbsy_fix  +1'b1;
    if (trg_req_i && bsy_past_i ) ntrgbsy_past <=ntrgbsy_past +1'b1;
    if (trg_req_i && bsy_rdo_i  ) ntrgbsy_rdo  <=ntrgbsy_rdo  +1'b1;
    if (trg_req_i && bsy_send_i ) ntrgbsy_send <=ntrgbsy_send +1'b1;
    if (trg_req_i && bsy_force_i) ntrgbsy_force<=ntrgbsy_force+1'b1;
                     ttot      <=ttot      +1'b1;
    if (bsy_i      ) tbsy      <=tbsy      +1'b1;
    if (bsy_ext_i  ) tbsy_ext  <=tbsy_ext  +1'b1;
    if (bsy_fix_i  ) tbsy_fix  <=tbsy_fix  +1'b1;
    if (bsy_past_i ) tbsy_past <=tbsy_past +1'b1;
    if (bsy_rdo_i  ) tbsy_rdo  <=tbsy_rdo  +1'b1;
    if (bsy_send_i ) tbsy_send <=tbsy_send +1'b1;
    if (bsy_force_i) tbsy_force<=tbsy_force+1'b1;
  end

always @(posedge clk_i)
  if (rst_i) begin
    tsys_lat         <=0;
    ttrgreq_lat      <=0;
    ttrgacc_lat      <=0;
    ntrgreq_lat      <=0;
    ntrgacc_lat      <=0;
    ntrgbsy_ext_lat  <=0;
    ntrgbsy_fix_lat  <=0;
    ntrgbsy_past_lat <=0;
    ntrgbsy_rdo_lat  <=0;
    ntrgbsy_send_lat <=0;
    ntrgbsy_force_lat<=0;
    ttot_lat         <=0;
    tbsy_lat         <=0;
    tbsy_ext_lat     <=0;
    tbsy_fix_lat     <=0;
    tbsy_past_lat    <=0;
    tbsy_rdo_lat     <=0;
    tbsy_send_lat    <=0;
    tbsy_force_lat   <=0;
  end else if (lat) begin
    tsys_lat         <=tsys_i       ;
    ttrgreq_lat      <=ttrgreq      ;
    ttrgacc_lat      <=ttrgacc      ;
    ntrgreq_lat      <=ntrgreq      ;
    ntrgacc_lat      <=ntrgacc      ;
    ntrgbsy_ext_lat  <=ntrgbsy_ext  ;
    ntrgbsy_fix_lat  <=ntrgbsy_fix  ;
    ntrgbsy_past_lat <=ntrgbsy_past ;
    ntrgbsy_rdo_lat  <=ntrgbsy_rdo  ;
    ntrgbsy_send_lat <=ntrgbsy_send ;
    ntrgbsy_force_lat<=ntrgbsy_force;
    ttot_lat         <=ttot         ;
    tbsy_lat         <=tbsy         ;
    tbsy_ext_lat     <=tbsy_ext     ;
    tbsy_fix_lat     <=tbsy_fix     ;
    tbsy_past_lat    <=tbsy_past    ;
    tbsy_rdo_lat     <=tbsy_rdo     ;
    tbsy_send_lat    <=tbsy_send    ;
    tbsy_force_lat   <=tbsy_force   ;
  end 


//FIXME: move these syncronisers out
wire exttrg_i_s,extbsy_i_s,exttrg_o_s,extbsy_o_s;
//sync(.i(exttrg_i),.o(exttrg_i_s));
//sync(.i(extbsy_i),.o(extbsy_i_s));
//sync(.i(exttrg_o),.o(exttrg_o_s));
//sync(.i(extbsy_o),.o(extbsy_o_s));

assign exttrg_i_s=exttrg_i;
assign extbsy_i_s=extbsy_i;
assign exttrg_o_s=exttrg_o;
assign extbsy_o_s=extbsy_o;

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS        ,
    REGADDR_CMD           :reg_data_o={exttrg_i_s,extbsy_i_s,exttrg_o_s,extbsy_o_s,5'b0,trg_req_i,trg_acc_i,bsy_ext_i,bsy_fix_i,bsy_past_i,bsy_rdo_i,bsy_force_i};
    REGADDR_TSYS0         :reg_data_o=tsys_lat         [15:0];REGADDR_TSYS1         :reg_data_o=tsys_lat         [31:16];REGADDR_TSYS2         :reg_data_o=tsys_lat         [47:32];REGADDR_TSYS3         :reg_data_o=tsys_lat         [63:48];
    REGADDR_TTRGREQ0      :reg_data_o=ttrgreq_lat      [15:0];REGADDR_TTRGREQ1      :reg_data_o=ttrgreq_lat      [31:16];REGADDR_TTRGREQ2      :reg_data_o=ttrgreq_lat      [47:32];REGADDR_TTRGREQ3      :reg_data_o=ttrgreq_lat      [63:48];
    REGADDR_TTRGACC0      :reg_data_o=ttrgacc_lat      [15:0];REGADDR_TTRGACC1      :reg_data_o=ttrgacc_lat      [31:16];REGADDR_TTRGACC2      :reg_data_o=ttrgacc_lat      [47:32];REGADDR_TTRGACC3      :reg_data_o=ttrgacc_lat      [63:48];
    REGADDR_NTRGREQ0      :reg_data_o=ntrgreq_lat      [15:0];REGADDR_NTRGREQ1      :reg_data_o=ntrgreq_lat      [31:16];REGADDR_NTRGREQ2      :reg_data_o=ntrgreq_lat      [47:32];REGADDR_NTRGREQ3      :reg_data_o=ntrgreq_lat      [63:48];
    REGADDR_NTRGACC0      :reg_data_o=ntrgacc_lat      [15:0];REGADDR_NTRGACC1      :reg_data_o=ntrgacc_lat      [31:16];REGADDR_NTRGACC2      :reg_data_o=ntrgacc_lat      [47:32];REGADDR_NTRGACC3      :reg_data_o=ntrgacc_lat      [63:48];
    REGADDR_NTRGBSY_EXT0  :reg_data_o=ntrgbsy_ext_lat  [15:0];REGADDR_NTRGBSY_EXT1  :reg_data_o=ntrgbsy_ext_lat  [31:16];REGADDR_NTRGBSY_EXT2  :reg_data_o=ntrgbsy_ext_lat  [47:32];REGADDR_NTRGBSY_EXT3  :reg_data_o=ntrgbsy_ext_lat  [63:48];
    REGADDR_NTRGBSY_FIX0  :reg_data_o=ntrgbsy_fix_lat  [15:0];REGADDR_NTRGBSY_FIX1  :reg_data_o=ntrgbsy_fix_lat  [31:16];REGADDR_NTRGBSY_FIX2  :reg_data_o=ntrgbsy_fix_lat  [47:32];REGADDR_NTRGBSY_FIX3  :reg_data_o=ntrgbsy_fix_lat  [63:48];
    REGADDR_NTRGBSY_PAST0 :reg_data_o=ntrgbsy_past_lat [15:0];REGADDR_NTRGBSY_PAST1 :reg_data_o=ntrgbsy_past_lat [31:16];REGADDR_NTRGBSY_PAST2 :reg_data_o=ntrgbsy_past_lat [47:32];REGADDR_NTRGBSY_PAST3 :reg_data_o=ntrgbsy_past_lat [63:48];
    REGADDR_NTRGBSY_RDO0  :reg_data_o=ntrgbsy_rdo_lat  [15:0];REGADDR_NTRGBSY_RDO1  :reg_data_o=ntrgbsy_rdo_lat  [31:16];REGADDR_NTRGBSY_RDO2  :reg_data_o=ntrgbsy_rdo_lat  [47:32];REGADDR_NTRGBSY_RDO3  :reg_data_o=ntrgbsy_rdo_lat  [63:48];
    REGADDR_NTRGBSY_SEND0 :reg_data_o=ntrgbsy_send_lat [15:0];REGADDR_NTRGBSY_SEND1 :reg_data_o=ntrgbsy_send_lat [31:16];REGADDR_NTRGBSY_SEND2 :reg_data_o=ntrgbsy_send_lat [47:32];REGADDR_NTRGBSY_SEND3 :reg_data_o=ntrgbsy_send_lat [63:48];
    REGADDR_NTRGBSY_FORCE0:reg_data_o=ntrgbsy_force_lat[15:0];REGADDR_NTRGBSY_FORCE1:reg_data_o=ntrgbsy_force_lat[31:16];REGADDR_NTRGBSY_FORCE2:reg_data_o=ntrgbsy_force_lat[47:32];REGADDR_NTRGBSY_FORCE3:reg_data_o=ntrgbsy_force_lat[63:48];
    REGADDR_TTOT0         :reg_data_o=ttot_lat         [15:0];REGADDR_TTOT1         :reg_data_o=ttot_lat         [31:16];REGADDR_TTOT2         :reg_data_o=ttot_lat         [47:32];REGADDR_TTOT3         :reg_data_o=ttot_lat         [63:48];
    REGADDR_TBSY0         :reg_data_o=tbsy_lat         [15:0];REGADDR_TBSY1         :reg_data_o=tbsy_lat         [31:16];REGADDR_TBSY2         :reg_data_o=tbsy_lat         [47:32];REGADDR_TBSY3         :reg_data_o=tbsy_lat         [63:48];
    REGADDR_TBSY_EXT0     :reg_data_o=tbsy_ext_lat     [15:0];REGADDR_TBSY_EXT1     :reg_data_o=tbsy_ext_lat     [31:16];REGADDR_TBSY_EXT2     :reg_data_o=tbsy_ext_lat     [47:32];REGADDR_TBSY_EXT3     :reg_data_o=tbsy_ext_lat     [63:48];
    REGADDR_TBSY_FIX0     :reg_data_o=tbsy_fix_lat     [15:0];REGADDR_TBSY_FIX1     :reg_data_o=tbsy_fix_lat     [31:16];REGADDR_TBSY_FIX2     :reg_data_o=tbsy_fix_lat     [47:32];REGADDR_TBSY_FIX3     :reg_data_o=tbsy_fix_lat     [63:48];
    REGADDR_TBSY_PAST0    :reg_data_o=tbsy_past_lat    [15:0];REGADDR_TBSY_PAST1    :reg_data_o=tbsy_past_lat    [31:16];REGADDR_TBSY_PAST2    :reg_data_o=tbsy_past_lat    [47:32];REGADDR_TBSY_PAST3    :reg_data_o=tbsy_past_lat    [63:48];
    REGADDR_TBSY_RDO0     :reg_data_o=tbsy_rdo_lat     [15:0];REGADDR_TBSY_RDO1     :reg_data_o=tbsy_rdo_lat     [31:16];REGADDR_TBSY_RDO2     :reg_data_o=tbsy_rdo_lat     [47:32];REGADDR_TBSY_RDO3     :reg_data_o=tbsy_rdo_lat     [63:48];
    REGADDR_TBSY_SEND0    :reg_data_o=tbsy_send_lat    [15:0];REGADDR_TBSY_SEND1    :reg_data_o=tbsy_send_lat    [31:16];REGADDR_TBSY_SEND2    :reg_data_o=tbsy_send_lat    [47:32];REGADDR_TBSY_SEND3    :reg_data_o=tbsy_send_lat    [63:48];
    REGADDR_TBSY_FORCE0   :reg_data_o=tbsy_force_lat   [15:0];REGADDR_TBSY_FORCE1   :reg_data_o=tbsy_force_lat   [31:16];REGADDR_TBSY_FORCE2   :reg_data_o=tbsy_force_lat   [47:32];REGADDR_TBSY_FORCE3   :reg_data_o=tbsy_force_lat   [63:48];
    default               :reg_data_o=16'hF001;
  endcase

assign clr=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_CLR && reg_we_i;
assign lat=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_LAT && reg_we_i;

endmodule

