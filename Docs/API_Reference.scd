/*
 * nUPIC API Reference
 * ===================
 * Programmatic access to arcs, defaults, and transformations.
 */


// ============================================================================
// REACTIVE DEFAULTS
// ============================================================================
// The defaults system supports reactive updates - UI components automatically
// update when values change programmatically.

// Set a value (automatically updates UI)
~nUPIC[\defaults][\setValue].value(\playDuration, 100);

// Read a value
~nUPIC[\defaults][\playDuration];

// Register a listener for value changes
~nUPIC[\defaults][\addDependant].value({ |what, val|
    ("Changed: " ++ what ++ " = " ++ val).postln;
});

// Available defaults:
//   \playDuration    - playback duration in seconds
//   \defaultSynthDef - SynthDef for new arcs (\upicWavetable, \upicWavetable8ch, etc.)


// ============================================================================
// PAGES API
// ============================================================================
// Each page has its own independent arcs, duration, synthdefs, envelopes.
// Default pages are _a, _b, _c, _d (up to 24 pages supported).

// --- Basic Page Access ---

// Get current page index (0-based)
~nUPIC[\pages][\manager][\getCurrentIndex].value;

// Get current page data
~nUPIC[\pages][\manager][\getCurrent].value;
// Returns: (label, duration, arcs, amplitudeEnvelopes, spatialEnvelopes, arcSynthDefs, ...)

// Get specific page by index
~nUPIC[\pages][\manager][\getPage].value(0);  // Get page _a

// Get number of pages
~nUPIC[\pages][\manager][\count].value;

// Get summary of all pages
~nUPIC[\pages][\manager][\getSummary].value;
// Returns list of: (index, label, duration, arcCount, isCurrent)

// --- Switching Pages ---

// Switch to page by index (0 = _a, 1 = _b, etc.)
~nUPIC[\pages][\manager][\switchTo].value(1);  // Switch to page _b

// Note: switching automatically:
//   1. Saves current page data (syncFromData)
//   2. Loads new page data (syncToData)
//   3. Updates UI controls (duration, tabs)
//   4. Refreshes arc display

// --- Page Duration ---

// Get duration for a specific page
~nUPIC[\pages][\manager][\getDuration].value(0);  // Page _a duration

// Set duration for a specific page (in seconds, 0.1-240)
~nUPIC[\pages][\manager][\setDuration].value(0, 30);   // Page _a = 30 sec
~nUPIC[\pages][\manager][\setDuration].value(1, 60);   // Page _b = 60 sec
~nUPIC[\pages][\manager][\setDuration].value(2, 120);  // Page _c = 120 sec

// --- Page Labels ---

// Set custom label for a page
~nUPIC[\pages][\manager][\setLabel].value(0, "_intro");
~nUPIC[\pages][\manager][\setLabel].value(1, "_verse");
~nUPIC[\pages][\manager][\setLabel].value(2, "_chorus");

// --- Creating & Managing Pages ---

// Create a new page (returns new page index)
~nUPIC[\pages][\manager][\create].value("_e", 45);  // Label "_e", duration 45 sec

// Duplicate an existing page (copies all arcs, envelopes, etc.)
~nUPIC[\pages][\manager][\duplicate].value(0);  // Duplicate page _a

// Delete a page by index (cannot delete if only one page remains)
~nUPIC[\pages][\manager][\delete].value(3);  // Delete page at index 3

// Clear all and reset to default pages (_a, _b, _c, _d)
~nUPIC[\pages][\manager][\clearAll].value;

// --- Per-Page Arcs & SynthDefs ---

// Each page has its own arcs. When you switch pages, ~nUPIC[\data][\arcs]
// points to the current page's arcs. To modify arcs on a specific page:

// 1. Switch to that page
~nUPIC[\pages][\manager][\switchTo].value(1);  // Go to page _b

// 2. Now arc operations affect page _b
~nUPIC[\arcs][\setSynthDef].value(0, \upicWavetable8ch);  // Arc 0 on page _b

// Or access page data directly:
(
var page = ~nUPIC[\pages][\manager][\getPage].value(2);  // Get page _c
page.arcs.size.postln;  // Number of arcs on page _c
page.arcSynthDefs[0].postln;  // SynthDef for arc 0 on page _c
)

// --- Page Sequence (Playback Order) ---

// Pages can be arranged in a sequence for continuous playback.
// The sequence is a list of page indices.

// Set playback sequence
~nUPIC[\pages][\manager][\setSequence].value([0, 1, 0, 2, 3]);  // _a, _b, _a, _c, _d

// Add page to end of sequence
~nUPIC[\pages][\manager][\addToSequence].value(1);  // Add page _b to end

// Add page at specific position
~nUPIC[\pages][\manager][\addToSequence].value(0, 2);  // Insert _a at position 2

// Remove from sequence by position
~nUPIC[\pages][\manager][\removeFromSequence].value(3);  // Remove item at position 3

// Move item in sequence
~nUPIC[\pages][\manager][\moveInSequence].value(0, 2);  // Move from pos 0 to pos 2

// Get total duration of sequence (sum of all page durations)
~nUPIC[\pages][\manager][\getTotalDuration].value;

// Get sequence as labels
~nUPIC[\pages][\manager][\getSequenceLabels].value;  // ["_a", "_b", "_a", "_c", "_d"]

// --- Convenience Accessors ---

// Shorter syntax using convenience functions:
~nUPIC[\pages][\current].value;                    // Get current page
~nUPIC[\pages][\count].value;                      // Get page count
~nUPIC[\pages][\switchTo].value(2);                // Switch to page _c
~nUPIC[\pages][\setDuration].value(0, 30);         // Set page _a duration
~nUPIC[\pages][\getDuration].value(1);             // Get page _b duration
~nUPIC[\pages][\setLabel].value(0, "_intro");      // Set page label
~nUPIC[\pages][\create].value("_new", 60);         // Create new page
~nUPIC[\pages][\duplicate].value(0);               // Duplicate page
~nUPIC[\pages][\delete].value(4);                  // Delete page

// --- Example: Set Up Different SynthDefs Per Page ---

(
// Page _a: stereo wavetable synth
~nUPIC[\pages][\manager][\switchTo].value(0);
~nUPIC[\pages][\manager][\setDuration].value(0, 30);
~nUPIC[\data][\arcs].do { |arc, i|
    ~nUPIC[\arcs][\setSynthDef].value(i, \upicWavetable);
};

// Page _b: 8-channel spatial synth
~nUPIC[\pages][\manager][\switchTo].value(1);
~nUPIC[\pages][\manager][\setDuration].value(1, 60);
~nUPIC[\data][\arcs].do { |arc, i|
    ~nUPIC[\arcs][\setSynthDef].value(i, \upicWavetable8ch);
};

// Page _c: FM synthesis
~nUPIC[\pages][\manager][\switchTo].value(2);
~nUPIC[\pages][\manager][\setDuration].value(2, 45);
~nUPIC[\data][\arcs].do { |arc, i|
    ~nUPIC[\arcs][\setSynthDef].value(i, \upicFM);
};

// Switch back to page _a
~nUPIC[\pages][\manager][\switchTo].value(0);
)


// ============================================================================
// ARCS API
// ============================================================================
// Access and modify arc data programmatically.

// --- Basic Access ---

// Get number of arcs
~nUPIC[\arcs][\count].value;

// List all arcs (summary)
~nUPIC[\arcs][\list].value;

// Get all data for a arc
~nUPIC[\arcs][\get].value(0);
// Returns: (index, points, synthDef, amplitudeEnvelope, spatialEnvelope, wavetable, isSelected)

// --- SynthDef ---

~nUPIC[\arcs][\getSynthDef].value(0);
~nUPIC[\arcs][\setSynthDef].value(0, \upicWavetable8ch);

// --- Points ---

~nUPIC[\arcs][\getPoints].value(0);
~nUPIC[\arcs][\setPoints].value(0, newPoints);

// --- Amplitude Envelope ---

~nUPIC[\arcs][\getAmplitudeEnvelope].value(0);
~nUPIC[\arcs][\setAmplitudeEnvelope].value(0, myEnvelope);

// --- Spatial Envelope ---

~nUPIC[\arcs][\getSpatialEnvelope].value(0);
~nUPIC[\arcs][\setSpatialEnvelope].value(0, List[
    (x: 0, channel: 0),
    (x: 600, channel: 7)
]);

// --- Wavetable (per-arc) ---

// Get wavetable data (2048 samples, -1 to 1)
~nUPIC[\arcs][\getWavetable].value(0);

// Set wavetable data
~nUPIC[\arcs][\setWavetable].value(0, Array.fill(2048, { |i| sin(2pi * i / 2048) }));

// Get the server buffer reference
~nUPIC[\arcs][\getWavetableBuffer].value(0);

// Open wavetable editor for arc
~nUPIC[\arcs][\editWavetable].value(0);

// Copy wavetable from one arc to another
~nUPIC[\arcs][\copyWavetable].value(0, 1);  // Copy from arc 0 to 1

// Or open editor for selected arc (uses first selected)
~nUPIC[\wavetableEditor][\open].value;

// --- Wavetable Files (.wav) ---

// Scan TABLES directory for .wav files
~nUPIC[\wavetablePresets][\scanWavFiles].value;

// List all .wav files found
~nUPIC[\wavetablePresets][\listWavFiles].value;

// Load .wav file to arc (async - resamples to 2048 samples)
~nUPIC[\wavetablePresets][\loadWavToArc].value("mywave.wav", 0);

// Set TABLES directory path manually
~nUPIC[\wavetablePresets][\tablesPath] = "/path/to/TABLES";
~nUPIC[\wavetablePresets][\scanWavFiles].value;

// --- Programmatic Presets (fallback) ---

// List all available (wav files + basic presets)
~nUPIC[\wavetablePresets][\list].value;

// Get programmatic preset data
~nUPIC[\wavetablePresets][\get].value(\sine);
~nUPIC[\wavetablePresets][\get].value(\brass);

// Load any wavetable to arc (handles both wav and programmatic)
~nUPIC[\wavetablePresets][\loadToArc].value("mywave.wav", 0);
~nUPIC[\wavetablePresets][\loadToArc].value(\sine, 0);


// ============================================================================
// ARC TRANSFORMATIONS
// ============================================================================
// Modify arc frequencies using periodic, random, or custom functions.

// --- Resolution / Resampling ---

// Increase arc resolution for finer modulation (interpolates between points)
~nUPIC[\arcs][\resample].value(0, 200);  // Resample arc 0 to 200 points

// Typical workflow: resample first, then modulate
~nUPIC[\arcs][\resample].value(0, 500);
~nUPIC[\arcs][\modulateFreq].value(0, ~nUPIC[\arcs][\sineModulation].value(0.1, 8));

// --- Periodic Modulation ---

// Vibrato: multiply frequency by sine wave (depth = ±2%, 4 cycles)
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\sineModulation].value(0.02, 4)
);

// Additive sine: add Hz offset (±100 Hz, 8 cycles)
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\sineAdd].value(100, 8)
);

// Sawtooth modulation
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\sawModulation].value(0.1, 3)
);

// --- Envelope Shaping ---

// Exponential decay
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\expDecay].value(0.5, 3)
);

// Exponential growth
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\expGrowth].value(0.5, 2)
);

// --- Noise / Random ---

// Multiply by random noise (90% original + 10% noise)
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\noiseModulation].value(0.9)
);

// Add random Hz offset
~nUPIC[\arcs][\modulateFreq].value(0,
    ~nUPIC[\arcs][\noiseAdd].value(50)
);

// --- Xenakis GENDYN Style ---

// Full stochastic transformation (random walks on freq + time)
~nUPIC[\arcs][\gendyn].value(0,
    freqStep: 0.05,     // step size for frequency walk
    freqBarrier: 0.3,   // max ±30% frequency deviation
    timeStep: 0.02,     // step size for time walk
    timeBarrier: 0.1    // max ±10% time deviation
);

// Brownian motion on frequencies only
~nUPIC[\arcs][\brownian].value(0,
    stepSize: 0.03,
    barrier: 0.2
);

// General stochastic modulation
~nUPIC[\arcs][\stochasticModulation].value(0,
    stepSize: 0.05,
    barrier: 0.3,
    distribution: \gaussian  // or \uniform, \cauchy
);

// --- Custom Functions ---

// Apply any function: { |freq, position, index| -> newFreq }
~nUPIC[\arcs][\modulateFreq].value(0, { |freq, pos, idx|
    freq * (1 + (0.5 * sin(pos * 10pi) * exp(-3 * pos)))  // damped oscillation
});

// Generic transform (modify points directly)
~nUPIC[\arcs][\transform].value(0, { |points|
    points.collect { |pt| (x: pt.x, y: pt.y * 0.5, freq: pt.freq * 2) }
});


// ============================================================================
// SCALE QUANTIZATION
// ============================================================================
// Quantize arc frequencies to musical scales.

// Quantize using scale name and root MIDI note
~nUPIC[\arcs][\quantize].value(0, \major, 60);       // C major
~nUPIC[\arcs][\quantize].value(0, \minor, 57);       // A minor
~nUPIC[\arcs][\quantize].value(0, \phrygian, 64);    // E phrygian

// Quantize using raw scale intervals
~nUPIC[\arcs][\quantizeToScale].value(0, [0,2,4,5,7,9,11], 60);

// List all available scales
~nUPIC[\scales][\list].value;

// Access scale intervals directly
~nUPIC[\scales][\lydian];  // -> [0, 2, 4, 6, 7, 9, 11]


// ============================================================================
// AVAILABLE SCALES
// ============================================================================
/*
Diatonic Modes:
    \major, \minor, \dorian, \phrygian, \lydian, \mixolydian,
    \locrian, \harmonicMinor, \melodicMinor

Pentatonic & Blues:
    \pentatonicMajor, \pentatonicMinor, \blues, \bluesMajor

Symmetric:
    \chromatic, \wholeTone, \diminishedHW, \diminishedWH, \augmented

Bebop:
    \bebopDominant, \bebopMajor, \bebopMinor, \bebopDorian

World / Ethnic:
    \hungarian, \hungarianMinor, \spanish, \spanish8tone, \phrygianDominant,
    \arabic, \persian, \japanese, \hirajoshi, \iwato, \insen, \chinese,
    \indian, \gypsy, \byzantine, \balinese, \javanese

Messiaen Modes of Limited Transposition:
    \messiaen1, \messiaen2, \messiaen3, \messiaen4, \messiaen5, \messiaen6, \messiaen7

Other:
    \prometheus, \enigmatic, \neapolitanMajor, \neapolitanMinor,
    \doubleHarmonic, \altered, \superlocrian, \lydianDominant,
    \tritone, \fifths, \fourths
*/


// ============================================================================
// WAVETABLE FILES
// ============================================================================
/*
The TABLES directory can contain .wav, .aif, or .aiff files.
Any audio file will be:
  - Converted to mono (if stereo)
  - Resampled to 2048 samples
  - Normalized to -1 to 1 range

Place your wavetable .wav files in the TABLES directory, then use:
  ~nUPIC[\wavetablePresets][\scanWavFiles].value;  // Rescan directory
  ~nUPIC[\wavetablePresets][\listWavFiles].value;  // List files

In the Wavetable Editor:
  - Use "refresh" button to rescan TABLES directory
  - Use "set path..." button to choose a different directory
  - Select a .wav file from the dropdown to load it

Fallback programmatic presets:
    \sine, \saw, \square, \triangle, \organFull, \brass
*/
