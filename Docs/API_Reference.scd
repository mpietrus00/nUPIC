/*
 * nUPIC API Reference
 * ===================
 * Programmatic access to trajectories, defaults, and transformations.
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
//   \defaultSynthDef - SynthDef for new trajectories (\upicWavetable, \upicWavetable8ch, etc.)


// ============================================================================
// TRAJECTORIES API
// ============================================================================
// Access and modify arc data programmatically.

// --- Basic Access ---

// Get number of trajectories
~nUPIC[\arcs][\count].value;

// List all trajectories (summary)
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
// TRAJECTORY TRANSFORMATIONS
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
