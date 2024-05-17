#!/usr/bin/env python3

from alpidedaqboard import alpidedaqboard
import argparse
import datetime
import os
import json
import os
from time import sleep
from tqdm import tqdm

def thrscan(args,verbose=True):

    now=datetime.datetime.now()

    if args.serial:
        fname='thrscan-%s-%s'%(args.serial,now.strftime('%Y%m%d_%H%M%S'))
    else:
        fname='thrscan-%s'%(now.strftime('%Y%m%d_%H%M%S'))
    if not args.output: args.output=fname+'.raw'
    if not args.params: args.params=fname+'.json'

    if args.path != '.':  #creating new directory
        os.makedirs(args.path,exist_ok=True)

    with open('%s/%s'%(args.path,args.params),'w') as f:
        f.write(json.dumps(vars(args)))

    try:
        daq=alpidedaqboard.ALPIDEDAQBoard(serial=args.serial,verbose=verbose)
    except ValueError as e:
        print(e)
        raise SystemExit(-1)

    # Well, power has a too bad connotation sometimes.
    daq.power_on()
    sleep(0.1) # let it settle
    iaa,idd,status=daq.power_status()
    if verbose: print('IAA = %5.2f mA'%iaa)
    if verbose: print('IDD = %5.2f mA'%idd)
    if status:
        if verbose: print('LDOs: ON')
    else:
        print('LDOs: OFF... too bad!')
        raise SystemExit(1)

    #just in case we got up on the wrong side of the fw...
    daq.fw_reset()
    daq.alpide_cmd_issue(0xD2) # GRST for ALPIDE
    # now for monitoring, also start clean
    daq.fw_clear_monitoring()


    if args.vcasn : daq.alpide_reg_write(0x604,args.vcasn ,chipid=args.chipid)
    if args.vcasn2: daq.alpide_reg_write(0x607,args.vcasn2,chipid=args.chipid)
    if args.vclip : daq.alpide_reg_write(0x608,args.vclip ,chipid=args.chipid)
    if args.ithr  : daq.alpide_reg_write(0x60E,args.ithr  ,chipid=args.chipid)

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

    daq.alpide_reg_write(0x605,args.vpulseh,chipid=args.chipid)
    daq.alpide_reg_write(0x602,args.vresetd,chipid=args.chipid)

    with open('%s/%s'%(args.path,args.output),'wb') as datafile:
        rows=args.row if args.row else list(range(512))
        vpulsels=[args.vpulseh-dqi for dqi in range(args.dvmin,args.dvmax+1)]
        for row in tqdm(rows,leave=verbose):
            daq.alpide_pixel_mask_all(True,chipid=args.chipid)
            daq.alpide_pixel_mask_row(row,False,chipid=args.chipid)
            daq.alpide_pixel_pulsing_all(False,chipid=args.chipid)
            daq.alpide_pixel_pulsing_row(row,True,chipid=args.chipid)
            for vpulsel in tqdm(vpulsels,leave=False):
                daq.alpide_reg_write(0x0606,vpulsel,chipid=args.chipid) # VPULSEL
                ntodo=args.ntrg
                while ntodo!=0:
                    if args.dctrl:
                        # software ping-pong... rdo can take ms...
                        ni=1
                    else:
                        # do triggers in bursts of 20 to ensure that DAQ board is never busy
                        ni=min(20,ntodo)
                    daq.trgseq.ntrg_set.write(ni)
                    daq.trgseq.start.issue()
                    for iev in range(ni):
                        ev=daq.event_read()
                        datafile.write(ev)
                    ntodo-=ni

    daq.trgmon.lat.issue()
    if verbose:
        print('TRGMON: Triggers sent: %d'    %daq.trgmon.ntrgacc.read())
        print('TRGMON: avg rdo time: %.1f us'%(daq.trgmon.tbsy_rdo.read()/daq.trgmon.ntrgacc.read()/80e6/1e-6))
        print('ALPIDE: Triggers: %d'         %daq.alpide_reg_read(0x0009,chipid=args.chipid))
        print('ALPIDE: Strobes: %d'          %daq.alpide_reg_read(0x000A,chipid=args.chipid))
        print('ALPIDE: Matrix readouts: %d'  %daq.alpide_reg_read(0x000B,chipid=args.chipid))
        print('ALPIDE: Frames: %d'           %daq.alpide_reg_read(0x000C,chipid=args.chipid))
    daq.dispose()


if __name__=="__main__":
    parser=argparse.ArgumentParser(description='The mighty threshold scanner')
    parser.add_argument('--serial' ,'-s',help='serial number of the DAQ board')
    parser.add_argument('--chipid' ,'-c',type=int,help='Chip ID (default: 0x10)',default=0x10)
    parser.add_argument('--vcasn'  ,'-v',type=int,help='ALPIDE VCASN DAC setting')
    parser.add_argument('--vcasn2' ,'-w',type=int,help='ALPIDE VCASN2 DAC setting')
    parser.add_argument('--vclip'  ,'-x',type=int,help='ALPIDE VCLIP DAC setting')
    parser.add_argument('--ithr'   ,'-i',type=int,help='ALPIDE ITHR DAC setting')
    parser.add_argument('--vresetd',     type=int,help='ALPIDE VRESETD DAC setting (default: 147)',default=147)
    parser.add_argument('--vpulseh',     type=int,help='ALPIDE VPULSEH DAC setting (default: 170)',default=170)
    parser.add_argument('--row'    ,'-r',type=int,action='append',help='row to be pulsed (can be specified multiple times)')
    parser.add_argument('--dctrl'  ,     action='store_true',help='use readout via DCTRL')
    parser.add_argument('--dvmin'  ,'-m',type=int,help='smallest voltage step to be injected (default=0)',default=0)
    parser.add_argument('--dvmax'  ,'-M',type=int,help='largest voltage step to be injected (default=30)',default=30)
    parser.add_argument('--ntrg'   ,'-n',type=int,help='number of triggers per setting (default=50)',default=50)
    parser.add_argument('--output' ,'-o',help='name of file to which events are written')
    parser.add_argument('--params' ,'-p',help='name of file to which settings are written')
    parser.add_argument('--path' ,help='Path to directory for data saving',default=".")
    args=parser.parse_args()

    thrscan(args)
