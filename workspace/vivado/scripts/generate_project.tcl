# Insert the location of the project on your disk, this include the name of the project folder
set projectDir C:/Users/Mani/Documents/Projects/FPGA/Training_SPI_slave
# The full part name for use when generating the project
set fullPartName xc7a100tcsg324-1
# The part name that appears in the hardware manager to upload the bitstream to the FPGA
set shortPartName xc7a100t_0

cd $projectDir/workspace/vivado/scripts
set outputDir ../projectflow
file mkdir $outputDir

create_project littleriscy ./$outputDir -part $fullPartName -force

add_files $projectDir/rtl/syn/littleriscy_core
# Change this line if using some other constraint file
add_files -fileset constrs_1 $projectDir/rtl/constraints/Arty-A7-100-Master.xdc
import_files -force -norecurse
set_property top top [current_fileset]
update_compile_order -fileset sources_1

# Synthesize, implement and upload bitstream to device, uncomment to use
# launch_runs synth_1
# wait_on_run synth_1
# 
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# puts "Implementation done!"
# set_param labtools.override_cs_server_version_check 1
# open_hw_manager
# connect_hw_server -allow_non_jtag
# open_hw_target
# set_property PROGRAM.FILE {$projectDir/workspace/vivado/projectflow/littleriscy.runs/impl_1/riscv_core.bit} [get_hw_devices $shortPartName]
# current_hw_device [get_hw_devices $shortPartName]
# refresh_hw_device -update_hw_probes false [lindex [get_hw_devices $shortPartName] 0]
# program_hw_devices [get_hw_devices $shortPartName]