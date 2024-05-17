#!/usr/bin/env python3

import os
import argparse
import pyeudaq
import numpy as np
from tqdm import tqdm

parser = argparse.ArgumentParser(description = 'SPAD data dumper')
parser.add_argument('filename')
parser.add_argument('-n', type = int, default = 1, help = 'Number of events to look at')
parser.add_argument('--outdir', default = '.', help = 'Path to output directory')
args = parser.parse_args()

fr = pyeudaq.FileReader('native', args.filename)
    
# for _ in tqdm(range(args.n)):

for _ in range(args.n):
    ev = fr.GetNextEvent()
    sevs = ev.GetSubEvents()
    
    if sevs is None:
        break
    
    for sev in sevs:        
        if sev.GetDescription() == 'SPAD':
            e = sev.GetBlock(0)
            d = np.frombuffer(e, dtype = np.int8)
            d.shape = (2, len(d) // 2)
            np.save(os.path.join(args.outdir, 'dump_{}.npy'.format(ev.GetEventN())), d)
            
