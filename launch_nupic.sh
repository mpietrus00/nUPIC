#!/bin/bash

# nUPIC Launcher Script
# This script properly launches SuperCollider with nUPIC from the command line

# Set the nUPIC directory
NUPIC_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "nUPIC Directory: $NUPIC_DIR"

# Function to check if SuperCollider is installed
check_supercollider() {
    if command -v sclang &> /dev/null; then
        echo "✓ SuperCollider found at: $(which sclang)"
        return 0
    else
        echo "✗ SuperCollider (sclang) not found in PATH"
        echo ""
        echo "Please ensure SuperCollider is installed and sclang is in your PATH."
        echo "On macOS, you may need to add it manually:"
        echo "  export PATH=\"/Applications/SuperCollider.app/Contents/MacOS:$PATH\""
        return 1
    fi
}

# Function to run SuperCollider code
run_sc_code() {
    local code="$1"
    echo "$code" | sclang
}

# Check for SuperCollider
if ! check_supercollider; then
    exit 1
fi

echo ""
echo "=== Launching nUPIC System ==="
echo ""

# Create a temporary SuperCollider script that loads everything in sequence
cat > /tmp/nupic_launcher.scd << 'EOF'
(
// nUPIC Command Line Launcher
"=== nUPIC System Launcher ===".postln;
"".postln;

// Set the working directory
var nupicPath = "NUPIC_PATH_PLACEHOLDER";
"Working directory: %".format(nupicPath).postln;

// Boot server with proper configuration
Server.default.options.memSize = 65536 * 2;
Server.default.options.numWireBufs = 128;
Server.default.options.maxNodes = 2048;
Server.default.options.numAudioBusChannels = 512;
Server.default.options.sampleRate = 44100;
Server.default.options.blockSize = 64;
Server.default.options.numBuffers = 1024;
Server.default.options.numInputBusChannels = 2;
Server.default.options.numOutputBusChannels = 2;

"Booting audio server...".postln;
Server.default.boot;

Server.default.waitForBoot {
    var loadSequence;
    
    "Server booted successfully!".postln;
    "".postln;
    
    loadSequence = {
        fork {
            // Load SynthDefs first
            "Loading SynthDefs...".postln;
            (nupicPath +/+ "Audio/SynthDefs.scd").load;
            1.wait;
            Server.default.sync;
            
            // Load the main nUPIC system
            "Loading nUPIC system...".postln;
            (nupicPath +/+ "nUPIC_Main.scd").load;
            2.wait;
            
            "".postln;
            "=== nUPIC System Ready ===".postln;
            "".postln;
            "Available commands:".postln;
            "  - Draw trajectories in the GUI window".postln;
            "  - Press SPACE to play/stop".postln;
            "  - Use mouse to draw and interact".postln;
            "".postln;
            "To quit: Press Cmd+Q in the GUI or Ctrl+C here".postln;
        };
    };
    
    loadSequence.value;
};
)
EOF

# Replace the path placeholder with the actual nUPIC directory
sed -i '' "s|NUPIC_PATH_PLACEHOLDER|$NUPIC_DIR|g" /tmp/nupic_launcher.scd

# Launch SuperCollider with the launcher script
echo "Starting SuperCollider..."
cd "$NUPIC_DIR"
sclang /tmp/nupic_launcher.scd

# Clean up
rm -f /tmp/nupic_launcher.scd
