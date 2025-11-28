#!/bin/bash

# Helper script to run SuperCollider files from the command line
# Usage: ./run_sc.sh filename.scd

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <supercollider_file.scd>"
    echo ""
    echo "Examples:"
    echo "  $0 init_nupic_complete.scd    # Initialize complete system"
    echo "  $0 audio_test.scd              # Test audio"
    echo "  $0 doppler_test.scd            # Test Doppler effect"
    echo "  $0 clean_server.scd            # Clean hanging synths"
    echo ""
    echo "Available scripts:"
    ls *.scd 2>/dev/null | sed 's/^/  /'
    exit 1
fi

SC_FILE="$1"

# Check if file exists
if [ ! -f "$SC_FILE" ]; then
    echo "Error: File '$SC_FILE' not found"
    exit 1
fi

echo "Running SuperCollider script: $SC_FILE"
echo "=================================="
echo ""

# Run the SuperCollider file
/Applications/SuperCollider.app/Contents/MacOS/sclang "$SC_FILE"
