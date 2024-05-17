#!/usr/bin/env python3

import argparse
import numpy as np
from matplotlib import pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
import copy
from alpidedaqboard import decoder
from tqdm import tqdm
import os

parser=argparse.ArgumentParser(description='The mighty threshold scanner')
parser.add_argument('rawdata', metavar='FILENAME',help='raw data file to be processed')
parser.add_argument('--bins' ,'-b',type=int,choices=[1,2,4,8,16,32],help='bin size',default=1)
parser.add_argument('--max' ,'-M',type=int,help='color scale limit')
parser.add_argument('--path',help='Output plots path', default='.' )
parser.add_argument('--dump-raw-hits',help='Dump hit pixel addresses for each event to file',action='store_true')
parser.add_argument('--dump-acc-hits',help='Dump hit pixel addresses sorted by frequency to file',action='store_true')
args=parser.parse_args()

outfilename=args.rawdata.split("/")[-1].split(".")[0]


hm=np.zeros((512,1024))

# https://stackoverflow.com/a/8090605
def rebin(a, shape):
    sh = shape[0],a.shape[0]//shape[0],shape[1],a.shape[1]//shape[1]
    return a.reshape(sh).mean(-1).mean(1)

if args.dump_raw_hits:
    fhits = open(os.path.join(args.path,outfilename+"_dump.txt"),'w')

nev=0
with open(args.rawdata,'rb') as f:
     d=f.read()
     i=0
     pbar=tqdm(total=len(d))
     while i<len(d):
         hits,iev,tev,j=decoder.decode_event(d,i)
         if args.dump_raw_hits: fhits.write(f"Event {nev}\n")
         nev+=1
         for x,y in hits:
             hm[y,x]+=1
             if args.dump_raw_hits: fhits.write(f"{x} {y}\n")
         pbar.update(j-i)
         i=j

if args.dump_raw_hits:
    fhits.close()

hitrate = {}
for nmasked in [0, 10, 100, 1000]:
    hitrate[nmasked] = 1.*np.sum(np.sort(hm,axis=None)[::-1][nmasked:])/nev/512./1024.
    print(f"Hit rate {nmasked: 5d} masked: {hitrate[nmasked]:.2e} per pixel per event")

if args.dump_acc_hits:
    with open(os.path.join(args.path,outfilename+"_freq.txt"), 'w') as f:
        for nmasked in hitrate:
            f.write(f"Hit rate {nmasked: 5d} masked: {hitrate[nmasked]:.2e} per pixel per event\n")
        freq = [(hm[y,x],x,y) for x in range(1024) for y in range(512) if hm[y,x]>0]
        for i,x,y in sorted(freq,reverse=True):
            f.write(f"{x} {y} {i}\n")

plt.figure(figsize=(10,5))
cmap = copy.copy(plt.cm.get_cmap("viridis"))
cmap.set_under(color='white')
im = plt.imshow(rebin(hm,(512//args.bins,1024//args.bins)),vmax=args.max, cmap=cmap, vmin=0.5)
plt.xlabel("Column")
plt.xticks([0,256,512,768,1023])
plt.ylabel("Row")
plt.yticks([0,256,511])
plt.title(f"Hit rate: {hitrate[0]:.2e} per pixel per event")
divider = make_axes_locatable(plt.gca())
cax = divider.append_axes("right", size="5%", pad=0.05)
cbar = plt.colorbar(im,cax=cax)
cbar.set_label("Hits")
plt.savefig(os.path.join(args.path,outfilename+".png"))

