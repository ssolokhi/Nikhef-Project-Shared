`include "../../versions.h"
module id(
  input             clk_i          ,
  input             rst_i          ,
  input             reg_we_i       ,
  input      [ 7:0] reg_addr_i     ,
  input      [15:0] reg_data_i     ,
  output reg [15:0] reg_data_o     ,
  input      [ 3:0] brdaddr_i      ,
  output reg [ 1:0] board_version_o
);

localparam [7:0] REGADDR_VERSION      =8'h03,
                 REGADDR_SUBSERION    =8'h04,
                 REGADDR_PATCHLEVEL   =8'h05,
                 REGADDR_GIT_HASH0    =8'h06,
                 REGADDR_GIT_HASH1    =8'h07,
                 REGADDR_GIT_HASH2    =8'h08,
                 REGADDR_GIT_HASH3    =8'h09,
                 REGADDR_GIT_HASH4    =8'h0A,
                 REGADDR_GIT_HASH5    =8'h0B,
                 REGADDR_GIT_HASH6    =8'h0C,
                 REGADDR_GIT_HASH7    =8'h0D,
                 REGADDR_GIT_HASH8    =8'h0E,
                 REGADDR_GIT_HASH9    =8'h0F,
                 REGADDR_GIT_DIRTY    =8'h10,
                 REGADDR_COMMIT_YYYY  =8'h11,
                 REGADDR_COMMIT_MMDD  =8'h12,
                 REGADDR_COMMIT_HHMM  =8'h13,
                 REGADDR_COMPILE_YYYY =8'h14,
                 REGADDR_COMPILE_MMDD =8'h15,
                 REGADDR_COMPILE_HHMM =8'h16,
                 REGADDR_BOARD_ADDRESS=8'h17,
                 REGADDR_DUMMY        =8'h18,
                 REGADDR_BOARD_VERSION=8'h19;

wire [ 15:0] version     =`VERSION     ;
wire [ 15:0] subversion  =`SUBVERSION  ;
wire [ 15:0] patchlevel  =`PATCHLEVEL  ;
wire [159:0] git_hash    =`GIT_HASH    ;
wire         git_dirty   =`GIT_DIRTY   ;
wire [ 15:0] commit_yyyy =`COMMIT_YYYY ;
wire [ 15:0] commit_hhmm =`COMMIT_HHMM ;
wire [ 15:0] commit_mmdd =`COMMIT_MMDD ;
wire [ 15:0] compile_yyyy=`COMPILE_YYYY;
wire [ 15:0] compile_hhmm=`COMPILE_HHMM;
wire [ 15:0] compile_mmdd=`COMPILE_MMDD;
reg  [ 15:0] dummyreg;

always @(*)
  case(reg_addr_i)
    REGADDR_VERSION      :reg_data_o=version   ;
    REGADDR_SUBSERION    :reg_data_o=subversion;
    REGADDR_PATCHLEVEL   :reg_data_o=patchlevel;
    REGADDR_GIT_HASH0    :reg_data_o=git_hash[0*16+15:0*16];
    REGADDR_GIT_HASH1    :reg_data_o=git_hash[1*16+15:1*16];
    REGADDR_GIT_HASH2    :reg_data_o=git_hash[2*16+15:2*16];
    REGADDR_GIT_HASH3    :reg_data_o=git_hash[3*16+15:3*16];
    REGADDR_GIT_HASH4    :reg_data_o=git_hash[4*16+15:4*16];
    REGADDR_GIT_HASH5    :reg_data_o=git_hash[5*16+15:5*16];
    REGADDR_GIT_HASH6    :reg_data_o=git_hash[6*16+15:6*16];
    REGADDR_GIT_HASH7    :reg_data_o=git_hash[7*16+15:7*16];
    REGADDR_GIT_HASH8    :reg_data_o=git_hash[8*16+15:8*16];
    REGADDR_GIT_HASH9    :reg_data_o=git_hash[9*16+15:9*16];
    REGADDR_GIT_DIRTY    :reg_data_o={15'b0,git_dirty};
    REGADDR_COMMIT_YYYY  :reg_data_o=commit_yyyy;
    REGADDR_COMMIT_MMDD  :reg_data_o=commit_mmdd;
    REGADDR_COMMIT_HHMM  :reg_data_o=commit_hhmm;
    REGADDR_COMPILE_YYYY :reg_data_o=compile_yyyy;
    REGADDR_COMPILE_MMDD :reg_data_o=compile_mmdd;
    REGADDR_COMPILE_HHMM :reg_data_o=compile_hhmm;
    REGADDR_BOARD_ADDRESS:reg_data_o={12'b0,~brdaddr_i};
    REGADDR_DUMMY        :reg_data_o=dummyreg;
    REGADDR_BOARD_VERSION:reg_data_o={14'b0,board_version_o};
    default              :reg_data_o=16'hF001;
  endcase

always @(posedge clk_i)
       if(rst_i                                        ) dummyreg       <=16'h5678       ;
  else if(reg_addr_i==REGADDR_DUMMY         && reg_we_i) dummyreg       <=reg_data_i     ;

always @(posedge clk_i)
       if(rst_i                                        ) board_version_o<=0              ;
  else if(reg_addr_i==REGADDR_BOARD_VERSION && reg_we_i) board_version_o<=reg_data_i[1:0];

endmodule

