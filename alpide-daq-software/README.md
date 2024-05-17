# ALPIDE DAQ Software

Python library and scripts to control DAQ board(s) (only `rev3b` and `rev4`, see [TWiki](https://twiki.cern.ch/twiki/bin/view/ALICE/ITS3WP3DAQboards)), programmed with [ALPIDE DAQ FPGA Firmware](https://gitlab.cern.ch/alice-its3-wp3/alpide-daq-fpga-firmware) and [ALPIDE DAQ FX3 Firmware](https://gitlab.cern.ch/alice-its3-wp3/alpide-daq-fx3-firmware).

## Installation

Download and install:

    git clone https://gitlab.cern.ch/alice-its3-wp3/alpide-daq-software.git
    cd alpide-daq-software && pip3 install .

### RaspberryPi

Only on a RaspberryPi, fefore running above commands execute:

    sudo apt install libatlas-base-dev python3-numpy python3-matplotlib python3-scipy

### Udev rules

Install the ALPIDE rules to allow user access to the DAQ board (in programmed and unprogrammed state) via USB:

    sudo cp etc/90-alpide-daq.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules && sudo udevadm trigger

### Look for DAQ baords

    alpide-daq-program --list

## Program FX3 and FPGA firmwares

This needs to be done after every power cycle, the firmwares are not persistent (on purpose).

In case you have not done that yet, download the firmwares from [TWiki](https://twiki.cern.ch/twiki/bin/view/ALICE/ITS3WP3DAQboardSWandFW) and execute:

    alpide-daq-program --fx3=/path/to/fx3.img --fpga=/path/to/fpga-v1.0.0.bit

## Do some tests

All the test commands start with `alpide-` prefix. Detailed usage info can be obtained by `alpide-testname --help`.
N.B. The default test settings are set for no reverse bias operation. When operating with reverse bias voltage, the ALPIDE DAC settings need to be adjusted correspondingly. In particular, `VCASN`, `VCASN2` and `VCLIP` need to be adjusted for `alpide-analog`, `alpide-thrscan` and `alpide-fhr`.

### Standard carrier card

* `alpide-power-on`: Power ON the chip.
* `alpide-fifo`: Test ALPIDE region FIFOs.
* `alpide-dac`: Test ALPIDE DACs. If `--via-daq-board` argument is passed, the test is done via DAQ Board ADC, otherwise uses ALPIDE internal ADC). Corresponding analysis: `analyses/dacana.py`.
* `alpide-digital`: Test functionality of the digital part of the in-pixel circuitry. Corresponding analysis: `analyses/digitalana.py`.
* `alpide-analog`: Test functionality of the analog part of the in-pixel circuitry. Corresponding analysis: `analyses/analogana.py`.
* `alpide-thrscan`: Threshold scan. Corresponding analysis: `analyses/thrana.py`.
* `alpide-fhr`: Fake hit rate test. Can also be used for source measurements. Corresponding analysis: `analyses/hitmap.py`.
* `alpide-power-off`: Power OFF the chip.

### Bent ALPIDEs

As above, except that:

* `--dctrl --chipid=1` parameters need to be passed to `alpide-digital`, `alpide-analog`, `alpide-thrscan` and `alpide-fhr`.
* `--via-daq-board` parameter doesn't make sense for `alpide-dac`

### Threshold tuning

    cd scripts
    ./thr_tune.py

By default, this script will do the threshold tuning procedure for all the DAQ boards connected to the computer, assuming `Vbb = -3 V`. The output directory contains the measurement data, threshold tuning result and threshold scan at tuned threshold. See `./thr_tune.py --help` and the code itself for details.

## Uninstall

    pip3 uninstall alpide-daq-software
