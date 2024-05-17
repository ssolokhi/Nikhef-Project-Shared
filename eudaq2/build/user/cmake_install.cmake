# Install script for directory: /home/isis/eudaq2/user

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

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/isis/eudaq2/build/user/alibava/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/adeniumConverter/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/example/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/experimental/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/eudet/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/calice/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/caribou/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/cmspixel/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/itkstrip/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/timepix3/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/tlu/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/stcontrol/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/aidastrip/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/tbscDESY/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/piStage/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/ITS3/cmake_install.cmake")
  include("/home/isis/eudaq2/build/user/cms-phase2/cmake_install.cmake")

endif()

