# This script resets the ZCU102 board and programs it with a specified bitstream and LTX file.

# Files
set bitstream_file "/home/zcu102/cheshire_top_xilinx.bit"
set ltx_file "/home/zcu102/cheshire_top_xilinx.ltx"
set board_name "xczu9_0"

# Check if the files exist
if {![file exists $bitstream_file]} {
    puts "Error: Bitstream file not found at $bitstream_file"
    exit 1
}
if {![file exists $ltx_file]} {
    puts "Error: LTX file not found at $ltx_file"
    exit 1
}

# Load the hardware server
if {[llength [get_hw_servers]] > 0} {
    disconnect_hw_server
}
open_hw_manager
connect_hw_server

set targets [get_hw_targets]
if {[llength $targets] == 0} {
    puts "Error: no hardware targets found"
    exit 1
} else {
    set board [lindex $targets 0]
    open_hw_target $board
    puts "Connected to hardware target: $board"
}

set_property PROBES.FILE $ltx_file [get_hw_devices $board_name]
set_property FULL_PROBES_FILE $ltx_file [get_hw_devices $board_name]
set_property PROGRAM.FILE $bitstream_file [get_hw_devices $board_name]

# Program the device
program_hw_devices [get_hw_devices $board_name]
refresh_hw_device [get_hw_devices $board_name]
puts "Board programmed."
