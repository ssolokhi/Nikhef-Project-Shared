import argparse
import subprocess

parser = argparse.ArgumentParser(description='Easy DAQ boards programming and power on')
parser.add_argument('--prog-all', help='program all chips', action='store_true')
parser.add_argument('--on', help='power on all chips', action='store_true')
parser.add_argument('--off',help='power off all chips', action='store_true')
args = parser.parse_args()

daq_serials = {
'DAQ-0009092509591A1E': 'Amsterdam',
'DAQ-0009002400533331': 'Brussel',
'DAQ-000900240054153A': 'Copenhagen',
'DAQ-0009002400530E19': 'Delft',
'DAQ-000900240054142B': 'Eindhoven',
'DAQ-0009002400532232': 'Frankfurt ',
}


if args.prog_all:
    subprocess.run(['alpide-daq-program', '--all',
                         '--fx3=/home/alpaca/alpide-daq-software/tools/fx3.img',
                         '--fpga=/home/alpaca/alpide-daq-software/tools/fpga-v1.0.0.bit'])
    exit()

#device_list = '''2 device(s) with unprogrammed FX3 firmware found:
#- DAQ-000900240054142B (bus: 3, address 71)
#- DAQ-0009002400530E19 (bus: 3, address 72)
#'''

device_list = subprocess.run(['alpide-daq-program', '--list'], capture_output=True, text=True)
print(device_list)

daq_boards = []
for i, line in enumerate(device_list.stdout.split('\n')):
    if i == 0:
        print(line)
        continue

    if len(line) == 0:
        continue

    serial = line.split(' ')[1]
    daq_boards.append(serial)

    daq = daq_serials[serial]
    print('\n', serial, 'AKA', daq)

    if args.on:
        subprocess.run(['python3', '/home/alpaca/alpide-daq-software/scans/power-on.py', f'--serial={serial}'])
    elif args.off:
        subprocess.run(['python3', '/home/alpaca/alpide-daq-software/scans/power-off.py', f'--serial={serial}'])

