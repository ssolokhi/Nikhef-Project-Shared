// This FIFO gets 4x(8+1) bits in and writes 4x8+1 bits out, i.e. packs the ALPIDE data into 32 words + alignes start of events to 32 bit
module evt_packer(
  input             clk_i           ,
  input             rst_i           ,

  input             reg_we_i         , // ignored.
  input      [ 7:0] reg_addr_i       ,
  input      [15:0] reg_data_i       , // ignored.
  output reg [15:0] reg_data_o       ,

  input      [ 7:0] data_i          ,
  input             evtdone_i       ,
  output     [31:0] data_o          ,
  output            evtdone_o       ,
  input             we_i            ,
  input             re_i            ,
  output            full_o          ,
  output            empty_o          
);

localparam REGADDR_STATUS=8'h00,
           REGADDR_CMD   =8'h02,
           REGADDR_NEV   =8'h03,
           REGADDR_NIN8  =8'h04,
           REGADDR_NIN32 =8'h05,
           REGADDR_NOUT32=8'h06;

localparam [15:0] CMD_RST=16'h0000,
                  CMD_CLR=16'h0001;

wire rst,clr;

reg [7:0] data_r;
reg [7:0] data_rr;
reg [7:0] data_rrr;

always @(posedge clk_i)
  if (we_i) begin
    data_r  <=data_i ;
    data_rr <=data_r ;
    data_rrr<=data_rr;
  end

reg [1:0] cnt;
wire we=(cnt==3||evtdone_i)&&we_i;
always @(posedge clk_i)
  if      (rst_i||rst) cnt<=0       ;
  else if (we        ) cnt<=0       ;
  else if (we_i      ) cnt<=cnt+1'b1;

reg [31:0] data;
always @(*)
  case (cnt) 
    0: data={8'hFF ,8'hFF ,8'hFF  ,data_i  };
    1: data={8'hFF ,8'hFF ,data_i ,data_r  };
    2: data={8'hFF ,data_i,data_r ,data_rr };
    3: data={data_i,data_r,data_rr,data_rrr};
  endcase

data_fifo data_fifo(
  .clk_i           (clk_i             ),
  .rst_i           (rst_i||rst        ),
  .data_i          ({evtdone_i,data  }),
  .data_o          ({evtdone_o,data_o}),
  .re_i            (re_i              ),
  .we_i            (we&&!full_o       ), // TODO: check should not be needed... report it
  .empty_o         (empty_o           ),
  .full_o          (full_o            )
);

reg [15:0] nev   ;
reg [15:0] nin8  ;
reg [15:0] nin32 ;
reg [15:0] nout32;
always @(posedge clk_i)
       if(rst_i || rst || clr) nev<=0     ;
  else if(evtdone_i && we_i) nev<=nev+1'b1;
always @(posedge clk_i)
       if(rst_i || rst || clr) nin8<=0        ;
  else if(we_i ) nin8<=nin8+1'b1;
always @(posedge clk_i)
       if(rst_i || rst || clr) nin32<=0         ;
  else if(we&&!full_o) nin32<=nin32+1'b1;
always @(posedge clk_i)
       if(rst_i || rst || clr) nout32<=0          ;
  else if(re_i ) nout32<=nout32+1'b1;

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS,
    REGADDR_CMD   :reg_data_o={cnt,6'b0,empty_o,full_o};
    REGADDR_NEV   :reg_data_o=nev           ;
    REGADDR_NIN8  :reg_data_o=nin8          ;
    REGADDR_NIN32 :reg_data_o=nin32         ;
    REGADDR_NOUT32:reg_data_o=nout32        ;
    default       :reg_data_o=16'hF001      ;
  endcase
assign rst=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_RST && reg_we_i;
assign clr=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_CLR && reg_we_i;

endmodule

