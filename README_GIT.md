# nUPIC - Nu-UPIC Trajectory Synthesis System

A modular trajectory-based synthesis system inspired by Iannis Xenakis' UPIC, implemented in SuperCollider.

## Overview

nUPIC (nu-UPIC) is a comprehensive system for creating and manipulating frequency trajectories that can be played back as audio synthesis with advanced spatialization capabilities.

## Features

- **Trajectory-Based Synthesis**: Draw frequency paths that generate sound
- **8-Channel Spatialization**: Spatial envelope editor for positioning mono sources in 8-channel space
- **Multiple Synthesis Methods**: Wavetable, FM, granular, additive synthesis
- **Modular Architecture**: Clean separation of UI, audio, and data components
- **Real-time Editing**: Draw, select, erase, and modify trajectories in real-time
- **Amplitude Control**: Per-trajectory amplitude envelope editing
- **Grid Systems**: Support for various tuning systems

## Requirements

- SuperCollider 3.13.0 or higher
- macOS, Windows, or Linux

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/nUPIC.git
   cd nUPIC
   ```

2. Open SuperCollider IDE

3. Run the startup script:
   ```supercollider
   "START_NUPIC.scd".load
   ```

## Usage

### Quick Start

Once loaded, the main GUI will open with:
- **Drawing area**: Click and drag to create frequency trajectories
- **Controls**: Bottom panel with playback and synthesis options
- **Synthdef menu**: Select different synthesis engines

### Basic Operations

- **Draw**: Click and drag in the main window
- **Play/Stop**: Press SPACE bar
- **Select**: Press 'G' to enter select mode, then click trajectories
- **Erase**: Press 'E' to enter erase mode
- **Grid**: Press 'T' to toggle frequency grid
- **Delete**: Select trajectory and press DELETE/BACKSPACE

### Spatialization

1. Draw a trajectory
2. Select it with 'G' mode
3. Choose an 8ch spatial synthdef (e.g., "UPIC Wavetable 8ch Spatial")
4. Open the Spatialization Editor to draw spatial movement paths

## Project Structure

```
nUPIC/
├── START_NUPIC.scd          # Main startup file (loads everything)
├── Core/                    # Core system components
│   ├── Constants.scd        # System constants and configuration
│   └── TrajectoryData.scd   # Data management
├── Audio/                   # Audio synthesis components
│   ├── SynthDefs.scd        # Main synthesis definitions
│   ├── SynthDefs_8ch_envelope.scd  # 8-channel spatial synthdefs
│   └── upicWavetable.scd    # Wavetable synthesis
├── UI/                      # User interface components
│   ├── MainWindow.scd       # Main GUI window
│   ├── Controls.scd         # UI controls
│   ├── Drawing.scd          # Drawing canvas
│   ├── AmplitudeEditor.scd  # Amplitude envelope editor
│   └── SpatializationEditor.scd  # Spatial envelope editor
└── Utils/                   # Utility functions
```

## Available Synthdefs

- **UPIC Wavetable (Mono)**: Clean mono wavetable synthesis
- **UPIC Wavetable Precise**: Precise amplitude control
- **UPIC Wavetable 8ch Spatial**: 8-channel spatialization
- **Simple Grav Object**: Gravity-inspired synthesis
- **Pulsar Train**: Advanced pulsar synthesis
- **FM Cascade**: FM synthesis chain
- **Grain Bank**: Granular synthesis

## Development

The system uses a modular architecture where each component has a single responsibility:

- **Core**: System constants and data management
- **Audio**: Synthesis engines and effects
- **UI**: User interface and interaction
- **Utils**: Helper functions and utilities

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project continues the open-source tradition of the original UPIC-inspired trajectory synthesis systems.

## Credits

- Inspired by Iannis Xenakis' UPIC system
- Built with SuperCollider
- Developed by [Your Name]

## Version History

- 2.0.0 - Current modular version with 8-channel spatialization
- 1.0.0 - Original monolithic version