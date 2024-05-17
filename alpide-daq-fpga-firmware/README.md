# Important legal notice

Do NOT share contents of this repository outside `alice-its3-wp3` e-group (i.e. to anybody cannot access it themselves); some parts are copyrighted/protected.


# Build instructions

```
/afs/cern.ch/project/parc/quartus14/quartus/bin/quartus_sh --flow compile alpide-daq-fpga-fw  
/afs/cern.ch/project/parc/quartus14/quartus/bin/quartus_sta -t report_timing.tcl
```

# Functional description
This is a partial help for some of the firmware modules.

## Trigger mode
Source: [modules/trg/trg.v](modules/trg/trg.v#L154)

Trigger module can operate in two different modes: `primary` or `replica`. 

- In `replica` mode, there is no arbitration on the trigger input signal (every requested trigger is accepted trigger) and the trigger opcode is sent to [`ctrl` module](modules/ctrl) (and if it is actually propagated to the chip depends on the [arbitration](modules/ctrl/ctrl_arb.v)).
- In `primary` mode, a requested trigger is only accepted if busy is deasserted (low).
A fixed busy time after each accepted trigger can be set via `fixedbusy` register (in 80 MHz clock cycles).
Furthermore, a minimum spacing between triggers (also known as past protection) can be set via `minspacing` register (in 80 MHz clock cycles). It ensures that the time to the last requested (but possibly not accepted) trigger is larger than given value.

N.B. In configuration where multiple DAQ boards are connected in trigger/busy daisy chain (e.g. in a testbeam telescope), it only makes sense to have one `primary` board at the beginning of the trigger daisy chain i.e. end of the busy daisy chain. In other words, the `BUSY_OUT` output of `replica` boards should be connected to the `BUSY_IN` of the `primary`, and `TRIGGER_OUT` of the `primary` to `TRIGGER_IN` of `replica`s. 

## Trigger monitor
Source: [modules/trg/trg_mon.v](modules/trg/trg_mon.v)

The trigger monitoring module allows to retrieve information about the trigger logic. In particular, it counts the number of incomming trigger reuqests, and the decisions of their acceptance or rejection, as well as the reasons for the latter. In addition, also the accumulated time spend in any of the busy conditions is counted.

These are the counters, all 64 bit -- will never overflow™️. They come in three sets.

For consistent readout of these counters, they need to be captured/latched into shadow registers prior to reading. This is accomplished by the `LAT` command. For convenience there is also a clear command `CLR` to reset them (affects only 2nd and 3rd set below).

1. Time stamps (at 80 MHz, free running as of system start)

| Name         | Meaning |
|:-------------|:---|
| `TSYS`       | uptime of the DAQ board (at the moment of capture) |
| `TTRGREQ`    | timestamp of the last trigger request |
| `TTRGACC`    | timestamp of the last trigger accept |

2. Time counters, counting how long a certain condition is valid  (since last `CLR` command):

| Name         | Meaning |
|:-------------|:---|
| `TTOT`       | total time
| `TBSY`       | integral time the board is busy (for any of the reasons below)
| `TBSY_EXT`   | integral time the board is busy due to an external busy
| `TBSY_FIX`   | integral time the board is busy after the acceptance of the last trigger (fixed busy time)
| `TBSY_PAST`  | integral time the board is busy after the last trigger request (independent of acceptance, "past protection") 
| `TBSY_RDO`   | integral time the board is busy with reading out the ALPIDE 
| `TBSY_SEND`  | integral time the board is busy with sending data via USB
| `TBSY_FORCE` | integral time the board is busy on command (forced busy) 

3. Event counters, counting how often a certain contition occurs

| Name            | Meaning |
|:----------------|:---|
| `NTRGREQ`       | number of trigger requests |
| `NTRGACC`       | number of trigger accepts |
| `NTRGBSY_EXT`   | number of trigger rejects due to assertion of external busy |
| `NTRGBSY_FIX`   | number of trigger rejects due to being busy after the acceptance of the last trigger (fixed busy time) |
| `NTRGBSY_PAST`  | number of trigger rejects due to being busy after the last trigger request (independent of acceptance, "past protection") |
| `NTRGBSY_RDO`   | number of trigger rejects due to being busy with reading out the ALPIDE |
| `NTRGBSY_SEND`  | number of trigger rejects due to being busy with sending data via USB |
| `NTRGBSY_FORCE` | number of trigger rejects due to being busy on command (forced busy) |

# Random miscellaneous notes
set_configuration somewhat kills data in the FX3 fifos..

