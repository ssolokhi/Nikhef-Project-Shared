import pyeudaq as eu
from alpidedaqboard.decoder import decode_event


muon_files = [
"tests/4chip-2pmt-0deg-overnight-muon-run254155254_240620155259.raw",
"tests/4chip-2pmt-0deg-overnight-part2-muon-run255132552_240621132557.raw",
"tests/4chip-2pmt-10deg-overnight-muon-run262070953_240625070958.raw",
"tests/4chip-2pmt-20deg-overnight-muon-run261100043_240624100048.raw",
"tests/4chip-2pmt-30deg-overnight-muon-run257144721_240623144727.raw",
"tests/4chip-2pmt-40deg-overnight-muon-run255170528_240621170533.raw",
"tests/4chip-2pmt-First-overnight-muon-run253161546_240619161552.raw",
]

final_file_path = "tests/all_muons.raw"
all_events = []

possible_nondata_descr = set()

for raw_path in muon_files:
    print("Opening", raw_path)
    reader = eu.FileReader("native", raw_path)

    i = 0
    ev = reader.GetNextEvent()
    last_ev = ev
    while ev:

        possible_nondata_descr.add(ev.GetDescription())

        for sev in ev.GetSubEvents():
            try:
                block = sev.GetBlock(0)
                _, iev, tev, _ = decode_event(block, 0)
                #print("Event", i, sev.GetDescription(), "decoded subevent", iev, tev)
            except Exception as e:
                print(e)

        all_events.append(ev)
        last_ev = ev
        ev = reader.GetNextEvent()
        i += 1

    print("Had", i, "events")
    #print("Last event:")
    #print(last_ev)

print(possible_nondata_descr)


print("\nNow starting writing")
try:
    writer = eu.FileWriter('native', final_file_path)
    for n, ev in enumerate(all_events):
        writer.WriteEvent(ev)
except Exception as e:
    print(e)
    print(n, "events written to file")

print("Done")
