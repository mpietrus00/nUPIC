# nUPIC Extension Proposals
## Based on "The Digital Instrument as an Artifact" by Marcin Pietruszewski

This document outlines implementation proposals for extending nUPIC in alignment with the original UPIC system, based on the ZKM publication "From Xenakis's UPIC to Graphic Notation Today."

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

## References

All quotations from:
- Pietruszewski, Marcin. "The Digital Instrument as an Artifact." In *From Xenakis's UPIC to Graphic Notation Today*, edited by Peter Weibel, Ludger Brummer, and Sharon Kanach. ZKM | Center for Art and Media Karlsruhe / Hatje Cantz, 2020. Pages 613-625.

Additional references cited in the source:
- Roads, Curtis. *Microsound*. Cambridge, MA: MIT Press, 2004.
- Xenakis, Iannis. *Formalized Music*. Hillsdale, NY: Pendragon Press, 1992.
- Marino, Gerard, Marie-Helene Serra, and Jean-Michel Raczinski. "The UPIC System: Origins and Innovations." *Perspectives of New Music* 31 (1993): 258-270.
