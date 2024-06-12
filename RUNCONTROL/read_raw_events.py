import numpy as np
import matplotlib.pyplot as plt
from collections import Counter

import pyeudaq as eu
from alpidedaqboard.decoder import decode_event


def getPixelCounts(reader):
    hm = np.zeros((512,1024))

    i = 0
    ev = reader.GetNextEvent()
    while ev:
        #print("Event number:", i)

        for j, sev in enumerate(ev.GetSubEvents()):
            #print("\tsub event", j)
            block = sev.GetBlock(0)
            hits, iev, tev, k = decode_event(block, 0)
            #print("\t", tev, hits)

            for x,y in hits:
                hm[y,x] += 1
                #hm [y,x] = tev

        ev = reader.GetNextEvent()
        i += 1

    return hm


def truncatedHist(hm, ax, truncate=100, **kwargs):
    # Log histogram of non zero hits, truncated
    hits = hm[(hm != 0)] 
    flattened = hm.flatten()
    counts = Counter(hits)
    print("max counts should be each pixel =", hm.size)
    print(counts)

    return ax.hist(hits[hits < truncate], bins = 100, **kwargs)


#fig, ax = plt.subplots()

# RAW file paths
ten_min_source = "tests/10min-loop-run243171836_240612171843.raw"
with_source =  "tests/1min-loop-run243170602_240612170608.raw"
no_blanket =  "tests/1min-loop-run241124058_240610124104(noblanket).raw"
blanket =  "tests/1min-loop-run241130131_240610130137(blanket).raw"

if False:
    f = eu.FileReader("native", ten_min_source)
    hm = getPixelCounts(f)
    np.savez("10min_sr90_a2_d4-hitmap.npz", hm=hm)
else:
    save_file = np.load("10min_sr90_a2_d4-hitmap.npz", allow_pickle=True)
    hm = save_file['hm']
#truncatedHist(hm, ax, label="no blanket", alpha=0.6)

#f_blanket = eu.FileReader("native", blanket)
#hm_blanket = getPixelCounts(f_blanket)
#truncatedHist(hm_blanket, ax, label='blanket', alpha=0.6)
#plt.legend()
#plt.show()

# Scatter plot of non zero
#nonzero_xy = np.nonzero(hm)
#counts_xy = truncated[nonzero_xy]
#print(nonzero_xy)
#print(counts_xy)
#plt.scatter(nonzero_xy[0], nonzero_xy[1], s=1)
#plt.scatter(nonzero_xy[0], nonzero_xy[1], s=counts_xy, alpha=0.6)
#plt.show()

# Show non zero
#plt.imshow((hm > 0) + (hm > 1), cmap='jet', vmin=0, vmax=2)

# Masked array?
#masked_array = np.ma.masked_where(hm == 0, hm)

# Simpe imshow
#plt.imshow(hm, cmap='jet', vmax=150)
plt.imshow(np.log(hm+0.000001), cmap='jet', vmax=np.log(200), vmin=0)
plt.colorbar()

plt.show()
