#!/usr/bin/env python3
from alpidedaqboard import decoder
import matplotlib.pyplot as plt
import numpy as np
import argparse
from tqdm import tqdm

parser=argparse.ArgumentParser(description='The mighty threshold scanner')
parser.add_argument('rawdata', metavar='RAWFILE',help='raw data file to be processed')
parser.add_argument('--path',help='Output plots path', default='.')
args=parser.parse_args()

hitmap=np.zeros((512,1024))

try:
    with open('%s'%(args.rawdata),'rb') as f:
        d=f.read()
except IOError:
    print('ERROR: File %s could not be read!'%(args.rawdata))
    raise SystemExit(1)

i=0
pbar=tqdm(total=len(d), position=0, leave=True, desc='Reading data')
while i<len(d):
    hits,iev,tev,j=decoder.decode_event(d,i)
    for x,y in hits:
        hitmap[y,x]+=1
    pbar.update(j-i)
    i=j
pbar.close()

dead=[]
noise=[]
for (x,y),value in np.ndenumerate(hitmap):
    if value==0:
        dead.append( (x,y) )
    if value>1:
        noise.append( (x,y) ) 
            
plt.figure()
plt.title('Hitmap')
plt.xlabel('X')
plt.ylabel('Y')
plt.xlim(0,1024)
plt.ylim(0,512)
plt.xticks([0,128,256,384,512,640,768,896,1023])
plt.yticks([0,128,256,384,511])
plt.gca().invert_yaxis()
plt.pcolor(hitmap)
plt.savefig('%s/hitmap_analogtest.png'%args.path)


print('Number of dead pixels=%d at:'%len(dead),dead)
print('Number of noise pixels=%d at: '%len(noise),noise)





