#ifndef H_EudetTluController_hh
#define H_EudetTluController_hh

#include <cstdint>
#include <string>
#include <vector>
#include <stdexcept>
#include <iostream>
#include <ostream>
#include "eudaq/Time.hh"

#define DO_NOT_USE_TRIGGER_INPUT_INFORMATION 0
#define USE_TRIGGER_INPUT_INFORMATION 1

namespace tlu {

  struct TLU_LEDs {
    TLU_LEDs(int left = 0, int right = 0, int rst = 0, int busy = 0,
             int trig = 0)
        : left(left), right(right), rst(rst), busy(busy), trig(trig) {}
    void print(std::ostream &) const;
    int left, right, rst, busy, trig;
  };

  inline std::ostream &operator<<(std::ostream &os, const TLU_LEDs &leds) {
    leds.print(os);
    return os;
  }

  typedef void *ZESTSC1_HANDLE;
  
  static const int TLU_TRIGGER_INPUTS = 4;
  static const int TLU_LEMO_DUTS = 4;
  static const int TLU_DUTS = 6;
  static const int TLU_BUFFER_SIZE = 4096;
  static const int NUM_TLU_BUFFERS = 4;
  static const int TLU_PMTS = 4;
  static const int PMT_VCNTL_DEFAULT = 800; // in mV

  static const unsigned TLU_DEBUG_UPDATE = 0x0001;
  static const unsigned TLU_DEBUG_CONFIG = 0x0002;
  static const unsigned TLU_DEBUG_BLOCKREAD = 0x0004;

  double Timestamp2Seconds(uint64_t t);
  double Timestamp2NanoSeconds(uint64_t t);

  class TLUException : public std::runtime_error {
  public:
    TLUException(const std::string &msg, int status = 0, int tries = 0)
        : std::runtime_error(make_msg(msg, status, tries).c_str()),
          m_status(status), m_tries(tries) {}
    int GetStatus() const { return m_status; }
    int GetTries() const { return m_tries; }

  private:
    static std::string make_msg(const std::string &msg, int status, int tries);
    int m_status, m_tries;
  };

  class TLUEntry {
  public:
    TLUEntry(uint64_t t = 0, uint32_t e = 0, unsigned trigger = 0)
        : m_timestamp(t), m_eventnum(e) {
      for (int i = 0; i < 4; ++i) {
        m_trigger[i] = (trigger >> i) & 1;
      }
    }

    uint64_t Timestamp() const { return m_timestamp; }
    uint32_t Eventnum() const { return m_eventnum; }
    void Print(std::ostream &out = std::cout) const;
    std::string trigger2String();

  private:
    uint64_t m_timestamp;
    uint32_t m_eventnum;
    bool m_trigger[TLU_TRIGGER_INPUTS];
  };

  struct TLUAddresses;

  class TLUController {
  public:
    enum ErrorHandler { // What to do if a usb access returns an error
      ERR_ABORT,        // Abort the program (used for debugging)
      ERR_THROW,        // Throw a TLUException
      ERR_RETRY1,       // Retry once before throwing
      ERR_RETRY2        // Retry twice
    };
    enum Input_t { // Selects the input for DUT connectors 0-3
      IN_NONE,     // Disable the DUT input
      IN_HDMI,     // Select the HDMI input
      IN_LEMO,     // Select the Lemo (TTL or NIM) input
      IN_RJ45      // Select the RJ45 input
    };

    TLUController(int errormech = ERR_RETRY1);
    ~TLUController();

    void SetVersion(
        unsigned version); // default (0) = auto detect from serial number
    void SetFirmware(const std::string &filename); // can be just version number
    void SetDebugLevel(unsigned level); // default (0) = no debug output
    void SetDUTMask(unsigned char mask, bool updateleds = true);
    void SetVetoMask(unsigned char mask);
    void SetAndMask(unsigned char mask);
    void SetOrMask(unsigned char mask);
    void SetStrobe(uint32_t period, uint32_t width);
    void SetEnableDUTVeto(unsigned char mask);
    void SetHandShakeMode(unsigned handshakemode);
    void SetTriggerInformation(unsigned TriggerInf);
    void SetClockSource(unsigned in);

    bool SetPMTVcntl(
        unsigned value =
            PMT_VCNTL_DEFAULT); // in mV, sets all PMT control voltages the same
    // in mV, TLU_PMTS entries expected, sets each PMT control voltage
    // separately
    bool SetPMTVcntl(unsigned *values, double *gain_errors = NULL,
                     double *offset_errors = NULL);
    void SetPMTVcntlMod(unsigned value);
    unsigned char GetVetoMask() const;
    unsigned char GetAndMask() const;
    unsigned char GetOrMask() const;
    uint32_t GetStrobeWidth() const;
    uint32_t GetStrobePeriod() const;
    unsigned char GetStrobeStatus() const;
    unsigned char GetDUTClockStatus() const;
    unsigned char GetEnableDUTVeto() const;
    unsigned char getTriggerInformation() const;
    unsigned char GetClockSource() const;
    std::string GetStatusString() const;
    static int DUTnum(const std::string &name);
    void SelectDUT(const std::string &name, unsigned mask = 0xf,
                   bool updateleds = true);
    void SelectDUT(int input, unsigned mask = 0xf, bool updateleds = true);

    void SetTriggerInterval(unsigned millis);

    void Configure();
    void Update(bool timestamps = true);
    void Start();
    void Stop();
    void ResetTriggerCounter();
    void ResetScalers();
    void ResetTimestamp();
    void ResetUSB();
    eudaq::Time TimestampZero() const { return m_timestampzero; }

    size_t NumEntries() const { return m_buffer.size(); }
    TLUEntry GetEntry(size_t i) const { return m_buffer[i]; }
    unsigned GetTriggerNum() const { return m_triggernum; }
    uint64_t GetTimestamp() const { return m_timestamp; }

    unsigned char GetTriggerStatus() const;

    bool InhibitTriggers(bool inhibit = true); // returns previous value

    void Print(std::ostream &out = std::cout, bool timestamps = true) const;
    void Print(bool timestamps) const { Print(std::cout, timestamps); }

    std::string GetVersion() const;
    std::string GetFirmware() const;
    unsigned GetFirmwareID() const;
    unsigned GetSerialNumber() const;
    unsigned GetLibraryID(unsigned ver = 0) const;
    void SetLEDs(int left, int right = 0); // DEPRECATED
    void SetLEDs(const std::vector<TLU_LEDs> &);
    void UpdateLEDs();

    unsigned GetScaler(unsigned) const;
    unsigned GetParticles() const;
    bool SetupLVPower(int value = 800); // in mV -- obsolete, use SetPMTVctrl()

  private:
    void OpenTLU();
    void LoadFirmware();
    void Initialize();
    bool SetupLemo(); // Tries to set the LEMO termination and DAC voltage,
                      // returns true if successful
    unsigned CalcPMTDACValue(double voltage);

    void WriteRegister(uint32_t offset, unsigned char val);
    void WriteRegister24(uint32_t offset, uint32_t val);
    unsigned char ReadRegister8(uint32_t offset) const;
    unsigned short ReadRegister16(uint32_t offset) const;
    uint32_t ReadRegister24(uint32_t offset) const;
    uint32_t ReadRegister32(uint32_t offset) const;
    uint64_t ReadRegister64(uint32_t offset) const;
    uint64_t *ReadBlock(unsigned entries);
    unsigned ReadBlockRaw(unsigned entries, unsigned buffer_offset);
    unsigned ReadBlockSoftErrorCorrect(unsigned entries, bool pad);
    unsigned ResetBlockRead(unsigned entries);
    void PrintBlock(uint64_t block[][4096], unsigned nbuf, unsigned bufsize);
    unsigned char ReadRegisterRaw(uint32_t offset) const;

    void SelectBus(unsigned bus);
    void WritePCA955(unsigned bus, unsigned device, unsigned data);
    void WriteI2C16(unsigned device, unsigned command, unsigned data);
    void WriteI2Cbyte(unsigned data);
    bool WriteI2Clines(bool scl, bool sda);

    std::string m_filename;
    ZESTSC1_HANDLE m_handle;
    unsigned char m_mask, m_vmask, m_amask, m_omask, m_ipsel, m_enabledutveto;
    uint32_t m_strobewidth, m_strobeperiod;
    unsigned m_triggerint, m_serial;
    bool m_inhibit;

    unsigned m_vetostatus, m_fsmstatus, m_dutbusy, m_clockstat, m_dmastat,
        m_pmtvcntlmod;
    uint32_t m_fsmstatusvalues;
    unsigned m_triggernum;
    uint64_t m_timestamp;
    std::vector<TLUEntry> m_buffer;
    uint64_t *m_oldbuf;
    unsigned *m_triggerBuffer;
    uint64_t m_working_buffer[NUM_TLU_BUFFERS][TLU_BUFFER_SIZE];
    unsigned m_scalers[TLU_TRIGGER_INPUTS];
    unsigned m_particles;
    mutable uint64_t m_lasttime;
    int m_errorhandler;
    unsigned m_version;
    TLUAddresses *m_addr;
    eudaq::Time m_timestampzero;
    unsigned m_correctable_blockread_errors;
    unsigned m_uncorrectable_blockread_errors;
    unsigned m_usb_timeout_errors;
    unsigned m_debug_level;
    unsigned m_handshakemode;
    unsigned m_TriggerInformation;
  };

  inline std::ostream &operator<<(std::ostream &o, const TLUController &t) {
    t.Print(o);
    return o;
  }

  inline std::ostream &operator<<(std::ostream &o, const TLUEntry &t) {
    t.Print(o);
    return o;
  }
}

#endif
