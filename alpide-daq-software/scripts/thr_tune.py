#!/usr/bin/env python3

import sys,os
import argparse
import usb
import datetime
import glob
import json
import numpy as np
from time import sleep
from pathlib import Path
from tqdm import tqdm

sys.path.append(os.path.join(os.path.dirname(__file__),"../scans"))
sys.path.append(os.path.join(os.path.dirname(__file__),"../analyses"))


def measure_thresholds(dirname,vcasn_range,vclip,ithr):
    from thrscan import thrscan

    serials = [d.serial_number for d in list(usb.core.find(idVendor=0x1556,idProduct=0x01B8,find_all=True))]
    assert len(serials)>0, "No DAQ boards found"

    for serial in tqdm(serials,desc="DAQBoard"):
        for vcasn in tqdm(vcasn_range,desc="VCASN",leave=False):
            thrscan(argparse.Namespace(
                serial=serial,
                chipid=16,
                vcasn=vcasn,
                vcasn2=vcasn+12,
                vclip=vclip,
                ithr=ithr,
                vresetd=147,
                vpulseh=170,
                row=list(range(16,512,32)),
                dctrl=False,
                dvmin=0,
                dvmax=30,
                ntrg=50,
                output=None,
                params=None,
                path=dirname),
                verbose=False
            )


def analyse_thresholds(dirname,quiet=True):
    from thrscanana import thrscanana
    print("Reminder: this step is slow on RaspberyPi")
    assert os.path.exists(dirname), f"Directory {dirname} not found!"
    for f in tqdm(sorted(glob.glob(os.path.join(dirname,"thrscan-*.raw"))),desc="Analysing"):
        try:
            thrscanana(argparse.Namespace(
                rawdata=f,
                params=Path(f).with_suffix(".json"),
                path=dirname,
                debug_plots=False,
                fit=False,
                output=Path(f).stem+".npy",
                quiet=quiet)
            )
        except Exception as e:
            print("Unhandled exception when analysing", f)
            raise e


def tune_thresholds(dirname,target):
    from matplotlib import pyplot as plt

    assert os.path.exists(dirname), f"Directory {dirname} not found!"
    data = {}
    for f in tqdm(glob.glob(os.path.join(dirname,"thrscan-*.npy"))):
        thresholds = np.load(f)
        thresholds[thresholds==0]=np.nan
        with open(Path(f).with_suffix(".json")) as jf:
            pars=json.load(jf)

        if pars['serial'] not in data:
            data[pars['serial']] = []
        data[pars['serial']].append((pars['vcasn'],np.nanmean(thresholds)))

    plt.figure()
    data_tuned = {}
    for serial,d in data.items():
        d=sorted(d)
        plt.plot(*zip(*d),label=serial)
        it=next((i for i,dd in enumerate(d) if dd[1]<target),0)
        if it==0:
            data_tuned[serial] = None
        else:
            x1,y1=d[it-1]
            x2,y2=d[it]
            vcasn=round(x1+(target-y1)*(x2-x1)/(y2-y1))
            thr=(y1+(vcasn-x1)*(y2-y1)/(x2-x1))
            data_tuned[serial]={
                "VCASN": vcasn,
                "VCASN2": vcasn+12,
                "VCLIP": pars["vclip"],
                "ITHR": pars["ithr"]
            }
            plt.plot([vcasn],[thr],color='black',marker='o')
    plt.axhline(target,linestyle='dashed',color='grey',label="Target")
    plt.xlabel("VCASN (DAC)")
    plt.ylabel("Threshold (DAC)")
    plt.legend(loc='best')
    plt.savefig(os.path.join(dirname,"threshold_tuning.png"))
    plt.clf()

    print(json.dumps(data_tuned,indent=4))

    with open(os.path.join(dirname,"threshold_tuning.json"),'w') as jf:
        json.dump(data_tuned,jf,indent=4)


def measure_tuned_thresholds(dirname):
    from thrscan import thrscan

    assert os.path.exists(dirname), f"Directory {dirname} not found! Did you perfrom previous steps?"
    dirname_verify=os.path.join(dirname,"tuned")
    with open(os.path.join(dirname,"threshold_tuning.json")) as jf:
        tuning = json.load(jf)
    assert None not in tuning.values(), "Threshold tuning bad"

    for serial,pars in tqdm(tuning.items(),desc="Measuring"):
        thrscan(argparse.Namespace(
            serial=serial,
            chipid=16,
            vcasn=pars["VCASN"],
            vcasn2=pars["VCASN2"],
            vclip=pars["VCLIP"],
            ithr=pars["ITHR"],
            vresetd=147,
            vpulseh=170,
            row=None,#list(range(16,512,32)),
            dctrl=False,
            dvmin=0,
            dvmax=30,
            ntrg=50,
            output=None,
            params=None,
            path=dirname_verify),
            verbose=False
        )
    
if __name__=="__main__":
    now=datetime.datetime.now()

    parser = argparse.ArgumentParser("The ultimate threshold tuning script")
    parser.add_argument("command",metavar="CMD",choices=["FULL","MEASURE","ANALYSE","TUNE","MEASURE_TUNED","ANALYSE_TUNED"],
    default="FULL",help="Threshold tunining procedure step (default=FULL)")
    parser.add_argument("--dirname","-d",default='thrtun-%s'%(now.strftime('%Y%m%d_%H%M%S')),help="Directory name.")
    parser.add_argument("--vcasn-range","-v",nargs=3,default=range(102,116,2),type=lambda x: range(*map(int,x)), help="VCASN range (default=102,116,2)")
    parser.add_argument('--vclip'  ,'-x',type=int,default=60,help='ALPIDE VCLIP DAC setting (default=60)')
    parser.add_argument('--ithr'   ,'-i',type=int,default=60,help='ALPIDE ITHR DAC setting (default=60)')
    parser.add_argument('--target' ,'-t',type=float,default=10,help='Threshold tuning target in DAC units (default=10)')
    args = parser.parse_args()

    if "FULL" in args.command: args.command = ["MEASURE","ANALYSE","TUNE","MEASURE_TUNED","ANALYSE_TUNED"]
    else:                      args.command = [args.command]
    if "MEASURE"       in args.command: measure_thresholds(args.dirname,args.vcasn_range,args.vclip,args.ithr)
    if "ANALYSE"       in args.command: analyse_thresholds(args.dirname)
    if "TUNE"          in args.command: tune_thresholds(args.dirname,args.target)
    if "MEASURE_TUNED" in args.command: measure_tuned_thresholds(args.dirname)
    if "ANALYSE_TUNED" in args.command: analyse_thresholds(os.path.join(args.dirname,"tuned"),quiet=False)
