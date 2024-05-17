# CMake generated Testfile for 
# Source directory: /home/isis/eudaq2/main/exe
# Build directory: /home/isis/eudaq2/build/main/exe
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(test_mimosa_tlu_io "/home/isis/eudaq2/build/main/exe/euCliReader" "-i" "/home/isis/eudaq2/testing/data/mimosa_tlu.raw" "-std" "-e" "0" "-E" "5" "-s")
set_tests_properties(test_mimosa_tlu_io PROPERTIES  _BACKTRACE_TRIPLES "/home/isis/eudaq2/main/exe/CMakeLists.txt;54;add_test;/home/isis/eudaq2/main/exe/CMakeLists.txt;0;")
