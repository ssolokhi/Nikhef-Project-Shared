#!/usr/bin/env python3

from alpidedaqboard import alpidedaqboard
import argparse
import datetime
from time import sleep
from tqdm import tqdm
import os

DACS = [
    'VRESETP',
    'VRESETD',
    'VCASP',
    'VCASN',
    'VPULSEH',
    'VPULSEL',
    'VCASN2',
    'VCLIP',
    'VTEMP',
    'IAUX2',
    'IRESET',
    'IDB',
    'IBIAS',
    'ITHR',
]

VDACSel = {
    'VCASN':0,
    'VCASP':1,
    'VPULSEH':2,
    'VPULSEL':3,
    'VRESETP':4,
    'VRESETD':5,
    'VCASN2':6,
    'VCLIP':7,
    'VTEMP':8,
    'ADCDAC':9
    }

CDACSel = {
    'IRESET':0,
    'IAUX2':1,
    'IBIAS':2,
    'IDB':3,
    'IREF':4,
    'ITHR':5,
    'IREFBuffer':6
    }



def measure_dac_step(daq, idac, step,chipid,mode):
        data=[]
        dac = DACS[idac]
        dac_addr = 0x601+idac
        adc_input = 5 if dac_addr<0x60A else 6 # DACMONV or DACMONI
        daq.alpide_reg_write(dac_addr, step, chipid)
        daq.alpide_setreg_analog_monitor_and_override(
            VoltageDACSel=VDACSel[dac] if dac in VDACSel.keys() else 0,
            CurrentDACSel=CDACSel[dac] if dac in CDACSel.keys() else 0,
            SWCNTL_DACMONI=0,SWCNTL_DACMONV=0,IRefBufferCurrent=1,chipid=chipid)

        if mode:

            for k,sel_input in [['Value',adc_input], ['AVDD',2]]: # measure AVDD and DAC
                daq.alpide_setreg_adc_ctrl(
                                          Mode=0,        #Manual
                                          SelInput=sel_input,
                                          SetIComp=2,
                                          RampSpd=1,
                                          DiscriSign=0,
                                          HalfLSBTrim=0,
                                          CompOut=0,chipid=chipid) 
                daq.alpide_reg_write(0x0000, 0xFF20, chipid)
                sleep(0.005) # wait >=5ms, according to ALPIDE manual           
                output=daq.alpide_reg_read(0x613,chipid)
                data.append(output)
        else:

             sleep(0.01) # wait >=5ms, according to ALPIDE manual 
             if dac_addr<0x60A:
                 data= daq.read_dacmonv()
             else:
                data= daq.read_dacmoni()
        return (data) 



 

now=datetime.datetime.now()
parser=argparse.ArgumentParser(description='The dac scan test')
parser.add_argument('--serial' ,'-s',help='serial number of the DAQ board')
parser.add_argument('--chipid' ,'-c',type=int,help='Chip ID (default: 0x10)',default=0x10)
parser.add_argument('--path' ,help='Path to directory for data saving',default=".")
parser.add_argument('--via-on-chip-adc',help='Monitor DAC with ALPIDE ADCs',action='store_true')
args=parser.parse_args()


if args.serial:
    fname='dacscan-%s-%s.txt'%(args.serial,now.strftime('%Y%m%d_%H%M%S'))
else:
    fname='dacscan-%s.txt'%(now.strftime('%Y%m%d_%H%M%S'))

if args.path != '.':  #creating new directory
    try:
        os.mkdir(args.path)
    except OSError:
        print ("Creation of the directory %s failed" %args.path)

try:
    daq=alpidedaqboard.ALPIDEDAQBoard(args.serial)
except ValueError as e:
    print(e)
    raise SystemExit(-1)


daq.power_on()
sleep(0.1) # let it settle
iaa,idd,status=daq.power_status()
print('IAA = %5.2f mA'%iaa)
print('IDD = %5.2f mA'%idd)
if status:
    print('LDOs: ON')
else:
    print('LDOs: OFF... too bad!')
    raise SystemExit(1)

#--------------------------- init

#just in case we got up on the wrong side #of the fw...
daq.fw_reset()
daq.alpide_cmd_issue(0xD2) # GRST for ALPIDE
# now for monitoring, also start clean
daq.fw_clear_monitoring()
daq.alpide_cmd_issue(0xE4) # PRST

if args.via_on_chip_adc:
    daq.alpide_setreg_adc_ctrl(Mode=2,      #Automatic
                              SelInput=0,  #AVSS
                              SetIComp=2,  # 
                              DiscriSign=0,
                              RampSpd=1,   # 1mks
                              HalfLSBTrim=0,
                              CompOut=0,
                              chipid=args.chipid)

daq.alpide_setreg_mode_ctrl(ChipModeSelector=0x0,
                            EnClustering=0x1,
                            MatrixROSpeed=0x1,
                            IBSerialLinkSpeed=0x2,
                            EnSkewGlobalSignals=0x1,
                            EnSkewStartReadout=0x1,
                            EnReadoutClockGating=0x0,
                            EnReadoutFromCMU=0x0,
                            chipid=args.chipid)

daq.alpide_setreg_cmu_and_dmu_cfg(PreviousChipID=0x0,
                                  InitialToken=0x1,
                                  DisableManchester=0x1,
                                  EnableDDR=0x1,
                                  chipid=args.chipid)

#----------------------------- run

daq.alpide_configure_dacs(chipid=args.chipid)
sleep(1)
print('Starting DAC scan...')

of =open('%s/%s'%(args.path,fname),'w')
try:
    for idac in tqdm(range(len(DACS)),desc="Overall progress"):
        for step in tqdm(range(256),leave=False,desc="scan: %s"%(DACS[idac])):            
            data=measure_dac_step(daq, idac, step,chipid=args.chipid,mode=args.via_on_chip_adc)
            if args.via_on_chip_adc: 
                of.write('%s\t%d\t%d\n'%(DACS[idac],step,data[0]))
            else:
                of.write('%s\t%d\t%d\n'%(DACS[idac],step,data)) 
except KeyboardInterrupt:
    print('Test interrupted!')

of.close()
#daq.power_off()





