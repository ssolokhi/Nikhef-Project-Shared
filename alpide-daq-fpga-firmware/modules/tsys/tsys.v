module tsys (
  input             clk_i     ,
  input             rst_i     ,
  input             reg_we_i  ,
  input      [ 7:0] reg_addr_i,
  input      [15:0] reg_data_i,
  output reg [15:0] reg_data_o,
  output reg [63:0] tsys_o    
);

localparam [7:0] REGADDR_STATUS=8'h00,
                 REGADDR_CMD   =8'h02,
                 REGADDR_TSYS0 =8'h03,
                 REGADDR_TSYS1 =8'h04,
                 REGADDR_TSYS2 =8'h05,
                 REGADDR_TSYS3 =8'h06;
localparam [15:0] CMD_LAT=16'h0001,
                  CMD_CLR=16'h0002;

wire clr,lat;

always @(posedge clk_i)
  if (rst_i || clr)
    tsys_o<=0;
  else
    tsys_o<=tsys_o+1'b1;

reg [63:0] tsys_lat;
always @(posedge clk_i)
  if (rst_i || clr)
    tsys_lat<=0;
  else if (lat)
    tsys_lat<=tsys_o;

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS,
    REGADDR_CMD  :reg_data_o=0;
    REGADDR_TSYS0:reg_data_o=tsys_lat[15: 0];
    REGADDR_TSYS1:reg_data_o=tsys_lat[31:16];
    REGADDR_TSYS2:reg_data_o=tsys_lat[47:32];
    REGADDR_TSYS3:reg_data_o=tsys_lat[63:48];
    default      :reg_data_o=16'hF001;
  endcase

assign clr=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_CLR && reg_we_i;
assign lat=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_LAT && reg_we_i;

endmodule

