import pyeudaq as eu
from alpidedaqboard.decoder import decode_event
from sys import argv

assert len(argv) == 2, "Provide one argument: path to raw file"
raw_path = argv[1]

print("Opening", raw_path)
reader = eu.FileReader("native", raw_path)

events = 0
status_events = 0
rawdata_events = 0

ev = reader.GetNextEvent()
while ev:
    events += 1
    subevs = len(ev.GetSubEvents())
    if subevs > 0:
        rawdata_events += 1
    else:
        status_events += 1

    ev = reader.GetNextEvent()

print("Events", events, "Status", status_events, "RawData", rawdata_events)
