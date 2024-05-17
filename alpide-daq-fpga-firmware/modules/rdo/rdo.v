module rdo(
  input             clk_i         ,
  input             rst_i         ,

  input             reg_we_i      ,
  input      [ 7:0] reg_addr_i    ,
  input      [15:0] reg_data_i    ,
  output reg [15:0] reg_data_o    ,

  input             alpide_phase_i,
  input      [ 7:0] alpide_data_i ,
  output reg [ 7:0] data_o        ,
  output reg        evtdone_o     ,
  output reg        we_o       
);

localparam [7:0] REGADDR_STATUS         =8'h00,
                 REGADDR_CTRL           =8'h01,
                 REGADDR_CMD            =8'h02,
                 REGADDR_N_DATA_LONG    =8'h03,
                 REGADDR_N_DATA_SHORT   =8'h04,
                 REGADDR_N_CHIP_HEADER  =8'h05,
                 REGADDR_N_CHIP_TRAILER =8'h06,
                 REGADDR_N_REGION_HEADER=8'h07,
                 REGADDR_N_CHIP_EMPTY   =8'h08,
                 REGADDR_N_BUSY_ON      =8'h09,
                 REGADDR_N_BUSY_OFF     =8'h0A,
                 REGADDR_N_IDLE         =8'h0B,
                 REGADDR_N_ERROR        =8'h0C;
localparam [15:0] CMD_RST=16'h0001,
                  CMD_CLR=16'h0002;

reg phase;
reg valid;
always @(posedge clk_i) // FIXME: enforce IOREG 
  if(rst_i) begin
    valid<=0;
    // no need to reset unvalid-marked data
  end
  else if (phase^alpide_phase_i) begin
    data_o<=alpide_data_i;
    valid<=1;
  end else 
    valid<=0;

reg        [3:0] nextstate,state;
localparam [3:0] IDLE=0,
                 READ1=1,READ2=2,READ3=3,
                 END1 =4,END2 =5,
                 ERROR1=6,ERROR2=7,ERROR3=8,
                 REC1 =9,REC2 =10,REC3 =11;
wire rst;
reg enable;
always @(posedge clk_i)
  if(rst_i || rst || !enable)
    state<=IDLE;
  else
    state<=nextstate;

wire data_long    =data_o[7:6]==2'b00      ;
wire data_short   =data_o[7:6]==2'b01      ;
wire chip_header  =data_o[7:4]==4'b1010    ;
wire chip_trailer =data_o[7:4]==4'b1011    ;
wire region_header=data_o[7:5]==3'b110     ;
wire chip_empty   =data_o[7:4]==4'b1110    ;
wire busy_on      =data_o     ==8'b11110001;
wire busy_off     =data_o     ==8'b11110000;
wire idle         =data_o     ==8'b11111111;
wire error        =!(data_long||data_short||chip_header||chip_trailer||region_header||chip_empty||busy_on||busy_off||idle);

//TODO: ERROR handling/reporting
//TODO: timeout/force end of event?
always @(*) begin
  nextstate=state;
  case(state)
    IDLE  :if(valid)  
                  if(data_long    ) nextstate=READ3 ;
             else if(data_short   ) nextstate=READ2 ;
             else if(chip_header  ) nextstate=READ2 ;
             else if(chip_trailer ) nextstate=END1  ;
             else if(region_header) nextstate=READ1 ;
             else if(chip_empty   ) nextstate=END2  ;
             else if(busy_on      ) nextstate=IDLE  ;
             else if(busy_off     ) nextstate=IDLE  ;
             else if(idle         ) nextstate=IDLE  ;
             else                   nextstate=ERROR3; // OH-OH
    READ3 :if(valid)                nextstate=READ2 ;
    READ2 :if(valid)                nextstate=READ1 ;
    READ1 :                         nextstate=IDLE  ;
    END2  :if(valid)                nextstate=END1  ;
    END1  :                         nextstate=IDLE  ;
    ERROR3:if(valid)                nextstate=ERROR2;
    ERROR2:if(valid)                nextstate=ERROR1;
    ERROR1:if(valid)                nextstate=REC3  ;
    REC3  :if(valid)
             if (idle)              nextstate=REC2  ;
             else                   nextstate=REC3  ;
    REC2  :if(valid)
             if (idle)              nextstate=REC1  ;
             else                   nextstate=REC3  ;
    REC1  :if(valid)
             if (idle)              nextstate=IDLE  ;
             else                   nextstate=REC3  ;
    default:;
  endcase
end

reg done;
always @(*) begin
  we_o     =0;
  evtdone_o=0;
  if (!valid) // this is the 2nd cylce
    case(state)
      READ3 ,
      READ2 ,
      READ1 ,
      ERROR3,
      ERROR2,
      END2  : begin we_o=1;             end
      END1  ,
      ERROR1: begin we_o=1;evtdone_o=1; end
      default:;
    endcase
end 

reg [15:0] n_data_long    ;
reg [15:0] n_data_short   ;
reg [15:0] n_chip_header  ;
reg [15:0] n_chip_trailer ;
reg [15:0] n_region_header;
reg [15:0] n_chip_empty   ;
reg [15:0] n_busy_on      ;
reg [15:0] n_busy_off     ;
reg [15:0] n_idle         ;
reg [15:0] n_error        ;

wire clr;
always @(posedge clk_i)
  if(rst_i||clr) begin
    n_data_long    <=0;
    n_data_short   <=0;
    n_chip_header  <=0;
    n_chip_trailer <=0;
    n_region_header<=0;
    n_chip_empty   <=0;
    n_busy_on      <=0;
    n_busy_off     <=0;
    n_idle         <=0;
    n_error        <=0;
  end else if(state==IDLE && valid) begin
    if(data_long    &&n_data_long    !=16'hFFFF) n_data_long    <=n_data_long    +1'b1;
    if(data_short   &&n_data_short   !=16'hFFFF) n_data_short   <=n_data_short   +1'b1;
    if(chip_header  &&n_chip_header  !=16'hFFFF) n_chip_header  <=n_chip_header  +1'b1;
    if(chip_trailer &&n_chip_trailer !=16'hFFFF) n_chip_trailer <=n_chip_trailer +1'b1;
    if(region_header&&n_region_header!=16'hFFFF) n_region_header<=n_region_header+1'b1;
    if(chip_empty   &&n_chip_empty   !=16'hFFFF) n_chip_empty   <=n_chip_empty   +1'b1;
    if(busy_on      &&n_busy_on      !=16'hFFFF) n_busy_on      <=n_busy_on      +1'b1;
    if(busy_off     &&n_busy_off     !=16'hFFFF) n_busy_off     <=n_busy_off     +1'b1;
    if(idle         &&n_idle         !=16'hFFFF) n_idle         <=n_idle         +1'b1;
    if(error        &&n_error        !=16'hFFFF) n_error        <=n_error        +1'b1;
  end

always @(posedge clk_i)
       if(rst_i                               ) {phase,enable}<=2'b00 ;
  else if(reg_addr_i==REGADDR_CTRL && reg_we_i) {phase,enable}<=reg_data_i[1:0];

assign rst=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_RST && reg_we_i;
assign clr=reg_addr_i==REGADDR_CMD && reg_data_i==CMD_CLR && reg_we_i;

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS         ,
    REGADDR_CTRL           ,
    REGADDR_CMD            :reg_data_o={data_o,state,2'b0,phase,enable};
    REGADDR_N_DATA_LONG    :reg_data_o=n_data_long    ;
    REGADDR_N_DATA_SHORT   :reg_data_o=n_data_short   ;
    REGADDR_N_CHIP_HEADER  :reg_data_o=n_chip_header  ;
    REGADDR_N_CHIP_TRAILER :reg_data_o=n_chip_trailer ;
    REGADDR_N_REGION_HEADER:reg_data_o=n_region_header;
    REGADDR_N_CHIP_EMPTY   :reg_data_o=n_chip_empty   ;
    REGADDR_N_BUSY_ON      :reg_data_o=n_busy_on      ;
    REGADDR_N_BUSY_OFF     :reg_data_o=n_busy_off     ;
    REGADDR_N_IDLE         :reg_data_o=n_idle         ;
    REGADDR_N_ERROR        :reg_data_o=n_error        ;
    default                :reg_data_o=16'hF001       ;
  endcase

endmodule

