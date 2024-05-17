module top(
// GLOBAL
  input         clk40_i          ,
// LEMOs                  //   v2                  |  v3
                          // ----------------------+------------
//input           p21_i,  // LVTTLI3               | N/C
  input           p22_i,  // LVTTLI2 (BUSY IN)     | N/C
//input           r20_i,  // LVTTLI1               | N/C
  input           r21_i,  // LVTTLI0 (TRIGGER IN ) | TRIGGER IN
  output          r22_o,  // LVTTLO1 (TRIGGER OUT) | TRIGGER OUT
  inout           u21_io, // LVTTLO2 (BUSY OUT)    | BUSY IN
  inout           u22_io, // FX3SCK                | BUSY OUT
//  input         exttrg_i         ,
//  input         extbsy_i         ,
//  output        exttrg_o         ,
//  output        extbsy_o         ,
// PIN HEADER
  input  [ 3:0] brdaddr_i        ,
  output [ 3:0] dbg_o            ,
// FX3
  input         fx3_flaga_i      ,
  input         fx3_flagb_i      ,
  input         fx3_flagc_i      ,
  input         fx3_flagd_i      ,
  output [ 1:0] fx3_sladdr_o     ,
  output        fx3_sloe_n_o     ,
  output        fx3_slcs_n_o     ,
  output        fx3_slrd_n_o     ,
  output        fx3_slwr_n_o     ,
  output        fx3_pktend_n_o   ,
  inout  [31:0] fx3_dq_io        ,
  output        fx3_rst_n_o      , // TODO: use for sth?
  output        fx3_slclk_o      ,
// ALPIDE
  output        alpide_mclk_o    ,
  output        alpide_mclk_oe_o ,
  output        alpide_pordis_n_o,
  output        alpide_rst_n_o   ,
  input         alpide_busy_i    ,
  output        alpide_dctrl_o   ,
  output        alpide_dctrl_oe_o,
  input         alpide_dctrl_i   ,
  input         alpide_ctrl_io   , // ignore, input only
  input  [ 7:0] alpide_data_i    ,
  output        alpide_sce_o     , // ignore FIXME: trace+remove
  output        alpide_sci_o     , // ignore FIXME: trace+remove
  input         alpide_sco_i     , // ignore FIXME: trace+remove
// MONITORING ADCs
  output        adc_clk_o        ,
  output        adc_cs_n_o       ,
  input  [ 5:0] adc_d_i          ,
// LDOs
  output        ldo_en_o         ,
  output        ldo2_en_o        , // FIXME: new DAQ baard? "SHUTOFF_NEW"
// DS2411 (not really needed)
  inout         onewire_io         // TODO: do sth with that!
);

// DAQ board version switch
wire [1:0] board_version;
wire exttrg_i;
wire extbsy_i;
wire exttrg_o;
wire extbsy_o;
always @*
  case(board_version)
    2: begin
      exttrg_i=r21_i ;
      extbsy_i=p22_i ;
      r22_o   =exttrg_o;
      u21_io  =extbsy_o;
      u22_io  =1'bz;
    end
    3: begin
      exttrg_i=r21_i ;
      extbsy_i=u21_io;
      r22_o   =exttrg_o;
      u21_io  =1'bz;
      u22_io  =extbsy_o;
    end
    default: begin
      exttrg_i=1'b0;
      extbsy_i=1'b1;
      r22_o   =1'b0;
      u21_io  =1'bz;
      u22_io  =1'bz;
    end
  endcase

// unused stuff:
assign onewire_io  =1;
assign alpide_sce_o=0; // TODO: where does this go?
assign alpide_sci_o=0; // TODO: where does this go?

// allow programming of flash via JTAG:
flash flash();

// TODO: make this a proper module
pll pll(.inclk0(clk40_i),.c0(clk),.locked(locked));
// TODO: make this a module... and ensure min rst period...
wire clk;
wire locked;
wire rst=!locked; // TODO...

// OUT0: reg rd/wr commands from PC
wire [31:0] out0_data ;
wire        out0_full ;
wire        out0_we   ;
// IN0: reg rd/wr answers to PC
wire [31:0] in0_data  ;
wire        in0_pktend;
wire        in0_empty ;
wire        in0_re    ;
// IN1: evt data to PC
wire [31:0] in1_data  ;
wire        in1_pktend;
wire        in1_empty ;
wire        in1_re    ;
// IN2: other data to PC (to be implemented)
wire [31:0] in2_data  =0;
wire        in2_pktend=0;
wire        in2_empty =1;
wire        in2_re      ;

fx3 fx3(
  .clk_i         (clk           ),
  .rst_i         (rst           ), 
  .fx3_flaga_i   (fx3_flaga_i   ),
  .fx3_flagb_i   (fx3_flagb_i   ),
  .fx3_flagc_i   (fx3_flagc_i   ),
  .fx3_flagd_i   (fx3_flagd_i   ),
  .fx3_sladdr_o  (fx3_sladdr_o  ),
  .fx3_sloe_n_o  (fx3_sloe_n_o  ),
  .fx3_slcs_n_o  (fx3_slcs_n_o  ),
  .fx3_slrd_n_o  (fx3_slrd_n_o  ),
  .fx3_slwr_n_o  (fx3_slwr_n_o  ),
  .fx3_pktend_n_o(fx3_pktend_n_o),
  .fx3_dq_io     (fx3_dq_io     ),
  .out0_full_i   (out0_full     ),
  .out0_data_o   (out0_data     ),
  .out0_we_o     (out0_we       ),
  .in0_empty_i   (in0_empty     ),
  .in0_data_i    (in0_data      ),
  .in0_pktend_i  (in0_pktend    ),
  .in0_re_o      (in0_re        ),
  .in1_empty_i   (in1_empty     ),
  .in1_data_i    (in1_data      ),
  .in1_pktend_i  (in1_pktend    ),
  .in1_re_o      (in1_re        ),
  .in2_empty_i   (in2_empty     ),
  .in2_data_i    (in2_data      ),
  .in2_pktend_i  (in2_pktend    ),
  .in2_re_o      (in2_re        )
);
assign fx3_slclk_o=clk;
assign fx3_rst_n_o  =1'b1; // no reset, please!

// MODULE MULTIPLEXER:
localparam [5:0] MODADDR_ID        =6'h01,
                 MODADDR_PWR       =6'h02,
                 MODADDR_ADC       =6'h03,
                 MODADDR_CTRLSOFT  =6'h04,
                 MODADDR_TRG       =6'h05,
                 MODADDR_TRGSEQ    =6'h06,
                 MODADDR_TRGMON    =6'h07,
                 MODADDR_RST       =6'h08,
                 MODADDR_RDOMUX    =6'h09,
                 MODADDR_RDOPAR    =6'h0A,
                 MODADDR_RDOCTRL   =6'h0B,
                 MODADDR_RDOCTRLDEC=6'h0C,
                 MODADDR_CTRL      =6'h0D,
                 MODADDR_EVTPKR    =6'h0E,
                 MODADDR_EVTBLD    =6'h0F,
                 MODADDR_TSYS      =6'h10,
                 MODADDR_XONXOFF   =6'h11;
wire [15:0] reg_datard_id        ,
            reg_datard_pwr       ,
            reg_datard_adc       ,
            reg_datard_ctrl      ,
            reg_datard_ctrlsoft  ,
            reg_datard_trg       ,
            reg_datard_trgseq    ,
            reg_datard_trgmon    ,
            reg_datard_rst       ,
            reg_datard_rdomux    ,
            reg_datard_rdopar    ,
            reg_datard_rdoctrl   ,
            reg_datard_rdoctrldec,
            reg_datard_evtpkr    ,
            reg_datard_evtbld    ,
            reg_datard_xonxoff   ,
            reg_datard_tsys      ;
wire [ 5:0] mod_addr  ;
wire [ 7:0] reg_addr  ;
wire [15:0] reg_datawr;
reg  [15:0] reg_datard;
wire        we        ;
always @(*)
  case(mod_addr)
    MODADDR_ID        :reg_datard=reg_datard_id        ;
    MODADDR_PWR       :reg_datard=reg_datard_pwr       ;
    MODADDR_ADC       :reg_datard=reg_datard_adc       ;
    MODADDR_CTRL      :reg_datard=reg_datard_ctrl      ;
    MODADDR_CTRLSOFT  :reg_datard=reg_datard_ctrlsoft  ;
    MODADDR_TRG       :reg_datard=reg_datard_trg       ;
    MODADDR_TRGSEQ    :reg_datard=reg_datard_trgseq    ;
    MODADDR_TRGMON    :reg_datard=reg_datard_trgmon    ;
    MODADDR_RST       :reg_datard=reg_datard_rst       ;
    MODADDR_RDOMUX    :reg_datard=reg_datard_rdomux    ;
    MODADDR_RDOPAR    :reg_datard=reg_datard_rdopar    ;
    MODADDR_RDOCTRL   :reg_datard=reg_datard_rdoctrl   ;
    MODADDR_RDOCTRLDEC:reg_datard=reg_datard_rdoctrldec;
    MODADDR_EVTPKR    :reg_datard=reg_datard_evtpkr    ;
    MODADDR_EVTBLD    :reg_datard=reg_datard_evtbld    ;
    MODADDR_TSYS      :reg_datard=reg_datard_tsys      ;
    MODADDR_XONXOFF   :reg_datard=reg_datard_xonxoff   ;
    default           :reg_datard=16'h2BAD             ;
  endcase

// BUS MASTER
busmaster busmaster(
  .clk_i      (clk       ),
  .rst_i      (rst       ),
  .out_data_i (out0_data ),
  .out_full_o (out0_full ),
  .out_we_i   (out0_we   ),
  .in_data_o  (in0_data  ),
  .in_pktend_o(in0_pktend),
  .in_empty_o (in0_empty ),
  .in_re_i    (in0_re    ),
  .modaddr_o  (mod_addr  ),
  .regaddr_o  (reg_addr  ),
  .regdata_o  (reg_datawr),
  .we_o       (we        ),
  .regdata_i  (reg_datard)
);

// MODULES
id id(
  .clk_i          (clk                       ),
  .rst_i          (rst                       ),
  .reg_we_i       (we && mod_addr==MODADDR_ID),
  .reg_addr_i     (reg_addr                  ),
  .reg_data_i     (reg_datawr                ),
  .reg_data_o     (reg_datard_id             ),
  .brdaddr_i      ({1'b1,brdaddr_i[2:0]}     ), //FIXME
  .board_version_o(board_version             ) // TODO: separate module?
);

wire [63:0] tsys;
tsys tys_mod(
  .clk_i     (clk                         ),
  .rst_i     (rst                         ),
  .reg_we_i  (we && mod_addr==MODADDR_TSYS),
  .reg_addr_i(reg_addr                    ),
  .reg_data_i(reg_datawr                  ),
  .reg_data_o(reg_datard_tsys             ),
  .tsys_o    (tsys                        )
);

wire ldo_en;
pwr pwr(
  .clk_i     (clk                        ),
  .rst_i     (rst                        ),
  .reg_we_i  (we && mod_addr==MODADDR_PWR),
  .reg_addr_i(reg_addr                   ),
  .reg_data_i(reg_datawr                 ),
  .reg_data_o(reg_datard_pwr             ),
  .tsys_i    (tsys                       ),
  .adca_i    (adcs[5]                    ),
  .adcd_i    (adcs[3]                    ),
  .ldo_en_o  (ldo_en                     )                    
);
assign ldo_en_o =ldo_en; // FIXME: board versions
assign ldo2_en_o=ldo_en; // FIXME: board versions

wire [11:0] adcs[5:0];
adc adc(
  .clk_i     (clk                        ), 
  .rst_i     (rst                        ),
  .reg_we_i  (we && mod_addr==MODADDR_ADC),
  .reg_addr_i(reg_addr                   ),
  .reg_data_i(reg_datawr                 ),
  .reg_data_o(reg_datard_adc             ),
  .adc_cs_n_o(adc_cs_n_o                 ),
  .adc_clk_o (adc_clk_o                  ),
  .adc_d_i   (adc_d_i                    ),
  .adc0_o    (adcs[0]                    ),
  .adc1_o    (adcs[1]                    ),
  .adc2_o    (adcs[2]                    ),
  .adc3_o    (adcs[3]                    ),
  .adc4_o    (adcs[4]                    ),
  .adc5_o    (adcs[5]                    )
);

wire alpide_phase;

wire [ 7:0] ctrl_opcode     ;
wire [ 7:0] ctrl_chipid     ;
wire [15:0] ctrl_addr       ;  
wire [15:0] ctrl_datawr     ;
wire [15:0] ctrl_datard     ;
wire        ctrl_rd         ;
wire        ctrl_wr         ;
wire        ctrl_cmd        ;
wire        ctrl_ack        ;
wire [ 7:0] ctrl_trg_opcode ;
wire        ctrl_trg_cmd    ;
wire        ctrl_trg_ack    ;
wire [ 7:0] ctrl_fc_opcode  ;
wire [ 7:0] ctrl_fc_chipid  ;
wire [15:0] ctrl_fc_addr    ;  
wire [15:0] ctrl_fc_datawr  ;
wire        ctrl_fc_wr      ;
wire        ctrl_fc_ack     ;
wire [ 7:0] ctrl_rdo_opcode ;
wire [ 7:0] ctrl_rdo_chipid ;
wire [15:0] ctrl_rdo_addr   ;  
wire        ctrl_rdo_rd     ;
wire        ctrl_rdo_ack    ;
wire [ 7:0] ctrl_soft_opcode;
wire [ 7:0] ctrl_soft_chipid;
wire [15:0] ctrl_soft_addr  ;  
wire [15:0] ctrl_soft_datawr;
wire        ctrl_soft_rd    ;
wire        ctrl_soft_wr    ;
wire        ctrl_soft_cmd   ;
wire        ctrl_soft_ack   ;
ctrl ctrl(
  .clk_i            (clk                         ),
  .rst_i            (rst                         ),
  .reg_we_i         (we && mod_addr==MODADDR_CTRL),
  .reg_addr_i       (reg_addr                    ),
  .reg_data_i       (reg_datawr                  ),
  .reg_data_o       (reg_datard_ctrl             ),
  .alpide_phase_i   (alpide_phase                ),
  .opcode_i         (ctrl_opcode                 ),
  .chipid_i         (ctrl_chipid                 ),
  .addr_i           (ctrl_addr                   ),  
  .data_i           (ctrl_datawr                 ),
  .rd_i             (ctrl_rd                     ),
  .wr_i             (ctrl_wr                     ),
  .cmd_i            (ctrl_cmd                    ),
  .data_o           (ctrl_datard                 ),
  .ack_o            (ctrl_ack                    ),
  .alpide_dctrl_i   (alpide_dctrl_i              ),
  .alpide_dctrl_o   (alpideio_dctrlo             ),
  .alpide_dctrl_oe_o(alpideio_dctrloe            )
);
ctrl_arb  ctrl_arb(
  .clk_i        (clk             ),
  .rst_i        (rst             ),
  .trg_opcode_i (ctrl_trg_opcode ),
  .trg_cmd_i    (ctrl_trg_cmd    ),
  .trg_ack_o    (ctrl_trg_ack    ),
  .fc_opcode_i  (ctrl_fc_opcode  ),
  .fc_chipid_i  (ctrl_fc_chipid  ),
  .fc_addr_i    (ctrl_fc_addr    ),
  .fc_data_i    (ctrl_fc_datawr  ),
  .fc_wr_i      (ctrl_fc_wr      ),
  .fc_ack_o     (ctrl_fc_ack     ),
  .rdo_opcode_i (ctrl_rdo_opcode ),
  .rdo_chipid_i (ctrl_rdo_chipid ),
  .rdo_addr_i   (ctrl_rdo_addr   ),
  .rdo_rd_i     (ctrl_rdo_rd     ),
  .rdo_ack_o    (ctrl_rdo_ack    ),
  .soft_opcode_i(ctrl_soft_opcode),
  .soft_chipid_i(ctrl_soft_chipid),
  .soft_addr_i  (ctrl_soft_addr  ),  
  .soft_data_i  (ctrl_soft_datawr),
  .soft_rd_i    (ctrl_soft_rd    ),
  .soft_wr_i    (ctrl_soft_wr    ),
  .soft_cmd_i   (ctrl_soft_cmd   ),
  .soft_ack_o   (ctrl_soft_ack   ),
  .ctrl_opcode_o(ctrl_opcode     ),
  .ctrl_chipid_o(ctrl_chipid     ),
  .ctrl_addr_o  (ctrl_addr       ),  
  .ctrl_data_o  (ctrl_datawr     ),
  .ctrl_rd_o    (ctrl_rd         ),
  .ctrl_wr_o    (ctrl_wr         ),
  .ctrl_cmd_o   (ctrl_cmd        ),
  .ctrl_data_i  (ctrl_datard     ),
  .ctrl_ack_i   (ctrl_ack        )
);
ctrl_soft ctrl_soft(
  .clk_i        (clk                             ),
  .rst_i        (rst                             ),
  .reg_we_i     (we && mod_addr==MODADDR_CTRLSOFT),
  .reg_addr_i   (reg_addr                        ),
  .reg_data_i   (reg_datawr                      ),
  .reg_data_o   (reg_datard_ctrlsoft             ),
  .opcode_o     (ctrl_soft_opcode                ),
  .chipid_o     (ctrl_soft_chipid                ),
  .addr_o       (ctrl_soft_addr                  ),  
  .data_o       (ctrl_soft_datawr                ),
  .rd_o         (ctrl_soft_rd                    ),
  .wr_o         (ctrl_soft_wr                    ),
  .cmd_o        (ctrl_soft_cmd                   ),
  .data_i       (ctrl_datard                     ),
  .ack_i        (ctrl_soft_ack                   )
);

wire rdo_done        ;
wire trgmon_trg_req  ;
wire trgmon_trg_acc  ;
wire trgmon_bsy      ;
wire trgmon_bsy_ext  ;
wire trgmon_bsy_fix  ;
wire trgmon_bsy_past ;
wire trgmon_bsy_rdo  ;
wire trgmon_bsy_send ;
wire trgmon_bsy_force;
wire softtrg         ;
wire trg             ;
wire bld_rdodone     ;
trg trg_mod(
  .clk_i          (clk                        ),
  .rst_i          (rst                        ),
  .reg_we_i       (we && mod_addr==MODADDR_TRG),
  .reg_addr_i     (reg_addr                   ),
  .reg_data_i     (reg_datawr                 ),
  .reg_data_o     (reg_datard_trg             ),
  .ctrl_opcode_o  (ctrl_trg_opcode            ),
  .ctrl_cmd_o     (ctrl_trg_cmd               ),
  .ctrl_ack_i     (ctrl_trg_ack               ),
  .trg_o          (trg                        ),
  .rdo_done_i     (bld_rdodone                ), // TODO: differnt operating modes. This is ping-pong
  .trg_req_o      (trgmon_trg_req             ),
  .trg_acc_o      (trgmon_trg_acc             ),
  .bsy_o          (trgmon_bsy                 ),
  .bsy_ext_o      (trgmon_bsy_ext             ),
  .bsy_fix_o      (trgmon_bsy_fix             ),
  .bsy_past_o     (trgmon_bsy_past            ),
  .bsy_rdo_o      (trgmon_bsy_rdo             ),
  .bsy_send_o     (trgmon_bsy_send            ),
  .bsy_force_o    (trgmon_bsy_force           ),
  .softtrg_i      (softtrg                    ),
  .watermark_low_i(rdo_low                    ),
  .exttrg_i       (exttrg_i||!brdaddr_i[3]    ), // FIXME
  .extbsy_i       (extbsy_i                   ),
  .exttrg_o       (exttrg_o                   ),
  .extbsy_o       (extbsy_o                   )
);
trg_seq trg_seq(
  .clk_i      (clk                           ),
  .rst_i      (rst                           ),
  .reg_we_i   (we && mod_addr==MODADDR_TRGSEQ),
  .reg_addr_i (reg_addr                      ),
  .reg_data_i (reg_datawr                    ),
  .reg_data_o (reg_datard_trgseq             ),
  .trg_o      (softtrg                       )
);
trg_mon trg_mon(
  .clk_i      (clk                           ),
  .rst_i      (rst                           ),
  .tsys_i     (tsys                          ),
  .reg_we_i   (we && mod_addr==MODADDR_TRGMON),
  .reg_addr_i (reg_addr                      ),
  .reg_data_i (reg_datawr                    ),
  .reg_data_o (reg_datard_trgmon             ),
  .trg_req_i  (trgmon_trg_req                ),
  .trg_acc_i  (trgmon_trg_acc                ),
  .bsy_i      (trgmon_bsy                    ),
  .bsy_ext_i  (trgmon_bsy_ext                ),
  .bsy_fix_i  (trgmon_bsy_fix                ),
  .bsy_past_i (trgmon_bsy_past               ),
  .bsy_rdo_i  (trgmon_bsy_rdo                ),
  .bsy_send_i (trgmon_bsy_send               ),
  .bsy_force_i(trgmon_bsy_force              ),
  .exttrg_i   (exttrg_i                      ),
  .extbsy_i   (extbsy_i                      ),
  .exttrg_o   (exttrg_o                      ),
  .extbsy_o   (extbsy_o                      )
);

wire alpideio_rst      ;
wire alpideio_forcezero;
wire alpideio_oe       ;
wire alpideio_dctrlo   ; // TODO: consistent naming of dctrl_o dctrlo_o dctrlo_i etc
wire alpideio_dctrloe  ;
alpideio alpideio(
  .clk_i         (clk               ),
  .oe_i          (alpideio_oe       ),
  .forcezero_i   (alpideio_forcezero),
  .rst_i         (alpideio_rst      ),
  .dctrl_i       (alpideio_dctrlo   ),
  .dctrl_oe_i    (alpideio_dctrloe  ),
  .alpide_phase_o(alpide_phase      ),
  .mclk_o        (alpide_mclk_o     ),
  .mclk_oe_o     (alpide_mclk_oe_o  ),
  .pordis_n_o    (alpide_pordis_n_o ),
  .rst_n_o       (alpide_rst_n_o    ),
  .dctrl_o       (alpide_dctrl_o    ),
  .dctrl_oe_o    (alpide_dctrl_oe_o )
);
alpiderst alpiderst(
  .clk_i      (clk                        ),
  .rst_i      (rst                        ),
  .reg_we_i   (we && mod_addr==MODADDR_RST),
  .reg_addr_i (reg_addr                   ),
  .reg_data_i (reg_datawr                 ),
  .reg_data_o (reg_datard_rst             ),
  .ldo_en_i   (ldo_en                     ),
  .rst_o      (alpideio_rst               ),
  .forcezero_o(alpideio_forcezero         ),
  .oe_o       (alpideio_oe                )
);

wire [7:0] rdopar_data   ;
wire       rdopar_evtdone;
wire       rdopar_we     ;
rdo rdopar(
  .clk_i         (clk                           ),
  .rst_i         (rst                           ),
  .reg_we_i      (we && mod_addr==MODADDR_RDOPAR),
  .reg_addr_i    (reg_addr                      ),
  .reg_data_i    (reg_datawr                    ),
  .reg_data_o    (reg_datard_rdopar             ),
  .alpide_phase_i(alpide_phase                  ),
  .alpide_data_i (alpide_data_i                 ),
  .data_o        (rdopar_data                   ),
  .evtdone_o     (rdopar_evtdone                ),
  .we_o          (rdopar_we                     )
);
wire        rdo_low        ;
wire        rdo_high       ;
xonxoff xonxoff(
  .clk_i           (clk                            ),
  .rst_i           (rst                            ),
  .tsys_i          (tsys                           ),
  .reg_we_i        (we && mod_addr==MODADDR_XONXOFF),
  .reg_addr_i      (reg_addr                       ),
  .reg_data_i      (reg_datawr                     ),
  .reg_data_o      (reg_datard_xonxoff             ),
  .watermark_high_i(rdo_high                       ),
  .watermark_low_i (rdo_low                        ),
  .ctrl_opcode_o   (ctrl_fc_opcode                 ),
  .ctrl_chipid_o   (ctrl_fc_chipid                 ),
  .ctrl_addr_o     (ctrl_fc_addr                   ),
  .ctrl_data_o     (ctrl_fc_datawr                 ),
  .ctrl_wr_o       (ctrl_fc_wr                     ),
  .ctrl_ack_i      (ctrl_fc_ack                    )
);

wire [7: 0] rdoctrl_data   ;
wire [23:0] rdoctrl_data24 ;
wire        rdoctrl_stop   ;
wire        rdoctrl_evtdone;
wire        rdoctrl_we     ;
wire        rdoctrl_we24   ;
wire        rdoctrl_full   ;
wire        rdoctrl_done   ;
rdoctrl rdoctrl(
  .clk_i        (clk                           ),
  .rst_i        (rst                           ),
  .reg_we_i     (we && mod_addr==MODADDR_RDOCTRL),
  .reg_addr_i   (reg_addr                      ),
  .reg_data_i   (reg_datawr                    ),
  .reg_data_o   (reg_datard_rdoctrl            ),
  .trg_i        (trg                           ),
  .rdo_stop_i   (rdoctrl_stop                  ),
  .rdo_done_o   (rdoctrl_done                  ),
  .ctrl_opcode_o(ctrl_rdo_opcode               ),
  .ctrl_chipid_o(ctrl_rdo_chipid               ),
  .ctrl_addr_o  (ctrl_rdo_addr                 ),  
  .ctrl_rd_o    (ctrl_rdo_rd                   ),
  .ctrl_data_i  (ctrl_datard                   ),
  .ctrl_ack_i   (ctrl_rdo_ack                  ),
  .evt_data_o   (rdoctrl_data24                ),
  .evt_we_o     (rdoctrl_we24                  ),
  .evt_full_i   (rdoctrl_full                  )
);

wire pkr_full;
rdoctrl_decoder rdo_ctrl_decoder(
  .clk_i     (clk                               ),
  .rst_i     (rst                               ),
  .reg_we_i  (we && mod_addr==MODADDR_RDOCTRLDEC),
  .reg_addr_i(reg_addr                          ),
  .reg_data_i(reg_datawr                        ),
  .reg_data_o(reg_datard_rdoctrldec             ),
  .data_i    (rdoctrl_data24                    ),
  .stopread_o(rdoctrl_stop                      ),
  .data_o    (rdoctrl_data                      ),
  .evtdone_o (rdoctrl_evtdone                   ),
  .we_i      (rdoctrl_we24                      ),
  .we_o      (rdoctrl_we                        ),
  .full_o    (rdoctrl_full                      )
);

wire [7:0] rdo_data   ;
wire       rdo_evtdone;
wire       rdo_we     ;
wire       rdo_re     ;
rdo_mux rdo_mux(
  .clk_i            (clk                           ),
  .rst_i            (rst                           ),
  .reg_we_i         (we && mod_addr==MODADDR_RDOMUX),
  .reg_addr_i       (reg_addr                      ),
  .reg_data_i       (reg_datawr                    ),
  .reg_data_o       (reg_datard_rdomux             ),
  .rdopar_data_i    (rdopar_data                   ),
  .rdopar_evtdone_i (rdopar_evtdone                ),
  .rdopar_we_i      (rdopar_we                     ),
  .rdopar_done_i    (rdopar_evtdone                ),
  .rdoctrl_data_i   (rdoctrl_data                  ),
  .rdoctrl_evtdone_i(rdoctrl_evtdone               ),
  .rdoctrl_we_i     (rdoctrl_we                    ),
  .rdoctrl_done_i   (rdoctrl_done                  ),
  .rdo_data_o       (rdo_data                      ),
  .rdo_evtdone_o    (rdo_evtdone                   ),
  .rdo_we_o         (rdo_we                        ),
  .rdo_done_o       (rdo_done                      )
);
wire        pkr_empty;
wire [31:0] pkr_data;
wire        pkr_evtdone;
wire        bld_re;
evt_packer evt_packer(
  .clk_i           (clk                           ),
  .rst_i           (rst                           ),
  .reg_we_i        (we && mod_addr==MODADDR_EVTPKR),
  .reg_addr_i      (reg_addr                      ),
  .reg_data_i      (reg_datawr                    ),
  .reg_data_o      (reg_datard_evtpkr             ),
  .data_i          (rdo_data                      ),
  .evtdone_i       (rdo_evtdone                   ),
  .data_o          (pkr_data                      ),
  .evtdone_o       (pkr_evtdone                   ), // TODO: packets etc
  .we_i            (rdo_we                        ),
  .re_i            (bld_re                        ),
  .full_o          (pkr_full                      ),
  .empty_o         (pkr_empty                     )
);
wire bld_evtdone     ;
evt_builder evt_builder(
  .clk_i           (clk                           ),
  .rst_i           (rst                           ),
  .tsys_i          (tsys                          ),
  .reg_we_i        (we && mod_addr==MODADDR_EVTBLD),
  .reg_addr_i      (reg_addr                      ),
  .reg_data_i      (reg_datawr                    ),
  .reg_data_o      (reg_datard_evtbld             ),
  .trg_i           (trg                           ),
  .empty_i         (pkr_empty                     ),
  .data_i          (pkr_data                      ),
  .evtdone_i       (pkr_evtdone                   ),
  .re_o            (bld_re                        ),
  .watermark_low_o (rdo_low                       ),
  .watermark_high_o(rdo_high                      ),
  .rdodone_o       (bld_rdodone                   ),
  .empty_o         (in1_empty                     ),
  .data_o          (in1_data                      ),
  .evtdone_o       (bld_evtdone                   ),
  .re_i            (in1_re                        )
);
assign in1_pktend=bld_evtdone; // TODO: here readout done and evtdone are the same, but evtdone_o is looked at with re_i

assign dbg_o={alpide_dctrl_o,trg,trgmon_bsy,bld_evtdone};

endmodule

