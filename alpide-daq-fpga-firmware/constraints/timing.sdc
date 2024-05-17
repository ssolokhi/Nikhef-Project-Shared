# CLOCKS
# TODO: add uncertainties
# - input (40 MHz), not used for anything
create_clock -name clk40 -period 25.000 [get_ports clk40_i]
set pllinpin [get_pins {pll|altpll_component|auto_generated|pll1|inclk[0]}]
# - main (80 MHz), used for all logic
set clkpin       [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}  ]
create_generated_clock -name clk       -source $pllinpin -multiply_by 2 -master_clock clk40 $clkpin 
# - ALPIDE (40 MHz), used for timing wrt ALPIDE
set alpideclkport [get_ports {alpide_mclk_o}]
create_generated_clock -name alpideclk -source $clkpin   -divide_by   2 -master_clock clk   $alpideclkport
# - FX3 (80 MHz), used for timing wrt FX3
set fx3clkport    [get_ports fx3_slclk_o]
create_generated_clock -name fx3clk    -source $clkpin                  -master_clock clk   $fx3clkport

#derive_clock_uncertainty
#derive_pll_clocks
# ALPIDE
# TODO: check these numbers...
set alpide_os     [get_ports {alpide_mclk_oe_o alpide_pordis_n_o alpide_rst_n_o alpide_dctrl_o alpide_dctrl_oe_o}]
set alpide_is     [get_ports {alpide_data_i[*] alpide_dctrl_i}]
set_output_delay -clock alpideclk -min  2.0 $alpide_os
set_output_delay -clock alpideclk -max  3.0 $alpide_os
set_input_delay  -clock alpideclk -min  0.0 $alpide_is
set_input_delay  -clock alpideclk -max 10.0 $alpide_is

# FX3
# TODO: check these numbers...
set fx3_os      [get_ports {fx3_sladdr_o[*] fx3_sloe_n_o fx3_slcs_n_o fx3_slrd_n_o fx3_slwr_n_o fx3_pktend_n_o fx3_dq_io[*] fx3_rst_n_o}]
set fx3_is      [get_ports {fx3_dq_io[*] fx3_flaga_i fx3_flagb_i fx3_flagc_i fx3_flagd_i}]
set_output_delay -clock fx3clk -min  1.0 $fx3_os
set_output_delay -clock fx3clk -max  3.0 $fx3_os
set_input_delay  -clock fx3clk -min  0.0 $fx3_is
set_input_delay  -clock fx3clk -max  5.0 $fx3_is

# TODO: ignore:  output        alpide_sce_o     , // ignore FIXME: trace+remove
# TODO: ignore:  output        alpide_sci_o     , // ignore FIXME: trace+remove

# TODO: ignore:  input         alpide_ctrl_io   , // ignore, input only
# TODO: ignore:  input         alpide_sco_i     , // ignore FIXME: trace+remove
# TODO: ignore: set_input_delay -add_delay -clock [get_clocks alpideclk]  0.000 [get_ports alpide_busy_i]


# trigger and busy inputs
# TODO

# trigger and busy outputs
 # TODO

# hardware address input (static)
# TODO

# JTAG + FLASH
# TODO

