project_open alpide-daq-fpga-fw

create_timing_netlist
read_sdc constraints/timing.sdc
update_timing_netlist

report_timing -npaths 10

project_close
