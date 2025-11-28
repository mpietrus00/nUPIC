# nUPIC Usage Guide

## Quick Start - ADVANCED VERSION

### 🎵 NEW: High-Quality Audio with Oversampled Oscillators

**For the best audio quality, use the advanced startup:**

```supercollider
"START_NUPIC_ADVANCED.scd".load
```

This advanced startup script:
- Configures server for 48kHz with increased memory
- Loads 7 high-quality SynthDefs with oversampled oscillators
- Includes pulsar synthesis, FM, granular, and additive synthesis
- Sets default to advanced `pulsarTrain` synthdef
- Provides backwards compatibility

### Standard Version (if advanced doesn't work)

```supercollider
"START_NUPIC.scd".load
```

### Available SynthDefs

1. **pulsarTrain** - Advanced pulsar synthesis (default)
2. **grainBank** - Granular synthesis bank  
3. **fmCascade** - FM synthesis cascade
4. **additiveOS** - Additive synthesis with partials
5. **simpleOS** - Simple oversampled reference
6. **simpleGravObject** - Classic compatibility
7. **testOrbit** - Basic test synth

## Alternative Quick Start Methods

### Method 1: Command Line Launch (Recommended)
```bash
# From the nUPIC directory, run:
./launch_nupic.sh
```

This will automatically:
1. Start the SuperCollider server
2. Load all SynthDefs
3. Initialize nUPIC
4. Open the GUI

### Method 2: SuperCollider IDE

If you prefer using the SuperCollider IDE:

1. **Open SuperCollider IDE**
2. **Load the complete initialization script:**
   ```supercollider
   "init_nupic_complete.scd".load
   ```
   
   This single command will handle everything automatically.
   
   **If you get SynthDef errors**, use the fixed version instead:
   ```supercollider
   "init_synthdefs_fixed.scd".load  // Load fixed SynthDefs first
   "nUPIC_Main.scd".load            // Then load main system
   ```

### Method 3: Manual Step-by-Step (for debugging)

If you need more control or are debugging issues:

1. **Start Server and Load SynthDefs:**
   ```supercollider
   "start_server_and_load.scd".load
   ```
   Wait for "READY" message

2. **Load nUPIC System:**
   ```supercollider
   "nUPIC_SafeLoader.scd".load
   ```
   Or directly:
   ```supercollider
   "nUPIC_Main.scd".load
   ```

## Common Issues and Fixes

### "SynthDef not found" Error
This means the synth definitions weren't loaded properly.

**Fix:**
```supercollider
// Run this to reload synthdefs
"fix_synthdefs.scd".load
```

### "Node not found" Error
This happens when trying to control synths that don't exist.

**Fix:**
```supercollider
// Clean up hanging nodes
"clean_server.scd".load

// Then fix playback system
"fix_playback_nodes.scd".load
```

### Hanging Notes (audio won't stop)
**Fix:**
```supercollider
// Stop all sounds immediately
s.freeAll;

// Or use the cleanup script
"audio_reset.scd".load
```

### Server Not Starting
**Fix:**
```supercollider
// Force quit and restart
Server.killAll;
s.boot;
```

## Testing the System

### Test if SynthDefs are loaded:
```supercollider
// List all available SynthDefs
SynthDescLib.global.synthDescs.keys.postln;

// Should include: \trajectoryVarSaw and \simpleGravObject
```

### Test Audio:
```supercollider
"audio_test.scd".load
```

### Test Doppler Effect:
```supercollider
"doppler_test.scd".load
```

## Using nUPIC

Once loaded successfully:

1. **Draw Trajectories**: Click and drag in the main window
2. **Play/Stop**: Press SPACE bar
3. **Select Trajectories**: Click to select, Shift+click for multiple
4. **Delete**: Select trajectory and press DELETE/BACKSPACE
5. **Zoom**: Mouse wheel or pinch gesture
6. **Pan**: Right-click and drag

## Command Line Arguments

When using `launch_nupic.sh`, you can pass SuperCollider files:

```bash
# Run with a specific test
./launch_nupic.sh doppler_test.scd

# Run with custom configuration
./launch_nupic.sh my_config.scd
```

## Important Notes

1. **DO NOT** run SuperCollider code in the shell - it must be run in SuperCollider (IDE or sclang)
2. **Always** ensure the server is booted before loading SynthDefs
3. **Always** load SynthDefs before trying to play sounds
4. The system expects to be run from the nUPIC directory

## File Structure

```
nUPIC/
├── Audio/
│   ├── SynthDefs.scd         # Main synthdef definitions
│   └── SynthDefs_old_backup.scd
├── Core/
│   ├── Constants.scd         # System constants
│   └── TrajectoryData.scd    # Data management
├── UI/
│   ├── MainWindow.scd        # Main GUI
│   ├── Controls.scd          # Control panel
│   └── ...
├── nUPIC_Main.scd           # Main application file
├── init_nupic_complete.scd  # Complete initialization
├── launch_nupic.sh          # Shell launcher
└── README_USAGE.md          # This file
```

## Troubleshooting Workflow

If something isn't working:

1. **Stop everything:**
   ```supercollider
   s.freeAll;
   ```

2. **Restart server:**
   ```supercollider
   Server.killAll;
   s.boot;
   ```

3. **Use complete initialization:**
   ```supercollider
   "init_nupic_complete.scd".load
   ```

4. **Check status:**
   ```supercollider
   s.queryAllNodes;  // Check running synths
   SynthDescLib.global.synthDescs.keys.postln;  // Check loaded SynthDefs
   ```

## Getting Help

- Check the console output in SuperCollider for error messages
- The post window will show detailed information about what's happening
- Error messages usually indicate which SynthDef or node is causing issues
