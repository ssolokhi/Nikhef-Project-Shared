#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "eudaq::core" for configuration "RelWithDebInfo"
set_property(TARGET eudaq::core APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(eudaq::core PROPERTIES
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libeudaq_core.so.2.6"
  IMPORTED_SONAME_RELWITHDEBINFO "libeudaq_core.so.2.6"
  )

list(APPEND _IMPORT_CHECK_TARGETS eudaq::core )
list(APPEND _IMPORT_CHECK_FILES_FOR_eudaq::core "${_IMPORT_PREFIX}/lib/libeudaq_core.so.2.6" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
