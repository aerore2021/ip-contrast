# Constrast Adjust Project Quick Start Script
# This script ensures clean project creation and build using separated TCL scripts
# Updated: 2025.7.16 - Using separated TCL scripts for better modularity
echo "=========================================="
echo "   Contrast Adjust Project Quick Start"
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
vivado -mode tcl -source make.tcl

