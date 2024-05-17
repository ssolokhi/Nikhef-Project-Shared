# Install script for directory: /home/isis/eudaq2/main/lib/core

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/isis/eudaq2")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "RelWithDebInfo")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set default install directory permissions.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6"
         RPATH "$ORIGIN/../lib:$ORIGIN/../extern/lib")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/home/isis/eudaq2/build/main/lib/core/libeudaq_core.so.2.6")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6"
         OLD_RPATH "::::::::::::::::::::::::::::::::::::"
         NEW_RPATH "$ORIGIN/../lib:$ORIGIN/../extern/lib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so.2.6")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so"
         RPATH "$ORIGIN/../lib:$ORIGIN/../extern/lib")
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE SHARED_LIBRARY FILES "/home/isis/eudaq2/build/main/lib/core/libeudaq_core.so")
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so"
         OLD_RPATH "::::::::::::::::::::::::::::::::::::"
         NEW_RPATH "$ORIGIN/../lib:$ORIGIN/../extern/lib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libeudaq_core.so")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/eudaq" TYPE FILE FILES
    "/home/isis/eudaq2/main/lib/core/include/eudaq/BufferSerializer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/CommandReceiver.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Configuration.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/DataCollector.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/DataConverter.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/DataReceiver.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/DataSender.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Deserializer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Documentation.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Event.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Exception.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Factory.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/FileDeserializer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/FileNamer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/FileReader.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/FileSerializer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/FileWriter.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/LogCollector.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/LogMessage.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/LogSender.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Logger.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/ModuleManager.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Monitor.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/OptionParser.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Platform.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Processor.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Producer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/RawEvent.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/RunControl.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Serializable.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Serializer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/StandardEvent.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/StandardPlane.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Status.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/StdEventConverter.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Time.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportBase.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportClient.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportNULL.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportServer.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportTCP.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportTCP_POSIX.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/TransportTCP_WIN32.hh"
    "/home/isis/eudaq2/main/lib/core/include/eudaq/Utils.hh"
    )
endif()

