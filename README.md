# nUPIC - Trajectory Synthesis System

A modular trajectory-based synthesis system inspired by Xenakis' UPIC, implemented in SuperCollider.

## Overview

nUPIC (nu-UPIC) is a comprehensive system for creating and manipulating frequency trajectories that can be played back as audio synthesis. The system features a modular architecture that separates concerns and makes the codebase maintainable and extensible.

## Architecture

The system is organized into several modules:

### Core/
- **Constants.scd** - Central configuration, constants, colors, and presets
- **TrajectoryData.scd** - Data management, undo/redo, selection handling

### Audio/
- **SynthDefs.scd** - All synthesis definitions (simpleGravObject, auditoryDistortion, percNoise)
- **AudioEngine.scd** - Playback control and synthesis management
- **Effects.scd** - Audio effects processing chain

### UI/
- **MainWindow.scd** - Main interface window and controls  
- **AmplitudeEditor.scd** - Amplitude envelope editing windows
- **Controls.scd** - UI controls and widgets
- **Drawing.scd** - Canvas drawing and visualization

### Generators/
- **BasicGenerators.scd** - Simple trajectory generators (glissando, sine waves, etc.)
- **XenakisGenerators.scd** - Arborescences, explosions, cascades, etc.
- **MathGenerators.scd** - Special function trajectories (Bessel, gamma, etc.)

### Utils/
- **FileIO.scd** - Save/load functionality with versioning
- **GridSystems.scd** - Tuning grid calculations
- **MathUtils.scd** - Mathematical utility functions

## Usage

### Quick Start

1. Load the main application:
```supercollider
"/path/to/nUPIC/nUPIC_Main.scd".load;
```

2. Create a simple trajectory:
```supercollider
// Define trajectory points
~traj = List[
    (x: 100, y: 400, freq: 440),
    (x: 200, y: 300, freq: 880), 
    (x: 300, y: 200, freq: 1320)
];

// Add to system
~nUPIC.data.addTrajectory(~traj);
```

3. Work with trajectories:
```supercollider
// Select trajectory
~nUPIC.data.selectTrajectory(0);

// Copy and paste
~nUPIC.data.copy();
~nUPIC.data.paste();

// Undo/redo
~nUPIC.data.undo();
~nUPIC.data.redo();

// Get statistics
~nUPIC.data.getStats();
```

### Data Management

The trajectory data manager (`~nUPIC.data`) provides:

- **Trajectory Management**: Add, remove, clear trajectories
- **Selection System**: Select, deselect, toggle selection
- **Copy/Paste**: Full trajectory copying with amplitude envelopes
- **Undo/Redo**: Complete state management with configurable history depth
- **Validation**: Trajectory data validation
- **Transformation**: Move, transpose operations on selected trajectories

### Configuration

All system constants are centralized in `Core/Constants.scd`:

```supercollider
// Access constants
~nUPIC.constants.maxSynths        // 200
~nUPIC.constants.frameRate        // 30
~nUPIC.constants.freqMin          // 20
~nUPIC.constants.freqMax          // 7500

// Access colors
~nUPIC.colors.background          // Color.white
~nUPIC.colors.selected            // Color.blue
~nUPIC.colors.trajectory(5)       // Color based on index

// Access defaults
~nUPIC.defaults.playDuration      // 10
~nUPIC.defaults.defaultSynthDef   // \simpleGravObject
```

## Modules Status

### ✅ Completed
- Core/Constants.scd
- Core/TrajectoryData.scd  
- Audio/SynthDefs.scd
- nUPIC_Main.scd

### 🚧 In Progress
- UI/MainWindow.scd
- UI/Drawing.scd
- Audio/AudioEngine.scd

### 📋 Planned
- UI/AmplitudeEditor.scd
- UI/Controls.scd
- Generators/BasicGenerators.scd
- Generators/XenakisGenerators.scd
- Generators/MathGenerators.scd
- Utils/FileIO.scd
- Utils/GridSystems.scd
- Utils/MathUtils.scd
- Audio/Effects.scd

## Benefits of Modular Architecture

1. **Maintainability** - Each module has a single responsibility
2. **Testability** - Individual modules can be tested in isolation
3. **Extensibility** - New features can be added as separate modules
4. **Reusability** - Modules can be reused in other projects
5. **Collaboration** - Multiple developers can work on different modules
6. **Documentation** - Each module is self-contained and well-documented

## Migration from Monolithic Version

The original 3000+ line `XenakisTrajectory.scd` file has been refactored into this modular system. Key improvements:

- **Separation of Concerns** - Audio, UI, data management are separate
- **Centralized Configuration** - All constants and settings in one place
- **Better Error Handling** - Each module can handle errors independently
- **Memory Management** - Better resource cleanup and management
- **Performance** - Optimized loading and initialization

## Development

To add new modules:

1. Create the module file in the appropriate directory
2. Follow the established naming convention
3. Add the module to the load list in `nUPIC_Main.scd`
4. Document the module's public API
5. Add appropriate error handling

## Version

Current version: 2.0.0
File format version: 2.0

## License

This project continues the open-source tradition of the original UPIC-inspired trajectory synthesis system.
