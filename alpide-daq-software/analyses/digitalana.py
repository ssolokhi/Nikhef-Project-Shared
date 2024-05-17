#!/usr/bin/env python3
import re
from alpidedaqboard import decoder
import matplotlib.pyplot as plt
import argparse
import json

def plot_map(path,fname,title,pixels,invert=False):
        plt.figure()
        plt.title(title)
        plt.xlabel('X')
        plt.ylabel('Y')
        plt.xlim(0,1024)
        plt.ylim(0,512)
        plt.xticks([0,128,256,384,512,640,768,896,1023])
        plt.yticks([0,128,256,384,511])
        plt.gca().invert_yaxis()        
        if invert:
            tmp=[]
            for y in range(512):
                for x in range(1024):
                    tmp.append((x,y))
            pixels=list(set(tmp)-set(pixels))
        xs=[xy[0] for xy in pixels]
        ys=[xy[1] for xy in pixels]
        plt.scatter(xs,ys)
        plt.savefig('%s/%s'%(path,fname))
        plt.close()

parser=argparse.ArgumentParser(description='The mighty threshold scanner')
parser.add_argument('rawfile', metavar='RAWFILE',help='raw data file to be processed')
parser.add_argument('datfile', metavar='DATFILE',help='.dat file produced by digital scan')
parser.add_argument('--path',help='Output plots path', default='.' )
args=parser.parse_args()


outfilename=args.rawfile.split("/")[-1].split(".")[0]

try:
    rawfile = open ('%s'%(args.rawfile),'rb')
except IOError:
    print('ERROR: File %s could not be read!'%(args.rawfile))
    raise SystemExit(1)

try:
    f=open('%s'%(args.datfile),'r')
except IOError:
    print('ERROR: File %s could not be read!'%(args.datfile))
    raise SystemExit(1)


# These are dicts of dicts of arrays, indexed by regions, meb
unmaskable={} # fire if mask=1 pulse=1
pulsable  ={} # do fire if mask=0 pusle=1
stuck     ={} # fire if mask=0 pulse=0
bad       ={} # fire if mask=1 pulse=0 (OK!?)
masked    ={} # pixels that were recursively masked to achieve self.result
nlines=0



print('Reading data...')
while (f):
    header=f.readline()
    if header=='' and nlines==0:
        raise SystemExit(1) 
    elif header=='':
        break

    nlines+=1
    pulsing=int(re.search('pulsing=(\d)',header).group(1))
    mask   =int(re.search('mask=(\d)'   ,header).group(1))
    meb    =int(re.search('meb=(\d)'    ,header).group(1))
    length =int(re.search('length=(\d+)',header).group(1))
    regions=map(int,re.search('regions=range\S(\d+, \d+)\S',header).group(1).split(','))
    if not meb in unmaskable:
        unmaskable[meb]=[]
        pulsable  [meb]=[]
        stuck     [meb]=[]
        bad       [meb]=[]
        masked    [meb]=[]
   
    pixel_mask=f.readline()
    pixel_mask=re.search('masked pixels: \[(.*)\]',pixel_mask).group(1)
    if len(pixel_mask)>0:
        masked[meb]+=map(lambda x:tuple(map(int,x.split(','))),pixel_mask[1:-1].split('),('))

    raw=rawfile.read(length)
    hits,iev,tev,j=decoder.decode_event(raw,0)

    if mask==1 and pulsing==1:
        unmaskable[meb]+=hits
    elif mask==0 and pulsing==1:
        pulsable[meb]+=hits
    elif mask==0 and pulsing==0:
        stuck[meb]+=hits
    elif mask==1 and pulsing==0:
        bad[meb]+=hits

    f.readline() #just to skip empty line


results={}
unmaskable_all=[]
unpulsable_all  =[]
stuck_all     =[] 
bad_all       =[]
masked_all    =[]

print('Plotting...')
for meb in [0b001, 0b010, 0b100, 0b111]:
    unpulsable_meb=[(x,y) for x in range(1024) for y in range(512)]
    unmaskable[meb]=list(set(unmaskable[meb]))
    unpulsable_meb=list(set(unpulsable_meb)-set(pulsable[meb]))
    stuck[meb]     =list(set(stuck[meb]     ))
    bad[meb]       =list(set(bad[meb]       ))
    masked[meb]    =list(set(masked[meb]    ))

    plot_map(args.path,'%s-unmaskable-meb%d.png'%(outfilename,meb),'Unmaskable pixels (fire if pulsed but also masked) MEB%d'      %meb,unmaskable[meb])
    plot_map(args.path,'%s-unpulsable-meb%d.png'%(outfilename,meb),'Unpulsable pixels (do not fire if not masked but pulsed) MEB%d'%meb,unpulsable_meb)
    plot_map(args.path,'%s-stuck-meb%d.png'     %(outfilename,meb),'Stuck pixels (fire if not masked and not pulsed) MEB%d'        %meb,stuck[meb])
    plot_map(args.path,'%s-bad-meb%d.png'       %(outfilename,meb),'Bad pixels (fire if masked and not pulsed) MEB%d'              %meb,bad[meb])
    plot_map(args.path,'%s-masked-meb%d.png'    %(outfilename,meb),'Masked pixels (due to failure) MEB%d'                          %meb,masked[meb])
    results['unmaskable-meb%d'%meb]=len(unmaskable[meb])
    results['unpulsable-meb%d'%meb]=len(unpulsable_meb)
    results['stuck-meb%d'     %meb]=len(stuck[meb])
    results['bad-meb%d'       %meb]=len(bad[meb])
    results['masked-meb%d'    %meb]=len(masked[meb])
    unmaskable_all+=unmaskable[meb]
    unpulsable_all+=unpulsable_meb
    stuck_all     +=stuck[meb]
    bad_all       +=bad[meb]
    masked_all    +=masked[meb]

unmaskable_all=list(set(unmaskable_all))
unpulsable_all=list(set(unpulsable_all))
stuck_all     =list(set(stuck_all     ))
bad_all       =list(set(bad_all       ))
masked_all    =list(set(masked_all    ))
plot_map(args.path,'%s-unmaskable-all.png'%outfilename,'Unmaskable pixels (fire if pulsed but also masked)'      ,unmaskable_all)
plot_map(args.path,'%s-unpulsable-all.png'%outfilename,'Unpulsable pixels (do not fire if not masked but pulsed)',unpulsable_all)
plot_map(args.path,'%s-stuck-all.png'%outfilename     ,'Stuck pixels (fire if not masked and not pulsed)'        ,stuck_all)
plot_map(args.path,'%s-bad-all.png'%outfilename       ,'Bad pixels (fire if masked and not pulsed)'              ,bad_all)
plot_map(args.path,'%s-masked-all.png'%outfilename    ,'Masked pixels (due to failure)'                          ,masked_all)
results['unmaskable-all']=len(unmaskable_all)
results['unpulsable-all']=len(unpulsable_all)
results['stuck-all'     ]=len(stuck_all)
results['bad-all'       ]=len(bad_all)
results['masked-all'    ]=len(masked_all)

results = {k:results[k] for k in sorted(results.keys())}

with open(outfilename+"-analysis.json",'w') as f:
    json.dump(results,f,indent=4)

print("All is done. Result:", json.dumps(results,indent=4))


