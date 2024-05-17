module pwr(
  input             clk_i       ,
  input             rst_i       ,
  input             reg_we_i    ,
  input      [ 7:0] reg_addr_i  ,
  input      [15:0] reg_data_i  ,
  output reg [15:0] reg_data_o  ,
  input      [63:0] tsys_i      ,
  input      [11:0] adca_i      ,
  input      [11:0] adcd_i      ,
  output reg        ldo_en_o
);

localparam [7:0] REGADDR_STATUS=8'h00,
                 REGADDR_CMD   =8'h02,
                 REGADDR_THRA  =8'h03,
                 REGADDR_THRD  =8'h04,
                 REGADDR_DELAY =8'h05,
                 REGADDR_TON0  =8'h08,
                 REGADDR_TON1  =8'h09,
                 REGADDR_TON2  =8'h0A,
                 REGADDR_TON3  =8'h0B,
                 REGADDR_TOFF0 =8'h0C,
                 REGADDR_TOFF1 =8'h0D,
                 REGADDR_TOFF2 =8'h0E,
                 REGADDR_TOFF3 =8'h0F,
                 REGADDR_PMTA  =8'h10,
                 REGADDR_PMTD  =8'h11,
                 REGADDR_PMADCA=8'h12,
                 REGADDR_PMADCD=8'h13;
localparam [15:0] CMD_ON =16'h0001,
                  CMD_OFF=16'h0000;

reg [15:0] delay;
reg [15:0] tota;
reg [15:0] totd;
reg [11:0] thra;
reg [11:0] thrd;
wire oca=ldo_en_o&&(adca_i>thra);
wire ocd=ldo_en_o&&(adcd_i>thrd);
always @(posedge clk_i)
  if (rst_i)
    tota<=0;
  else if(oca)
    tota<=tota+1'b1;
  else
    tota<=0;
always @(posedge clk_i)
  if (rst_i)
    totd<=0;
  else if(ocd)
    totd<=totd+1'b1;
  else
    totd<=0;
wire fusea=tota>delay;
wire fused=totd>delay;
reg [63:0] ton;
reg [63:0] toff;
reg        fuse;
reg [15:0] pmta;
reg [15:0] pmtd;
reg [11:0] pmadca;
reg [11:0] pmadcd;
always @(posedge clk_i)
  if (rst_i) begin
    ldo_en_o<=0;
    fuse    <=0;
    ton     <={64{1'b1}};
    toff    <={64{1'b1}};
    pmta    <=0;
    pmtd    <=0;
    pmadca  <=0;
    pmadcd  <=0;
  end else if (ldo_en_o && (fusea || fused)) begin
    ldo_en_o<=0;
    fuse    <=1;
    toff    <=tsys_i;
    pmta    <=tota;
    pmtd    <=totd;
    pmadca  <=adca_i;
    pmadcd  <=adcd_i;
  end else if (en_strb) begin
    ldo_en_o<=1;
    fuse    <=0;
    ton     <=tsys_i; // FIXME: this is 1 clk too early...
  end else if (dis_strb) begin
    ldo_en_o<=0;
    toff    <=tsys_i;
  end

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS,
    REGADDR_CMD   :reg_data_o={{14{1'b0}},fuse,ldo_en_o};
    REGADDR_THRA  :reg_data_o={4'b0,thra};
    REGADDR_THRD  :reg_data_o={4'b0,thrd};
    REGADDR_DELAY :reg_data_o=delay;
    REGADDR_TON0  :reg_data_o=ton[15: 0];
    REGADDR_TON1  :reg_data_o=ton[31:16];
    REGADDR_TON2  :reg_data_o=ton[47:32];
    REGADDR_TON3  :reg_data_o=ton[63:48];
    REGADDR_TOFF0 :reg_data_o=toff[15: 0];
    REGADDR_TOFF1 :reg_data_o=toff[31:16];
    REGADDR_TOFF2 :reg_data_o=toff[47:32];
    REGADDR_TOFF3 :reg_data_o=toff[63:48];
    REGADDR_PMTA  :reg_data_o=pmta;
    REGADDR_PMTD  :reg_data_o=pmtd;
    REGADDR_PMADCA:reg_data_o={4'b0,pmadca};
    REGADDR_PMADCD:reg_data_o={4'b0,pmadcd};
    default       :reg_data_o=16'hF001;
  endcase

wire en_strb =reg_addr_i==REGADDR_CMD&&reg_data_i==CMD_ON &&reg_we_i;
wire dis_strb=reg_addr_i==REGADDR_CMD&&reg_data_i==CMD_OFF&&reg_we_i;

always @(posedge clk_i)
       if(rst_i                               ) thra<=0               ;
  else if(reg_addr_i==REGADDR_THRA && reg_we_i) thra<=reg_data_i[11:0];

always @(posedge clk_i)
       if(rst_i                               ) thrd<=0               ;
  else if(reg_addr_i==REGADDR_THRD && reg_we_i) thrd<=reg_data_i[11:0];

always @(posedge clk_i)
       if(rst_i                                ) delay<=0         ;
  else if(reg_addr_i==REGADDR_DELAY && reg_we_i) delay<=reg_data_i;

endmodule

