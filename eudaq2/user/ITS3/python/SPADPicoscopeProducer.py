#!/usr/bin/env python3

import pyeudaq
import pico_daq as daq
import trigger
from datetime import datetime
from time import sleep
import subprocess
import numpy as np

class SPADPicoscopeProducer(pyeudaq.Producer):
    def __init__(self, name, runctrl):
        pyeudaq.Producer.__init__(self, name, runctrl)
        self.name = name
        self.daq = None
        self.trigger = None
        self.ps_model = None
        self.is_running = False
        self.idev = 0
        self.isev = 0

    def DoInitialise(self):

        print("SPAD: DoInitialise")
        conf = self.GetInitConfiguration().as_dict()
        self.trigger = trigger.Trigger(conf['trigger_path'] if "trigger_path" in conf else trigger.find_trigger() )
        self.plane = int(conf['plane'])

    def DoConfigure(self):

        print("SPAD: DoConfigure")
        
        self.idev = 0
        self.isev = 0

        conf = self.GetConfiguration().as_dict()
        self.trigger_on = conf['trigger_on']
        self.ps_model = conf['picoscope_model']

        if self.trigger_on not in ['A', 'E', 'AUX']:
            raise ValueError('need to specify trigger mode to be A, E or AUX')

        self.trigger.write(trigger.Trigger.MOD_SOFTBUSY, 0, 0x1, commit=True)
        
        if self.daq is None:
            self.daq = daq.ScopeAcqPS6000a(trg_ch = self.trigger_on, trg_mV = 50, npre = 5000, npost = 5000, model = self.ps_model)
            self.daq.print()

    def DoStartRun(self):

        print("SPAD: DoStartRun")
        
        self.idev = 0
        self.isev = 0
        self.send_status_event(self.isev, self.idev, datetime.now(), bore = True)
        self.isev += 1
        self.is_running = True

    def DoStopRun(self):

        print("SPAD: DoStopRun")
        self.is_running = False

    def DoReset(self):

        print("SPAD: DoReset")        
        self.is_running = False

    def DoStatus(self):
        self.SetStatusTag('StatusEventN', '%d' % self.isev);
        self.SetStatusTag('DataEventN', '%d' % self.idev);

    def RunLoop(self):
        try:
            self.foo()
        except Exception as e:
            print(e)
            raise

    def foo(self):
        tlast = datetime.now()
        ilast = 0
        while self.is_running:
            checkstatus = False
            if self.read_and_send_event(self.idev):
                self.idev += 1
            else:
                checkstatus = True
            if (self.idev-ilast) % 1000 == 0: checkstatus = True
            if checkstatus:
                if (datetime.now() - tlast).total_seconds() >= 10:
                    tlast = datetime.now()
                    ilast = self.idev
                    self.send_status_event(self.isev, ilast, tlast)
                    self.isev += 1
                    
        tlast = datetime.now()
        self.send_status_event(self.isev, self.idev, tlast)
        self.isev += 1
        sleep(1)

        tlast = datetime.now()
        self.send_status_event(self.isev, self.idev, tlast, eore = True)
        self.isev += 1

    def send_status_event(self, isev, idev, time, bore = False, eore = False):
        ev = pyeudaq.Event('RawEvent', self.name+'_status')
        ev.SetTag('Event', '%d' % idev)
        ev.SetTag('Time', time.isoformat())
        if bore:
            ev.SetBORE()
            git = subprocess.check_output(['git', 'rev-parse', 'HEAD']).strip()
            diff = subprocess.check_output(['git', 'diff'])
            ev.SetTag('EUDAQ_GIT', git)
            ev.SetTag('EUDAQ_DIFF', diff)
            
        if eore:
            ev.SetEORE()
            
        self.SendEvent(ev)

    def read_and_send_event(self, iev):
        self.daq.arm()
        sleep(0.001)
        self.trigger.write(trigger.Trigger.MOD_SOFTBUSY, 0, 0x2, commit=True)
        
        print('wait data')
        
        data_available = self.daq.ready()
        while not data_available and self.is_running:
            sleep(0.001)
            data_available = self.daq.ready()
            
        if not data_available:
            self.daq.stop()
            return False
        print('done')
        
        data = self.daq.rdo()
        ev = pyeudaq.Event('RawEvent', self.name)
        tev = 0 # no global time stamp
        ev.SetTriggerN(iev) # clarification: itrg is set to iev
        ev.SetTimestamp(begin = tev, end = tev)
        ev.SetDeviceN(self.plane)
        
        ev.AddBlock(0, bytes(data))        
        self.SendEvent(ev)
        
        return True

if __name__ == '__main__':
    
    import argparse
    parser = argparse.ArgumentParser(description = 'SPAD EUDAQ2 Producer for Picoscope',
                                     formatter_class = argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--run-control', '-r', default = 'tcp://localhost:44000')
    parser.add_argument('--name', '-n', default = 'SPAD_XXX')
    args = parser.parse_args()

    myproducer = SPADPicoscopeProducer(args.name, args.run_control)
    myproducer.Connect()
    while(myproducer.IsConnected()):
        sleep(1)
