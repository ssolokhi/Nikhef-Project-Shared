# Nikhef-Project
Codebase for the Nikhef Project course at the University of Amsterdam for April-June 2024

ALPACA Collaboration (Lieke Gijsen, Sergei Solokhin, Anna Hurhina, Esther-Lauren M'Bilo, Aditi Sharma, Noël Wallaart, Yağmur Zubaroğlu, Damian van Leeuwen. Rens Roosenstein, Quinten Bredeveldt)

## Power-On Algorithm 

To power on the DAQ board, use the following commands:

```
cd /home/alpaca/alpide-daq-software/
alpide-daq-program --all --fx3=tools/fx3.img --fpga=tools/fpga-v1.0.0.bit
```

The output will be all serial numbers of the DAQ boards in the format: 

DAQ-SERIAL-NUMBER: DONE

Then use this serial number to power the board on:
```
python3 scans/power-on.py DAQ-SERIAL-NUMBER
```
>[!CAUTION]
>If multiple boards are present, each of them has to be powered on individually!
