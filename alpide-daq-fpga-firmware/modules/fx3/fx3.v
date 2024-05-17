// BASED ON:
// ------------------------------------------------------------
//                  OUTFN Sezione di Cagliari
// ------------------------------------------------------------
//
//  Project: pAlpideFS readout board
//   Module: controller         
//          
//   Author: Davide Marras
// Creation: 28.03.14
// ------------------------------------------------------------

module fx3(
// global:
   input             clk_i         ,
   input             rst_i         , 
// FX3:
   input             fx3_flaga_i   , // OUT0: empty
   input             fx3_flagb_i   , // IN0: avail
   input             fx3_flagc_i   , // IN1: avail
   input             fx3_flagd_i   , // IN2: avail
   output reg [ 1:0] fx3_sladdr_o  ,
   output reg        fx3_sloe_n_o  ,
   output reg        fx3_slcs_n_o  ,
   output reg        fx3_slrd_n_o  ,
   output reg        fx3_slwr_n_o  ,
   output reg        fx3_pktend_n_o,
   inout      [31:0] fx3_dq_io     ,
// data output (USB->DAQ):
   input             out0_full_i   ,
   output     [31:0] out0_data_o   ,
   output reg        out0_we_o     ,
// data input FIFOs (DAQ->USB):
   input             in0_empty_i   ,
   input      [31:0] in0_data_i    ,
   input             in0_pktend_i  ,
   output reg        in0_re_o      ,
   input             in1_empty_i   ,
   input      [31:0] in1_data_i    ,
   input             in1_pktend_i  ,
   output reg        in1_re_o      ,
   input             in2_empty_i   ,
   input      [31:0] in2_data_i    ,
   input             in2_pktend_i  ,
   output reg        in2_re_o      
);

// aliases
wire fx3_out0_empty_i= fx3_flaga_i; // note missing "!"
wire fx3_in0_full_i  =!fx3_flagb_i;
wire fx3_in1_full_i  =!fx3_flagc_i;
wire fx3_in2_full_i  =!fx3_flagd_i;

reg [1:0] sel;
reg [31:0] fx3_dq_o;
always @(*)
  case (fx3_sladdr_o)
    2'h1   : fx3_dq_o=in0_data_i;
    2'h2   : fx3_dq_o=in1_data_i;
    2'h3   : fx3_dq_o=in2_data_i;
    default: fx3_dq_o={32'hXXXXXXXX};
  endcase
assign fx3_dq_io=!fx3_sloe_n_o?32'bZ:fx3_dq_o; // TODO: should this not better be delayed a bit?

reg        [4:0] nextstate,state;
localparam [4:0] OUT0= 0,OUT0_AV= 1,OUT0_CS= 2,OUT0_RD= 3,OUT0_WT=4,OUT0_LAT=5,OUT0_WT2=6,
                 IN0 = 7,IN0_AV = 8,IN0_CS = 9,IN0_WR =10,
                 IN1 =11,IN1_AV =12,IN1_CS =13,IN1_WR =14,
                 IN2 =15,IN2_AV =16,IN2_CS =17,IN2_WR =18;
always @(posedge clk_i)
  if (rst_i)
    state<=OUT0;
  else
    state<=nextstate;

always @(*) begin
  nextstate=state;
  case (state)
    OUT0    :                                       nextstate=OUT0_AV ;
    OUT0_AV : if(!fx3_out0_empty_i && !out0_full_i) nextstate=OUT0_CS ;
              else                                  nextstate=IN0     ;
    OUT0_CS :                                       nextstate=OUT0_RD ;
    OUT0_RD :                                       nextstate=OUT0_WT ;
    OUT0_WT :                                       nextstate=OUT0_LAT;
    OUT0_LAT:                                       nextstate=OUT0_WT2;
    OUT0_WT2:                                       nextstate=IN0     ;
    IN0     :                                       nextstate=IN0_AV  ;
    IN0_AV  : if(!fx3_in0_full_i && !in0_empty_i)   nextstate=IN0_CS  ;
              else                                  nextstate=IN1     ;
    IN0_CS  :                                       nextstate=IN0_WR  ;
    IN0_WR  :                                       nextstate=IN1     ;
    IN1     :                                       nextstate=IN1_AV  ;
    IN1_AV   : if(!fx3_in1_full_i && !in1_empty_i)  nextstate=IN1_CS  ;
              else                                  nextstate=IN2     ;
    IN1_CS  :                                       nextstate=IN1_WR  ;
    IN1_WR  :                                       nextstate=IN2     ;
    IN2     :                                       nextstate=IN2_AV  ;
    IN2_AV  : if(!fx3_in2_full_i && !in2_empty_i)   nextstate=IN2_CS  ;
              else                                  nextstate=OUT0    ;
    IN2_CS  :                                       nextstate=IN2_WR  ;
    IN2_WR  :                                       nextstate=OUT0    ;
  endcase
end

always @(*) begin
  fx3_sloe_n_o  =1;
  fx3_slcs_n_o  =0; // TODO: why should this ever be high?
  fx3_slrd_n_o  =1;
  fx3_slwr_n_o  =1;
  fx3_pktend_n_o=1;
  out0_we_o     =0;
  in0_re_o      =0;
  in1_re_o      =0;
  in2_re_o      =0;
  case(state)
    OUT0    :      fx3_sladdr_o=2'h0;
    OUT0_AV :      fx3_sladdr_o=2'h0;
    OUT0_CS :begin fx3_sladdr_o=2'h0;fx3_slcs_n_o=0;fx3_sloe_n_o=0;                              end // TODO: why OE here?
    OUT0_RD :begin fx3_sladdr_o=2'h0;fx3_slcs_n_o=0;fx3_sloe_n_o=0;fx3_slrd_n_o=0;               end
    OUT0_WT :begin fx3_sladdr_o=2'h0;fx3_slcs_n_o=0;fx3_sloe_n_o=0;                              end
    OUT0_LAT:begin fx3_sladdr_o=2'h0;fx3_slcs_n_o=0;fx3_sloe_n_o=0;out0_we_o=1;                  end
    OUT0_WT2:begin fx3_sladdr_o=2'h0;fx3_slcs_n_o=0;fx3_sloe_n_o=0;                              end
    IN0     :      fx3_sladdr_o=2'h1;
    IN1     :      fx3_sladdr_o=2'h2;
    IN2     :      fx3_sladdr_o=2'h3;
    IN0_AV  :      fx3_sladdr_o=2'h1;
    IN1_AV  :      fx3_sladdr_o=2'h2;
    IN2_AV  :      fx3_sladdr_o=2'h3;
    IN0_CS  :begin fx3_sladdr_o=2'h1;fx3_slcs_n_o=0;in0_re_o=1;                                  end
    IN1_CS  :begin fx3_sladdr_o=2'h2;fx3_slcs_n_o=0;in1_re_o=1;                                  end
    IN2_CS  :begin fx3_sladdr_o=2'h3;fx3_slcs_n_o=0;in2_re_o=1;                                  end
    IN0_WR  :begin fx3_sladdr_o=2'h1;fx3_slcs_n_o=0;fx3_slwr_n_o=0;fx3_pktend_n_o=!in0_pktend_i; end
    IN1_WR  :begin fx3_sladdr_o=2'h2;fx3_slcs_n_o=0;fx3_slwr_n_o=0;fx3_pktend_n_o=!in1_pktend_i; end
    IN2_WR  :begin fx3_sladdr_o=2'h3;fx3_slcs_n_o=0;fx3_slwr_n_o=0;fx3_pktend_n_o=!in2_pktend_i; end
  endcase
end
//TODO: need to register the outputs to avoid glitches...

assign out0_data_o=fx3_dq_io; // TODO: better register... I mean, within here..

endmodule

