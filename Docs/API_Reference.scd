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
// Access and modify trajectory data programmatically.

// --- Basic Access ---

// Get number of trajectories
~nUPIC[\trajectories][\count].value;

// List all trajectories (summary)
~nUPIC[\trajectories][\list].value;

// Get all data for a trajectory
~nUPIC[\trajectories][\get].value(0);
// Returns: (index, points, synthDef, amplitudeEnvelope, spatialEnvelope, wavetable, isSelected)

// --- SynthDef ---

~nUPIC[\trajectories][\getSynthDef].value(0);
~nUPIC[\trajectories][\setSynthDef].value(0, \upicWavetable8ch);

// --- Points ---

~nUPIC[\trajectories][\getPoints].value(0);
~nUPIC[\trajectories][\setPoints].value(0, newPoints);

// --- Amplitude Envelope ---

~nUPIC[\trajectories][\getAmplitudeEnvelope].value(0);
~nUPIC[\trajectories][\setAmplitudeEnvelope].value(0, myEnvelope);

// --- Spatial Envelope ---

~nUPIC[\trajectories][\getSpatialEnvelope].value(0);
~nUPIC[\trajectories][\setSpatialEnvelope].value(0, List[
    (x: 0, channel: 0),
    (x: 600, channel: 7)
]);

// --- Wavetable (per-trajectory) ---

// Get wavetable data (2048 samples, -1 to 1)
~nUPIC[\trajectories][\getWavetable].value(0);

// Set wavetable data
~nUPIC[\trajectories][\setWavetable].value(0, Array.fill(2048, { |i| sin(2pi * i / 2048) }));

// Get the server buffer reference
~nUPIC[\trajectories][\getWavetableBuffer].value(0);

// Open wavetable editor for trajectory
~nUPIC[\trajectories][\editWavetable].value(0);

// Copy wavetable from one trajectory to another
~nUPIC[\trajectories][\copyWavetable].value(0, 1);  // Copy from trajectory 0 to 1

// Or open editor for selected trajectory (uses first selected)
~nUPIC[\wavetableEditor][\open].value;


// ============================================================================
// TRAJECTORY TRANSFORMATIONS
// ============================================================================
// Modify trajectory frequencies using periodic, random, or custom functions.

// --- Periodic Modulation ---

// Vibrato: multiply frequency by sine wave (depth = ±2%, 4 cycles)
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\sineModulation].value(0.02, 4)
);

// Additive sine: add Hz offset (±100 Hz, 8 cycles)
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\sineAdd].value(100, 8)
);

// Sawtooth modulation
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\sawModulation].value(0.1, 3)
);

// --- Envelope Shaping ---

// Exponential decay
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\expDecay].value(0.5, 3)
);

// Exponential growth
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\expGrowth].value(0.5, 2)
);

// --- Noise / Random ---

// Multiply by random noise (90% original + 10% noise)
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\noiseModulation].value(0.9)
);

// Add random Hz offset
~nUPIC[\trajectories][\modulateFreq].value(0,
    ~nUPIC[\trajectories][\noiseAdd].value(50)
);

// --- Xenakis GENDYN Style ---

// Full stochastic transformation (random walks on freq + time)
~nUPIC[\trajectories][\gendyn].value(0,
    freqStep: 0.05,     // step size for frequency walk
    freqBarrier: 0.3,   // max ±30% frequency deviation
    timeStep: 0.02,     // step size for time walk
    timeBarrier: 0.1    // max ±10% time deviation
);

// Brownian motion on frequencies only
~nUPIC[\trajectories][\brownian].value(0,
    stepSize: 0.03,
    barrier: 0.2
);

// General stochastic modulation
~nUPIC[\trajectories][\stochasticModulation].value(0,
    stepSize: 0.05,
    barrier: 0.3,
    distribution: \gaussian  // or \uniform, \cauchy
);

// --- Custom Functions ---

// Apply any function: { |freq, position, index| -> newFreq }
~nUPIC[\trajectories][\modulateFreq].value(0, { |freq, pos, idx|
    freq * (1 + (0.5 * sin(pos * 10pi) * exp(-3 * pos)))  // damped oscillation
});

// Generic transform (modify points directly)
~nUPIC[\trajectories][\transform].value(0, { |points|
    points.collect { |pt| (x: pt.x, y: pt.y * 0.5, freq: pt.freq * 2) }
});


// ============================================================================
// SCALE QUANTIZATION
// ============================================================================
// Quantize trajectory frequencies to musical scales.

// Quantize using scale name and root MIDI note
~nUPIC[\trajectories][\quantize].value(0, \major, 60);       // C major
~nUPIC[\trajectories][\quantize].value(0, \minor, 57);       // A minor
~nUPIC[\trajectories][\quantize].value(0, \phrygian, 64);    // E phrygian

// Quantize using raw scale intervals
~nUPIC[\trajectories][\quantizeToScale].value(0, [0,2,4,5,7,9,11], 60);

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
