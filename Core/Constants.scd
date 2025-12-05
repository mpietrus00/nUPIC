// nUPIC Core Constants and Configuration
// Central configuration for the nUPIC arc synthesis system

(
// Initialize nUPIC namespace
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };

// Core constants
~nUPIC[\constants] = (
    // System limits
    maxSynths: 200,
    maxTrajectories: 200,
    maxUndoSteps: 50,
    
    // UI dimensions
    defaultWidth: 1200,
    defaultHeight: 670,  // Increased by 20px for better proportions
    controlPanelHeight: 32,  // Reduced from 240 for compact controls
    
    // Timing and performance
    frameRate: 60,  // Increased to 60 Hz for smoother parameter updates
    audioFrameRate: 120, // Even higher rate for audio parameter updates
    defaultDuration: 10, // seconds
    maxDuration: 600, // 10 minutes
    
    // Smoothness settings
    useHighResAudio: true, // Enable high resolution audio updates
    lagTimeFreq: 0.1,     // Lag time for frequency changes (seconds)
    lagTimeAmp: 0.05,     // Lag time for amplitude changes (seconds)
    lagTimePan: 0.08,     // Lag time for panning changes (seconds)
    
    // Audio parameters
    defaultSampleRate: 44100,
    freqMin: 20,   // Set back to 20 Hz as requested
    freqMax: 7500,
    
    // Interaction
    dragThreshold: 10,
    eraseRadius: 20,
    clickThreshold: 10,
    moveStep: 10,
    
    // Drawing
    arcWidth: 2,
    selectedWidth: 4,
    gridOpacity: 0.5,
    
    // File system
    presetExtension: ".nupic",
    presetDirectory: "nUPIC_Projects",
    
    // Version
    version: "2.0.0",
    fileFormatVersion: "2.0"
);

// Color palette - Clean Professional theme
~nUPIC[\colors] = (
    // Main UI colors with clean light gray theme
    background: Color.white,  // Keep drawing areas white for clarity
    systemBackground: Color.gray(0.9),  // Light gray for system areas
    controlBackground: Color.new(205/255, 250/255, 205/255),  // Light green for control areas (rgb 205, 250, 205)
    grid: Color.gray(0.3, 0.5),
    gridText: Color.gray(0.4),
    arc: { |index, maxIndex = 200| 
        Color.hsv((index / maxIndex) * 0.8, 0.7, 0.9) 
    },
    selected: Color.blue,
    eraseMode: Color.red,
    selectMode: Color.blue,
    drawMode: Color.gray,
    playback: Color.green,
    playbackLine: Color.red,
    
    // Amplitude editor colors
    amplitudeEnvelope: Color.red.alpha_(0.6),
    amplitudeStroke: Color.red,
    amplitudeBackground: Color.white,
    amplitudeGrid: Color.gray(0.8, 0.5),
    
    // Button colors
    buttonNormal: Color.gray(0.9),
    buttonPressed: Color.gray(0.7),
    buttonActive: Color.blue.alpha_(0.8),
    buttonDanger: Color.red.alpha_(0.8),
    buttonSuccess: Color.green.alpha_(0.8)
);

// Default settings
~nUPIC[\defaults] = (
    // Playback
    playDuration: 10,
    
    // Zoom
    zoomFreqMin: 20,   // Set back to 20 Hz as requested
    zoomFreqMax: 7500,
    zoomTimeMin: 0,
    zoomTimeMax: 1,
    
    // Grid
    showGrid: true,
    gridType: \equalTemperament,
    
    // Audio
    synthDefNames: [\upicWavetable, \simpleGravObject, \arcVarSaw, \testOrbit],
    defaultSynthDef: \upicWavetable,
    
    // UI modes
    drawMode: \frequency, // \frequency or \amplitude
    eraseMode: false,
    selectMode: false,
    
    // Server configuration
    serverMemSize: 65536 * 2,
    serverWireBufs: 128,
    serverMaxNodes: 2048,
    serverAudioBusChannels: 512
);

// Defaults - reactive settings that notify UI when changed
// Values stored directly for backwards compatibility: defaults[\playDuration]
// Use defaults.setValue(\key, value) to update and auto-refresh UI
// Clear dependants on reload - UI will re-register fresh dependants
~nUPIC['_defaultsDependants'] = IdentitySet.new;

~nUPIC[\defaults] = (
    // Actual values (backwards compatible - direct access works)
    defaultSynthDef: \upicWavetable,
    playDuration: 10,
    showGrid: true,
    gridType: \equalTemperament
);

// Define methods separately to avoid Event method dispatch issues
// These functions access ~nUPIC directly instead of relying on self

~nUPIC[\defaults][\setValue] = { |key, value|
    var defaults = ~nUPIC[\defaults];
    var oldValue = defaults[key];
    defaults[key] = value;
    if(oldValue != value) {
        ~nUPIC[\defaults][\notifyChanged].value(key, value, oldValue);
    };
    value
};

~nUPIC[\defaults][\addDependant] = { |dep|
    ~nUPIC['_defaultsDependants'].add(dep);
};

~nUPIC[\defaults][\removeDependant] = { |dep|
    ~nUPIC['_defaultsDependants'].remove(dep);
};

~nUPIC[\defaults][\notifyChanged] = { |what, value, oldValue|
    ~nUPIC['_defaultsDependants'].do { |dep|
        {
            if(dep.isKindOf(Function)) {
                dep.value(what, value, oldValue);
            };
        }.defer;
    };
};

// ============================================================================
// Trajectories API - Clean interface to access and modify arc data
// ============================================================================
// Usage:
//   ~nUPIC[\arcs][\count].value              // Get number of trajectories
//   ~nUPIC[\arcs][\get].value(0)             // Get all data for arc 0
//   ~nUPIC[\arcs][\getSynthDef].value(0)     // Get SynthDef for arc 0
//   ~nUPIC[\arcs][\setSynthDef].value(0, \upicWavetable8ch)  // Set SynthDef
//   etc.

~nUPIC[\arcs] = IdentityDictionary.new;

// Get number of trajectories
~nUPIC[\arcs][\count] = {
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\arcs].notNil }) {
        data[\arcs].size
    } { 0 };
};

// Get all data for a arc as an Event
~nUPIC[\arcs][\get] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil and: { index >= 0 } and: { index < ~nUPIC[\arcs][\count].value }) {
        (
            index: index,
            points: if(data[\arcs].notNil) { data[\arcs][index] } { nil },
            synthDef: if(data[\arcSynthDefs].notNil and: { index < data[\arcSynthDefs].size }) {
                data[\arcSynthDefs][index]
            } { nil },
            amplitudeEnvelope: if(data[\amplitudeEnvelopes].notNil and: { index < data[\amplitudeEnvelopes].size }) {
                data[\amplitudeEnvelopes][index]
            } { nil },
            spatialEnvelope: if(data[\getSpatialEnvelope].notNil) {
                data[\getSpatialEnvelope].value(index)
            } {
                if(data[\spatialEnvelopes].notNil and: { index < data[\spatialEnvelopes].size }) {
                    data[\spatialEnvelopes][index]
                } { nil }
            },
            wavetable: if(data[\wavetables].notNil and: { index < data[\wavetables].size }) {
                data[\wavetables][index]
            } { nil },
            isSelected: if(data[\selectedArcs].notNil) {
                data[\selectedArcs].includes(index)
            } { false }
        )
    } { nil };
};

// Get arc points
~nUPIC[\arcs][\getPoints] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\arcs].notNil } and: { index >= 0 } and: { index < data[\arcs].size }) {
        data[\arcs][index]
    } { nil };
};

// Set arc points
~nUPIC[\arcs][\setPoints] = { |index, points|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\arcs].notNil } and: { index >= 0 } and: { index < data[\arcs].size }) {
        data[\arcs][index] = points;
        ~nUPIC[\ui][\refreshDisplay].value;
        points
    } { nil };
};

// Get SynthDef for arc
~nUPIC[\arcs][\getSynthDef] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\arcSynthDefs].notNil } and: { index >= 0 } and: { index < data[\arcSynthDefs].size }) {
        data[\arcSynthDefs][index]
    } { nil };
};

// Set SynthDef for arc
~nUPIC[\arcs][\setSynthDef] = { |index, synthDef|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\arcSynthDefs].notNil } and: { index >= 0 } and: { index < data[\arcSynthDefs].size }) {
        data[\arcSynthDefs][index] = synthDef;
        ("Arc " ++ index ++ " SynthDef set to: " ++ synthDef).postln;
        synthDef
    } { nil };
};

// Get amplitude envelope for arc
~nUPIC[\arcs][\getAmplitudeEnvelope] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\amplitudeEnvelopes].notNil } and: { index >= 0 } and: { index < data[\amplitudeEnvelopes].size }) {
        data[\amplitudeEnvelopes][index]
    } { nil };
};

// Set amplitude envelope for arc
~nUPIC[\arcs][\setAmplitudeEnvelope] = { |index, envelope|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\amplitudeEnvelopes].notNil } and: { index >= 0 } and: { index < data[\amplitudeEnvelopes].size }) {
        data[\amplitudeEnvelopes][index] = envelope;
        ("Arc " ++ index ++ " amplitude envelope set").postln;
        envelope
    } { nil };
};

// Get spatial envelope for arc
~nUPIC[\arcs][\getSpatialEnvelope] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil) {
        if(data[\getSpatialEnvelope].notNil) {
            data[\getSpatialEnvelope].value(index)
        } {
            if(data[\spatialEnvelopes].notNil and: { index >= 0 } and: { index < data[\spatialEnvelopes].size }) {
                data[\spatialEnvelopes][index]
            } { nil }
        }
    } { nil };
};

// Set spatial envelope for arc
~nUPIC[\arcs][\setSpatialEnvelope] = { |index, envelope|
    var data = ~nUPIC[\data];
    if(data.notNil and: { index >= 0 }) {
        // Set in ArcData
        if(data[\setSpatialEnvelope].notNil) {
            data[\setSpatialEnvelope].value(index, envelope);
        };
        // Also set in editor storage for consistency
        if(data[\spatializationEnvelopes].notNil and: { index < data[\spatializationEnvelopes].size }) {
            data[\spatializationEnvelopes][index] = envelope;
        };
        ("Arc " ++ index ++ " spatial envelope set").postln;
        envelope
    } { nil };
};

// Get wavetable data for arc
~nUPIC[\arcs][\getWavetable] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\wavetables].notNil } and: { index >= 0 } and: { index < data[\wavetables].size }) {
        data[\wavetables][index]
    } { nil };
};

// Set wavetable data for arc (2048 samples, -1 to 1)
~nUPIC[\arcs][\setWavetable] = { |index, wavetableData|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\wavetables].notNil } and: { index >= 0 } and: { index < data[\wavetables].size }) {
        data[\wavetables][index] = wavetableData;
        // Update server buffer if it exists
        if(data[\wavetableBuffers].notNil and: { data[\wavetableBuffers][index].notNil }) {
            data[\wavetableBuffers][index].loadCollection(wavetableData);
        };
        ("Arc " ++ index ++ " wavetable set").postln;
        wavetableData
    } { nil };
};

// Get wavetable buffer reference for arc
~nUPIC[\arcs][\getWavetableBuffer] = { |index|
    var data = ~nUPIC[\data];
    if(data.notNil and: { data[\wavetableBuffers].notNil } and: { index >= 0 } and: { index < data[\wavetableBuffers].size }) {
        data[\wavetableBuffers][index]
    } { nil };
};

// Open wavetable editor for arc
~nUPIC[\arcs][\editWavetable] = { |index|
    ~nUPIC[\wavetableEditor][\open].value(index);
};

// Copy wavetable from one arc to another
~nUPIC[\arcs][\copyWavetable] = { |fromIndex, toIndex|
    var data = ~nUPIC[\data];
    var fromWavetable;
    if(data.notNil and: { data[\wavetables].notNil }) {
        fromWavetable = ~nUPIC[\arcs][\getWavetable].value(fromIndex);
        if(fromWavetable.notNil) {
            ~nUPIC[\arcs][\setWavetable].value(toIndex, fromWavetable.copy);
            ("Wavetable copied from arc " ++ fromIndex ++ " to " ++ toIndex).postln;
            true
        } { false }
    } { false };
};

// List all trajectories with summary info
~nUPIC[\arcs][\list] = {
    var count = ~nUPIC[\arcs][\count].value;
    "=== Trajectories (%): ===".format(count).postln;
    count.do { |i|
        var traj = ~nUPIC[\arcs][\get].value(i);
        if(traj.notNil) {
            "  [%] SynthDef: %, Points: %, Selected: %".format(
                i,
                traj.synthDef ? "nil",
                if(traj.points.notNil) { traj.points.size } { 0 },
                traj.isSelected
            ).postln;
        };
    };
    count
};

// ============================================================================
// Arc Transformation Functions
// ============================================================================
// Apply mathematical functions to modulate arc values
// Supports periodic, stochastic, and custom functions

// Resample arc to increase/decrease number of points (for higher modulation resolution)
// Uses linear interpolation between existing points
~nUPIC[\arcs][\resample] = { |index, numPoints = 100|
    var points, newPoints, totalLength, segmentLengths, cumulativeLengths;
    var i, dx, dy, length, targetDist, segIdx, prevCumulative;
    var segStart, t, x, y, freq, cumLen, j;

    points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil and: { points.size >= 2 } and: { numPoints >= 2 }) {
        newPoints = List.new;
        totalLength = 0;
        segmentLengths = List.new;
        cumulativeLengths = List.new;

        // Calculate total length and segment lengths
        (points.size - 1).do { |idx|
            dx = points[idx+1].x - points[idx].x;
            dy = points[idx+1].y - points[idx].y;
            length = sqrt((dx*dx) + (dy*dy));
            segmentLengths.add(length);
            totalLength = totalLength + length;
            cumulativeLengths.add(totalLength);
        };

        // Generate evenly spaced points along the arc
        numPoints.do { |idx|
            targetDist = (idx / (numPoints - 1)) * totalLength;
            segIdx = 0;
            prevCumulative = 0;

            // Find which segment contains this point
            cumulativeLengths.do { |cumulative, jdx|
                if(cumulative <= targetDist) {
                    segIdx = jdx + 1;
                    prevCumulative = cumulative;
                };
            };
            segIdx = segIdx.min(points.size - 2);

            // Interpolate within segment
            if(segmentLengths[segIdx] > 0) {
                segStart = if(segIdx > 0) { cumulativeLengths[segIdx - 1] } { 0 };
                t = (targetDist - segStart) / segmentLengths[segIdx];
                t = t.clip(0, 1);

                x = points[segIdx].x.blend(points[segIdx + 1].x, t);
                y = points[segIdx].y.blend(points[segIdx + 1].y, t);
                freq = if(points[segIdx].freq.notNil and: { points[segIdx + 1].freq.notNil }) {
                    points[segIdx].freq.blend(points[segIdx + 1].freq, t)
                } { nil };

                newPoints.add((x: x, y: y, freq: freq));
            } {
                // Zero-length segment, just copy the point
                newPoints.add((x: points[segIdx].x, y: points[segIdx].y, freq: points[segIdx].freq));
            };
        };

        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        ("Arc " ++ index ++ " resampled: " ++ points.size ++ " -> " ++ numPoints ++ " points").postln;
        newPoints
    } { nil };
};

// Transform arc with arbitrary function
// func receives: (point, index, totalPoints, normalizedPosition)
// func should return modified point or new (x:, y:, freq:) event
~nUPIC[\arcs][\transform] = { |index, func|
    var points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil and: { func.notNil }) {
        var newPoints = points.collect { |point, i|
            var normalized = i / (points.size - 1).max(1);
            func.value(point, i, points.size, normalized);
        };
        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        newPoints
    } { nil };
};

// Modulate frequency/y values with a function
// func receives: (freq, normalizedPosition, index) and returns new freq
~nUPIC[\arcs][\modulateFreq] = { |index, func|
    var points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil and: { func.notNil }) {
        var newPoints = points.collect { |point, i|
            var normalized = i / (points.size - 1).max(1);
            var newFreq = func.value(point.freq ? point.y, normalized, i);
            (x: point.x, y: point.y, freq: newFreq)
        };
        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        newPoints
    } { nil };
};

// Modulate time/x values with a function
// func receives: (x, normalizedPosition, index) and returns new x
~nUPIC[\arcs][\modulateTime] = { |index, func|
    var points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil and: { func.notNil }) {
        var newPoints = points.collect { |point, i|
            var normalized = i / (points.size - 1).max(1);
            var newX = func.value(point.x, normalized, i);
            (x: newX, y: point.y, freq: point.freq)
        };
        // Sort by x to maintain proper order
        newPoints = newPoints.sort({ |a, b| a.x < b.x });
        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        newPoints
    } { nil };
};

// ============================================================================
// Preset Modulation Functions
// ============================================================================

// Sine modulation: value * (1 + depth * sin(freq * 2pi * position + phase))
~nUPIC[\arcs][\sineModulation] = { |depth = 0.2, freq = 4, phase = 0|
    { |val, pos, idx|
        val * (1 + (depth * sin((freq * 2pi * pos) + phase)))
    }
};

// Add sine wave to value: value + amplitude * sin(freq * 2pi * position + phase)
~nUPIC[\arcs][\sineAdd] = { |amplitude = 100, freq = 4, phase = 0|
    { |val, pos, idx|
        val + (amplitude * sin((freq * 2pi * pos) + phase))
    }
};

// Noise modulation: value * (1 + depth * random)
~nUPIC[\arcs][\noiseModulation] = { |depth = 0.1|
    { |val, pos, idx|
        val * (1 + (depth * rrand(-1.0, 1.0)))
    }
};

// Add noise to value
~nUPIC[\arcs][\noiseAdd] = { |amplitude = 50|
    { |val, pos, idx|
        val + (amplitude * rrand(-1.0, 1.0))
    }
};

// Sawtooth modulation
~nUPIC[\arcs][\sawModulation] = { |depth = 0.2, freq = 4|
    { |val, pos, idx|
        var sawVal = ((pos * freq) % 1) * 2 - 1;  // -1 to 1 sawtooth
        val * (1 + (depth * sawVal))
    }
};

// Exponential decay: value * exp(-decay * position)
~nUPIC[\arcs][\expDecay] = { |decay = 2|
    { |val, pos, idx|
        val * exp(decay * pos.neg)
    }
};

// Exponential growth: value * exp(growth * position)
~nUPIC[\arcs][\expGrowth] = { |growth = 1|
    { |val, pos, idx|
        val * exp(growth * pos)
    }
};

// ============================================================================
// Xenakis-style Dynamic Stochastic Synthesis
// ============================================================================
// Based on Xenakis' GENDYN algorithm - random walks with barriers

~nUPIC[\arcs][\stochasticModulation] = { |
    ampStep = 0.1,      // Max amplitude step size (as fraction of value)
    durStep = 0.1,      // Max duration/time step size
    ampBarrier = 0.5,   // Amplitude barrier (max deviation from original)
    mirror = true       // Mirror at barriers (true) or wrap (false)
|
    var ampAccum = 0;
    { |val, pos, idx|
        var step = rrand(ampStep.neg, ampStep);
        ampAccum = ampAccum + step;

        // Apply barriers
        if(mirror) {
            // Mirror/reflect at barriers
            while { ampAccum.abs > ampBarrier } {
                if(ampAccum > ampBarrier) {
                    ampAccum = ampBarrier - (ampAccum - ampBarrier);
                };
                if(ampAccum < ampBarrier.neg) {
                    ampAccum = ampBarrier.neg - (ampAccum + ampBarrier);
                };
            };
        } {
            // Wrap at barriers
            ampAccum = ampAccum.wrap(ampBarrier.neg, ampBarrier);
        };

        val * (1 + ampAccum)
    }
};

// Full Xenakis GENDYN-style transformation
// Modulates both amplitude and time with random walks
~nUPIC[\arcs][\gendyn] = { |index,
    freqStep = 0.05,
    freqBarrier = 0.3,
    timeStep = 0.02,
    timeBarrier = 0.1
|
    var points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil) {
        var freqAccum = 0;
        var timeAccum = 0;
        var newPoints;

        newPoints = points.collect { |point, i|
            var normalized = i / (points.size - 1).max(1);
            var newFreq, newX;

            // Random walk for frequency
            freqAccum = freqAccum + rrand(freqStep.neg, freqStep);
            freqAccum = freqAccum.fold(freqBarrier.neg, freqBarrier);
            newFreq = point.freq * (1 + freqAccum);

            // Random walk for time (smaller effect)
            timeAccum = timeAccum + rrand(timeStep.neg, timeStep);
            timeAccum = timeAccum.fold(timeBarrier.neg, timeBarrier);
            newX = point.x * (1 + timeAccum);

            (x: newX, y: point.y, freq: newFreq)
        };

        // Sort by x
        newPoints = newPoints.sort({ |a, b| a.x < b.x });
        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        ("Arc " ++ index ++ " transformed with GENDYN stochastic").postln;
        newPoints
    } { nil };
};

// Brownian motion / random walk modulation
~nUPIC[\arcs][\brownian] = { |index, stepSize = 0.02, barrier = 0.3|
    var points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil) {
        var accum = 0;
        var newPoints = points.collect { |point, i|
            accum = accum + rrand(stepSize.neg, stepSize);
            accum = accum.fold(barrier.neg, barrier);
            (x: point.x, y: point.y, freq: point.freq * (1 + accum))
        };
        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        ("Arc " ++ index ++ " transformed with Brownian motion").postln;
        newPoints
    } { nil };
};

// Quantize frequencies to a scale
~nUPIC[\arcs][\quantizeToScale] = { |index, scale, root = 60|
    var points = ~nUPIC[\arcs][\getPoints].value(index);
    if(points.notNil and: { scale.notNil }) {
        var newPoints = points.collect { |point, i|
            var midi = point.freq.cpsmidi;
            var degree = ((midi - root) % 12);
            var octave = ((midi - root) / 12).floor;
            var nearestDegree = scale.minIndex { |scaleDegree| (degree - scaleDegree).abs };
            var quantizedMidi = root + (octave * 12) + scale[nearestDegree];
            var newFreq = quantizedMidi.midicps;
            (x: point.x, y: point.y, freq: newFreq)
        };
        ~nUPIC[\arcs][\setPoints].value(index, newPoints);
        ("Arc " ++ index ++ " quantized to scale").postln;
        newPoints
    } { nil };
};

// ============================================================================
// Musical Scales Dictionary
// ============================================================================
// All scales in semitones from root (0-11)
// Usage: ~nUPIC[\scales][\major] returns [0, 2, 4, 5, 7, 9, 11]

~nUPIC[\scales] = IdentityDictionary[
    // === DIATONIC MODES ===
    \major -> [0, 2, 4, 5, 7, 9, 11],           // Ionian
    \minor -> [0, 2, 3, 5, 7, 8, 10],           // Natural minor / Aeolian
    \harmonicMinor -> [0, 2, 3, 5, 7, 8, 11],
    \melodicMinor -> [0, 2, 3, 5, 7, 9, 11],    // Ascending
    \dorian -> [0, 2, 3, 5, 7, 9, 10],
    \phrygian -> [0, 1, 3, 5, 7, 8, 10],
    \lydian -> [0, 2, 4, 6, 7, 9, 11],
    \mixolydian -> [0, 2, 4, 5, 7, 9, 10],
    \locrian -> [0, 1, 3, 5, 6, 8, 10],

    // === PENTATONIC ===
    \pentatonicMajor -> [0, 2, 4, 7, 9],
    \pentatonicMinor -> [0, 3, 5, 7, 10],
    \blues -> [0, 3, 5, 6, 7, 10],              // Minor pentatonic + blue note
    \bluesMajor -> [0, 2, 3, 4, 7, 9],          // Major blues

    // === SYMMETRIC ===
    \chromatic -> [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    \wholeTone -> [0, 2, 4, 6, 8, 10],
    \diminishedHW -> [0, 1, 3, 4, 6, 7, 9, 10], // Half-Whole
    \diminishedWH -> [0, 2, 3, 5, 6, 8, 9, 11], // Whole-Half
    \augmented -> [0, 3, 4, 7, 8, 11],

    // === BEBOP ===
    \bebopDominant -> [0, 2, 4, 5, 7, 9, 10, 11],
    \bebopMajor -> [0, 2, 4, 5, 7, 8, 9, 11],
    \bebopMinor -> [0, 2, 3, 5, 7, 8, 9, 10],

    // === EXOTIC / WORLD ===
    \hungarian -> [0, 2, 3, 6, 7, 8, 11],       // Hungarian minor
    \hungarianMajor -> [0, 3, 4, 6, 7, 9, 10],
    \spanish -> [0, 1, 4, 5, 7, 8, 10],         // Phrygian dominant
    \arabic -> [0, 1, 4, 5, 7, 8, 11],          // Double harmonic
    \persian -> [0, 1, 4, 5, 6, 8, 11],
    \japanese -> [0, 1, 5, 7, 8],               // In scale
    \hirajoshi -> [0, 2, 3, 7, 8],              // Japanese
    \iwato -> [0, 1, 5, 6, 10],                 // Japanese
    \chinese -> [0, 4, 6, 7, 11],
    \indian -> [0, 1, 4, 5, 7, 8, 10],          // Bhairav
    \gypsy -> [0, 2, 3, 6, 7, 8, 11],           // Hungarian gypsy
    \byzantine -> [0, 1, 4, 5, 7, 8, 11],       // Double harmonic
    \balinese -> [0, 1, 3, 7, 8],               // Pelog

    // === MESSIAEN MODES OF LIMITED TRANSPOSITION ===
    \messiaen1 -> [0, 2, 4, 6, 8, 10],          // = whole tone
    \messiaen2 -> [0, 1, 3, 4, 6, 7, 9, 10],    // = diminished HW
    \messiaen3 -> [0, 2, 3, 4, 6, 7, 8, 10, 11],
    \messiaen4 -> [0, 1, 2, 5, 6, 7, 8, 11],
    \messiaen5 -> [0, 1, 5, 6, 7, 11],
    \messiaen6 -> [0, 2, 4, 5, 6, 8, 10, 11],
    \messiaen7 -> [0, 1, 2, 3, 5, 6, 7, 8, 9, 11],

    // === MICROTONAL / XENHARMONIC (in 12-TET approximations) ===
    \prometheus -> [0, 2, 4, 6, 9, 10],         // Scriabin
    \enigmatic -> [0, 1, 4, 6, 8, 10, 11],
    \neapolitan -> [0, 1, 3, 5, 7, 9, 11],      // Neapolitan major
    \neapolitanMinor -> [0, 1, 3, 5, 7, 8, 11],

    // === SIMPLE / SPARSE ===
    \tritone -> [0, 6],
    \fifths -> [0, 7],
    \fourths -> [0, 5],
    \octaves -> [0]
];

// Helper to list all available scales
~nUPIC[\scales][\list] = {
    "Available scales:".postln;
    ~nUPIC[\scales].keys.reject({ |k| k == \list }).sort.do { |key|
        ("  \\" ++ key ++ " -> " ++ ~nUPIC[\scales][key]).postln;
    };
};

// Convenient quantize function using scale name
~nUPIC[\arcs][\quantize] = { |index, scaleName = \major, root = 60|
    var scale = ~nUPIC[\scales][scaleName];
    if(scale.notNil) {
        ~nUPIC[\arcs][\quantizeToScale].value(index, scale, root);
    } {
        ("Unknown scale: " ++ scaleName ++ ". Use ~nUPIC[\\scales][\\list].value to see options.").postln;
        nil
    };
};

// Grid system definitions
~nUPIC[\gridSystems] = (
    equalTemperament: (
        name: "Equal Temperament (12-TET)",
        baseFreq: 440,
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            // Generate actual semitones, not arbitrary subdivisions
            var semitone = 2.pow(1/12);
            var startNote = (minFreq / baseFreq).log2 * 12;
            var endNote = (maxFreq / baseFreq).log2 * 12;
            var freqs = [];
            
            // Generate every semitone in the range
            (startNote.floor..(endNote.ceil)).do { |noteNum|
                var freq = baseFreq * semitone.pow(noteNum);
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    fokker31: (
        name: "31-tone Equal Temperament (Fokker)",
        baseFreq: 440,
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            // Generate ALL 31 steps per octave, not arbitrary subdivisions
            var step31 = 2.pow(1/31);
            var startStep = (minFreq / baseFreq).log2 * 31;
            var endStep = (maxFreq / baseFreq).log2 * 31;
            var freqs = [];
            
            // Generate every 31-TET step in the range
            (startStep.floor..(endStep.ceil)).do { |stepNum|
                var freq = baseFreq * step31.pow(stepNum);
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    harmonicSeries: (
        name: "Harmonic Series",
        baseFreq: 110, // A2
        calculation: { |baseFreq = 110, minFreq, maxFreq, numLines|
            // Generate ALL harmonics in range, not arbitrary subdivisions
            var fundamental = baseFreq;
            var startHarm = (minFreq / fundamental).ceil.max(1);
            var endHarm = (maxFreq / fundamental).floor;
            var freqs = [];
            
            // Generate every harmonic in the range
            (startHarm..endHarm).do { |harm|
                var freq = fundamental * harm;
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    just: (
        name: "Just Intonation",
        baseFreq: 440,
        ratios: [1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2/1],
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            var justRatios = [1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2/1];
            var octave = (minFreq / baseFreq).log2.floor;
            var freqs = [];
            
            while { baseFreq * (2.pow(octave)) < maxFreq } {
                justRatios.do { |ratio|
                    var freq = baseFreq * (2.pow(octave)) * ratio;
                    if(freq >= minFreq and: { freq <= maxFreq }) {
                        freqs = freqs.add(freq);
                    };
                };
                octave = octave + 1;
            };
            freqs;
        }
    ),
    
    quarterTone: (
        name: "Quarter-tone (24-TET)",
        baseFreq: 440,
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            // Generate ALL 24 quarter-tone steps per octave
            var quarterStep = 2.pow(1/24);
            var startQuarter = (minFreq / baseFreq).log2 * 24;
            var endQuarter = (maxFreq / baseFreq).log2 * 24;
            var freqs = [];
            
            // Generate every quarter-tone step in the range
            (startQuarter.floor..(endQuarter.ceil)).do { |quarterNum|
                var freq = baseFreq * quarterStep.pow(quarterNum);
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    pythagorean: (
        name: "Pythagorean Tuning",
        baseFreq: 440,
        ratios: [1/1, 256/243, 9/8, 32/27, 81/64, 4/3, 729/512, 3/2, 128/81, 27/16, 16/9, 243/128, 2/1],
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            var pythRatios = [1/1, 256/243, 9/8, 32/27, 81/64, 4/3, 729/512, 3/2, 128/81, 27/16, 16/9, 243/128, 2/1];
            var octave = (minFreq / baseFreq).log2.floor;
            var freqs = [];
            
            while { baseFreq * (2.pow(octave)) < maxFreq } {
                pythRatios.do { |ratio|
                    var freq = baseFreq * (2.pow(octave)) * ratio;
                    if(freq >= minFreq and: { freq <= maxFreq }) {
                        freqs = freqs.add(freq);
                    };
                };
                octave = octave + 1;
            };
            freqs;
        }
    )
);

// Amplitude envelope presets
~nUPIC[\amplitudePresets] = (
    fadeIn: { |width|
        var env = List.new;
        10.do { |i|
            env.add((x: i * width / 10, amp: i / 10));
        };
        env.add((x: width, amp: 1.0));
        env
    },
    
    fadeOut: { |width|
        var env = List.new;
        env.add((x: 0, amp: 1.0));
        10.do { |i|
            env.add((x: (i + 1) * width / 10, amp: 1.0 - ((i + 1) / 10)));
        };
        env
    },
    
    fadeInOut: { |width|
        var env = List.new;
        5.do { |i|
            env.add((x: i * width / 10, amp: i / 5));
        };
        5.do { |i|
            env.add((x: (i + 5) * width / 10, amp: 1.0 - (i / 5)));
        };
        env
    },
    
    constant: { |width|
        List[(x: 0, amp: 0.7), (x: width, amp: 0.7)]
    },
    
    pulse: { |width|
        var env = List.new;
        20.do { |i|
            var amp = if(i.even) { 0.9 } { 0.1 };
            env.add((x: i * width / 20, amp: amp));
        };
        env.add((x: width, amp: 0.1));
        env
    },
    
    swell: { |width|
        var env = List.new;
        var numSwells = 3;
        (numSwells * 20).do { |i|
            var phase = (i / 20 * 2pi);
            var amp = phase.sin.linlin(-1, 1, 0.1, 0.9);
            env.add((x: i * width / (numSwells * 20), amp: amp));
        };
        env
    },
    
    percussive: { |width|
        List[
            (x: 0, amp: 0.0),
            (x: width * 0.02, amp: 1.0),
            (x: width * 0.1, amp: 0.3),
            (x: width * 0.5, amp: 0.1),
            (x: width, amp: 0.0)
        ]
    },
    
    reverse: { |width|
        List[
            (x: 0, amp: 0.0),
            (x: width * 0.7, amp: 0.1),
            (x: width * 0.95, amp: 1.0),
            (x: width, amp: 0.0)
        ]
    }
);

"nUPIC constants and configuration loaded".postln;
)
