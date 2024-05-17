module ctrl(
  input             clk_i            ,
  input             rst_i            ,

  input             reg_we_i         , // ignored.
  input      [ 7:0] reg_addr_i       ,
  input      [15:0] reg_data_i       , // ignored.
  output reg [15:0] reg_data_o       ,

  input             alpide_phase_i   ,
  input      [ 7:0] opcode_i         ,
  input      [ 7:0] chipid_i         ,
  input      [15:0] addr_i           ,  
  input      [15:0] data_i           ,
  input             rd_i             ,
  input             wr_i             ,
  input             cmd_i            ,
  output     [15:0] data_o           ,
  output            err_o            ,
  output reg        ack_o            ,
  input             alpide_dctrl_i   ,
  output            alpide_dctrl_o   ,
  output            alpide_dctrl_oe_o
);

localparam REGADDR_STATUS  =8'h00,
           REGADDR_DI0     =8'h03,
           REGADDR_DI1     =8'h04,
           REGADDR_DI2     =8'h05,
           REGADDR_NERR    =8'h06,
           REGADDR_DATAIN  =8'h07,
           REGADDR_CHIPIDIN=8'h08;

localparam DO_LEN= 60;
localparam OE_LEN=105;
localparam DI_LEN= 45;

// "constants" to be fed into OE and DO shift regs:
wire [DO_LEN-1:0] do_cmd={{(DO_LEN-10){1'b1}},
                          1'b1,opcode_i   ,1'b0};
wire [DO_LEN-1:0] do_wr={{(DO_LEN-60){1'b1}},
                         1'b1,data_i[15:8],1'b0,
                         1'b1,data_i[ 7:0],1'b0,
                         1'b1,addr_i[15:8],1'b0,
                         1'b1,addr_i[ 7:0],1'b0,
                         1'b1,chipid_i    ,1'b0,
                         1'b1,opcode_i    ,1'b0};
wire [DO_LEN-1:0] do_rd={{(DO_LEN-40){1'b1}},
                         1'b1,addr_i[15:8],1'b0,
                         1'b1,addr_i[ 7:0],1'b0,
                         1'b1,chipid_i    ,1'b0,
                         1'b1,opcode_i    ,1'b0};
wire [OE_LEN-1:0] oe_cmd={OE_LEN{1'b1}};
wire [OE_LEN-1:0] oe_wr ={OE_LEN{1'b1}};
wire [OE_LEN-1:0] oe_rd ={{10{1'b1}},
                          {50{1'b0}},
                          {45{1'b1}}};
wire [DI_LEN-1:0] err_check={{(DI_LEN-36){1'b1}},
                             1'b1,8'h00,1'b0,
                             1'b1,8'h00,1'b0,
                             1'b1,chipid_i,1'b0,
                             6'b111111};
wire [DI_LEN-1:0] err_mask ={{(DI_LEN-36){1'b1}},
                             1'b1,8'h00,1'b1,
                             1'b1,8'h00,1'b1,
                             1'b1,8'hFF,1'b1,
                             6'b111111};
assign err_o=((di_sr^err_check)&err_mask)==0;

reg loado ;
reg shifto;
reg [DO_LEN-1:0] do_in;
reg [OE_LEN-1:0] oe_in;
reg [DO_LEN-1:0] do_sr;
reg [OE_LEN-1:0] oe_sr;
assign alpide_dctrl_oe_o=oe_sr[0];
assign alpide_dctrl_o   =do_sr[0];
always @(posedge clk_i) begin
  if (rst_i) begin
    do_sr<={DO_LEN{1'b1}};
    oe_sr<={OE_LEN{1'b1}};
  end
  else if (loado) begin
    do_sr<=do_in;
    oe_sr<=oe_in;
  end
  else if (shifto) begin
    do_sr<={1'b1,do_sr[DO_LEN-1:1]};
    oe_sr<={1'b1,oe_sr[OE_LEN-1:1]};
  end   
end

reg              shifti;
reg [DI_LEN-1:0] di_sr;
assign data_o={di_sr[34:27],di_sr[24:17]};
wire [7:0] chipid=di_sr[14: 7];
always @(posedge clk_i)
  if (rst_i)
    di_sr<={DI_LEN{1'b1}};
  else if(shifti)
    di_sr<={alpide_dctrl_i,di_sr[DI_LEN-1:1]};

reg [7:0] n;
reg       nclr;
always @(posedge clk_i)
  if(rst_i || nclr)
    n<=0;
  else if(shifto)
    n<=n+1'b1;

reg        [3:0] state,nextstate;
localparam [3:0] IDLE=0,
                 COMMAND=1,COMMAND_SHIFT=2,            COMMAND_END= 3,
                 WRITE  =4,WRITE_SHIFT  =5,            WRITE_END  = 6,
                 READ   =7,READ_SHIFT   =8,READ_WAIT=9,READ_END   =10;

always @(posedge clk_i)
  if (rst_i)
    state<=IDLE;
  else
    state<=nextstate;

wire phaseo=alpide_phase_i;
wire phasei=alpide_phase_i;

//TODO: speed up!
always @(*) begin
  nextstate=state;
  case(state)
    IDLE         :      if( cmd_i) nextstate=COMMAND      ;
                   else if( wr_i ) nextstate=WRITE        ;
                   else if( rd_i ) nextstate=READ         ;
    COMMAND      :      if(phaseo) nextstate=COMMAND_SHIFT;
    WRITE        :      if(phaseo) nextstate=WRITE_SHIFT  ;
    READ         :      if(phaseo) nextstate=READ_SHIFT   ;
    COMMAND_SHIFT:      if(n== 10) nextstate=COMMAND_END  ; //TODO: find a better way to tune these parameters...
    WRITE_SHIFT  :      if(n== 60) nextstate=WRITE_END    ;
    READ_SHIFT   :      if(n== 96) nextstate=READ_WAIT    ;
    READ_WAIT    :      if(n==105) nextstate=READ_END     ;
    COMMAND_END  :      if(!cmd_i) nextstate=IDLE         ;
    WRITE_END    :      if(!wr_i ) nextstate=IDLE         ;
    READ_END     :      if(!rd_i ) nextstate=IDLE         ;
  endcase
end

always @(*) begin
  loado   =0;
  shifto  =0;
  shifti  =0;
  nclr    =0;
  ack_o   =0;
  oe_in={(OE_LEN-1){1'b1}};
  do_in={(DO_LEN-1){1'b1}};
  case(state)
    COMMAND      :begin nclr=1;oe_in=oe_cmd;do_in=do_cmd;loado=phaseo; end
    WRITE        :begin nclr=1;oe_in=oe_wr ;do_in=do_wr ;loado=phaseo; end
    READ         :begin nclr=1;oe_in=oe_rd ;do_in=do_rd ;loado=phaseo; end
    COMMAND_SHIFT:      shifto=phaseo;
    WRITE_SHIFT  :      shifto=phaseo;
    READ_SHIFT   :begin shifto=phaseo;shifti=phasei; end
    READ_WAIT    :begin shifto=phaseo;               end
    WRITE_END    :begin nclr=1;ack_o=1; end
    COMMAND_END  :begin nclr=1;ack_o=1; end
    READ_END     :begin nclr=1;ack_o=1; end
    default:;
  endcase
end

reg [15:0] nerr;
always @(posedge clk_i)
       if (rst_i) nerr<=0        ;
  else if (err_o && n==104 && phasei) nerr<=nerr+1'b1; // ugly


always @(*)
  case(reg_addr_i)
    REGADDR_STATUS  :reg_data_o=state;
    REGADDR_DI0     :reg_data_o=di_sr[15: 0];
    REGADDR_DI1     :reg_data_o=di_sr[31:16];
    REGADDR_DI2     :reg_data_o={{(47-DI_LEN){1'b0}},di_sr[DI_LEN-1:32]};
    REGADDR_NERR    :reg_data_o=nerr;
    REGADDR_DATAIN  :reg_data_o=data_o; //funny
    REGADDR_CHIPIDIN:reg_data_o={8'h00,chipid};
    default         :reg_data_o=16'hF001;
  endcase

endmodule

