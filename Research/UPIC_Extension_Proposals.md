# nUPIC Extension Proposals
## Based on the ZKM Publication "From Xenakis's UPIC to Graphic Notation Today"

This document outlines implementation proposals for extending nUPIC in alignment with the original UPIC system, drawing from the comprehensive ZKM publication featuring contributions from 30+ scholars and practitioners.

**Source Document:** `Research/pdf_from_xenakiss_upic_to_graphic_notation_today_zkm.pdf` (extracted text: `.txt`)

**Last Updated:** December 2024

---

## Executive Summary

The ZKM publication represents the definitive scholarly resource on UPIC, containing:
- Historical accounts from original UPIC developers (Médigue, 1977)
- Pedagogical applications (Després, Frisius, Estrada)
- Analytical studies of Xenakis's UPIC works (Squibbs, Couprie)
- Modern implementations (IanniX, UPISketch, Smallfish)
- Theoretical frameworks (Pietruszewski, Weibel, Lohner)

### Key Concepts to Integrate into nUPIC:

1. **Multitemporal Paradigm** - Seamless work across micro, meso, and macro timescales
2. **Transparent Stratification** - Pendular differentiation and reintegration of materials at all levels
3. **Outside-of-Time → In-Time** - Shapes exist abstractly until temporalized by duration assignment
4. **Rhythm-Sound Continuum** - Continuous spectrum from infrasonic pulsation to audio frequency (Estrada)
5. **Continuum-Discontinuum Fusion** - Scale theory bridging discrete steps and continuous glides
6. **Canvas-Player-Instrument Architecture** - Modular decomposition for modern reimplementation
7. **Score-Instrument Fusion** - The GUI simultaneously functions as notation and instrument
8. **Morphological Composition** - Using visual shape types (arborescences, clusters) as structural units
9. **Embodied + Hermeneutic Interface** - Balancing gestural drawing with interpretive data display
10. **Educational Accessibility** - "Tabula rasa" philosophy enabling anyone to compose

---

## Historical UPIC Specifications (Médigue, 1977)

The original UPIC A had these constraints that inform our design:

| Parameter | Original UPIC A | nUPIC Current | nUPIC Target |
|-----------|-----------------|---------------|--------------|
| Waveforms per project | 32 | Unlimited | Unlimited |
| Envelopes per project | 55 | Per-arc | Unified bank |
| Arcs per page | 2000 | Unlimited | Unlimited |
| Pages per project | 24 | 1 | Multiple |
| Sampling rates | 25,000 / 38,460 / 52,000 | 44,100 | Configurable |
| Pitch grain | Half-comma | Continuous | Configurable |
| Amplitude grain | Configurable | Continuous | Configurable |

---

## 1. Multitemporal/Multiscale Composition

### Source Reference
> "An incessant interpolation between temporal resolutions of the micro, meso, and macro scales constituted a vital feature of the vision behind the UPIC." (Page 2)

> "The system incorporated a particular view of sound composition which moved beyond the theory of Fourier and took as a starting point the pressure versus time curve together with a sound conceived as quantum; a 'phonon' imagined already by Einstein in 1910." (Page 2)

### Current nUPIC State
- Fixed play duration applies uniformly to all arcs
- Wavetables are 2048 samples at fixed resolution
- No mechanism to treat arc shapes as microstructure elements

### Proposal 1.1: Arc-to-Waveform Conversion ✓ IMPLEMENTED
**Description:** Allow any drawn arc to be converted into a wavetable waveform, enabling macro-scale shapes to become micro-scale timbral characteristics.

**Implementation:** (in `Core/ArcData.scd` and `Core/Constants.scd`)
```supercollider
~nUPIC[\arcs][\convertToWavetable].value(arcIndex);  // Returns wavetable array
~nUPIC[\arcs][\applyShapeAsWavetable].value(arcIndex);  // Apply to same arc
```

**UI:** "arc→" button in WavetableEditor converts current arc's shape to its wavetable

### Proposal 1.2: Waveform-to-Arc Expansion ✓ IMPLEMENTED
**Description:** Expand a wavetable's pressure-time curve into a drawable arc at meso/macro scale.

**Implementation:** (in `Core/ArcData.scd` and `Core/Constants.scd`)
```supercollider
~nUPIC[\arcs][\createFromWavetable].value(wavetableData, startX, width);
```

**UI:** "→arc" button in WavetableEditor creates new arc from current wavetable shape

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
- **IMPLEMENTED** - Time and frequency compression/expansion now available
- Keyboard shortcuts: `[` / `]` for time, `{` / `}` for frequency
- Functions work on all selected arcs simultaneously

### Proposal 3.1: Time Compression/Expansion ✓ IMPLEMENTED
**Description:** Compress or expand an arc's temporal extent while maintaining frequency relationships.

**Implementation:** (in `UI/MouseHandlers.scd`)
```supercollider
~nUPIC[\ui][\compressTimeSelected] = { |factor|
    // factor < 1 = compress (shorter), factor > 1 = expand (longer)
    // Scales around arc center, also transforms amplitude envelopes
};
```

**Keyboard Shortcuts:**
- `[` - Compress time by 10%
- `]` - Expand time by 10%

### Proposal 3.2: Frequency Compression/Expansion ✓ IMPLEMENTED
**Description:** Scale frequency content using log-space transformation around geometric mean (preserves glissando character).

**Implementation:** (in `UI/MouseHandlers.scd`)
```supercollider
~nUPIC[\ui][\compressFrequencySelected] = { |factor|
    // factor < 1 = compress (narrower range), factor > 1 = expand (wider)
    // Uses log-space scaling to preserve musical intervals
};
```

**Keyboard Shortcuts:**
- `{` (Shift+[) - Compress frequency range by 10%
- `}` (Shift+]) - Expand frequency range by 10%

### Proposal 3.3: Interactive Transform Mode
**Status:** Pending
**Description:** UI mode where dragging selected arcs scales them in time (horizontal) or frequency (vertical).

**Files to modify:**
- `UI/Controls.scd` - Add Transform mode toggle
- `UI/MouseHandlers.scd` - Implement drag-to-scale behavior

---

## 4. Variable Reading Position and Direction

### Source Reference
> "The reading position and direction on a page and between pages can be variable, too." (Page 3)

### Current nUPIC State
- **IMPLEMENTED** - Playback direction control and interactive scrubbing now available
- Direction options: Forward (FWD), Reverse (REV), Palindrome (PAL), Loop (LOOP), Drag/Scrub (DRAG)

### Proposal 4.1: Playback Direction Control ✓ IMPLEMENTED
**Description:** Allow arcs to be played in reverse or with variable direction.

**Implementation:** (in `UI/MainWindow.scd` and `UI/Controls.scd`)
- State variables: `state[\playbackDirection]`, `state[\palindromePhase]`
- UI: Playback mode menu (FWD/REV/PAL/LOOP/DRAG) next to play button
- Modes:
  - FWD: Forward playback (0 → duration, plays once)
  - REV: Reverse playback (duration → 0, plays once)
  - PAL: Palindrome (forward then reverse, loops continuously)
  - LOOP: Forward loop (continuous playback)
  - DRAG: Interactive scrubbing (click and drag on canvas to hear sound at mouse position)

### Proposal 4.2: Playhead Position Control ✓ IMPLEMENTED (via DRAG mode)
**Description:** Allow setting arbitrary start position for playback.

**Implementation:** (in `UI/MouseHandlers.scd`)
- DRAG mode enables interactive scrubbing
- Click and drag anywhere on canvas to hear sound at that time position
- Functions: `startScrub`, `updateScrub`, `stopScrub`
- Real-time frequency interpolation and amplitude envelope support

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

## 13. Rhythm-Sound Continuum (Estrada)

### Source Reference
> "The notion of continuum naturally leads to the observation of the physical unit rhythm-sound, where rhythmic frequencies are fundamental to sound frequencies." (Estrada, Page 316)

> "I proposed to Xenakis to expand the range of the UPIC to rhythm as part of the musical frequency continuum." (Estrada, Page 317)

### Current nUPIC State
- Fixed frequency range (20Hz - 7500Hz)
- No rhythmic/sub-audio frequency support
- Rhythm and pitch treated as separate domains

### Proposal 13.1: Extended Frequency Range
**Description:** Extend the Y-axis to include sub-audio frequencies (0.25Hz - 20Hz) allowing arcs to define rhythmic patterns that can seamlessly transition into pitched sounds.

**Implementation:**
```supercollider
~nUPIC[\constants][\freqRange] = [0.25, 7500];  // Extended range

~nUPIC[\ui][\setFrequencyMode] = { |mode|
    // \pitch (20-7500Hz), \rhythm (0.25-20Hz), \continuum (0.25-7500Hz)
    state[\frequencyMode] = mode;
};
```

### Proposal 13.2: Rhythm-to-Pitch Morphing
**Description:** Allow arcs to smoothly transition between rhythmic (sub-20Hz) and pitched (20Hz+) domains during playback.

---

## 14. Morphological Shape Library (Squibbs Analysis)

### Source Reference
> "The morphology of the sections in Part I forms the simple and well-defined pattern: A B C A' B' C'." (Squibbs, Page 423)

Squibbs identifies these morphological types in Mycènes Alpha:
- **Type A**: Narrow bands of tightly clustered arcs
- **Type B**: Arborescences (branching structures)
- **Type C**: Low-register horizontal clusters
- **Type D**: Clustered horizontal arcs with silences
- **Type E/F**: Fantastic, curved "creature-like" forms

### Current nUPIC State
- Freehand drawing only
- No shape templates or presets
- No morphological analysis tools

### Proposal 14.1: Morphological Shape Templates
**Description:** Provide generative templates for common UPIC morphological types.

**Implementation:**
```supercollider
~nUPIC[\morphology][\arborescence] = { |rootFreq, branchCount, spread|
    // Generate branching structure from root point
};

~nUPIC[\morphology][\cluster] = { |centerFreq, density, bandwidth|
    // Generate horizontal cluster of arcs
};

~nUPIC[\morphology][\glissandoFan] = { |startFreq, endFreqs, duration|
    // Generate diverging/converging glissandi
};
```

### Proposal 14.2: Shape Recognition and Labeling
**Description:** Automatically analyze drawn arcs and suggest morphological classifications.

---

## 15. Page and Section System (Original UPIC)

### Source Reference
> "The temporal structure of Mycènes Alpha is based on a primary unit of one minute, which was the limit of duration for a page of music composed with the original version of the UPIC." (Squibbs, Page 423)

> "The user can open a new page or an old one they wish to complete." (Médigue, Page 136)

### Current nUPIC State
- Single canvas with global duration
- No section/page organization
- No structural hierarchy

### Proposal 15.1: Multi-Page Composition
**Description:** Implement the original UPIC's page system with up to 24 pages per project.

**Implementation:**
```supercollider
~nUPIC[\pages] = IdentityDictionary.new;
~nUPIC[\pages][\count] = 0;
~nUPIC[\pages][\current] = 0;

~nUPIC[\pages][\create] = { |duration|
    var pageIndex = ~nUPIC[\pages][\count];
    ~nUPIC[\pages][pageIndex] = (
        arcs: List.new,
        duration: duration ?? 60,  // Default 1 minute
        label: "Page " ++ (pageIndex + 1)
    );
    ~nUPIC[\pages][\count] = pageIndex + 1;
    pageIndex
};

~nUPIC[\pages][\setSequence] = { |pageIndices|
    // Define playback order of pages
    state[\pageSequence] = pageIndices;
};
```

### Proposal 15.2: Golden Section Structure Tools
**Description:** Provide tools for structuring compositions using proportional systems (Golden Section, Fibonacci).

> "There is a global division of the work according to the golden section, whose decimal approximation to three places is 0.618." (Squibbs, Page 429)

**Implementation:**
```supercollider
~nUPIC[\structure][\goldenSection] = { |totalDuration|
    [totalDuration * 0.382, totalDuration * 0.618]
};

~nUPIC[\structure][\fibonacciDivisions] = { |totalDuration, depth|
    // Generate nested Fibonacci proportions
};
```

---

## 16. Real-Time Performance Mode (Taurhiphanie)

### Source Reference
> "The work included fixed and improvised parts from sixty fragments manipulated in real time by playback with variation of sequences and by effects such as freezing or reverse." (Couprie, Page 440)

### Current nUPIC State
- Playback-only mode
- No real-time manipulation during playback
- No freeze/reverse effects

### Proposal 16.1: Live Performance Controls
**Description:** Add real-time manipulation controls for live performance contexts.

**Implementation:**
```supercollider
~nUPIC[\live][\freeze] = {
    // Freeze current playback position, loop current sample
    state[\frozen] = true;
};

~nUPIC[\live][\reverse] = {
    // Reverse playback direction
    state[\playDirection] = state[\playDirection].neg;
};

~nUPIC[\live][\scrub] = { |position|
    // Jump to arbitrary position
    state[\playheadPosition] = position;
};

~nUPIC[\live][\speedControl] = { |factor|
    // Real-time tempo scaling (0.25x to 4x)
    state[\playbackSpeed] = factor.clip(0.25, 4);
};
```

### Proposal 16.2: Fragment Triggering System
**Description:** Allow pre-composed sections to be triggered in variable order during performance.

---

## 17. IanniX-Style Vector Graphics Mode

### Source Reference
> "In contrast to painting, we focus more on abstract and mathematical properties of objects in the image when we draw geometrical shapes, diagrams, or blueprints and we use different tools such as compasses." (Miyama, Page 544)

> "The original UPIC system can be interpreted as a combination of three main elements; namely, Canvas, Player, and Instrument." (Miyama, Page 543)

### Current nUPIC State
- Point-based arc representation
- No Bézier curve support
- No mathematical curve definitions

### Proposal 17.1: Vector Arc Mode
**Description:** Add support for mathematically-defined curves (Bézier, splines) alongside freehand arcs.

**Implementation:**
```supercollider
~nUPIC[\arcs][\createBezier] = { |controlPoints|
    // Create arc from Bézier control points
    // Allows precise curve editing
};

~nUPIC[\arcs][\createSpiral] = { |centerFreq, startRadius, endRadius, rotations|
    // Generate logarithmic spiral arc
};

~nUPIC[\arcs][\createSinusoid] = { |baseFreq, amplitude, frequency, phase|
    // Generate sinusoidal frequency modulation
};
```

### Proposal 17.2: OSC/MIDI Output for External Control
**Description:** Add IanniX-style OSC output for controlling external synthesizers and software.

**Implementation:**
```supercollider
~nUPIC[\osc][\enableOutput] = { |host, port|
    state[\oscTarget] = NetAddr(host, port);
};

~nUPIC[\osc][\mapArcToAddress] = { |arcIndex, oscAddress|
    // During playback, send arc freq/amp to OSC address
};
```

---

## 18. UPISketch-Style Mobile/Touch Interface

### Source Reference
> "UPISketch's raison d'être is its UPICian heritage, but its creation was also motivated from the outset by possible new developments." (Bourotte, Page 366)

> "One of our goals in this direction is incorporating Dynamic Stochastic Synthesis in this tool." (Bourotte, Page 363)

### Current nUPIC State
- Desktop-only SuperCollider application
- Mouse input only
- No touch optimization

### Proposal 18.1: Touch-Optimized Interface Mode
**Description:** Add touch-friendly UI mode with larger hit targets and gesture support.

**Implementation:**
```supercollider
~nUPIC[\touch][\enable] = {
    state[\touchMode] = true;
    // Increase control sizes
    // Enable pinch-to-zoom
    // Enable two-finger pan
};

~nUPIC[\touch][\gestures] = (
    pinch: { |scale| /* Zoom canvas */ },
    twoFingerPan: { |dx, dy| /* Scroll canvas */ },
    longPress: { |x, y| /* Context menu */ }
);
```

### Proposal 18.2: Probability Distribution Drawing
**Description:** Allow drawing probability distributions for stochastic arc generation (per UPISketch plans).

> "One can decide on artificial, arbitrary probability distributions, conceiving scores by providing for each voice at every point in time a value and an amount of deviation from this value." (Bourotte, Page 369)

**Implementation:**
```supercollider
~nUPIC[\stochastic][\drawProbabilityRegion] = { |points|
    // Define a region where arcs will be stochastically generated
    // Y-axis = pitch center, width = deviation range
};

~nUPIC[\stochastic][\generate] = { |regionIndex, density|
    // Generate stochastic arcs within probability region
};
```

---

## Development Roadmap

### Phase 1: Core UPIC Alignment (Foundation)
**Goal:** Achieve feature parity with essential UPIC capabilities

| Priority | Proposal | Effort | Status |
|----------|----------|--------|--------|
| 1 | 3.1 Time Compression/Expansion | Medium | ✓ DONE |
| 2 | 3.2 Frequency Compression/Expansion | Medium | ✓ DONE |
| 3 | 2.1 Per-Arc Duration | Medium | Pending |
| 4 | 1.1 Arc-to-Wavetable Conversion | High | ✓ DONE |
| 5 | 1.2 Wavetable-to-Arc Conversion | Medium | ✓ DONE |
| 6 | 4.1 Playback Direction Control | Low | ✓ DONE |

### Phase 2: Enhanced Workflow
**Goal:** Streamline compositional workflow

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 6 | 6.1 Timbre Presets | Medium | None |
| 7 | 3.3 Interactive Transform Mode | High | 3.1, 3.2 |
| 8 | 4.2 Playhead Position Control | Low | ✓ Implemented |
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

### Phase 6: Modern Extensions
**Goal:** Incorporate findings from modern UPIC research

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 21 | 13.1 Extended Frequency Range | Medium | None |
| 22 | 14.1 Morphological Shape Templates | Medium | None |
| 23 | 15.1 Multi-Page Composition | High | 2.2 |
| 24 | 15.2 Golden Section Tools | Low | 15.1 |

### Phase 7: Performance & Interaction
**Goal:** Enable live performance and alternative interfaces

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 25 | 16.1 Live Performance Controls | Medium | Playback |
| 26 | 16.2 Fragment Triggering System | High | 15.1 |
| 27 | 17.1 Vector Arc Mode | High | None |
| 28 | 17.2 OSC/MIDI Output | Medium | None |

### Phase 8: Experimental Features
**Goal:** Push beyond historical UPIC

| Priority | Proposal | Effort | Dependencies |
|----------|----------|--------|--------------|
| 29 | 5.2 Fractal/Recursive Arc Structure | Very High | 12.1 |
| 30 | 18.1 Touch Interface Mode | High | Platform |
| 31 | 18.2 Probability Distribution Drawing | High | 8.1 |
| 32 | 13.2 Rhythm-to-Pitch Morphing | Very High | 13.1 |

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

### Primary Source
All quotations from the ZKM publication:
- Weibel, Peter, Ludger Brümmer, and Sharon Kanach (eds.). *From Xenakis's UPIC to Graphic Notation Today*. ZKM | Center for Art and Media Karlsruhe / Hatje Cantz, 2020.

### Chapter References Used in This Document

**Historical & Technical:**
- Médigue, Guy. "The Early Days of the UPIC." Pages 122-139.
- Lohner, Henning. "Reflections." Pages 455-473.
- Weibel, Peter. "The Road to the UPIC: From Graphic Notation to Graphic User Interface." Pages 485-523.

**Analytical:**
- Squibbs, Ronald. "Mycènes Alpha: A Listener's Guide." Pages 417-431.
- Couprie, Pierre. "Analytical Approaches to Taurhiphanie and Voyage Absolu des Unari vers Andromède." Pages 437-453.

**Theoretical:**
- Pietruszewski, Marcin. "The Digital Instrument as an Artifact." Pages 613-625.
- Estrada, Julio. "The Listening Hand." Pages 315-327.
- Bourotte, Rodolphe. "Probabilities, Drawing, and Sound Synthesis." Pages 357-371.

**Modern Implementations:**
- Furukawa, Kiyoshi. "The UPIC and Utopia." Pages 531-539.
- Miyama, Chikashi. "The UPIC 2019." Pages 543-557.
- Scordato, Julian. "Exploring Visualization Methods for Algorithmic Processes in IanniX." Pages 559-573.
- Simon, Victoria. "Beyond the Continuum." Pages 575-589.

**Pedagogical:**
- Després, Jean-Philippe. "The UPIC: Towards a Pedagogy of Creativity." Pages 141-157.
- Frisius, Rudolf. "UPIC—Experimental Music Pedagogy—Xenakis." Pages 159-173.
- Pape, Gerard. "Composing with Sound at Les Ateliers UPIC/CCMIX." Pages 175-195.

### Additional References
- Roads, Curtis. *Microsound*. Cambridge, MA: MIT Press, 2004.
- Xenakis, Iannis. *Formalized Music*. Hillsdale, NY: Pendragon Press, 1992.
- Marino, Gerard, Marie-Helene Serra, and Jean-Michel Raczinski. "The UPIC System: Origins and Innovations." *Perspectives of New Music* 31 (1993): 258-270.
- Ihde, Don. *Technology and the Lifeworld: From Garden to Earth*. Indiana University Press, 1990.
- Roads, Curtis, and Alberto de Campo. "Pulsar Generator" (2000).
- Rohrhuber, Julian, et al. "Algorithms Today: Notes on Language Design for Just In Time Programming." ICMC 2005.

### Related Software Projects
- **IanniX**: Open-source graphical sequencer (https://www.iannix.org)
- **UPISketch**: Mobile UPIC app for iOS/Windows (http://www.centre-iannis-xenakis.org/upisketch)
- **Smallfish**: Interactive music generation (https://zkm.de/en/publication/small-fish)
