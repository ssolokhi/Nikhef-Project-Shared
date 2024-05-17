// Module stearing six ADS7883 (runs at up to 32 MHz (@3V), i.e. here at 20)
module adc(
  input             clk_i       ,
  input             rst_i       ,
  input             reg_we_i    ,
  input      [ 7:0] reg_addr_i  ,
  input      [15:0] reg_data_i  ,
  output reg [15:0] reg_data_o  ,
  output reg        adc_cs_n_o  ,
  output reg        adc_clk_o   ,
  input      [5 :0] adc_d_i     ,
  output     [11:0] adc0_o      ,
  output     [11:0] adc1_o      ,
  output     [11:0] adc2_o      ,
  output     [11:0] adc3_o      ,
  output     [11:0] adc4_o      ,
  output     [11:0] adc5_o      
);

localparam [7:0] REGADDR_ADC0=8'h03,
                 REGADDR_ADC1=8'h04,
                 REGADDR_ADC2=8'h05,
                 REGADDR_ADC3=8'h06,
                 REGADDR_ADC4=8'h07,
                 REGADDR_ADC5=8'h08;

reg [3:0] n;
reg load;
reg dec;
always @(posedge clk_i)
  if (rst_i || load)
    n<=13;
  else if (dec)
    n<=n-1'b1;

// make the output glitch free... FIXME: use IOREGs?
reg adc_cs_n,adc_clk;
always @(posedge clk_i) begin
  adc_cs_n_o<=adc_cs_n;
  adc_clk_o <=adc_clk;
end

// FIXME: use IOREGs for the first bits?
reg [11:0] sr[5:0],adc[5:0];
reg shift;
reg latch;
generate
genvar i;
  for (i=0;i<6;i=i+1) begin:shiftreg
    always @(posedge clk_i)
      if (rst_i)
        sr[i]<=12'h000;
      else if (shift)
        sr[i]<={sr[i][10:0],adc_d_i[i]};
    always @(posedge clk_i)
      if (rst_i)
        adc[i]<=0;
      else if (latch)
        adc[i]<=sr[i];
  end
endgenerate
assign adc0_o=adc[0];
assign adc1_o=adc[1];
assign adc2_o=adc[2];
assign adc3_o=adc[3];
assign adc4_o=adc[4];
assign adc5_o=adc[5];

reg        [2:0] nextstate,state;
localparam [2:0] IDLE=0,CS=1,C00=2,C01=3,C10=4,C11=5,LAT=6;
always @(posedge clk_i)
  if (rst_i)
    state<=IDLE;
  else
    state<=nextstate;

always @(*) begin
  nextstate=state;
  case(state)
    IDLE:           nextstate=CS  ;//FIXME: add ACQ state(s) before?
    CS:             nextstate=C00 ;
    C00:            nextstate=C01 ;
    C01:            nextstate=C10 ;
    C10:            nextstate=C11 ;
    C11: if (n==0)  nextstate=LAT ;
         else       nextstate=C00 ;
    LAT:            nextstate=IDLE;
  endcase
end

always @(*) begin
  adc_cs_n  =1;
  adc_clk   =1;
  load      =0;
  dec       =0;
  shift     =0;
  latch     =0;
  case(state)
    IDLE:;
    CS : begin adc_cs_n=0;load=1;           end
    C00: begin adc_cs_n=0;adc_clk=0;dec=1;  end
    C01: begin adc_cs_n=0;adc_clk=0;        end
    C10: begin adc_cs_n=0;adc_clk=1;shift=1;end
    C11: begin adc_cs_n=0;adc_clk=1;        end
    LAT: begin latch=1;                     end
  endcase
end

always @(*)
  case(reg_addr_i)
    REGADDR_ADC0: reg_data_o={4'b0,adc[0]};
    REGADDR_ADC1: reg_data_o={4'b0,adc[1]};
    REGADDR_ADC2: reg_data_o={4'b0,adc[2]};
    REGADDR_ADC3: reg_data_o={4'b0,adc[3]};
    REGADDR_ADC4: reg_data_o={4'b0,adc[4]};
    REGADDR_ADC5: reg_data_o={4'b0,adc[5]};
    default     : reg_data_o=16'hF001;
  endcase

endmodule

