# nUPIC Extension Proposals
## Based on "The Digital Instrument as an Artifact" by Marcin Pietruszewski

This document outlines implementation proposals for extending nUPIC in alignment with the original UPIC system, based on the ZKM publication "From Xenakis's UPIC to Graphic Notation Today."

**Source Document:** `Research/pdf_from_xenakiss_upic_to_graphic_notation_today_zkm.pdf` (extracted text: `.txt`)

**Last Updated:** December 2024

---

## Executive Summary

The Pietruszewski paper identifies the UPIC as an "epistemic tool" - a system that not only produces sound but embodies a particular theory of composition. Key concepts to integrate into nUPIC:

1. **Multitemporal Paradigm** - Seamless work across micro, meso, and macro timescales
2. **Transparent Stratification** - Pendular differentiation and reintegration of materials at all levels
3. **Outside-of-Time → In-Time** - Shapes exist abstractly until temporalized by duration assignment
4. **Artifact as Knowledge Carrier** - The instrument encapsulates and transmits compositional theory
5. **Embodied + Hermeneutic Interface** - Balancing gestural drawing with interpretive data display

---

## 1. Multitemporal/Multiscale Composition

### Source Reference
> "An incessant interpolation between temporal resolutions of the micro, meso, and macro scales constituted a vital feature of the vision behind the UPIC." (Page 2)

> "The system incorporated a particular view of sound composition which moved beyond the theory of Fourier and took as a starting point the pressure versus time curve together with a sound conceived as quantum; a 'phonon' imagined already by Einstein in 1910." (Page 2)

### Current nUPIC State
- Fixed play duration applies uniformly to all arcs
- Wavetables are 2048 samples at fixed resolution
- No mechanism to treat arc shapes as microstructure elements

### Proposal 1.1: Arc-to-Waveform Conversion
**Description:** Allow any drawn arc to be converted into a wavetable waveform, enabling macro-scale shapes to become micro-scale timbral characteristics.

**Implementation:**
```supercollider
~nUPIC[\arcs][\convertToWavetable] = { |arcIndex|
    // Resample arc frequency contour to 2048 samples
    // Normalize to -1 to 1 range
    // Load into wavetable buffer
};
```

**Files to modify:**
- `Core/ArcData.scd` - Add conversion function
- `UI/WavetableEditor.scd` - Add "from arc" button

### Proposal 1.2: Waveform-to-Arc Expansion
**Description:** Expand a wavetable's pressure-time curve into a drawable arc at meso/macro scale.

**Implementation:**
```supercollider
~nUPIC[\wavetablePresets][\expandToArc] = { |wavetableName, duration|
    // Map 2048 samples to arc points over specified duration
    // Create new arc from waveform shape
};
```

---

## 2. Temporal Duration Assignment

### Source Reference
> "These drawn shapes need to be assigned to previously specified timbres. However, up to this point each input to the system—the waveform, envelope, and frequency time shapes on a page—exist only as a simple drawing. To use a Xenakian notion, these shapes exist outside-of-time—they lack temporal boundaries. By defining a duration (or multiple divisions of it) for the page, the user decides how to temporalize these drawings." (Page 3)

### Current nUPIC State
- Single global `playDuration` setting
- All arcs share the same temporal mapping

### Proposal 2.1: Per-Arc Duration
**Description:** Allow each arc to have its own duration, independent of the global page duration.

**Implementation:**
```supercollider
// Data structure extension
data[\arcDurations] = List.new;  // Per-arc duration overrides

~nUPIC[\arcs][\setDuration] = { |arcIndex, duration|
    data[\arcDurations][arcIndex] = duration;
};

~nUPIC[\arcs][\getDuration] = { |arcIndex|
    data[\arcDurations][arcIndex] ?? defaults[\playDuration]
};
```

**Files to modify:**
- `Core/ArcData.scd` - Add duration storage
- `UI/MainWindow.scd` - Add per-arc duration control when arc selected
- `UI/MouseHandlers.scd` - Use per-arc duration in playback

### Proposal 2.2: Page/Section System
**Description:** Implement UPIC's "page" concept allowing multiple temporal sections with different durations.

**Implementation:**
- Add `~nUPIC[\pages]` namespace
- Each page contains a subset of arcs with its own duration
- Pages can be played sequentially or with variable reading order

---

## 3. Arc Transformation: Compress/Stretch in Time and Frequency

### Source Reference
> "An essential aspect of UPIC's setup are the editing capabilities that each of the arcs could be subjected to: the user can cut, copy, and paste individual shapes, and compress or stretch them in time and frequency." (Page 3)

> "An example of all these procedures can be found in Xenakis's UPIC composition (1978), which consists of arborescent shapes, cut and pasted, compressed and stretched in time and frequency." (Page 3)

### Current nUPIC State
- Basic arc transformations exist (`modulateFreq`, `resample`)
- No explicit time/frequency compression/stretch functions
- No visual interface for these operations

### Proposal 3.1: Time Compression/Expansion
**Description:** Add functions to compress or expand an arc's temporal extent while maintaining frequency relationships.

**Implementation:**
```supercollider
~nUPIC[\arcs][\compressTime] = { |arcIndex, factor|
    // factor < 1 = compress, factor > 1 = expand
    var points = ~nUPIC[\arcs][\getPoints].value(arcIndex);
    var centerX = points.collect(_.x).mean;
    var newPoints = points.collect { |pt|
        (x: centerX + ((pt.x - centerX) * factor), y: pt.y, freq: pt.freq)
    };
    ~nUPIC[\arcs][\setPoints].value(arcIndex, newPoints);
};

~nUPIC[\arcs][\expandTime] = { |arcIndex, factor|
    ~nUPIC[\arcs][\compressTime].value(arcIndex, factor);
};
```

### Proposal 3.2: Frequency Compression/Expansion
**Description:** Scale frequency content of an arc by a factor (transposition with glide preservation).

**Implementation:**
```supercollider
~nUPIC[\arcs][\scaleFrequency] = { |arcIndex, factor|
    var points = ~nUPIC[\arcs][\getPoints].value(arcIndex);
    var newPoints = points.collect { |pt|
        var newFreq = (pt.freq * factor).clip(20, 7500);
        var newY = newFreq.explin(20, 7500, viewHeight, 0);
        (x: pt.x, y: newY, freq: newFreq)
    };
    ~nUPIC[\arcs][\setPoints].value(arcIndex, newPoints);
};
```

### Proposal 3.3: Interactive Transform Mode
**Description:** UI mode where dragging selected arcs scales them in time (horizontal) or frequency (vertical).

**Files to modify:**
- `UI/Controls.scd` - Add Transform mode toggle (T key)
- `UI/MouseHandlers.scd` - Implement drag-to-scale behavior

---

## 4. Variable Reading Position and Direction

### Source Reference
> "The reading position and direction on a page and between pages can be variable, too." (Page 3)

### Current nUPIC State
- Playback always proceeds left-to-right
- Fixed start position (leftmost point of each arc)

### Proposal 4.1: Playback Direction Control
**Description:** Allow arcs to be played in reverse or with variable direction.

**Implementation:**
```supercollider
~nUPIC[\arcs][\setPlayDirection] = { |arcIndex, direction|
    // direction: \forward, \reverse, \palindrome
    data[\arcPlayDirections][arcIndex] = direction;
};
```

### Proposal 4.2: Playhead Position Control
**Description:** Allow setting arbitrary start position for playback.

**Implementation:**
```supercollider
~nUPIC[\ui][\setPlayheadPosition] = { |normalizedX|
    // 0.0 = start, 1.0 = end
    state[\playheadStart] = normalizedX;
};
```

**UI Enhancement:** Clickable timeline ruler above canvas to set playhead position.

---

## 5. Microstructure as Form / Form as Microstructure

### Source Reference
> "As observed by Curtis Roads, arcs written to a page with a duration of a second become a characteristic of the sound's microstructure. An opposite manipulation is possible as well; the microstructural pressure versus time curve can be stretched in time and used as a structuring element at meso or macro time levels." (Page 3)

> "Such a bimodal process problematizes the duality between form and material: the same object can be conceived as material or form (substance or container) depending on the level of investigation." (Page 4)

### Current nUPIC State
- Wavetables and arcs are separate, non-interchangeable domains
- No mechanism for "zooming" between temporal scales

### Proposal 5.1: Temporal Zoom / Scale Bridging
**Description:** Implement a "zoom" function that reinterprets the current view at a different temporal scale.

**Implementation Concept:**
```supercollider
~nUPIC[\temporal][\zoomToMicro] = {
    // Convert current arc arrangement to waveform
    // Duration becomes single cycle period
};

~nUPIC[\temporal][\zoomToMacro] = {
    // Expand current wavetable to arc
    // Single cycle becomes full composition duration
};
```

### Proposal 5.2: Fractal/Recursive Arc Structure
**Description:** Allow arcs to contain nested sub-arcs that are revealed at finer temporal resolutions.

---

## 6. Timbre Assignment System

### Source Reference
> "These drawn shapes need to be assigned to previously specified timbres." (Page 3)

> "At the level of sound microstructure, the user specifies the waveform and a shape of the dynamic envelope, which together can be thought of as an elemental timbre of the instrument." (Page 3)

### Current nUPIC State
- Per-arc SynthDef assignment exists
- Per-arc wavetable assignment exists
- Per-arc amplitude envelope exists
- No unified "timbre preset" concept

### Proposal 6.1: Timbre Presets
**Description:** Create a timbre preset system that bundles wavetable + envelope + synthdef as a single assignable entity.

**Implementation:**
```supercollider
~nUPIC[\timbres] = IdentityDictionary.new;

~nUPIC[\timbres][\create] = { |name, wavetable, envelope, synthDef|
    ~nUPIC[\timbres][name] = (
        wavetable: wavetable,
        envelope: envelope,
        synthDef: synthDef
    );
};

~nUPIC[\arcs][\assignTimbre] = { |arcIndex, timbreName|
    var timbre = ~nUPIC[\timbres][timbreName];
    ~nUPIC[\arcs][\setWavetable].value(arcIndex, timbre.wavetable);
    ~nUPIC[\arcs][\setAmplitudeEnvelope].value(arcIndex, timbre.envelope);
    ~nUPIC[\arcs][\setSynthDef].value(arcIndex, timbre.synthDef);
};
```

**Files to modify:**
- New file: `Core/TimbresManager.scd`
- `UI/MainWindow.scd` - Timbre palette/browser

---

## 7. Crossfading Between States/Settings

### Source Reference (from Pulsar Generator description)
> "The program implemented a scheme for saving and loading these envelopes in groups called settings. The program lets one crossfade at a variable rate between multiple settings, which takes performance with Pulsar Generator to another level of synthesis complexity." (Page 5, Figure 2 caption)

### Current nUPIC State
- Save/load functionality for compositions
- No interpolation between states

### Proposal 7.1: State Morphing
**Description:** Allow saving multiple "states" and crossfading between them during playback.

**Implementation:**
```supercollider
~nUPIC[\states] = List.new;

~nUPIC[\states][\capture] = {
    // Snapshot current arc positions, envelopes, wavetables
};

~nUPIC[\states][\morphTo] = { |stateIndex, duration|
    // Interpolate all parameters over duration
};
```

---

## 8. GENDYN Integration Enhancement

### Source Reference
> The paper discusses Xenakis's stochastic approaches and the relationship between UPIC and his broader compositional philosophy.

### Current nUPIC State
- Basic GENDYN-style transformations exist in API (`gendyn`, `brownian`, `stochasticModulation`)
- Limited to frequency modulation

### Proposal 8.1: Full GENDYN on All Parameters
**Description:** Extend stochastic transformations to amplitude envelopes, spatial envelopes, and wavetables.

**Implementation:**
```supercollider
~nUPIC[\gendyn][\modulateEnvelope] = { |arcIndex, params|
    // Apply stochastic walk to amplitude envelope points
};

~nUPIC[\gendyn][\modulateSpatial] = { |arcIndex, params|
    // Apply stochastic walk to spatial envelope
};

~nUPIC[\gendyn][\modulateWavetable] = { |arcIndex, params|
    // Apply stochastic walk to wavetable samples
};
```

---

## Implementation Priority

### High Priority (Core UPIC Alignment)
1. **Proposal 3.1 & 3.2** - Time/Frequency compression/stretch
2. **Proposal 2.1** - Per-arc duration
3. **Proposal 1.1** - Arc-to-wavetable conversion

### Medium Priority (Enhanced Workflow)
4. **Proposal 6.1** - Timbre presets
5. **Proposal 4.1 & 4.2** - Variable playback direction/position
6. **Proposal 3.3** - Interactive transform mode

### Lower Priority (Advanced Features)
7. **Proposal 7.1** - State morphing
8. **Proposal 2.2** - Page/section system
9. **Proposal 5.1 & 5.2** - Temporal zoom / fractal structures
10. **Proposal 8.1** - Full GENDYN extension

---

## 9. Pulsar Synthesis Integration

### Source Reference
> "The technique generates a complex hybrid of sounds across the perceptual time span between infrasonic pulsations and audio frequencies, giving rise to a broad family of musical structures: singular impulses, sequences, continuous tones, time-varying phrases, and beating textures." (Page 3)

> "Through its inherently multiscale character, pulsar synthesis proposes a unique view on rhythm moving beyond a linear series of points and intervals tied to a time grid, and introduces a notion of rhythm as a continuously flowing temporal substrate." (Page 3)

### Current nUPIC State
- Wavetable synthesis using standard oscillator approach
- No grain/pulsar-based synthesis mode

### Proposal 9.1: Pulsar Synthesis Mode
**Description:** Add a pulsar synthesis engine as an alternative to continuous wavetable synthesis, enabling exploration of the micro-to-macro rhythm continuum.

**Implementation:**
```supercollider
// New SynthDef for pulsar synthesis
SynthDef(\upicPulsar, { |out=0, freq=440, pulsarRate=100, duty=0.5, amp=0.1|
    var pulsaret = Osc.ar(\pulsaretBuf.kr, freq);
    var envelope = Osc.ar(\envBuf.kr, pulsarRate);
    var train = pulsaret * envelope;
    Out.ar(out, train * amp);
});

~nUPIC[\pulsar][\setPulsarRate] = { |arcIndex, rate|
    // rate in Hz: infrasonic (0.25-20) to audio (20-642)
    data[\arcPulsarRates][arcIndex] = rate;
};
```

**Files to create:**
- `Audio/PulsarSynthDefs.scd` - Pulsar synthesis engine
- `UI/PulsarEditor.scd` - Pulsaret waveform editor

### Proposal 9.2: Arc-to-Pulsar-Train Mapping
**Description:** Map arc shapes to pulsar train parameters, where Y-axis controls pitch and X-axis evolution controls pulsar rate.

---

## 10. Embodied + Hermeneutic Interface Design

### Source Reference
> "Don Ihde conceptualized a variety of phenomenological modalities of instruments... embodied relations, where the instrument acts as an extension of the body and amplification of the senses; and hermeneutic relations, where the instrument provides us with data which we have to interpret." (Page 9)

> "The drawing board featured in the early version of the UPIC system... had a calibrated area of 60 cm high by 75 cm wide." (Page 10, footnote 38)

### Current nUPIC State
- Mouse-based drawing interface
- Limited haptic/embodied feedback
- Basic visual feedback during playback

### Proposal 10.1: Enhanced Gestural Input
**Description:** Support for drawing tablets and touch input to restore the embodied, gestural quality of the original UPIC drawing board.

**Implementation:**
```supercollider
~nUPIC[\input][\enablePressureSensitivity] = {
    // Map pen pressure to line thickness or amplitude
};

~nUPIC[\input][\enableTilt] = {
    // Map pen tilt to frequency range or timbre parameter
};
```

### Proposal 10.2: Hermeneutic Display Overlays
**Description:** Add interpretive overlays showing spectral analysis, waveform previews, and temporal markers during drawing.

**Implementation:**
- Real-time spectrogram overlay option
- Waveform preview when hovering over arc
- Temporal grid with musical subdivisions

**Files to modify:**
- `UI/Drawing.scd` - Add overlay rendering
- `UI/Controls.scd` - Toggle for overlay modes

---

## 11. Dual Graphical/Textual Interface

### Source Reference
> "A coupling between graphic and textual interfaces allows for powerful control of visual and formalized compositional models." (Page 6)

> "The underlying Just-In-Time programming paradigm used in the development of the program means that all objects can be redefined in real time." (Page 6)

### Current nUPIC State
- Primarily graphical interface
- Limited programmatic API access
- No live coding integration

### Proposal 11.1: Live Coding Console
**Description:** Embed a SuperCollider code console within nUPIC for real-time programmatic manipulation of arcs and parameters.

**Implementation:**
```supercollider
~nUPIC[\console][\open] = {
    // Open embedded SC code editor
    // All ~nUPIC functions accessible
    // Changes reflect immediately in GUI
};
```

### Proposal 11.2: Script Recording
**Description:** Record GUI actions as executable SuperCollider code for reproducibility and batch processing.

**Implementation:**
```supercollider
~nUPIC[\scripting][\startRecording] = {
    // Begin capturing all UI actions as code
};

~nUPIC[\scripting][\stopRecording] = {
    // Return recorded code as string
};

// Example output:
// ~nUPIC[\arcs][\create].value((x: 100, y: 200, freq: 440));
// ~nUPIC[\arcs][\setAmplitude].value(0, 0.8);
```

---

## 12. Transparent Stratification System

### Source Reference
> "The UPIC might be described as a system of 'transparent stratification' rendering entirely open for a pendular process of differentiation and reintegration of sound materials and forms at all the levels of temporal organization." (Page 4)

### Current nUPIC State
- Single-layer arc canvas
- No hierarchical organization of materials

### Proposal 12.1: Layered Composition View
**Description:** Implement a layer system where each temporal scale (micro/meso/macro) has its own canvas, with visibility into adjacent scales.

**Implementation:**
```supercollider
~nUPIC[\layers] = IdentityDictionary.new;
~nUPIC[\layers][\scales] = [\micro, \meso, \macro];

~nUPIC[\layers][\setActive] = { |scale|
    // Switch editing context to specified scale
    // Other scales visible but dimmed
};

~nUPIC[\layers][\linkAcrossScales] = { |microArc, mesoArc, macroArc|
    // Create bidirectional links between representations
    // Changes at one scale propagate to others
};
```

### Proposal 12.2: Scale Navigator
**Description:** Visual timeline showing the current zoom level relative to micro/meso/macro scales, with click-to-zoom navigation.

---

## Development Roadmap

### Phase 1: Core UPIC Alignment (Foundation)
**Goal:** Achieve feature parity with essential UPIC capabilities

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 1 | 3.1 Time Compression/Expansion | Medium | None |
| 2 | 3.2 Frequency Compression/Expansion | Medium | None |
| 3 | 2.1 Per-Arc Duration | Medium | None |
| 4 | 1.1 Arc-to-Wavetable Conversion | High | Wavetable system |
| 5 | 4.1 Playback Direction Control | Low | Playback system |

### Phase 2: Enhanced Workflow
**Goal:** Streamline compositional workflow

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 6 | 6.1 Timbre Presets | Medium | None |
| 7 | 3.3 Interactive Transform Mode | High | 3.1, 3.2 |
| 8 | 4.2 Playhead Position Control | Low | 4.1 |
| 9 | 10.2 Hermeneutic Display Overlays | Medium | None |

### Phase 3: Advanced Temporal Features
**Goal:** Enable full multiscale composition

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 10 | 2.2 Page/Section System | High | 2.1 |
| 11 | 5.1 Temporal Zoom/Scale Bridging | High | 1.1, 1.2 |
| 12 | 12.1 Layered Composition View | High | 2.2 |
| 13 | 12.2 Scale Navigator | Medium | 12.1 |

### Phase 4: Synthesis Extensions
**Goal:** Expand synthesis capabilities

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 14 | 9.1 Pulsar Synthesis Mode | High | Audio system |
| 15 | 9.2 Arc-to-Pulsar-Train Mapping | Medium | 9.1 |
| 16 | 8.1 Full GENDYN Extension | Medium | Existing GENDYN |

### Phase 5: Interface & Scripting
**Goal:** Professional workflow integration

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 17 | 11.1 Live Coding Console | High | None |
| 18 | 11.2 Script Recording | Medium | 11.1 |
| 19 | 10.1 Enhanced Gestural Input | Medium | Platform support |
| 20 | 7.1 State Morphing | High | 6.1 |

### Phase 6: Experimental Features
**Goal:** Push beyond historical UPIC

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 21 | 5.2 Fractal/Recursive Arc Structure | Very High | 12.1 |

---

## Implementation Notes

### Key Files for Modification
```
Core/
├── ArcData.scd          # Arc storage, per-arc properties
├── Constants.scd        # System configuration
├── Model/ArcModel.scd   # Arc data structures

Audio/
├── upicWavetable.scd    # Main synthesis
├── SynthDefs.scd        # Additional synths
└── [NEW] PulsarSynthDefs.scd

UI/
├── MainWindow.scd       # Main interface layout
├── Controls.scd         # Keyboard/button handlers
├── MouseHandlers.scd    # Drawing interaction
├── WavetableEditor.scd  # Waveform editing
└── [NEW] PulsarEditor.scd
└── [NEW] ScaleNavigator.scd
```

### Testing Strategy
Each proposal should include:
1. Unit tests for new functions (in `tests/`)
2. Visual verification script
3. Audio output validation

---

## References

All quotations from:
- Pietruszewski, Marcin. "The Digital Instrument as an Artifact." In *From Xenakis's UPIC to Graphic Notation Today*, edited by Peter Weibel, Ludger Brummer, and Sharon Kanach. ZKM | Center for Art and Media Karlsruhe / Hatje Cantz, 2020. Pages 613-625.

Additional references cited in the source:
- Roads, Curtis. *Microsound*. Cambridge, MA: MIT Press, 2004.
- Xenakis, Iannis. *Formalized Music*. Hillsdale, NY: Pendragon Press, 1992.
- Marino, Gerard, Marie-Helene Serra, and Jean-Michel Raczinski. "The UPIC System: Origins and Innovations." *Perspectives of New Music* 31 (1993): 258-270.
- Ihde, Don. *Technology and the Lifeworld: From Garden to Earth*. Indiana University Press, 1990.
- Roads, Curtis, and Alberto de Campo. "Pulsar Generator" (2000).
- Rohrhuber, Julian, et al. "Algorithms Today: Notes on Language Design for Just In Time Programming." ICMC 2005.
