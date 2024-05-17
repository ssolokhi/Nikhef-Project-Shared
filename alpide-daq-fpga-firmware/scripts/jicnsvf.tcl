qexec {quartus_cpf -c -s EP4CE40F23C6 -d EPCS16 alpide-daq-fpga-fw.sof foo.jic}
qexec {quartus_cpf -c foo.jic -n p -g 3.3 -q 10MHz foo.svf}
