module evt_builder(
  input             clk_i     ,
  input             rst_i     ,
  input      [63:0] tsys_i    ,
  input             reg_we_i  ,
  input      [ 7:0] reg_addr_i,
  input      [15:0] reg_data_i,
  output reg [15:0] reg_data_o,
  
  // Input for event header
  input        trg_i    , // latches header data
  // Input for event trailer
  // TODO: input        rdodone_i,
  
  // ALPIDE data input
  input        empty_i  ,
  input [31:0] data_i   ,
  input        evtdone_i,
  output reg   re_o     ,

  // XON/XOFF circuit
  output       watermark_high_o,
  output       watermark_low_o,

  // interface to trgger
  output            rdodone_o,

  // interface to USB
  output            empty_o  ,
  output     [31:0] data_o   ,
  output            evtdone_o,
  input             re_i
);

localparam [7:0] REGADDR_STATUS   =8'h00,
                 REGADDR_CMD      =8'h02,
                 REGADDR_SATUS_LAT=8'h03,
                 REGADDR_EVNO0    =8'h04,
                 REGADDR_EVNO1    =8'h05,
                 REGADDR_TTRG0    =8'h06,
                 REGADDR_TTRG1    =8'h07,
                 REGADDR_TTRG2    =8'h08,
                 REGADDR_TTRG3    =8'h09;

localparam [15:0] CMD_RST=16'h0000,
                  CMD_LAT=16'h0001,
                  CMD_CLR=16'h0002;

wire rst,clr,lat;

reg [63:0] ttrg;
always @(posedge clk_i)
       if(rst_i) ttrg<=0;
  else if(trg_i) ttrg<=tsys_i;
reg [31:0] evno;
always @(posedge clk_i)
       if(rst_i || clr || rst) evno<=32'hFFFFFFFF;
  else if(trg_i              ) evno<=evno+1'b1;

//             MSB   BYTE2 BYTE1 LSB
// HEADER-00:  MAGIC+FLAGS(e.g. REJECTED)
// HEADER-01:  EVENT_NUMBER
// HEADER-02:  TRG-TIMESTAMP[31:0]
// HEADER-03:  TRG-TIMESTAMP[63:32]
// PAYLOAD-00: A0    BC    Cx    ...
// PAYLOAD-01: ...   ...    ...   ...
// PAYLOAD-XX: ...   B0    PAD   PAD 
// TRAILER-00: MAGIC+FLAGS(e.g. TRUNC)

wire [31:0] header0 =32'hAAAAAAAA;
wire [31:0] header1 =evno;
wire [31:0] header2 =ttrg[31: 0];
wire [31:0] header3 =ttrg[63:32];
wire [31:0] trailer0=32'hBBBBBBBB;

wire        full   ;
reg         evtdone;
reg  [31:0] data   ;
reg         we     ;
evt_fifo evt_fifo(
  .clk_i           (clk_i             ),
  .rst_i           (rst_i             ),
  .data_i          ({evtdone  ,data  }),
  .data_o          ({evtdone_o,data_o}),
  .re_i            (re_i              ),
  .we_i            (we&&!full         ), // TODO: check should not be needed... report it
  .watermark_high_o(watermark_high_o  ),
  .watermark_low_o (watermark_low_o   ),
  .empty_o         (empty_o           ),
  .full_o          (full              )
);
assign rdodone_o=evtdone&&we&&!full;

reg [3:0] nextstate,state;
localparam [3:0] IDLE=0,HEADER0=1,HEADER1=2,HEADER2=3,HEADER3=4,PAYLOAD_READ=5,PAYLOAD_WRITE=6,TRAILER0=7,ERROR=8;

always @(posedge clk_i)
  if (rst_i || rst) state<=IDLE     ;
  else              state<=nextstate;

// TODO: all these full checks shoudl not be needed...
always @(*) begin
  nextstate=state;
  case(state)
    IDLE         :if(trg_i) 
                    if(!full )     nextstate=HEADER0      ;
                    else           nextstate=ERROR        ;
    HEADER0      :if(!full   )     nextstate=HEADER1      ;
    HEADER1      :if(!full   )     nextstate=HEADER2      ;
    HEADER2      :if(!full   )     nextstate=HEADER3      ;
    HEADER3      :if(!full   )     nextstate=PAYLOAD_READ ;
    PAYLOAD_READ :if(!empty_i)     nextstate=PAYLOAD_WRITE;
    PAYLOAD_WRITE:if(!full   )
                    if(!evtdone_i) nextstate=PAYLOAD_READ ;
                    else           nextstate=TRAILER0     ;
    TRAILER0     :if(!full   )     nextstate=IDLE         ;
    default:;
  endcase
end

always @(*) begin
  re_o=0       ;
  we  =0       ;
  data=32'hXXXXXXXX;
  evtdone=1'b0 ;
  case(state)
    HEADER0      :if(!full   ) begin data=header0;           we=1; end
    HEADER1      :if(!full   ) begin data=header1;           we=1; end
    HEADER2      :if(!full   ) begin data=header2;           we=1; end
    HEADER3      :if(!full   ) begin data=header3;           we=1; end
    PAYLOAD_READ :if(!empty_i) re_o=1;
    PAYLOAD_WRITE:if(!full   ) begin data=data_i ;           we=1; end
    TRAILER0     :if(!full   ) begin data=trailer0;evtdone=1;we=1; end
    default:;
  endcase
end

wire [15:0] status={state,watermark_high_o,watermark_low_o,empty_o,full,empty_i};
reg  [15:0] status_lat;
reg  [31:0] evno_lat  ;
reg  [63:0] ttrg_lat  ;

always @(posedge clk_i)
  if(rst_i || rst || clr) begin
    status_lat<=0;
    evno_lat  <=0;
    ttrg_lat  <=0;
  end else if(lat) begin
    status_lat<=status;
    evno_lat  <=evno  ;
    ttrg_lat  <=ttrg  ;
  end

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS   ,
    REGADDR_CMD      :reg_data_o=status         ;
    REGADDR_SATUS_LAT:reg_data_o=status_lat     ;
    REGADDR_EVNO0    :reg_data_o=evno_lat[15: 0];
    REGADDR_EVNO1    :reg_data_o=evno_lat[31:16];
    REGADDR_TTRG0    :reg_data_o=ttrg_lat[15: 0];
    REGADDR_TTRG1    :reg_data_o=ttrg_lat[31:16];
    REGADDR_TTRG2    :reg_data_o=ttrg_lat[47:32];
    REGADDR_TTRG3    :reg_data_o=ttrg_lat[63:48];
    default          :reg_data_o=16'hF001       ;
  endcase

assign rst=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_RST && reg_we_i;
assign clr=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_CLR && reg_we_i;
assign lat=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_LAT && reg_we_i;


endmodule

