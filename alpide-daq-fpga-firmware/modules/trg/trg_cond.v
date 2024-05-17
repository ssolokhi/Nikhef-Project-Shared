module trg_cond(
  input      rst_i,
  input      clk_i,
  input      trg_i,
  output reg trg_o
);

reg [2:0] nextstate,state;
localparam [2:0] IDLE=0,TRG1=1,TRG2=2,TRG3=3,TRG4=4,WAIT1=5,WAIT2=6,WAIT3=7;
always @(posedge clk_i)
  if (rst_i) state<=IDLE     ;
  else       state<=nextstate;

always @* begin
  nextstate=state;
  case(state)
    IDLE : if(trg_i) nextstate=TRG1 ;
    TRG1 :           nextstate=TRG2 ;
    TRG2 :           nextstate=TRG3 ;
    TRG3 :           nextstate=TRG4 ;
    TRG4 :           nextstate=WAIT1;
    WAIT1:           nextstate=WAIT2;
    WAIT2:           nextstate=WAIT3;
    WAIT3:           nextstate=IDLE ;
    default:;
  endcase
end

always @*
  case(nextstate) // nextstate!
    TRG1,TRG2,TRG3,TRG4: trg_o=1;
    default            : trg_o=0;    
  endcase

endmodule

