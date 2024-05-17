#!/usr/bin/env python3

from alpidedaqboard import alpidedaqboard
from time import sleep
import argparse

parser=argparse.ArgumentParser(description='Power OFF script')
parser.add_argument('--serial' ,'-s',help='serial number of the DAQ board')
args=parser.parse_args()


try:
    daq=alpidedaqboard.ALPIDEDAQBoard(args.serial)
except ValueError as e:
    print(e)
    raise SystemExit(-1)

iaa,idd,status=daq.power_status()
print('IAA = %5.2f mA'%iaa)
print('IDD = %5.2f mA'%idd)
daq.power_off()
print('Chip powered OFF')
sleep(0.5)
iaa,idd,status=daq.power_status()
print('IAA = %5.2f mA'%iaa)
print('IDD = %5.2f mA'%idd)
