module ctrl_soft(
  input             clk_i     ,
  input             rst_i     ,
  input             reg_we_i  ,
  input      [ 7:0] reg_addr_i,
  input      [15:0] reg_data_i,
  output reg [15:0] reg_data_o,
  output reg [ 7:0] opcode_o  ,
  output reg [ 7:0] chipid_o  ,
  output reg [15:0] addr_o    ,  
  output reg [15:0] data_o    ,
  output reg        rd_o      ,
  output reg        wr_o      ,
  output reg        cmd_o     ,
  input      [15:0] data_i    ,
  input             ack_i   
);

localparam [7:0] REGADDR_STATUS =8'h00,
                 REGADDR_CMD    =8'h02,
                 REGADDR_OPCODE =8'h03,
                 REGADDR_CHIPID =8'h04,
                 REGADDR_ADDR   =8'h05,
                 REGADDR_DATA   =8'h06,
                 REGADDR_RETURN =8'h07;

localparam [15:0] CMD_RD =16'h0002,
                  CMD_WR =16'h0001,
                  CMD_CMD=16'h0000;

wire rd_strb =reg_addr_i==REGADDR_CMD&&reg_data_i==CMD_RD &&reg_we_i;
wire wr_strb =reg_addr_i==REGADDR_CMD&&reg_data_i==CMD_WR &&reg_we_i;
wire cmd_strb=reg_addr_i==REGADDR_CMD&&reg_data_i==CMD_CMD&&reg_we_i;
wire pending=rd_o||wr_o||cmd_o;

always @(posedge clk_i)
  if      (rst_i || ack_i ) begin rd_o<=0;wr_o<=0;cmd_o<=0;end
  else if (!pending && rd_strb )  rd_o<=1;
  else if (!pending && wr_strb )          wr_o<=1;
  else if (!pending && cmd_strb)                  cmd_o<=1;
    
reg [15:0] answer;
always @(posedge clk_i)
       if(rst_i        ) answer<=0     ;
  else if(rd_o && ack_i) answer<=data_i;

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS,
    REGADDR_CMD   : reg_data_o={15'b0,pending};
    REGADDR_OPCODE: reg_data_o={8'b0,opcode_o};
    REGADDR_CHIPID: reg_data_o={8'b0,chipid_o};
    REGADDR_ADDR  : reg_data_o=addr_o;
    REGADDR_DATA  : reg_data_o=data_o;
    REGADDR_RETURN: reg_data_o=answer;
    default       : reg_data_o=16'hF001;
  endcase

always @(posedge clk_i)
       if(rst_i                                 ) opcode_o<=0              ;
  else if(reg_addr_i==REGADDR_OPCODE && reg_we_i) opcode_o<=reg_data_i[7:0];

always @(posedge clk_i)
       if(rst_i                                 ) chipid_o<=8'hFF          ;
  else if(reg_addr_i==REGADDR_CHIPID && reg_we_i) chipid_o<=reg_data_i[7:0];

always @(posedge clk_i)
       if(rst_i                                 ) addr_o  <=0              ;
  else if(reg_addr_i==REGADDR_ADDR   && reg_we_i) addr_o  <=reg_data_i     ;

always @(posedge clk_i)
       if(rst_i                                 ) data_o  <=0              ;
  else if(reg_addr_i==REGADDR_DATA   && reg_we_i) data_o  <=reg_data_i     ;

endmodule

