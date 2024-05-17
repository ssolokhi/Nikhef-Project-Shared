#include "eudaq/StdEventConverter.hh"
#include "eudaq/RawEvent.hh"
#include <iostream>

class SPADRawEvent2StdEventConverter: public eudaq::StdEventConverter {

  public:
  bool Converting(eudaq::EventSPC rawev,eudaq::StdEventSP stdev,eudaq::ConfigSPC conf) const override;

};

#define REGISTER_CONVERTER(name) namespace{auto dummy##name=eudaq::Factory<eudaq::StdEventConverter>::Register<SPADRawEvent2StdEventConverter>(eudaq::cstr2hash(#name));}
REGISTER_CONVERTER(SPAD)
REGISTER_CONVERTER(SPAD_0)

bool SPADRawEvent2StdEventConverter::Converting(eudaq::EventSPC in,eudaq::StdEventSP out,eudaq::ConfigSPC conf_) const{

  auto rawev = std::dynamic_pointer_cast<const eudaq::RawEvent>(in);
  std::vector<uint8_t> data = rawev -> GetBlock(0);

  eudaq::StandardPlane plane(rawev -> GetDeviceN(),"ITS3DAQ", "SPAD");
  plane.SetSizeZS(1, 1, 0, 1); // 1 x 1 plane

  out -> AddPlane(plane);

  return true;
}
