import numpy as np
import matplotlib.pyplot as plt
from collections import Counter
from copy import deepcopy

import pyeudaq as eu
from alpidedaqboard.decoder import decode_event


def getPixelCounts(reader):
    hm = np.zeros((512,1024))
    times = []
    subev_times = []
    n_subev_per_ev = []

    event_tracks = []
    curr_track = []
    curr_track_time = 0

    plane_hm = dict()

    i = 0
    ev = reader.GetNextEvent()
    while ev:

        dt_times = []

        j = 0
        for j, sev in enumerate(ev.GetSubEvents()):
            #print("\tsub event", j)
            block = sev.GetBlock(0)

            try:
                hits, iev, tev, k = decode_event(block, 0)
                times.append(tev)
                dt_times.append(tev)
                
                if tev - curr_track_time > 3E7:
                    event_tracks.append(deepcopy(curr_track))
                    curr_track = []
                    curr_track_time = tev
                    
                curr_track.append((sev.GetDescription(), hits, tev))

                for x,y in hits:
                    hm[y,x] += 1
                    plane = sev.GetDescription()
                    if not plane in plane_hm:
                        plane_hm[plane] = np.zeros_like(hm)
                    plane_hm[plane][y,x] += 1

            except Exception as e:
                print("decoding error on event", i, "subevent", j)
                print(sev.GetDescription())
                print(e)

        if j > 0:
            n_subev_per_ev.append(j+1)

        if len(dt_times):
            subev_timespan = max(dt_times) - min(dt_times)
            subev_times.append(subev_timespan)

        ev = reader.GetNextEvent()
        i += 1

    print()
    print("Mean:", hm.mean(), "Max:", hm.max(), "Min:", hm.min())
    print("N events in file =", len(times))

    for plane, hitmap in plane_hm.items():
        print()
        print(plane)
        print("Mean:", hitmap.mean(), "Max:", hitmap.max(), "Min:", hitmap.min())
        print(np.sum(hitmap[(hitmap > 0) & (hitmap < 50)]))

    plt.title("subev's per event")
    plt.hist(n_subev_per_ev)
    plt.xlabel("Time in daqboard units")
    plt.ylabel("Counts")
    plt.show()

    plt.title("time difference within event")
    plt.hist([t for t in subev_times if t != 0])
    plt.xlabel("Time in daqboard units")
    plt.ylabel("Counts")
    plt.show()

    return times, hm, plane_hm, event_tracks


def truncatedHist(hm, ax, truncate=100, **kwargs):
    # Log histogram of non zero hits, truncated
    hits = hm[(hm != 0)] 
    flattened = hm.flatten()
    counts = Counter(hits)
    counts = sorted([(c,p) for c,p in counts.items() if c > 0], key=lambda x:x[0])
    print("max counts should be each pixel =", hm.size)
    for Nhits, Npixels in counts:
        print('H', Nhits, 'P', Npixels)
    
    ax.set_xlabel("N hits")
    ax.set_ylabel("N pixels")
    ax.set_xticks(range(1, truncate+1))
    return ax.hist(hits[hits <= truncate], bins = truncate, **kwargs)






# RAW file paths
ten_min_source = "tests/10min-loop-run243171836_240612171843.raw"
with_source =  "tests/1min-loop-run243170602_240612170608.raw"
no_blanket =  "tests/1min-loop-run241124058_240610124104(noblanket).raw"
blanket =  "tests/1min-loop-run241130131_240610130137(blanket).raw"
pmt_2chip = "tests/2chip-PMTtrigger-run251111815_240617111820.raw"
first_4chip = "tests/4chip-PMTtrigger-run251144333_240617144338.raw"
second_4chip = "tests/4chip-PMTtrigger-run251144415_240617144420.raw"
third_4chip = "tests/4chip-PMTtrigger-run251144833_240617144838.raw"

radiation_2chip = "tests/2chip-radiation-run253134817_240619134821.raw"
radiation_4chip = "tests/4chip-radiation-run253141637_240619141642.raw"

first_overnight = "tests/4chip-2pmt-First-overnight-muon-run253161546_240619161552.raw"
second_overnight = "tests/4chip-2pmt-0deg-overnight-muon-run254155254_240620155259.raw"


# Read and process EUDAQ raw file
CURRENT_RAW = first_overnight
f = eu.FileReader("native", CURRENT_RAW)
times, hm, plane_hm, event_tracks = getPixelCounts(f)


# Plotting hits grouped in regions smaller than 1sec in time
for iev, track in enumerate(event_tracks):
    # Don't bother with empty plots
    if len(track) == 0:
        print("Event number", iev, "no hits")
        continue

    fig, ax = plt.subplots(1,2, figsize=(16,8))
    fig.suptitle(f"Event number {iev}\n {len(track)} hits")

    # Save times of each event
    plane_times = dict()

    # Save hits per plane
    plane_hits = dict()

    # Create lists
    for plane in plane_hm.keys():
        plane_hits[plane] = []
        plane_times[plane] = []

    # Populate lists
    for plane, hits, t in track:
        plane_times[plane].append(t)
        plane_hits[plane].extend(hits)
    
    total_hits = 0
    planes_sorted = sorted(plane_hm.keys())
    colors = ['red', 'magenta', 'purple', 'blue']
    for plane, c in zip(planes_sorted, colors):
        # Plot times
        ax[0].scatter(plane, plane_times[plane], color=c, label=plane)
        print(plane,"times", plane_times[plane])

        # Plot hit points
        hits = plane_hits[plane]
        total_hits += len(hits)
        ax[1].scatter([x[0] for x in hits], [x[1] for x in hits], label=plane, color=c, s=1)

        total_time_range = max([max(p_times) for p_times in plane_times.values()])\
                           - min([min(p_times) for p_times in plane_times.values()])

        total_secs = total_time_range / 7.8E7
     
        fig.suptitle(f"Event number {iev}\n {total_hits} hits, Timespan {total_time_range} ~ {total_secs}s")
    ax[0].legend()
    ax[1].legend()
    ax[1].set_xlim(0,1024)
    ax[1].set_ylim(512,0)
    fig.savefig(f"track_plots/event{iev}.png", dpi=200)
    plt.show()


# Plot distribution of time between events
dts = np.diff(times)
bins = np.logspace(0,13,num=26)
plt.title("Time between events")
plt.hist(dts, bins=bins)
plt.xscale('log')
plt.xlabel("Time in daqboard units")
plt.ylabel("Counts")
plt.show()

# Code to save and load hm, in case reading takes a long time
#    np.savez("1min_sr90_a2_d4-hitmap.npz", hm=hm)

#    save_file = np.load("1min_sr90_a2_d4-hitmap.npz", allow_pickle=True)
#    hm = save_file['hm']

# Calculate where to cut off to exclude noisy outliers
truncate_limit = int(np.ceil(np.quantile(hm, .9999)))

# Time of each subevent plotted
plt.title("All planes")
plt.plot(times)
plt.savefig("time_of_event.png", dpi=200)
plt.clf()

# Scatter plot of non zero
nonzero_xy = np.nonzero(hm)
plt.title("All planes")
plt.scatter(nonzero_xy[1], nonzero_xy[0], s=1)
plt.ylim(511, 0)
plt.xlim(0, 1023)
plt.savefig("scatter_nonzero.png", dpi=200)
plt.clf()

# Scatter plot of non zero, color for different planes
plt.title("All planes")
for plane, hitmap in plane_hm.items():
    nonzero_xy = np.nonzero(hitmap)
    plt.scatter(nonzero_xy[1], nonzero_xy[0], s=1, label=plane)
plt.ylim(511, 0)
plt.xlim(0, 1023)
plt.legend()
plt.savefig("scatter_nonzero.png", dpi=200)
plt.clf()

# Simpe imshow
plt.title("All planes")
plt.imshow(hm, cmap='jet', vmax=truncate_limit)
plt.colorbar()
plt.savefig("hitmap.png", dpi=200)
plt.clf()

for plane, hitmap in plane_hm.items():
# Truncated histogram
    fig, ax = plt.subplots()
    plt.title(plane)
    print(truncatedHist(hitmap, ax, truncate=truncate_limit))
    plt.savefig(f"{plane}-hit-hist.png", dpi=200)
    plt.clf()
    
# Scatter plot of non zero
    nonzero_xy = np.nonzero(hitmap)
    plt.title(plane)
    plt.scatter(nonzero_xy[1], nonzero_xy[0], s=1)
    plt.ylim(511, 0)
    plt.xlim(0, 1023)
    plt.savefig(f"{plane}-scatter_nonzero.png", dpi=200)
    plt.clf()

# Simpe imshow
    plt.title(plane)
    plt.imshow(hitmap, cmap='jet', vmax=truncate_limit)
    plt.colorbar()
    plt.savefig(f"{plane}-hitmap.png", dpi=200)
    plt.clf()

print("N hits Truncation", truncate_limit)
