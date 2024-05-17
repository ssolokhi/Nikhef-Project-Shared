# signal  io standard  slew rate  current  pullup  pin(s) MSB first

set ios_fx3 {
  {fx3_rst_n_o         "3.3-V LVTTL" 2  4MA 0  W21}
  {fx3_dq_io           "3.3-V LVTTL" 2  4MA 0 {W15  AB20 AB19 AA19 AB18 AA20 Y17  AB17 
                                               AA17 AB16 AA16 AB15 AA15 AB14 AA14 AB13
                                               AA13 Y13  AB10 AB9  AA9  Y8   AB8  AA8
                                               Y7   AB7   AA7 Y6   AB5  AA5  AA4  Y3  }}
  {fx3_slclk_o           "3.3-V LVTTL" 2  4MA 0  AA3   }
  {fx3_slcs_n_o          "3.3-V LVTTL" 2  4MA 0  Y1    }
  {fx3_sloe_n_o          "3.3-V LVTTL" 2  4MA 0  Y2    }
  {fx3_slrd_n_o          "3.3-V LVTTL" 2  4MA 0  AA1   }
  {fx3_slwr_n_o          "3.3-V LVTTL" 2  4MA 0  AB3   }
  {fx3_flaga_i           "3.3-V LVTTL" 2  4MA 0  Y21   }
  {fx3_flagb_i           "3.3-V LVTTL" 2  4MA 0  Y22   }
  {fx3_flagc_i           "3.3-V LVTTL" 2  4MA 0  W6    }
  {fx3_flagd_i           "3.3-V LVTTL" 2  4MA 0  W7    }
  {fx3_sladdr_o          "3.3-V LVTTL" 2  4MA 0 {W2 W1}}
  {fx3_pktend_n_o        "3.3-V LVTTL" 2  4MA 0  W22   }
}

# FIXME: board versions... this is for V3
# FIXME: inparticular what about P21, P22, R20 ??
# set ios_lemos {
#  {LVTTLI          "3.3-V LVTTL" {} 4MA 0 {P21 P22 R20 R21}}
#  {LVTTLO          "3.3-V LVTTL" {} 4MA 0 {U22 R22}        }
#  {LVTTL_IO        "3.3-V LVTTL" {} 4MA 0  U21             }
#}
set ios_lemos {
  {p22_i   "3.3-V LVTTL" {} 4MA 0 P22}
  {r21_i   "3.3-V LVTTL" {} 4MA 0 R21}
  {r22_o   "3.3-V LVTTL" 2  4MA 0 R22}
  {u21_io  "3.3-V LVTTL" 2  4MA 0 U21}
  {u22_io  "3.3-V LVTTL" 2  4MA 0 U22}
}

# FIXME: what about these:
#set ios_lvds {
#  {LVDSI2          "3.3-V LVTTL" {} 4MA 0 L22}
#  {LVDSI1_IO       "3.3-V LVTTL" {} 4MA 0 K21} 
#  {LVDSO2          "3.3-V LVTTL" 2  4MA 0 K22}
#  {LVDSO1          "3.3-V LVTTL" 2  4MA 0 L21} 
#}

# FIXME: what about these:
#set ios_tlu {
#  {TLUCLK          "3.3-V LVTTL" 2  4MA 0 B21}
#  {TLURES          "3.3-V LVTTL" 2  4MA 0 H21}
#  {TLUTRIGGER      "3.3-V LVTTL" {} 4MA 0 J21}
#  {TLUBUSY         "3.3-V LVTTL" {} 4MA 0 F21}
#}

set ios_ldo {
  {ldo_en_o        "3.3-V LVTTL" 2  4MA 0 H1}
  {ldo2_en_o       "3.3-V LVTTL" 2  4MA 0 H2}
}

set ios_adc {
  {adc_clk_o       "3.3-V LVTTL" 2  4MA 0  F1}
  {adc_cs_n_o      "3.3-V LVTTL" 2  4MA 0  F2}
  {adc_d_i         "3.3-V LVTTL" {} 4MA 0 {E1 D2 C2 C1 B2 B1}}
}

set ios_pinheader {
  {brdaddr_i       "3.3-V LVTTL" {} 4MA 1  {N2 N1 M2 M1}}
  {dbg_o           "3.3-V LVTTL" 2  4MA 0  {P4 P3 P2 P1}}
}

set ios_alpide {
  {alpide_mclk_o     "1.8 V"       2  4MA 0  E5 }
  {alpide_mclk_oe_o  "1.8 V"       2  4MA 0  E6 }
  {alpide_pordis_n_o "1.8 V"       2  4MA 0  C4 }
  {alpide_rst_n_o    "1.8 V"       2  4MA 0  C3 }
  {alpide_busy_i     "1.8 V"       {} 4MA 0  A17}
  {alpide_dctrl_o    "1.8 V"       2  4MA 0  A7 }
  {alpide_dctrl_oe_o "1.8 V"       2  4MA 0  B7 }
  {alpide_dctrl_i    "1.8 V"       {} 4MA 0  B8 }
  {alpide_ctrl_io    "1.8 V"       2  4MA 0  A8 }
  {alpide_data_i     "1.8 V"       {} 4MA 1 {A13 B14 B16 B15 B13 A14 A15 A16}}
  {alpide_sce_o      "1.8 V"       2  4MA 0  A4 }
  {alpide_sci_o      "1.8 V"       2  4MA 0  B4 }
  {alpide_sco_i      "1.8 V"       {} 4MA 0  A5 }
}

set ios_clk {
  {clk40_i         "3.3-V LVTTL" {} 4MA 0 G1}
}

set ios_onewire {
  {onewire_io      "3.3-V LVTTL" {} 4MA 0  V4}
}

#set ios_all [concat $ios_fx3 $ios_lemos $ios_lvds $ios_tlu $ios_ldo $ios_adc $ios_pinheader $ios_alpide $ios_clk]
set ios_all [concat $ios_fx3 $ios_lemos $ios_ldo $ios_adc $ios_pinheader $ios_alpide $ios_clk $ios_onewire]

foreach sp $ios_all {
  set sig  [lindex $sp 0]
  set std  [lindex $sp 1]
  set slr  [lindex $sp 2]
  set cur  [lindex $sp 3]
  set wpu  [lindex $sp 4]
  set pins [lindex $sp 5]
  if {[llength $pins]==1} {
    set_location_assignment PIN_$pins -to $sig
    if {[llength $std]>0} {set_instance_assignment -name IO_STANDARD           $std -to $sig}
    if {[llength $slr]>0} {set_instance_assignment -name SLEW_RATE             $slr -to $sig}
    if {[llength $cur]>0} {set_instance_assignment -name CURRENT_STRENGTH_NEW  $cur -to $sig}
    if {$wpu}            {set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON   -to $sig}
  }
  if {[llength $pins]>1} {
    for { set i 0}  {$i < [llength $pins]} {incr i} {
      set pini [lindex $pins $i]
      set sigi $sig\[[expr [llength $pins] - $i - 1]\]
      set_location_assignment PIN_$pini -to $sigi
      if {[llength $std]>0} {set_instance_assignment -name IO_STANDARD           $std -to $sigi}
      if {[llength $slr]>0} {set_instance_assignment -name SLEW_RATE             $slr -to $sigi}
      if {[llength $cur]>0} {set_instance_assignment -name CURRENT_STRENGTH_NEW  $cur -to $sigi}
      if {$wpu}            {set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON   -to $sigi}
    }
  }
} 

# This is for programming the FLASH via JTAG using the "Altera Serial Flash Loader" IP
# FIXME: see also? https://www.intel.com/content/www/us/en/programmable/support/support-resources/knowledge-base/solutions/rd02172015_590.html
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {flash:flash|altera_serial_flash_loader:serial_flash_loader_0|altserial_flash_loader:altserial_flash_loader_component|\GEN_ASMI_TYPE_1:asmi_inst~ALTERA_DCLK}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {flash:flash|altera_serial_flash_loader:serial_flash_loader_0|altserial_flash_loader:altserial_flash_loader_component|\GEN_ASMI_TYPE_1:asmi_inst~ALTERA_SCE}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {flash:flash|altera_serial_flash_loader:serial_flash_loader_0|altserial_flash_loader:altserial_flash_loader_component|\GEN_ASMI_TYPE_1:asmi_inst~ALTERA_SDO}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {flash:flash|altera_serial_flash_loader:serial_flash_loader_0|altserial_flash_loader:altserial_flash_loader_component|\GEN_ASMI_TYPE_1:asmi_inst~ALTERA_DATA0}

