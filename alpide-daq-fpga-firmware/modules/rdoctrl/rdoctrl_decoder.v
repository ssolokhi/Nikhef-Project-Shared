// This decoder gets 3x(8) bits in and writes 8+1 bits out
module rdoctrl_decoder(
  input             clk_i     ,
  input             rst_i     ,

  input             reg_we_i  , // ignored.
  input      [ 7:0] reg_addr_i,
  input      [15:0] reg_data_i, // ignored.
  output reg [15:0] reg_data_o,

  input      [23:0] data_i    ,
  output            stopread_o,
  output reg [ 7:0] data_o    ,
  output reg        evtdone_o ,
  input             we_i      ,
  output reg        we_o      ,
  output            full_o    , // in terms of up to 3x8bits
  input             full_i      // in terms of 1x8bits
);

localparam [7:0] REGADDR_STATUS         =8'h00,
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

// TODO: add one more FIFO entry to speed this up!!!
reg [23:0] data      ;
reg        data_valid;
reg        done      ;
assign full_o=data_valid;
always @(posedge clk_i)
  if(rst_i)
    data_valid<=0;
  else if (we_i) begin
    data<=data_i;
    data_valid<=1;
  end else if (done)
    data_valid<=0;

reg [3:0] nextstate,state;
localparam [3:0] IDLE   = 0,
                 READ33 = 1,READ32 = 2,READ31 = 3,
                            READ22 = 4,READ21 = 5,
                                       READ11 = 6,
                            END22  = 7,END21  = 8,
                                       END11  = 9,
                 ERROR33=10,ERROR32=11,ERROR31=12;
always @(posedge clk_i)
  if(rst_i) state<=IDLE     ;
  else      state<=nextstate;

wire data_long    =data_i[23:22]==2'b00      &&data_i[   7]== 1'b  0 ;
wire data_short   =data_i[23:22]==2'b01      &&data_i[ 7:0]== 8'h  FF;
wire chip_header  =data_i[23:20]==4'b1010    &&data_i[ 7:0]== 8'h  FF;
wire chip_trailer =data_i[23:20]==4'b1011    &&data_i[15:0]==16'hFFFF;
wire region_header=data_i[23:21]==3'b110     &&data_i[15:0]==16'hFFFF;
wire chip_empty   =data_i[23:20]==4'b1110    &&data_i[ 7:0]== 8'h  FF;
wire busy_on      =data_i[23:16]==8'b11110001&&data_i[15:0]==16'hFFFF;
wire busy_off     =data_i[23:16]==8'b11110000&&data_i[15:0]==16'hFFFF;
wire idle         =data_i[23: 0]==24'hFFFFFF                         ;
wire error        =!(data_long||data_short||chip_header||chip_trailer||region_header||chip_empty||busy_on||busy_off||idle);
assign stopread_o=chip_trailer||chip_empty||idle||error;

//TODO: speedup: do not go via IDLE do not collect clks
always @(*) begin
  nextstate=state;
  case(state)
    IDLE:
      if(we_i)
             if(data_long    ) nextstate=READ33 ; // READ LONG
        else if(data_short   ) nextstate=READ22 ; // READ SHORT
        else if(chip_header  ) nextstate=READ22 ; // CHIP HEADER
        else if(chip_trailer ) nextstate=END11  ; // CHIP TRAILER
        else if(region_header) nextstate=READ11 ; // REGION HEADER
        else if(chip_empty   ) nextstate=END22  ; // CHIP EMPTY
        else if(busy_on      ) nextstate=IDLE   ; // BUSY ON // TODO: verify
        else if(busy_off     ) nextstate=IDLE   ; // BUSY OFF // TODO: verify
        else if(idle         ) nextstate=IDLE   ; // IDLE
        else                   nextstate=ERROR33; // OH-OH
    READ33 :if(!full_i) nextstate=READ32 ;
    READ32 :if(!full_i) nextstate=READ31 ;
    READ31 :if(!full_i) nextstate=IDLE   ;
    READ22 :if(!full_i) nextstate=READ21 ;
    READ21 :if(!full_i) nextstate=IDLE   ;
    READ11 :if(!full_i) nextstate=IDLE   ;
    ERROR33:if(!full_i) nextstate=ERROR32;
    ERROR32:if(!full_i) nextstate=ERROR31;
    ERROR31:if(!full_i) nextstate=IDLE   ;
    END22  :if(!full_i) nextstate=END21  ;
    END21  :if(!full_i) nextstate=IDLE   ;
    END11  :if(!full_i) nextstate=IDLE   ;
  endcase
end

always @(*) begin
  we_o      =0;
  data_o    =8'hXX;
  evtdone_o =1'bX;
  done      =0;
  if(!full_i)
    case(state)
      READ33,ERROR33,READ22,END22,READ11:begin we_o=1;evtdone_o=0;data_o=data[23:16];end
      END11                             :begin we_o=1;evtdone_o=1;data_o=data[23:16];end
      READ32,ERROR32,READ21             :begin we_o=1;evtdone_o=0;data_o=data[15: 8];end
      END21                             :begin we_o=1;evtdone_o=1;data_o=data[15: 8];end
      READ31                            :begin we_o=1;evtdone_o=0;data_o=data[ 7: 0];end
      ERROR31                           :begin we_o=1;evtdone_o=1;data_o=data[ 7: 0];end
      IDLE                              :done=1;
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

always @(posedge clk_i)
  if(rst_i) begin
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
  end else if(we_i) begin
    if(data_long    ) n_data_long    <=n_data_long    +1'b1;
    if(data_short   ) n_data_short   <=n_data_short   +1'b1;
    if(chip_header  ) n_chip_header  <=n_chip_header  +1'b1;
    if(chip_trailer ) n_chip_trailer <=n_chip_trailer +1'b1;
    if(region_header) n_region_header<=n_region_header+1'b1;
    if(chip_empty   ) n_chip_empty   <=n_chip_empty   +1'b1;
    if(busy_on      ) n_busy_on      <=n_busy_on      +1'b1;
    if(busy_off     ) n_busy_off     <=n_busy_off     +1'b1;
    if(idle         ) n_idle         <=n_idle         +1'b1;
    if(error        ) n_error        <=n_error        +1'b1;
  end

always @(*)
  case(reg_addr_i)
    REGADDR_STATUS         :reg_data_o=state          ;
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

