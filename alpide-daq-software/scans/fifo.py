#!/usr/bin/env python3

from alpidedaqboard import alpidedaqboard
import argparse
import datetime
from time import sleep
from tqdm import tqdm
import os


PATTERNS=[
  ('ramp'         ,range(128*32)                          ),
  ('zeros'        ,[0]*(128*32)                           ),
  ('ones'         ,[0xFFFFFF]*(128*32)                    ),
  ('marching'     ,[1<<i for i in range(24)]*171          ),
  ('checker board',[0xAAAAAA,0x555555]*(64*32)            ),
  ('prime'        ,[(i*17)&0xFFFFFF for i in range(128*32)])
]


def write_pattern(daq, name, pattern, chipid):
    for region in tqdm(range(32),leave=False,desc=f"Writing {name} pattern"):
        for addr in range(128):
            data=pattern[region*128+addr]
            daq.alpide_write_region_reg(region, 1, addr, data>> 0&0xFFFF, chipid)
            daq.alpide_write_region_reg(region, 2, addr, data>>16&0x00FF, chipid)

def read_pattern(daq, outfile, name, pattern, chipid):
    outfile.write('Reading pattern "{}" chipID {}\n'.format(name, chipid))
    nerr=0
    for region in tqdm(range(32),leave=False,desc=f"Reading {name} pattern"):
        for addr in range(128):
            data_lo=daq.alpide_read_region_reg(region,1,addr, chipid)
            data_hi=daq.alpide_read_region_reg(region,2,addr, chipid)
            data=(data_hi&0xFF)<<16|data_lo
            if data!=pattern[region*128+addr]:
                nerr+=1
                msg = 'Error in chip %d, region %d, address 0x%02X: read 0x%06X instead of 0x%06X \n'%(chipid,region,addr,data,pattern[region*128+addr])
                outfile.write(msg)
                print(msg)                
    return nerr



now=datetime.datetime.now()
parser=argparse.ArgumentParser(description='The mighty fifo test')
parser.add_argument('--serial' ,'-s',help='serial number of the DAQ board')
parser.add_argument('--chipid' ,'-c',type=int,help='Chip ID (default: 0x10)',default=0x10)
parser.add_argument('--path' ,help='Path to directory for data saving',default=".")
args=parser.parse_args()


if args.serial:
    fname='fifo-%s-%s.txt'%(args.serial,now.strftime('%Y%m%d_%H%M%S'))
else:
    fname='fifo-%s.txt'%(now.strftime('%Y%m%d_%H%M%S'))

if args.path != '.':  #creating new directory
    try:
        os.mkdir(args.path)
    except OSError:
        print ("Creation of the directory %s failed" %args.path)



chipid=args.chipid

try:
    daq=alpidedaqboard.ALPIDEDAQBoard(args.serial)
except ValueError as e:
    print(e)
    raise SystemExit(-1)


daq.power_on()
sleep(1)

iaa,idd,status=daq.power_status()
print('IAA = %5.2f mA'%iaa)
print('IDD = %5.2f mA'%idd)
if status:
    print('LDOs: ON')
else:
    print('LDOs: OFF... too bad!')
    raise SystemExit(1)

#----------------------------------------------------------
#just in case we got up on the wrong side of the fw...
daq.fw_reset()
daq.alpide_cmd_issue(0xD2) # GRST

# now for monitoring, also start clean
daq.fw_clear_monitoring()
daq.alpide_cmd_issue(0xE4) # PRST


daq.alpide_setreg_mode_ctrl(ChipModeSelector=0x0,
                            EnClustering=0x1,
                            MatrixROSpeed=0x1,
                            IBSerialLinkSpeed=0x2,
                            EnSkewGlobalSignals=0x0,
                            EnSkewStartReadout=0x0,
                            EnReadoutClockGating=0x0,
                            EnReadoutFromCMU=0x0,
                            chipid=args.chipid)

daq.alpide_setreg_cmu_and_dmu_cfg(PreviousChipID=0x0,
                                  InitialToken=0x1,
                                  DisableManchester=0x1,
                                  EnableDDR=0x1,
                                  chipid=args.chipid)


daq.alpide_cmd_issue(0x63) # RORST (needed!!!)

#----------------------------

print('Starting FIFO scan...')
outfile=open('%s/%s'%(args.path,fname),'w')

try:
    nerr=0
    for name,pattern in tqdm(PATTERNS, desc="Overall progress"):
        write_pattern(daq,name,pattern,args.chipid)
        nerr += read_pattern(daq,outfile,name,pattern,args.chipid)
    if nerr>0:
        print("ERROR! FIFO test failed! %d errors found!"%(nerr))
        outfile.write("ERROR! FIFO test failed! %d errors found!"%(nerr))
    else:
        print("Done. FIFO test %s passed."%(name))
        outfile.write("Done. FIFO test %s passed."%(name))
except KeyboardInterrupt:
    print('Test interrupted!')

outfile.close()
#daq.power_off()



