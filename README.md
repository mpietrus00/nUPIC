# nUPIC - Trajectory Synthesis System

A modular trajectory-based synthesis system inspired by Xenakis' UPIC, implemented in SuperCollider with multi-channel spatial audio support.

## Overview

nUPIC (nu-UPIC) is a comprehensive system for creating and manipulating frequency trajectories that can be played back as audio synthesis. Draw trajectories on a canvas, edit amplitude envelopes, control spatial positioning across multiple channels, and shape wavetables - all in real-time.

## Quick Start

1. Open SuperCollider
2. Load the main application:
```supercollider
"/path/to/nUPIC/START_NUPIC.scd".load;
```

## Features

### Drawing & Editing
- **Freehand drawing** - Draw frequency trajectories directly on the canvas
- **Selection mode** (G key) - Select trajectories for editing
- **Erase mode** (E key) - Remove parts of trajectories
- **Copy/Paste** - Duplicate selected trajectories
- **Undo/Redo** - Full state history

### Audio Synthesis
- **Multi-channel output** - 2, 3, 4, 8, 12, 15, or 24 channel configurations
- **Wavetable synthesis** - upicWavetable SynthDefs with customizable waveforms
- **Real-time playback** - Space bar to play/stop

### Editors
- **Amplitude Editor** - Draw amplitude envelopes for each trajectory
- **Spatialization Editor** - Control panning across output channels over time
- **Wavetable Editor** - Design custom waveforms (sine, saw, square, FM, formant, etc.)

### Tuning Systems
- Equal Temperament (12-TET)
- Fokker 31-tone
- Harmonic Series
- Just Intonation
- Quarter Tone
- Pythagorean

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space | Play / Stop |
| G | Toggle Select Mode |
| E | Toggle Erase Mode |

## Architecture

```
nUPIC/
├── START_NUPIC.scd          # Main entry point
├── Core/
│   ├── Constants.scd        # Configuration and defaults
│   ├── TrajectoryData.scd   # Data management, undo/redo
│   ├── Model/               # Data models
│   ├── Connections/         # Audio routing
│   └── Utils/               # Helper functions
├── Audio/
│   ├── upicWavetable.scd    # Main wavetable SynthDefs
│   ├── SynthDefs.scd        # Additional synthesis definitions
│   └── SynthDefs_8ch.scd    # Multi-channel variants
├── UI/
│   ├── MainWindow.scd       # Main interface
│   ├── Controls.scd         # UI controls and keyboard handling
│   ├── MouseHandlers.scd    # Drawing and interaction
│   ├── AmplitudeEditor.scd  # Amplitude envelope editor
│   ├── SpatializationEditor.scd  # Spatial panning editor
│   └── WavetableEditor.scd  # Wavetable design editor
└── tests/                   # Test files
```

## Available SynthDefs

The system uses wavetable synthesis with configurable channel counts:

- `upicWavetable` - Mono output (default)
- `upicWavetable2ch` - Stereo output
- `upicWavetable3ch` - 3-channel output
- `upicWavetable4ch` - Quad output
- `upicWavetable8ch` - 8-channel output
- `upicWavetable12ch` - 12-channel output
- `upicWavetable15ch` - 15-channel output
- `upicWavetable24ch` - 24-channel output

## Configuration

Access system settings via the `~nUPIC` namespace:

```supercollider
// Constants (read-only)
~nUPIC[\constants][\maxTrajectories]  // 200
~nUPIC[\constants][\freqMin]          // 20 Hz
~nUPIC[\constants][\freqMax]          // 7500 Hz

// Defaults (runtime settings)
~nUPIC[\defaults][\defaultSynthDef]   // \upicWavetable (mono)
~nUPIC[\defaults][\playDuration]      // 10 seconds

// Colors
~nUPIC[\colors][\background]          // B&K green theme
```

## Reactive Defaults (Programmatic UI Updates)

The defaults system supports reactive updates - changing values programmatically will automatically update the UI.

### Setting Values with UI Auto-Update

```supercollider
// Set playDuration and automatically update the NumberBox UI
~nUPIC[\defaults][\setValue].value(\playDuration, 30)

// Read current value
~nUPIC[\defaults][\playDuration]  // -> 30
```

### Registering Custom Dependants

You can register your own functions to be notified when values change:

```supercollider
// Register a dependant
~nUPIC[\defaults][\addDependant].value({ |what, value, oldValue|
    ("Value changed: " ++ what ++ " = " ++ value).postln;
});

// Remove a dependant
~nUPIC[\defaults][\removeDependant].value(myFunc);
```

### Available Reactive Keys

- `\playDuration` - Total duration in seconds (updates duration NumberBox)
- `\defaultSynthDef` - Current SynthDef selection (updates SynthDef menu)

### Example: Programmatically Select SynthDef

```supercollider
// Switch to 8-channel output
~nUPIC[\defaults][\setValue].value(\defaultSynthDef, \upicWavetable8ch)
```

## Workflow

1. **Select SynthDef** - Choose channel configuration from the dropdown menu
2. **Draw trajectories** - Click and drag on the canvas to create frequency paths
3. **Edit amplitudes** - Select trajectory (G), click "_edit amps" to open amplitude editor
4. **Edit spatialization** - Select trajectory, click "_edit spatial" to control panning
5. **Play** - Press Space to hear your composition

## UI Style

The interface uses a B&K (Brüel & Kjær) green color scheme:
- Background: `Color.new(205/255, 250/255, 205/255)`
- Control areas: `Color.new(190/255, 240/255, 190/255)`
- Buttons: 60x25 pixels, `_lowercase` labels

## Version

Current version: 2.1.0

## License

Open-source project continuing the tradition of Xenakis' UPIC trajectory synthesis system.
