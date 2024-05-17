#!/usr/bin/env python3

import pyeudaq
import lecroy_daq as daq
from datetime import datetime
import subprocess
import numpy as np
import time, string, random
from smb.SMBConnection import SMBConnection

class SPADLeCroyProducer(pyeudaq.Producer):
    def __init__(self,name,runctrl):
        pyeudaq.Producer.__init__(self,name,runctrl)
        self.name = name
        self.daq = None
        self.ps_model = None
        self.is_running = False
        self.idev = 0 # number of data events
        self.isev = 0 # number of status events

    def DoInitialise(self):
        conf = self.GetInitConfiguration().as_dict()
        self.plane = int(conf['plane'])

    def DoConfigure(self):
        self.idev = 0
        self.isev = 0

    def DoStartRun(self):

        alphabet = string.ascii_lowercase + string.digits
        self.run_id = "scope_{}_{}".format(datetime.now().strftime("%y%m%d%H%M%S"), ''.join(random.choices(alphabet, k = 5)))
        print("SPAD: DoStartRun with run_id = {}".format(self.run_id))

        self.idev = 0
        self.isev = 0
        self.send_status_event(self.isev, self.idev, datetime.now(), bore = True)
        self.isev += 1
        self.is_running = True

        # configure scope
        conf = self.GetConfiguration().as_dict()
        self.processing_timeout = float(conf["processing_timeout"])

        # connect to scope through SMB for access to data
        self.lecroy_netbios_name = conf['lecroy_netbios_name']
        self.lecroy_ip_address = conf['lecroy_ip_address']

        self.daq_dataconn = SMBConnection("", "", "eudaq-host", self.lecroy_netbios_name)
        
        while True:
            try:
                self.daq_dataconn.connect(self.lecroy_ip_address, 139)
                break
            except:
                print("Could not connect ... retrying!")
                time.sleep(5)
        
        # create directory to hold the data for this run
        self.daq_dataconn.createDirectory("Waveforms", self.run_id)
        self.daq_dataconn.close()
        self.daq_dataconn = None
        
        # connect to scope through VISA for control
        assert self.daq is None
        self.number_events = int(conf['number_segments'])
        self.channels_to_save = self._parse_list(conf['channels_to_save'])

        # parse channel settings
        self.ver_scales = {}
        self.ver_offsets = {}
        for channel, ver_scale, ver_offset in zip(["C1", "C2", "C3", "C4"],
                                                  self._parse_list(conf['ver_scales']),
                                                  self._parse_list(conf['ver_offsets'])):
            self.ver_scales[channel] = ver_scale
            self.ver_offsets[channel] = ver_offset

        if conf['HLT_enabled'] == "true":

            # configure scope as HLT
            self.pattern_levels_A = {"Ext": 0.0}
            self.pattern_conditions_A = {"Ext": "DontCare"}
            for channel, trig_level, trigger_condition in zip(["C1", "C2", "C3", "C4"],
                                                              self._parse_list(conf['HLT_trig_levels']),
                                                              self._parse_list(conf['HLT_trig_logic'])):
                self.pattern_levels_A[channel] = trig_level
                self.pattern_conditions_A[channel] = trigger_condition        
                
            self.daq = daq.ScopeAcqLabMaster1036(conf['lecroy_ip_address'],
                                                 num_segments = self.number_events,
                                                 sampling_rate = conf['sampling_rate'],
                                                 hor_scale = conf['hor_scale'],
                                                 hor_offset = conf['hor_offset'],
                                                 channels_to_save = self.channels_to_save,
                                                 ver_scales = self.ver_scales,
                                                 ver_offsets = self.ver_offsets,
                                                 run_id = self.run_id,
                                                 aux_out_mode = "TriggerOut",
                                                 trigger_mode = "Qualified",
                                                 qualify_time = conf['coincidence_window'],
                                                 pattern_levels_A = self.pattern_levels_A,
                                                 pattern_conditions_A = self.pattern_conditions_A,
                                                 edge_source_B = "Ext",
                                                 edge_level_B = 0.4
            )
        else:

            # just pass through the L1 trigger signal
            self.daq = daq.ScopeAcqLabMaster1036(conf['lecroy_ip_address'],
                                                 num_segments = self.number_events,
                                                 sampling_rate = conf['sampling_rate'],
                                                 hor_scale = conf['hor_scale'],
                                                 hor_offset = conf['hor_offset'],
                                                 channels_to_save = self.channels_to_save,
                                                 ver_scales = self.ver_scales,
                                                 ver_offsets = self.ver_offsets,
                                                 run_id = self.run_id,
                                                 aux_out_mode = "TriggerOut",
                                                 trigger_mode = "Pattern",
                                                 trigger_levels = {"Ext": 0.4},
                                                 trigger_conditions = {"Ext": "High"}
            )
            
        self.daq.print()
        self.segment_length = self.daq.get_segment_length()
        self.sample_interval_ns = self.daq.get_sample_interval_ns()
        self.daq.arm_trigger_single()
        
    def DoStopRun(self):

        print("SPAD: DoStopRun")
        self.is_running = False

        self.daq_dataconn = SMBConnection("", "", "eudaq-host", self.lecroy_netbios_name)
        
        while True:
            try:
                self.daq_dataconn.connect(self.lecroy_ip_address, 139)
                break
            except:
                print("Could not connect ... retrying!")
                time.sleep(5)
        
        # wait for files to show up on remote file system before resetting scope
        print("Waiting for scope to finish processing ...")
        start_processing = time.time()
        
        while True:
            time.sleep(0.5)
            available_files = self.daq_dataconn.listPath("Waveforms", self.run_id)
            available_filenames = [cur.filename for cur in available_files if cur.filename not in ['.', '..']]
            
            if len(available_filenames) == len(self.channels_to_save): # check if files for all channels exist
                filesizes = np.array([cur.file_size for cur in available_files if cur.filename not in ['.', '..']])
                expected_file_size = self.number_events * self.segment_length * 2
                if any(abs(filesizes / expected_file_size - 1) > 0.3):
                    continue
                
                end_processing = time.time()
                print("... processing finished and resulted in {:.2f} MB of data (took {:.2f} sec)!".format(sum(filesizes) / 1e6, end_processing - start_processing))                
                break

            if(time.time() - start_processing > self.processing_timeout):
                print("Warning: processing exceeded timeout ({:.2f} sec); stopping scope manually".format(self.processing_timeout))
                self.daq.stop_trigger()
                self.daq.action("app.SaveRecall.DisableAutoSave")
                self.daq.action("app.SaveRecall.Waveform.SaveFile")
                break
                                    
        self.daq_dataconn.close() # will not need the SMB connection anymore now
        self.daq_dataconn = None
        
        self.daq.stop_trigger()
        self.daq.stop()
        self.daq = None

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
        while self.idev < self.number_events:
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
        
        ev = pyeudaq.Event('RawEvent', self.name)
        tev = 0 # no global time stamp
        ev.SetTriggerN(iev) # clarification: itrg is set to iev
        ev.SetTimestamp(begin = tev, end = tev)
        ev.SetDeviceN(self.plane)

        ev.AddBlock(0, bytes(self.run_id, "ascii"))  # the run id corresponds to the directory on the remote host where the data files are saved        
        self.SendEvent(ev)
        
        return True

    def _parse_list(self, liststring):
        return list(map(lambda s: s.strip(), liststring.split(",")))
    
if __name__ == '__main__':
    
    import argparse
    parser = argparse.ArgumentParser(description = 'SPAD EUDAQ2 Producer for LeCroy LabMaster',
                                     formatter_class = argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--run-control', '-r', default = 'tcp://localhost:44000')
    parser.add_argument('--name', '-n', default = 'SPAD_XXX')
    args = parser.parse_args()

    myproducer = SPADLeCroyProducer(args.name, args.run_control)
    myproducer.Connect()
    while(myproducer.IsConnected()):
        time.sleep(1)

