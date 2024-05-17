#include "SimpleStandardEvent.hh"
#include <set>
#include <algorithm>
#include <iostream>
#include <stdio.h>
#include <string.h>


// constructor, reserve some planes and initialize all variables
SimpleStandardEvent::SimpleStandardEvent() {
  _planes.reserve(20);
  monitor_eventfilltime = 0;
  monitor_eventanalysistime = 0;
  monitor_clusteringtime = 0;
  monitor_correlationtime = 0;
  event_number = 0;
  event_timestamp = 0;
}

void SimpleStandardEvent::addPlane(SimpleStandardPlane &plane) {
  // Checks if plane with same name and id is registered already
  bool found = false;
  for (unsigned int i = 0; i < _planes.size(); ++i) {
    if (_planes.at(i) == plane)
      found = true;
  }
  if (found)
    plane.addSuffix("-2");
  _planes.push_back(plane);
}
double SimpleStandardEvent::getMonitor_eventanalysistime() const {
  return monitor_eventanalysistime;
}

double SimpleStandardEvent::getMonitor_eventfilltime() const {
  return monitor_eventfilltime;
}

double SimpleStandardEvent::getMonitor_clusteringtime() const {
  return monitor_clusteringtime;
}

double SimpleStandardEvent::getMonitor_correlationtime() const {
  return monitor_correlationtime;
}

void SimpleStandardEvent::setMonitor_eventanalysistime(
    double monitor_eventanalysistime) {
  this->monitor_eventanalysistime = monitor_eventanalysistime;
}

void SimpleStandardEvent::setMonitor_eventfilltime(
    double monitor_eventfilltime) {
  this->monitor_eventfilltime = monitor_eventfilltime;
}

void SimpleStandardEvent::setMonitor_eventclusteringtime(
    double monitor_clusteringtime) {
  this->monitor_clusteringtime = monitor_clusteringtime;
}

void SimpleStandardEvent::setMonitor_eventcorrelationtime(
    double monitor_correlationtime) {
  this->monitor_correlationtime = monitor_correlationtime;
}

void SimpleStandardEvent::doClustering() {
  for (int plane = 0; plane < getNPlanes(); plane++) {
    _planes.at(plane).doClustering();
  }
}

unsigned int SimpleStandardEvent::getEvent_number() const {
  return event_number;
}

uint64_t SimpleStandardEvent::getEvent_timestamp() const {
  return event_timestamp;
}

void SimpleStandardEvent::setEvent_timestamp(uint64_t event_timestamp) {
  this->event_timestamp = event_timestamp;
}

void SimpleStandardEvent::setEvent_number(unsigned int event_number) {
  this->event_number = event_number;
}


void SimpleStandardEvent::setSlow_para(std::string name, double value) {
  slowpara[name] = value;

}

bool SimpleStandardEvent::getSlow_para(std::string name, double &value) const{
  auto it = slowpara.find(name);
  if (it == slowpara.end()){
    return false;
  }
  else{
    value = it->second;
    return true;
  }
}


std::vector<std::string> SimpleStandardEvent::getSlowList() const {
    std::vector<std::string> list;
    for(auto &e:slowpara)
      list.push_back(e.first);
    return list;
  };
