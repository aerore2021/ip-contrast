# ContrastAdjust Project Creation Script
# Compatible with Vivado 2021.1 and above
# Usage: vivado -mode tcl -source make.tcl -tclargs [options]
# Options: -synthesis, -simulation, -all
# Author: Aero2021
# Date: July 16, 2025

# Parse command line arguments
set do_synthesis false
set do_simulation false

# Process arguments
foreach arg $argv {
    switch -exact -- $arg {
        "-synthesis" {
            set do_synthesis true
            puts "INFO: Synthesis will be run after project creation"
        }
        "-simulation" {
            set do_simulation true
            puts "INFO: Simulation will be run after project creation"
        }
        "-all" {
            set do_synthesis true
            set do_simulation true
            puts "INFO: Both synthesis and simulation will be run"
        }
        default {
            puts "WARNING: Unknown argument: $arg"
        }
    }
}

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
# Note: When using SystemVerilog interfaces, individual signals are not exposed as ports
# These constraints will be applied at the interface level during elaboration

# Clock Uncertainty
set_clock_uncertainty -setup 0.1 -hold 0.1 [get_clocks clk]

# False Path Constraints for Reset
set_false_path -from [get_ports rst_n] -to [all_registers]

# Multi-cycle path constraints for BRAM lookup (commented out - adjust path names as needed)
# set_multicycle_path -setup 2 -from [get_cells {*/bram_reg[*]}] -to [get_cells {*/m_axis_tdata_reg[*]}]
# set_multicycle_path -hold 1 -from [get_cells {*/bram_reg[*]}] -to [get_cells {*/m_axis_tdata_reg[*]}]

# Timing exceptions for real number calculations (synthesis time)
# These paths are pre-calculated and stored in BRAM, so no additional timing constraints needed
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

# Execute additional steps based on arguments
if {$do_synthesis && $do_simulation} {
    puts "INFO: Running synthesis and simulation..."
    source syn.tcl
    source sim.tcl
} elseif {$do_synthesis} {
    puts "INFO: Running synthesis..."
    source syn.tcl
} elseif {$do_simulation} {
    puts "INFO: Running simulation..."
    source sim.tcl
} else {
    puts "INFO: Project creation completed. No additional steps requested."
}

puts "INFO: All requested operations completed successfully!"