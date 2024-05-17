#!/bin/bash

DAQS=$(lsusb -v | grep -o DAQ-.*)

for daq in DAQS; do
    awk 'BEGIN {for (i=0;i<512;i+=16) print "-r" i}' | xargs ./thrscan.py -s $daq &
done
