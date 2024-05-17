set env(TZ) UTC
set compile_time [clock seconds]

# TODO: the script name does not imply that we would delete stuff
#exec git clean -d -x -f

if {[catch {exec git status --porcelain} result] == 0} { 
    set dirty [expr [string length $result] != 0]
} else {
    set dirty 1
} 

if {[catch {exec git rev-parse HEAD} result] == 0} { 
    set git $result
} else {
    set git FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
} 

if {[catch {exec git show -s --format=%ct} result] == 0} { 
    set commit_time $result
} else {
    set commit_time 1402625460
} 

if {[catch {exec git describe --tags --abbrev=0 --exact-match} result] == 0} { 
    set version    "16'd[lindex [split [string trimleft $result v] .] 0]"
    set subversion "16'd[lindex [split [string trimleft $result v] .] 1]"
    set patchlevel "16'd[lindex [split [string trimleft $result v] .] 2]"
} else {
    set version    "16'hFFFF"
    set subversion "16'hFFFF"
    set patchlevel "16'hFFFF"
} 

set fp [open "versions.h" w]
puts $fp "`define GIT_HASH     160'h$git"
puts $fp "`define GIT_DIRTY      1'b$dirty"
puts $fp "`define COMMIT_YYYY   16'h[clock format $commit_time  -format %Y  ]"
puts $fp "`define COMMIT_MMDD   16'h[clock format $commit_time  -format %m%d]"
puts $fp "`define COMMIT_HHMM   16'h[clock format $commit_time  -format %H%M]"
puts $fp "`define COMPILE_YYYY  16'h[clock format $compile_time -format %Y  ]"
puts $fp "`define COMPILE_MMDD  16'h[clock format $compile_time -format %m%d]"
puts $fp "`define COMPILE_HHMM  16'h[clock format $compile_time -format %H%M]"

# TODO: find a better place/way
puts $fp "`define VERSION    $version"
puts $fp "`define SUBVERSION $subversion"
puts $fp "`define PATCHLEVEL $patchlevel"

