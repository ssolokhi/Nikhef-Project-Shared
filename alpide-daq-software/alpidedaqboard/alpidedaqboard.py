import json
import os
from keyword import iskeyword
import usb
import struct
import subprocess
from datetime import datetime
from math import log
from ._version import __version__

__location__ = os.path.realpath(
    os.path.join(os.getcwd(), os.path.dirname(__file__)))

class ALPIDEDAQBoard:
    VID=0x1556
    PID=0x01B8
    DACTOMA=3.3/4096/0.1*10 # VCC/12bit/0.1R*gain10
            
    class _FWMod:
        class _FWCmd:
            def __init__(self,mod,cmd):
                self._mod=mod
                self._cmd=cmd
            def issue(self):
                return self._mod.regs['cmd'].write(self._cmd)
        class _FWReg:
            def __init__(self,mod,addr):
                self._mod=mod
                self._addr=addr
            def read(self):
                return self._mod._reg_read(self._addr)
            def write(self,val):
                return self._mod._reg_write(self._addr,val)
        def __init__(self,daq,addr):
            self._daq=daq
            self._addr=addr
            self.regs={}
            self.cmds={}
        def _add_reg(self,name,addr):
            reg=self._FWReg(self,addr)
            self.regs[name]=reg
            if iskeyword(name): name+='_'
            setattr(self,name,reg)
            return reg
        def _add_cmd(self,name,cmd):
            cmd=self._FWCmd(self,cmd)
            self.cmds[name]=cmd
            if iskeyword(name): name+='_'
            setattr(self,name,cmd)
            return cmd
        def _reg_read(self,addr):
            return self._daq._fw_reg_read(self._addr,addr)
        def _reg_write(self,addr,val):
            return self._daq._fw_reg_write(self._addr,addr,val)

    def dispose(self):
        if self.dev:
            usb.util.dispose_resources(self.dev)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.dispose()
        self.dev=None

    def __del__(self):
        self.dispose()

    def __init__(self,serial=None,fw=None,verbose=True):
        self.dev=None
        if verbose: print(serial,fw)
        if not fw:
            with ALPIDEDAQBoard(serial=serial,fw=__location__+'/fw.json',verbose=verbose) as tmp:
                v=tmp.id.version   .read()
                s=tmp.id.subversion.read()
                p=tmp.id.patchlevel.read()
                fw=__location__+'/fw-v%d.%d.%d.json'%(v,s,p)
        if verbose: print(fw)

        self.mods={}
        with open(fw,'r') as f:
            fw=json.loads(f.read())
        for mod_name,mod_addr in fw['modules'].items():
            mod=self._add_mod(mod_name.lower(),mod_addr)
            if 'registers' in fw:
                for reg_name,reg_addr in fw['registers'][mod_name].items():
                    mod._add_reg(reg_name.lower(),reg_addr)
            if 'commands' in fw:
                for cmd_name,cmd in fw['commands'][mod_name].items():
                    mod._add_cmd(cmd_name.lower(),cmd)
        if serial:
            devs=list(usb.core.find(idVendor=self.VID,idProduct=self.PID,serial_number=serial,find_all=True))
            if not devs:
                raise ValueError('No DAQ board with serial number "%s" found.'%serial)
            if len(devs)>1:
                raise ValueError('More than 1 DAQ board with serial number "%s" were found. Actually %d were found...'%(serial,len(devs)))
            self.dev=devs[0]
        else:
            devs=list(usb.core.find(idVendor=self.VID,idProduct=self.PID,find_all=True))
            if len(devs)>1:
                raise ValueError('More than 1 DAQ boards were found. Actually %d were found... please specify serial number (options are %s)'%(len(devs),', '.join('"%s"'%dev.serial_number for dev in devs)))
            if len(devs)==0:
                raise ValueError('No DAQ board was found.')
            self.dev=devs[0]
        self.cfg=self.dev.get_active_configuration()
        self.itf=self.cfg[(0,0)]
        self.epo=self.itf[0]
        self.epi=self.itf[1]
        self.epd=self.itf[2]
        while True:
            try:
                d=self.epi.read(512,100)
            except usb.core.USBError as e:
                if e.errno in [60,110]: # TIMEOUT
                    break
                else:
                    raise e

    def alpide_reg_write(self,addr,val,chipid=0x10):
        self.ctrlsoft.opcode.write(0x9C)
        self.ctrlsoft.chipid.write(chipid)
        self.ctrlsoft.addr.write(addr)
        self.ctrlsoft.data.write(val)
        self.ctrlsoft.wr.issue()

    def alpide_reg_read(self,addr,chipid=0x10):
        self.ctrlsoft.opcode.write(0x4E)
        self.ctrlsoft.chipid.write(chipid)
        self.ctrlsoft.addr.write(addr)
        self.ctrlsoft.rd.issue()
        return self.ctrlsoft.return_.read()

    def alpide_cmd_issue(self,opcode):
        self.ctrlsoft.opcode.write(opcode)
        self.ctrlsoft.cmd.issue()

    def _add_mod(self,name,addr):
        mod=self._FWMod(self,addr)
        self.mods[name]=mod
        if iskeyword(name): name+='_'
        setattr(self,name,mod)
        return mod

    def _fw_reg_read(self,mod_addr,reg_addr):
        if not isinstance(reg_addr,list): reg_addr=[reg_addr]
        w=0
        for a in reg_addr:
            cmd=0b00<<30|mod_addr<<24|a<<16
            self.epo.write(struct.pack('<L',cmd))
            ret=self.epi.read(4)
            d=struct.unpack('<L',bytes(ret))[0]&0xFFFF
            w=w<<16|d
        return w

    def _fw_reg_write(self,mod_addr,reg_addr,val):
        if not isinstance(reg_addr,list): reg_addr=[reg_addr]
        for a in reversed(reg_addr):
            d=val&0xFFFF
            val>>=16
            cmd=0b10<<30|mod_addr<<24|a<<16|d
            self.epo.write(struct.pack('<L',cmd))

    def alpide_pixel_mask_all(self,mask=True,chipid=0x10):
        self.alpide_reg_write(0x0487             ,0x000       ,chipid=chipid) # deselect all
        self.alpide_reg_write(0x0500             ,mask<<1|0<<0,chipid=chipid) # set data and select mask register
        self.alpide_reg_write(0x0487             ,0xFFFF      ,chipid=chipid) # select all
        self.alpide_reg_write(0x0487             ,0x0000      ,chipid=chipid) # deselect all
    def alpide_pixel_mask_row(self,row,mask=True,chipid=0x10):
        self.alpide_reg_write(0x0487             ,0x000       ,chipid=chipid) # deselect all
        self.alpide_reg_write(0x0500             ,mask<<1|0<<0,chipid=chipid) # set data and select mask register
        self.alpide_reg_write(0x0483             ,0xFFFF      ,chipid=chipid) # select all columns
        self.alpide_reg_write(0x0404|(row>>4)<<11,1<<(row&0xF),chipid=chipid) # select one row
        self.alpide_reg_write(0x0487             ,0x000       ,chipid=chipid) # deselect all
    def alpide_pixel_mask_xy(self,x,y,mask=True,chipid=0x10):
        self.alpide_reg_write(0x0487             ,0x000       ,chipid=chipid) # deselect all
        self.alpide_reg_write(0x0500             ,mask<<1|0<<0,chipid=chipid) # set data and select mask register
        self.alpide_write_region_reg(x>>5&0x1F,4,0x1+(x>>4&0x1),1<<(x&0xF),chipid=chipid) # select one column
        self.alpide_reg_write(0x0404|(y>>4)<<11,1<<(y&0xF),chipid=chipid) # select one row
        self.alpide_reg_write(0x0487             ,0x000       ,chipid=chipid) # deselect all
    def alpide_pixel_pulsing_all(self,enable=True,chipid=0x10):
        self.alpide_reg_write(0x0487             ,0x000         ,chipid=chipid) # deselect all
        self.alpide_reg_write(0x0500             ,enable<<1|1<<0,chipid=chipid) # set data and select pulsing register
        self.alpide_reg_write(0x0487             ,0xFFFF        ,chipid=chipid) # select all
        self.alpide_reg_write(0x0487             ,0x0000        ,chipid=chipid) # deselect all
    def alpide_pixel_pulsing_row(self,row,enable=True,chipid=0x10):
        self.alpide_reg_write(0x0487             ,0x000         ,chipid=chipid) # deselect all
        self.alpide_reg_write(0x0500             ,enable<<1|1<<0,chipid=chipid) # set data and select pulsing register
        self.alpide_reg_write(0x0483             ,0xFFFF        ,chipid=chipid) # select all columns
        self.alpide_reg_write(0x0404|(row>>4)<<11,1<<(row&0xF)  ,chipid=chipid) # select one row
        self.alpide_reg_write(0x0487             ,0x000         ,chipid=chipid) # deselect all
    def alpide_pixel_pulsing_xy(self,x,y,enable=True,chipid=0x10):
        self.alpide_reg_write(0x0487             ,0x000         ,chipid=chipid) # deselect all
        self.alpide_reg_write(0x0500             ,enable<<1|1<<0,chipid=chipid) # set data and select pulsing register
        self.alpide_write_region_reg(x>>5&0x1F,4,0x1+(x>>4&0x1),1<<(x&0xF),chipid=chipid) # select one columns
        self.alpide_reg_write(0x0404|(y>>4)<<11,1<<(y&0xF)  ,chipid=chipid) # select one row
        self.alpide_reg_write(0x0487             ,0x000         ,chipid=chipid) # deselect all
        
    def alpide_setreg_mode_ctrl(self, 
                         ChipModeSelector=None,
                         EnClustering=None,
                         MatrixROSpeed=None,
                         IBSerialLinkSpeed=None,
                         EnSkewGlobalSignals=None,
                         EnSkewStartReadout=None,
                         EnReadoutClockGating=None,
                         EnReadoutFromCMU=None,
                         chipid=0x10):

        assert EnClustering is None or EnClustering | 0X1 == 0X1
        assert MatrixROSpeed is None or MatrixROSpeed | 0X1 == 0X1
        assert EnSkewGlobalSignals is None or EnSkewGlobalSignals | 0X1 == 0X1
        assert EnSkewStartReadout is None or EnSkewStartReadout | 0X1 == 0X1
        assert EnReadoutClockGating is None or EnReadoutClockGating | 0X1 == 0X1
        assert EnReadoutFromCMU is None or EnReadoutFromCMU | 0X1 == 0X1
        MODE_CTRL = (0 << 8) | 1

        datawrite = (((ChipModeSelector & 0X3) << 0) |
                     ((EnClustering & 0X1) << 2) |
                     ((MatrixROSpeed & 0X1) << 3) |
                     ((IBSerialLinkSpeed & 0X3) << 4) |
                     ((EnSkewGlobalSignals & 0X1) << 6) |
                     ((EnSkewStartReadout & 0X1) << 7) |
                     ((EnReadoutClockGating & 0X1) << 8) |
                     ((EnReadoutFromCMU & 0X1) << 9))
        self.alpide_reg_write(MODE_CTRL, datawrite,chipid)

    def alpide_setreg_cmu_and_dmu_cfg(self, 
                               PreviousChipID=None,
                               InitialToken=None,
                               DisableManchester=None,
                               EnableDDR=None,
                               chipid=0x10):

        assert PreviousChipID is None or PreviousChipID | 0XF == 0XF
        assert InitialToken is None or InitialToken | 0X1 == 0X1
        assert DisableManchester is None or DisableManchester | 0X1 == 0X1
        assert EnableDDR is None or EnableDDR | 0X1 == 0X1
        CMU_AND_DMU_CFG = (0 << 8) | 16
         
        datawrite = (((PreviousChipID & 0XF) << 0) |
                     ((InitialToken & 0X1) << 4) |
                     ((DisableManchester & 0X1) << 5) |
                     ((EnableDDR & 0X1) << 6))
        self.alpide_reg_write(CMU_AND_DMU_CFG,datawrite,chipid)

 
    def alpide_write_region_reg(self, rgn_add, base_add, sub_add, data,chipid=0x10):
        assert rgn_add | 0x1F == 0x1F
        assert base_add | 0x7 == 0x7
        assert sub_add | 0xFF == 0xFF
        self.alpide_reg_write( (rgn_add & 0x1F) << 11 | (base_add & 0x7) << 8 | sub_add & 0xFF, data,chipid)

    def alpide_read_region_reg (self, rgn_add, base_add, sub_add,chipid=0x10):
        assert rgn_add | 0x1F == 0x1F
        assert base_add | 0x7 == 0x7
        assert sub_add | 0xFF == 0xFF
        return self.alpide_reg_read( (rgn_add & 0x1F) << 11 | (base_add & 0x7) << 8 | sub_add & 0xFF,chipid)

    def alpide_setreg_analog_monitor_and_override(self,
                                           VoltageDACSel=None,
                                           CurrentDACSel=None,
                                           SWCNTL_DACMONI=None,
                                           SWCNTL_DACMONV=None,
                                           IRefBufferCurrent=None,
                                           readback=None,
                                           chipid=0x10):
        
        assert VoltageDACSel is None or VoltageDACSel | 0XF == 0XF
        assert CurrentDACSel is None or CurrentDACSel | 0X7 == 0X7
        assert SWCNTL_DACMONI is None or SWCNTL_DACMONI | 0X1 == 0X1
        assert SWCNTL_DACMONV is None or SWCNTL_DACMONV | 0X1 == 0X1
        assert IRefBufferCurrent is None or IRefBufferCurrent | 0X3 == 0X3
        ANALOG_MONITOR_AND_OVERRIDE = (6 << 8) | 0
 
        datawrite = (((VoltageDACSel & 0XF) << 0) |
                     ((CurrentDACSel & 0X7) << 4) |
                     ((SWCNTL_DACMONI & 0X1) << 7) |
                     ((SWCNTL_DACMONV & 0X1) << 8) |
                     ((IRefBufferCurrent & 0X3) << 9))
        self.alpide_reg_write(ANALOG_MONITOR_AND_OVERRIDE,datawrite,chipid)
    
    def alpide_setreg_adc_ctrl(self,
                        Mode=None,
                        SelInput=None,
                        SetIComp=None,
                        DiscriSign=None,
                        RampSpd=None,
                        HalfLSBTrim=None,
                        CompOut=None,
                        chipid=0x10):
        assert Mode is None or Mode | 0X3 == 0X3
        assert SelInput is None or SelInput | 0XF == 0XF
        assert SetIComp is None or SetIComp | 0X3 == 0X3
        assert DiscriSign is None or DiscriSign | 0X1 == 0X1
        assert RampSpd is None or RampSpd | 0X3 == 0X3
        assert HalfLSBTrim is None or HalfLSBTrim | 0X1 == 0X1
        assert CompOut is None or CompOut | 0X1 == 0X1
        ADC_CTRL = (6 << 8) | 16

        datawrite = (((Mode & 0X3) << 0) |
                     ((SelInput & 0XF) << 2) |
                     ((SetIComp & 0X3) << 6) |
                     ((DiscriSign & 0X1) << 8) |
                     ((RampSpd & 0X3) << 9) |
                     ((HalfLSBTrim & 0X1) << 11) |
                     ((CompOut & 0X1) << 15))
        self.alpide_reg_write(ADC_CTRL,datawrite,chipid)

    def alpide_configure_dacs(self,chipid=0x10):                          
        self.alpide_reg_write(0x601,0x0a,chipid)
        self.alpide_reg_write(0x602, 0x93,chipid)
        self.alpide_reg_write(0x603, 0x56,chipid)
        self.alpide_reg_write(0x604, 0x32,chipid)
        self.alpide_reg_write(0x605, 0xaa,chipid)
        self.alpide_reg_write(0x606, 0x6a,chipid)
        self.alpide_reg_write(0x607, 0x39,chipid)
        self.alpide_reg_write(0x608, 0x00,chipid)
        self.alpide_reg_write(0x609, 0xc8,chipid)
        self.alpide_reg_write(0x60a, 0x65,chipid)
        self.alpide_reg_write(0x60b, 0x65,chipid)
        self.alpide_reg_write(0x60c, 0x1d,chipid)
        self.alpide_reg_write(0x60d, 0x40,chipid)
        self.alpide_reg_write(0x60e, 0x32,chipid)

    def alpide_setreg_fromu_cfg_1(self,
                           MEBMask=None,
                           EnStrobeGeneration=None,
                           EnBusyMonitoring=None,
                           PulseMode=None,
                           EnPulse2Strobe=None,
                           EnRotatePulseLines=None,
                           TriggerDelay=None,
                           chipid=0x10):
       
        # Assertions
        assert MEBMask is None or MEBMask | 0X7 == 0X7
        assert EnStrobeGeneration is None or EnStrobeGeneration | 0X1 == 0X1
        assert EnBusyMonitoring is None or EnBusyMonitoring | 0X1 == 0X1
        assert PulseMode is None or PulseMode | 0X1 == 0X1
        assert EnPulse2Strobe is None or EnPulse2Strobe | 0X1 == 0X1
        assert EnRotatePulseLines is None or EnRotatePulseLines | 0X1 == 0X1
        assert TriggerDelay is None or TriggerDelay | 0X7 == 0X7
        FROMU_CFG_1 = (0 << 8) | 4
        # Writedata generation
        
        datawrite = (((MEBMask & 0X7) << 0) |
                     ((EnStrobeGeneration & 0X1) << 3) |
                     ((EnBusyMonitoring & 0X1) << 4) |
                     ((PulseMode & 0X1) << 5) |
                     ((EnPulse2Strobe & 0X1) << 6) |
                     ((EnRotatePulseLines & 0X1) << 7) |
                     ((TriggerDelay & 0X7) << 8))
        self.alpide_reg_write(FROMU_CFG_1,datawrite,chipid)


    def event_read(self,buf=None,timeout=100):
        # FIXME: this needs to be addressed in FW... then also buf makes sense...
        # FIXME: p2: only "works" for USB2 (512)
        assert buf==None
        ev=bytearray([])
        while True:
            try:
                evi=self.epd.read(512,timeout)
            except usb.core.USBError as e:
                if e.errno in [60,110]: # TIMEOUT
                    if len(ev)!=0:
                        raise e
                    else:
                        return None
                else:
                    raise e
            ev+=evi
            if len(evi)!=512: break
            if list(evi[-4:])==[0xBB]*4: break
        return ev

    def purge_events(self):
        while True:
            try:
                d=self.epd.read(512,100)
            except usb.core.USBError as e:
                if e.errno in [60,110]: # TIMEOUT
                    break
                else:
                    raise e

    def fw_reset(self):
        self.rdoctrl.rst.issue()
        self.rdopar.rst.issue()
        self.evtpkr.rst.issue()
        self.evtbld.rst.issue()
        self.xonxoff.rst.issue()
        self.trg.rstrdobsy.issue()
        self.purge_events()
   
    def fw_clear_monitoring(self):
        self.rdopar.clr.issue()
        self.trgmon.clr.issue()




    def power_on(self):
        self.pwr.delay.write(40000) # 0.5 ms (8k @ 80 MHz)
        self.pwr.thra.write(int( 40/self.DACTOMA))
        self.pwr.thrd.write(int(150/self.DACTOMA))
        self.pwr.on.issue()

    def power_off(self):
        self.pwr.off.issue()

    def power_status(self):
        a=self.adc.adc5.read() # analog current
        d=self.adc.adc3.read() # digital current
        a*=self.DACTOMA
        d*=self.DACTOMA
        s=self.pwr.status.read()&1==1
        return (a,d,s)

    def read_dacmoni(self):
        i=self.adc.adc2.read()
        #i*=self.DACTOMA
        return i
   
    def read_dacmonv(self):
        v=self.adc.adc1.read()
        #v*=3.3/4096/1.8
        return v


    def carrier_temp(self):
        TR=298.15
        RT=10000
        B=3940 # TODO...
        v=self.adc.adc0.read()
        try:
            v*=3.3/4096/1.8 # 3.3V/12bit/gain 
            r=5100*(1.8-v)/v # 5.1kR*(1.8V-v)/v
            t=B*TR/(B+TR*log(r/RT))
            return t-273.15
        except:
            return None

    def get_fpga_tcompile(self):
        yyyy='%04X'%self.id.compile_yyyy.read()
        mmdd='%04X'%self.id.compile_mmdd.read()
        hhmm='%04X'%self.id.compile_hhmm.read()
        return datetime.strptime(yyyy+mmdd+hhmm+'UTC','%Y%m%d%H%M%Z')

    def get_fpga_git(self):
        githash=self.id.git_hash.read()
        gitdirty=self.id.git_dirty.read()
        if gitdirty:
            return '%40x-dirty'%githash
        else:
            return '%40x'%githash

    def get_software_git(self):
        try:
            return subprocess.check_output(['git','rev-parse','HEAD'],
                                           cwd=__location__,stderr=subprocess.STDOUT).strip()
        except subprocess.CalledProcessError:
            return f"v{__version__} - {__location__} is not a git repository but an installation directory."

    def get_software_diff(self):
        try:
            return subprocess.check_output(['git','diff'],
                                           cwd=__location__,stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError:
                st = os.stat(__file__)
                return \
                    f"File {__file__} installed in {__location__} v{__version__}:\n" +\
                    f"Created:  {datetime.utcfromtimestamp(st.st_ctime)} UTC\n" +\
                    f"Accessed: {datetime.utcfromtimestamp(st.st_atime)} UTC\n" +\
                    f"Modified: {datetime.utcfromtimestamp(st.st_mtime)} UTC\n" +\
                    f"Size:     {st.st_size}"


    

if __name__=='__main__':
    import sys
    serial=sys.argv[1] if len(sys.argv)>1 else None
    daq=ALPIDEDAQBoard(serial=serial)
    print(hex(daq.id.git_hash.read()))
    daq.id.dummy.write(123)
    print(daq.id.dummy.read())
    daq.id.dummy.write(456)
    print(daq.id.dummy.read())
    daq.trgmon.lat.issue()
    print(daq.trgmon.tsys.read())
    print('T = %5.2f degC'%daq.carrier_temp())
 

