#!/bin/bash
# Constrast Adjust Project Quick Start Script
# This script ensures clean project creation and build using separated TCL scripts
# Updated: 2025.7.16 - Using separated TCL scripts for better modularity

# Default options
DO_SYNTHESIS=false
DO_SIMULATION=false

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -s, --synthesis      Run synthesis after project creation"
    echo "  -sim, --simulation   Run simulation"
    echo "  -a, --all           Run all steps (synthesis + simulation)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Only create project"
    echo "  $0 -s               # Create project and run synthesis"
    echo "  $0 -sim             # Create project and run simulation"
    echo "  $0 -a               # Create project and run all steps"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--synthesis)
            DO_SYNTHESIS=true
            shift
            ;;
        -sim|--simulation)
            DO_SIMULATION=true
            shift
            ;;
        -a|--all)
            DO_SYNTHESIS=true
            DO_SIMULATION=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "   Contrast Adjust Project Quick Start"
echo "=========================================="
echo "Options selected:"
echo "  - Synthesis: $DO_SYNTHESIS"
echo "  - Simulation: $DO_SIMULATION"
echo "=========================================="

echo "Using separated TCL scripts for modular build process"

# kill any existing Vivado processes
echo "Checking for existing Vivado processes..."
    tasklist | grep vivado > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Found existing Vivado processes. Attempting to terminate..."
        taskkill /f /im vivado.exe > /dev/null 2>&1
        sleep 2
fi
# Clean up any existing project directory
if [ -d "ContrastAdjust_project" ]; then
    echo "Removing existing project directory..."
    rm -rf ContrastAdjust_project > /dev/null 2>&1
    sleep 1
fi

# Clean up log and journal files
echo "Cleaning up previous log and journal files..."
rm -f vivado*.log > /dev/null 2>&1
rm -f vivado*.jou > /dev/null 2>&1
rm -f *.log > /dev/null 2>&1
rm -f *.jou > /dev/null 2>&1
rm -f vivado_pid*.str > /dev/null 2>&1
rm -f vivado_pid*.debug > /dev/null 2>&1
rm -f .Xil > /dev/null 2>&1
rm -rf .Xil/ > /dev/null 2>&1
echo "Log and journal files cleaned."

# Create and build project using separated TCL scripts
echo "=========================================="
echo "Creating Contrast Adjust project..."
echo "=========================================="

# Create project
echo "Running project creation script..."

# Prepare arguments for make.tcl
TCL_ARGS=""
if [ "$DO_SYNTHESIS" = true ] && [ "$DO_SIMULATION" = true ]; then
    TCL_ARGS="-all"
elif [ "$DO_SYNTHESIS" = true ]; then
    TCL_ARGS="-synthesis"
elif [ "$DO_SIMULATION" = true ]; then
    TCL_ARGS="-simulation"
fi

# Run make.tcl with appropriate arguments
if [ -n "$TCL_ARGS" ]; then
    echo "Running: vivado -mode tcl -source make.tcl -tclargs $TCL_ARGS"
    vivado -mode tcl -source make.tcl -tclargs $TCL_ARGS
else
    echo "Running: vivado -mode tcl -source make.tcl"
    vivado -mode tcl -source make.tcl
fi

if [ $? -ne 0 ]; then
    echo "ERROR: Project creation/build failed!"
    exit 1
fi

echo "Project and requested operations completed successfully!"

echo "=========================================="
echo "Build process completed successfully!"
echo "=========================================="

# Summary
echo "Summary:"
echo "  - Project created: ✓"
if [ "$DO_SYNTHESIS" = true ]; then
    echo "  - Synthesis: ✓"
fi
if [ "$DO_SIMULATION" = true ]; then
    echo "  - Simulation: ✓"
fi

echo "=========================================="

