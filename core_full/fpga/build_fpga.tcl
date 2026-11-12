# Sintetiza core_full para el Arty A7-100T (xc7a100tcsg324-1) con Vivado en
# modo batch y deja TopArtyA7.bit en el directorio actual. Uso:
#   mkdir -p core_full/fpga/build && cd core_full/fpga/build
#   vivado -mode batch -source ../build_fpga.tcl
set fpga [file dirname [file normalize [info script]]]
set core [file dirname $fpga]
file copy -force $fpga/program_fpga.hex .
read_verilog -sv $core/risc_v_32_i_pkg.sv
foreach f {ArithmeticLogicUnit ImmediateSignExtend RegisterFile ComparatorUnit LoadAndStoreUnit CoreControlUnit_full InstructionMemory_full DataMemory_full ProcessorCoreFull} {
    read_verilog -sv $core/$f.sv
}
read_verilog -sv $fpga/Debounce.sv
read_verilog -sv $fpga/TraceUart.sv
read_verilog -sv $fpga/TopArtyA7.sv
read_xdc $fpga/arty_a7_100t.xdc
synth_design -top TopArtyA7 -part xc7a100tcsg324-1
opt_design
place_design
route_design
report_timing_summary -file timing.rpt
report_utilization -file util.rpt
write_bitstream -force TopArtyA7.bit
