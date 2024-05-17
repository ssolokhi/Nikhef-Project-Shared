#!/usr/bin/env python3

from alpidedaqboard import alpidedaqboard
import argparse
import datetime
from time import sleep
import os

now=datetime.datetime.now()

parser=argparse.ArgumentParser(description='The mighty power test')
parser.add_argument('--serial' ,'-s',help='serial number of the DAQ board')
parser.add_argument('--ntrg'   ,'-n',type=int,help='number of triggers per setting (default=50)',default=50)
parser.add_argument('--path' ,help='Path to directory for data saving',default=".")
args=parser.parse_args()

if args.serial:
    fname='power-%s-%s'%(args.serial,now.strftime('%Y%m%d_%H%M%S.txt'))
else:
    fname='power-%s'%(now.strftime('%Y%m%d_%H%M%S.txt'))

if args.path != '.':  #creating new directory
    try:
        os.mkdir(args.path)
    except OSError:
        print ("Creation of the directory %s failed" %args.path)


if args.ntrg:
    total_steps=args.ntrg
else:
    total_steps=20

try:
    daq=alpidedaqboard.ALPIDEDAQBoard(args.serial)
except ValueError as e:
    print(e)
    raise SystemExit(-1)

daq.power_on()
sleep(0.1) # let it settle
current_step=0


of=open('%s/%s'%(args.path,fname),'w')
of.write('#time\tanalog (mA)\tdigital (mA)\tstatus\n')
print('#time\t\t\t\tIa (mA)\tId (mA)\tstatus')

try:
   for current_step in range(total_steps):
        iaa,idd,status=daq.power_status()
        msg= '%s\t%.2f\t%.2f\t%d'%(str(datetime.datetime.now()),iaa,idd,status)
        of.write(msg+"\n")
        if current_step%5==0: print(msg)
        sleep(0.1)
except KeyboardInterrupt:
    print('Test interrupted!')

of.close()
#daq.power_off()
