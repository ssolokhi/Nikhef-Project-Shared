module xonxoff(
  input             rst_i           ,
  input             clk_i           ,
  input      [63:0] tsys_i          ,
  input             reg_we_i        ,
  input      [ 7:0] reg_addr_i      ,
  input      [15:0] reg_data_i      ,
  output reg [15:0] reg_data_o      ,
  // data FIFO input
  input             watermark_high_i, // -> XON
  input             watermark_low_i , // -> XOFF if XON was sent before
  // to ctrl interface
  output     [ 7:0] ctrl_opcode_o   ,
  output     [ 7:0] ctrl_chipid_o   ,
  output     [15:0] ctrl_addr_o     ,
  output reg [15:0] ctrl_data_o     ,
  output reg        ctrl_wr_o       ,
  input             ctrl_ack_i   
);

localparam [7:0] REGADDR_STATUS    =8'h00,
                 REGADDR_CTRL      =8'h01,
                 REGADDR_CMD       =8'h02,
                 REGADDR_STATUS_LAT=8'h03,
                 REGADDR_TXON0     =8'h04,
                 REGADDR_TXON1     =8'h05,
                 REGADDR_TXON2     =8'h06,
                 REGADDR_TXON3     =8'h07,
                 REGADDR_TXOFF0    =8'h08,
                 REGADDR_TXOFF1    =8'h09,
                 REGADDR_TXOFF2    =8'h0A,
                 REGADDR_TXOFF3    =8'h0B,
                 REGADDR_NXON      =8'h0C,
                 REGADDR_NXOFF     =8'h0D;
localparam [15:0] CMD_RST=16'h0000,
                  CMD_LAT=16'h0001,
                  CMD_CLR=16'h0002;

reg        [1:0] nextstate,state;
localparam [1:0] IDLE=0,XOFF=1,WAIT=2,XON=3;

wire rst,clr,lat;
reg enable;

always @(posedge clk_i)
  if(rst_i || rst) state<=IDLE     ;
  else             state<=nextstate;

always @(*) begin
  nextstate=state;
  case(state)
    IDLE:if(watermark_high_i && enable) nextstate=XOFF; // enable is checked here, such that the last XOFF-XON is still handled
    XOFF:if(ctrl_ack_i                ) nextstate=WAIT; // this will probably work, but would be nicer to check ack_i only as of the 2nd cycle
    WAIT:if(watermark_low_i           ) nextstate=XON ;
    XON :if(ctrl_ack_i                ) nextstate=IDLE;
  endcase
end

always @(*) begin
  ctrl_data_o=16'hXXXX;
  ctrl_wr_o =0;
  case(state)
    XOFF:begin ctrl_wr_o=1;ctrl_data_o=16'hFF10;end
    XON :begin ctrl_wr_o=1;ctrl_data_o=16'hFF11;end
    default:;
  endcase
end
assign ctrl_opcode_o= 8'h  9C; // WROP
assign ctrl_chipid_o= 8'h  0F; // GLOBAL BROADCAST
assign ctrl_addr_o  =16'h0000; // COMMAND register

reg [63:0] txon ;
reg [63:0] txoff;
reg [15:0] nxon ;
reg [15:0] nxoff;
always @(posedge clk_i) begin
  if (rst_i || rst || clr) begin
    txon <=0;
    txoff<=0;
    nxon <=0;
    nxoff<=0;
  end
  if (state==XON  && nextstate==IDLE) begin 
    if (nxon!=16'hFFFF) nxon<=nxon+1'b1;
    txon<=tsys_i;
  end
  if (state==XOFF && nextstate==WAIT) begin
    if (nxon!=16'hFFFF) nxoff<=nxoff+1'b1;
    txoff<=tsys_i;
  end
end

reg [63:0] txon_lat ;
reg [63:0] txoff_lat;
reg [15:0] nxon_lat ;
reg [15:0] nxoff_lat;
wire [15:0] status={state,watermark_high_i,watermark_low_i,enable};
reg [15:0] status_lat;
always @(posedge clk_i)
  if (rst_i || rst || clr) begin
    txon_lat  <=0;
    txoff_lat <=0;
    nxon_lat  <=0;
    nxoff_lat <=0;
    status_lat<=0;
  end else if (lat) begin
    txon_lat  <=txon  ;
    txoff_lat <=txoff ;
    nxon_lat  <=nxon  ;
    nxoff_lat <=nxoff ;
    status_lat<=status;
  end

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS    ,
    REGADDR_CTRL      ,
    REGADDR_CMD       :reg_data_o=status;
    REGADDR_STATUS_LAT:reg_data_o=status_lat;
    REGADDR_TXON0     :reg_data_o=txon_lat [15: 0];
    REGADDR_TXON1     :reg_data_o=txon_lat [31:16];
    REGADDR_TXON2     :reg_data_o=txon_lat [47:32];
    REGADDR_TXON3     :reg_data_o=txon_lat [63:48];
    REGADDR_TXOFF0    :reg_data_o=txoff_lat[15: 0];
    REGADDR_TXOFF1    :reg_data_o=txoff_lat[31:16];
    REGADDR_TXOFF2    :reg_data_o=txoff_lat[47:32];
    REGADDR_TXOFF3    :reg_data_o=txoff_lat[63:48];
    REGADDR_NXON      :reg_data_o=nxon_lat;
    REGADDR_NXOFF     :reg_data_o=nxoff_lat;
    default           :reg_data_o=16'hF001;
  endcase

always @(posedge clk_i)
       if(rst_i) enable<=0;
  else if(reg_addr_i==REGADDR_CTRL && reg_we_i) enable<=reg_data_i[0];

assign rst=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_RST && reg_we_i;
assign clr=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_CLR && reg_we_i;
assign lat=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_LAT && reg_we_i;
endmodule

