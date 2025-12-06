# Claude Code Context for nUPIC

## Project Overview

nUPIC is a SuperCollider-based arc synthesis system inspired by Xenakis' UPIC. It provides a graphical interface for drawing frequency arcs that are played back as audio synthesis with multi-channel spatial support.

## Key Technologies

- **SuperCollider** - Audio synthesis platform and programming language
- **sclang** - SuperCollider's interpreted language (`.scd` files)
- **SynthDefs** - SuperCollider synthesis definitions

## Project Structure

```
nUPIC/
├── START_NUPIC.scd           # Main entry point - loads the application
├── Core/                      # Core logic and data management
│   ├── Constants.scd         # Configuration constants
│   ├── ArcData.scd           # Arc data management, undo/redo
│   ├── Model/                # Data models
│   ├── Connections/          # Audio routing
│   └── Utils/                # Helper functions
├── Audio/                     # Synthesis definitions
│   ├── upicWavetable.scd     # Main wavetable SynthDefs
│   └── SynthDefs_8ch.scd     # Multi-channel variants
├── UI/                        # User interface components
│   ├── MainWindow.scd        # Main application window
│   ├── Controls.scd          # UI controls and keyboard handling
│   ├── MouseHandlers.scd     # Drawing and mouse interaction
│   ├── AmplitudeEditor.scd   # Amplitude envelope editor
│   ├── SpatializationEditor.scd  # Spatial panning editor
│   └── WavetableEditor.scd   # Wavetable design editor
├── SynthDefs/                 # Additional synthesis definitions
├── Research/                  # Research documents and proposals
├── Docs/                      # Documentation
└── tests/                     # Test files
```

## Common Commands

```bash
# Launch SuperCollider with nUPIC
./launch_nupic.sh

# Or run SuperCollider manually
./run_sc.sh
```

In SuperCollider:
```supercollider
// Load nUPIC
"/path/to/nUPIC/START_NUPIC.scd".load;
```

## Code Conventions

### SuperCollider Syntax
- Files use `.scd` extension
- Global variables use tilde prefix: `~variableName`
- System namespace: `~nUPIC[\category][\key]`
- SynthDef names use camelCase: `upicWavetable8ch`

### UI Style
- B&K green color scheme: `Color.new(205/255, 250/255, 205/255)`
- Button labels use underscore prefix: `_lowercase`
- Standard button size: 60x25 pixels

### Channel Configurations
Supported output channels: 2, 3, 4, 8, 12, 15, 24

## Important Files

| File | Purpose |
|------|---------|
| `START_NUPIC.scd` | Main entry point |
| `START_NUPIC_ADVANCED.scd` | Advanced configuration startup |
| `Core/Constants.scd` | System constants and defaults |
| `Audio/upicWavetable.scd` | Main synthesis definitions |
| `UI/Controls.scd` | Keyboard shortcuts and UI controls |

## Testing

Test files are in the `tests/` directory. Individual test scripts:
- `simple_test.scd` - Basic functionality test
- `audio_test.scd` - Audio output test

## Configuration Access

```supercollider
// Read constants
~nUPIC[\constants][\maxArcs]      // 200
~nUPIC[\constants][\freqMin]      // 20 Hz
~nUPIC[\constants][\freqMax]      // 7500 Hz

// Read/write defaults
~nUPIC[\defaults][\playDuration]  // 10 seconds
~nUPIC[\defaults][\defaultSynthDef]

// Set values with UI update
~nUPIC[\defaults][\setValue].value(\playDuration, 30)
```

## Notes for Development

1. SuperCollider code uses curly braces for functions: `{ |args| code }`
2. Method calls can use dot notation or message passing
3. Arrays use square brackets: `[1, 2, 3]`
4. Symbols use backslash prefix: `\symbolName`
5. Comments: `//` for single line, `/* */` for multi-line
