#!/usr/bin/env python3

from alpidedaqboard import alpidedaqboard
import argparse
import datetime
from time import sleep
from alpidedaqboard import decoder
import os

NITERATIONS=10

parser=argparse.ArgumentParser(description='The mighty threshold scanner')
parser.add_argument('--serial' ,'-s',help='serial number of the DAQ board')
parser.add_argument('--chipid' ,'-c',type=int,help='Chip ID (default: 0x10)',default=0x10)
parser.add_argument('--dctrl'  ,     action='store_true',help='use readout via DCTRL')
parser.add_argument('--path' ,help='Path to directory for data saving',default=".")

args=parser.parse_args()
chipid=args.chipid
now=datetime.datetime.now()



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

if args.serial:
    fname='digital-%s-%s'%(args.serial,now.strftime('%Y%m%d_%H%M%S'))
else:
    fname='digital-%s'%(now.strftime('%Y%m%d_%H%M%S'))

of=open('%s/%s.dat'%(args.path,fname),'w')
rawfile=open('%s/%s.raw'%(args.path,fname),'wb')


# Well, power has a too bad connotation sometimes.
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

#just in case we got up on the wrong side of the fw...
daq.fw_reset()
daq.alpide_cmd_issue(0xD2) # GRST for ALPIDE
# now for monitoring, also start clean
daq.fw_clear_monitoring()
daq.alpide_cmd_issue(0xE4) # PRST


daq.alpide_reg_write(0x0004,0x0060,chipid=args.chipid) # disable busy monitoring, analog test pulse, enable test strobe
daq.alpide_reg_write(0x0005,   200,chipid=args.chipid) # strobe length
daq.alpide_reg_write(0x0007,     0,chipid=args.chipid) # strobe->pulse delay
daq.alpide_reg_write(0x0008,   400,chipid=args.chipid) # pulse duration
daq.alpide_reg_write(0x0010,0x0030,chipid=args.chipid) # initial token, SDR, disable manchester, previous token == self!!!
daq.alpide_reg_write(0x0001,0x000D,chipid=args.chipid) # normal readout, TRG mode
daq.alpide_cmd_issue(0x63) # RORST (needed!!!)

if args.dctrl:
    daq.alpide_reg_write(0x0001,0x020D,chipid=args.chipid) # normal readout, TRG mode, CMU RDO
    daq.rdoctrl.delay_set.write(1000) # when to start reading (@80MHz, i.e. at least strobe-time x2 + sth.)
    daq.rdoctrl.chipid.write(args.chipid)
    daq.rdoctrl.ctrl.write(1) # enable DCTRL RDO
    daq.rdomux.ctrl.write(2) # select DCTRL RDO
else:
    daq.alpide_reg_write(0x0001,0x000D,chipid=args.chipid) # normal readout, TRG mode
    daq.rdopar.ctrl.write(1) # enable parallel port RDO
    daq.rdomux.ctrl.write(1) # select parallel port RDO
    daq.xonxoff.ctrl.write(1) # enable XON XOFF

daq.trg.ctrl.write(0b1110) # master mode,  mask ext trg, mask ext busy, do not force forced busy
daq.trgseq.dt_set.write(4000) # 50 us
daq.trg.opcode.write(0x78) # PULSE OPCODE


	
allbad=set()



try:

    for regions in [range(0,8),range(8,16),range(16,24),range(24,32)]:
        for region in range(32):
            if region in regions:
                daq.alpide_write_region_reg(region,3,0,0x0000,chipid=args.chipid) # enable all columns
            else:
                daq.alpide_write_region_reg(region,3,0,0xFFFF,chipid=args.chipid) # disable all columns
     
        for meb_mask in [0b001, 0b010, 0b100, 0b111]:
            print('Regions %s, MEB slice no. %d:'%(regions,meb_mask))
            daq.alpide_setreg_fromu_cfg_1(MEBMask=meb_mask, EnStrobeGeneration=0, EnBusyMonitoring=0,
                                  PulseMode=0, EnPulse2Strobe=1,
                                  EnRotatePulseLines=0, TriggerDelay=0,chipid=args.chipid)
            daq.alpide_cmd_issue(0x63) # RORST 
            # 1) try to interatively mask bad pixels, i.e. those that would disable double columns
            pixel_mask=set()
            for i in range(NITERATIONS):
                 print('  Interation no. %d: %d pixel(s) masked'%(i+1,len(pixel_mask)))
                 for region in regions:
                     daq.alpide_write_region_reg(region,3,0,0x0000,chipid=args.chipid) # enable all columns in region
                 bad=set()
                 
                 for pulsing in [True,False]:
                       daq.alpide_pixel_pulsing_all(pulsing,chipid=args.chipid)
                       for mask in [False,True]:
                           daq.alpide_pixel_mask_all(mask,chipid=args.chipid)
                           for x,y in pixel_mask:
                                print('   Masking pixel x=%d, y=%d'%(x,y))
                                daq.alpide_pixel_mask_xy(x,y,True,chipid=args.chipid)
                           daq.alpide_cmd_issue(0x63) #readout reset
                           daq.alpide_cmd_issue(0xE4) #pixel matrix reset
                           
                           daq.trgseq.start.issue()
                           ev=daq.event_read()
                           rawfile.write(ev)
                           i=0
                           totalhits=0
                           while i<len(ev):
                               hits,iev,tev,j=decoder.decode_event(ev,i)
                               last_xy=None
                               for x,y in hits:
                                   if mask==True or pulsing==False:
                                       print('   Unwanted pixel at x=%d, y=%d'%(x,y))
                                       allbad.add((x,y))
                                   if last_xy==(x,y):
                                       print('   Bad pixel at x=%d, y=%d'%(x,y))
                                       bad.add((x,y))
                                       allbad.add((x,y))
                                   last_xy=(x,y)
                               i=j
                               totalhits+=len(hits)
                           print('    Pulsing=%s, Mask=%s: %d pixels fired.'%(pulsing,mask,totalhits))
                           of.write('# EVENT pulsing=%d mask=%d regions=%s meb=%d pixel length=%d\n'%(int(pulsing),int(mask),regions,meb_mask,len(ev)))
                           of.write('# masked pixels: ['+','.join(map(lambda xy:'(%d,%d)'%(x,y),pixel_mask))+']\n')
                           of.write('\n')
   
                 print('    ... %d bad pixels found.'%len(bad))
                 print('    ... %d bad pixels are new.'%len(bad-pixel_mask))
                 print('    ... %d bad pixels were there before.'%len(bad&pixel_mask))
                 if len(bad-pixel_mask)==0:
                     print('    ... No new bad pixel appeared. Stopping here.')
                     break
                 pixel_mask|=bad
                 if (i==NITERATIONS-1):
                        print('    ... Maximum number of trials reached. Stopping here.')
        print('Total of %d bad pixels found.'%len(allbad)) 
  
except KeyboardInterrupt:
    print('Test interrupted!')

rawfile.close()
of.close()
#daq.power_off()

