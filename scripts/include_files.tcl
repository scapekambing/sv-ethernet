set sv_eth_library_dir [file dirname [file normalize [info script]]]
set sv_eth_library_dir ${sv_eth_library_dir}/..

source $sv_eth_library_dir/lib/sv-axis/scripts/include_files.tcl
source $sv_eth_library_dir/lib/sv-axil/scripts/include_files.tcl

add_files $sv_eth_library_dir/lib/verilog-ethernet/lib
add_files $sv_eth_library_dir/lib/verilog-ethernet/rtl
add_files $sv_eth_library_dir/syn