# Programa el Arty A7-100T por JTAG con el bitstream indicado (default: el
# TopArtyA7.bit versionado junto a este script). Uso:
#   vivado -mode batch -source core_full/fpga/program_fpga.tcl
#   vivado -mode batch -source core_full/fpga/program_fpga.tcl -tclargs ruta/otro.bit
set here [file dirname [file normalize [info script]]]
set bit [expr {$argc > 0 ? [lindex $argv 0] : "$here/TopArtyA7.bit"}]
open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices xc7a100t*] 0]
current_hw_device $dev
set_property PROGRAM.FILE [file normalize $bit] $dev
program_hw_devices $dev
puts "DONE_PROGRAMMED: [get_property REGISTER.IR.BIT5_DONE $dev]"
close_hw_manager
