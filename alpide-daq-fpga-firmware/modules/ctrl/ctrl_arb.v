module ctrl_arb(
  input             clk_i        ,
  input             rst_i        ,
// TRIGGER
  input      [ 7:0] trg_opcode_i ,
  input             trg_cmd_i    ,
  output reg        trg_ack_o    ,
// XON/XOFF FLOW CONTROL
  input      [ 7:0] fc_opcode_i  ,
  input      [ 7:0] fc_chipid_i  ,
  input      [15:0] fc_addr_i    ,  
  input      [15:0] fc_data_i    ,
  input             fc_wr_i      ,
  output reg        fc_ack_o     ,
// READOUT VIA SLOW CONTROL
  input      [ 7:0] rdo_opcode_i ,
  input      [ 7:0] rdo_chipid_i ,
  input      [15:0] rdo_addr_i   ,  
  input             rdo_rd_i     ,
  output reg        rdo_ack_o    ,
// SOFTWARE (USB)
  input      [ 7:0] soft_opcode_i,
  input      [ 7:0] soft_chipid_i,
  input      [15:0] soft_addr_i  ,  
  input      [15:0] soft_data_i  ,
  input             soft_rd_i    ,
  input             soft_wr_i    ,
  input             soft_cmd_i   ,
  output reg        soft_ack_o   ,
// ctrl module
  output reg [ 7:0] ctrl_opcode_o,
  output reg [ 7:0] ctrl_chipid_o,
  output reg [15:0] ctrl_addr_o  ,  
  output reg [15:0] ctrl_data_o  ,
  output reg        ctrl_rd_o    ,
  output reg        ctrl_wr_o    ,
  output reg        ctrl_cmd_o   ,
  input      [15:0] ctrl_data_i  ,
  input             ctrl_ack_i   
);

reg        [2:0] nextstate,state;
localparam [2:0] IDLE=0,TRG_CMD=1,FC_WR=2,RDO_RD=3,SOFT_CMD=4,SOFT_RD=5,SOFT_WR=6;
always @(posedge clk_i)
  if (rst_i)
    state<=IDLE;
  else
    state<=nextstate;

always @(*) begin
  nextstate=state;
  case(state)
    IDLE:      if(trg_cmd_i ) nextstate=TRG_CMD ;
          else if(fc_wr_i   ) nextstate=FC_WR   ;
          else if(rdo_rd_i  ) nextstate=RDO_RD  ;
          else if(soft_cmd_i) nextstate=SOFT_CMD;
          else if(soft_rd_i ) nextstate=SOFT_RD ;
          else if(soft_wr_i ) nextstate=SOFT_WR ;
    default:   if(ctrl_ack_i) nextstate=IDLE    ; // TODO: fast track?
  endcase
end
        
always @(*) begin
  ctrl_opcode_o= 8'h  XX;
  ctrl_chipid_o= 8'h  XX;
  ctrl_addr_o  =16'hXXXX;
  ctrl_data_o  =16'hXXXX;
  ctrl_cmd_o   =0;
  ctrl_rd_o    =0;
  ctrl_wr_o    =0;
  trg_ack_o    =0;
  fc_ack_o     =0;
  rdo_ack_o    =0;
  soft_ack_o   =0;
  case(nextstate) // (!)
     TRG_CMD :begin ctrl_cmd_o=1;ctrl_opcode_o=trg_opcode_i ;                                                                            end
     FC_WR   :begin ctrl_wr_o =1;ctrl_opcode_o=fc_opcode_i  ;ctrl_chipid_o=fc_chipid_i  ;ctrl_addr_o=fc_addr_i  ;ctrl_data_o=fc_data_i  ;end
     RDO_RD  :begin ctrl_rd_o =1;ctrl_opcode_o=rdo_opcode_i ;ctrl_chipid_o=rdo_chipid_i ;ctrl_addr_o=rdo_addr_i ;                        end
     SOFT_CMD:begin ctrl_cmd_o=1;ctrl_opcode_o=soft_opcode_i;                                                                            end
     SOFT_RD :begin ctrl_rd_o =1;ctrl_opcode_o=soft_opcode_i;ctrl_chipid_o=soft_chipid_i;ctrl_addr_o=soft_addr_i;                        end
     SOFT_WR :begin ctrl_wr_o =1;ctrl_opcode_o=soft_opcode_i;ctrl_chipid_o=soft_chipid_i;ctrl_addr_o=soft_addr_i;ctrl_data_o=soft_data_i;end
     default:;
  endcase
  case(state)
     TRG_CMD :trg_ack_o =ctrl_ack_i;
     FC_WR   :fc_ack_o  =ctrl_ack_i;
     RDO_RD  :rdo_ack_o =ctrl_ack_i;
     SOFT_CMD,
     SOFT_RD ,
     SOFT_WR :soft_ack_o=ctrl_ack_i;
     default:;
  endcase
end

endmodule

