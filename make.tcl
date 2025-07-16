# ContrastAdjust Project Creation Script
# Compatible with Vivado 2021.1 and above
# Usage: vivado -mode tcl -source create_contrastadjust_project.tcl
# Author: Aero2021
# Date: July 16, 2025

# Project configuration
set project_name "ContrastAdjust_project"
set project_dir "."
set fpga_part "xc7a100tcsg324-1"

# Delete existing project
if {[file exists "$project_dir/$project_name"]} {
    file delete -force "$project_dir/$project_name"
}

# Create new project
create_project $project_name $project_dir/$project_name -part $fpga_part
puts "INFO: Project '$project_name' created successfully"

# Add design files
add_files -norecurse {
    src/Contrast.sv
    src/AxiStreamIf.sv
}

# Add simulation files
add_files -fileset sim_1 -norecurse {
    sim/tb_Contrast.sv
}

# Set file properties
set_property file_type SystemVerilog [get_files src/Contrast.sv]
set_property file_type SystemVerilog [get_files src/AxiStreamIf.sv]
set_property file_type SystemVerilog [get_files sim/tb_Contrast.sv]

# Set top modules
set_property top Contrast [get_filesets sources_1]
set_property top tb_Contrast [get_filesets sim_1]
puts "INFO: Source files added successfully"

# Create constraints file
set constraints_content {# ContrastAdjust Project Clock Constraints
create_clock -period 10.0 -name clk -waveform {0.000 5.000} [get_ports clk]

# Input/Output Delay Constraints
set_input_delay -clock clk -max 2.0 [get_ports {rst_n axis_in_*}]
set_output_delay -clock clk -max 2.0 [get_ports {axis_out_*}]

# Clock Uncertainty
set_clock_uncertainty -setup 0.1 -hold 0.1 [get_clocks clk]
}

set constraints_file "$project_dir/$project_name/constraints.xdc"

set file [open $constraints_file "w"]
puts $file $constraints_content
close $file

add_files -fileset constrs_1 -norecurse $constraints_file
puts "INFO: Constraints file created successfully"

# Set synthesis strategy
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Verify IP files are present
set ip_files [get_files -filter {FILE_TYPE == IP}]
if {[llength $ip_files] > 0} {
    puts "INFO: Found IP files: $ip_files"
} else {
    puts "WARNING: No IP files found in project"
}

puts "INFO: Project setup completed"
puts "=========================================="
puts "ContrastAdjust Project Created Successfully!"
puts "=========================================="
puts "Project is ready for synthesis and simulation."
puts "=========================================="
