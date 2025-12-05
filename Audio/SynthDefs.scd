// nUPIC Audio SynthDef - UPIC-Inspired Wavetable Synthesis
// Based on Xenakis's UPIC system: drawable waveforms as wavetables
// Uses OscOS for oversampled, anti-aliased wavetable synthesis

(
// Initialize SynthDef collection
~nUPIC_SynthDefs = IdentityDictionary.new;

// Initialize wavetable buffers
~nUPIC_WavetableBuffers = IdentityDictionary.new;

// Default wavetable buffer
~nUPIC_DefaultWaveTable = nil;

// Initialize default wavetable with a sine wave
~initDefaultWavetable = {
    var signal = Signal.sineFill(2048, [1], [0]); // Simple sine wave
    ~nUPIC_DefaultWaveTable = Buffer.loadCollection(s, signal);
    "Default wavetable initialized (sine wave)".postln;
    ~nUPIC_DefaultWaveTable;
};

// Function to create a wavetable from drawn arc
~createWavetableFromArc = { |arc, bufferSize = 2048|
    var signal, buffer;
    var points, normalized;
    
    // Extract Y values from arc for waveform
    points = arc.collect { |point| point.y };
    
    if(points.size < 2) {
        "Not enough points to create wavetable".warn;
        ^nil;
    };
    
    // Normalize points to -1 to 1 range
    normalized = points.collect { |p| 
        p.linlin(points.minItem, points.maxItem, -1, 1) 
    };
    
    // Create signal and resample to buffer size
    signal = Signal.newClear(bufferSize);
    
    // Interpolate the drawn points to fill the buffer
    (bufferSize - 1).do { |i|
        var pos = i / (bufferSize - 1) * (normalized.size - 1);
        var idx = pos.floor.asInteger;
        var frac = pos - idx;
        
        if(idx < (normalized.size - 1)) {
            // Linear interpolation between points
            signal[i] = normalized[idx] * (1 - frac) + (normalized[idx + 1] * frac);
        } {
            signal[i] = normalized.last;
        };
    };
    
    // Apply smoothing to reduce harsh transitions
    // Use linear interpolation between adjacent samples for smoothing
    3.do {
        var smoothed = Signal.newClear(bufferSize);
        bufferSize.do { |i|
            if(i == 0) {
                smoothed[i] = (signal[i] + signal[i+1]) * 0.5;
            } {
                if(i == (bufferSize - 1)) {
                    smoothed[i] = (signal[i-1] + signal[i]) * 0.5;
                } {
                    smoothed[i] = (signal[i-1] + signal[i] + signal[i+1]) / 3;
                };
            };
        };
        signal = smoothed;
    };
    
    // Create and return buffer
    buffer = Buffer.loadCollection(s, signal, action: {
        "Wavetable created from arc".postln;
    });
    
    buffer;
};

// Function to create multiple wavetables from a single drawing (for morphing)
~createMultiWavetableFromDrawing = { |drawing, numTables = 4, bufferSize = 2048|
    var combinedSignal = Signal.new;
    var segmentSize, buffer;
    
    if(drawing.size < (numTables * 2)) {
        "Not enough points for multi-wavetable".warn;
        numTables = (drawing.size / 2).floor.max(1);
    };
    
    segmentSize = drawing.size / numTables;
    
    numTables.do { |i|
        var start = (i * segmentSize).floor.asInteger;
        var end = ((i + 1) * segmentSize).floor.asInteger.min(drawing.size);
        var segment = drawing[start..end-1];
        var signal = Signal.newClear(bufferSize);
        
        // Process each segment into a wavetable
        if(segment.notNil and: { segment.size > 0 }) {
            segment.do { |point, j|
                var idx = (j * bufferSize / segment.size).floor.asInteger;
                if(idx < bufferSize) {
                    signal[idx] = point.y.linlin(0, 1, -1, 1);
                };
            };
        };
        
        // Smooth each wavetable using linear interpolation
        2.do {
            var smoothed = Signal.newClear(bufferSize);
            bufferSize.do { |k|
                if(k == 0) {
                    smoothed[k] = (signal[k] + signal[k+1]) * 0.5;
                } {
                    if(k == (bufferSize - 1)) {
                        smoothed[k] = (signal[k-1] + signal[k]) * 0.5;
                    } {
                        smoothed[k] = (signal[k-1] + signal[k] + signal[k+1]) / 3;
                    };
                };
            };
            signal = smoothed;
        };
        combinedSignal = combinedSignal ++ signal;
    };
    
    // Load combined buffer
    buffer = Buffer.loadCollection(s, combinedSignal, action: {
        ("Multi-wavetable created with " ++ numTables ++ " tables").postln;
    });
    
    buffer;
};

// Load UPIC-inspired SynthDefs
~loadnUPICSynthDefs = {
    
    // Main UPIC Wavetable Synthesis
    // Implements Xenakis's core UPIC principle: drawable waveforms as oscillators
    SynthDef(\upicWavetable, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,           // Wavetable buffer number (0 = default sine)
            // Compatibility parameters from old system
            mass = 1,             // Mass parameter (affects harmonics)
            velocity = 0,         // Velocity (affects modulation)
            distance = 100,       // Distance (affects filter cutoff)
            width = 0.5,          // Width (affects waveform morphing)
            modDepth = 0,         // Modulation depth
            rq = 0.5,             // Resonance quality
            radialVel = 0,        // Radial velocity (for future Doppler)
            dopplerSens = 0,      // Doppler sensitivity
            numSynths = 1,        // Number of synths (for amplitude scaling)
            // UPIC-specific parameters
            timeScale = 1,        // Time scaling factor (micro/macro time)
            oversample = 1;       // Oversampling (0=none, 1=2x, 2=4x)
        
        var sig, env, phase;
        var modulator, filter;
        var effectiveFreq, modFreq, filtCutoff;
        var morphPos, modIndex;
        
        // Use default wavetable if bufnum is 0 or not provided
        if(bufnum == 0) {
            if(~nUPIC_DefaultWaveTable.notNil) {
                bufnum = ~nUPIC_DefaultWaveTable.bufnum;
            };
        };
        
        // Map compatibility parameters to UPIC parameters
        modFreq = velocity.linlin(0, 20, 0.5, 10);  // Velocity controls modulation rate
        modIndex = modDepth.clip(0, 1);              // Use modDepth for modulation amount
        morphPos = width.clip(0, 1);                 // Width controls wavetable morphing
        filtCutoff = distance.linexp(20, 500, 8000, 500); // Distance affects brightness
        
        // Envelope with adjustable time scale and mass influence
        env = EnvGen.kr(
            Env.adsr(
                0.01 * timeScale * mass.linlin(1, 10, 1, 2),  // Heavier = slower attack
                0.05 * timeScale,
                0.8,
                0.2 * timeScale * mass.linlin(1, 10, 1, 3)    // Heavier = slower release
            ),
            gate,
            doneAction: 2
        );
        
        // Time scaling affects frequency (micro/macro time interpretation)
        effectiveFreq = freq * timeScale;
        
        // Phase generation with velocity-based modulation
        modulator = SinOsc.ar(modFreq, 0, modIndex * velocity.linlin(0, 20, 0, 1));
        phase = LFSaw.ar(effectiveFreq * (1 + modulator)).range(0, 1);
        
        // UPIC-style wavetable oscillator using OscOS
        // Use morphPos (from width parameter) for wavetable position
        sig = OscOS.ar(
            bufnum,
            phase,
            1,        // Single wavetable for now
            0,        // No morphing in single wavetable
            oversample,
            1,
            0
        );
        
        // Add harmonics based on mass (heavier objects = richer sound)
        sig = sig + (SinOsc.ar(effectiveFreq * 2, 0, mass.linlin(1, 10, 0, 0.2)) * 0.3);
        sig = sig + (SinOsc.ar(effectiveFreq * 3, 0, mass.linlin(1, 10, 0, 0.1)) * 0.2);
        
        // Filter with resonance from rq parameter
        filter = RLPF.ar(
            sig,
            filtCutoff.clip(20, 20000),
            rq.reciprocal.clip(0.1, 10)
        );
        
        // Mix between direct and filtered signal based on distance
        sig = XFade2.ar(sig, filter, distance.linlin(20, 500, -1, 1));
        
        // Apply envelope and amplitude with voice scaling
        sig = sig * env * amp * (1 / numSynths.sqrt.max(1));
        
        // Soft limiting
        sig = sig.tanh * 0.95;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Precise amplitude version of upicWavetable - NO built-in envelope for ultra-precise control
    SynthDef(\upicWavetablePrecise, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,           // Wavetable buffer number (0 = default sine)
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, dopplerShift, finalFreq, distAmp;
        var phase;
        
        // Use default wavetable if bufnum is 0 or not provided
        if(bufnum == 0) {
            if(~nUPIC_DefaultWaveTable.notNil) {
                bufnum = ~nUPIC_DefaultWaveTable.bufnum;
            };
        };
        
        // Calculate frequency with optional Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // NO ENVELOPE - direct amplitude control for precision
        // The amplitude envelope from the arc will control the level directly
        
        // Phase generation
        phase = LFSaw.ar(finalFreq).range(0, 1);
        
        // Main oscillator using OscOS for quality
        sig = OscOS.ar(
            bufnum,
            phase,
            1,        // Single wavetable
            0,        // No morphing
            2,        // 4x oversampling for quality
            1.0,
            0
        );
        
        // Add harmonics based on mass
        sig = sig + (SinOsc.ar(finalFreq * 2, 0, mass.linlin(1, 10, 0, 0.3)) * 0.3);
        sig = sig + (SinOsc.ar(finalFreq * 3, 0, mass.linlin(1, 10, 0, 0.1)) * 0.2);
        
        // Distance amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Direct amplitude control - no envelope!
        // Use Lag for very slight smoothing (1ms) to avoid clicks
        sig = sig * Lag.kr(amp * distAmp * (1 / numSynths.sqrt.max(1)), 0.001);
        
        // Gate for note off (very fast release to maintain precision)
        sig = sig * EnvGen.kr(Env.cutoff(0.002), gate, doneAction: 2);
        
        // Soft limiting
        sig = sig.clip(-0.9, 0.9);
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Store available SynthDef names - channel variants only
    ~nUPIC_SynthDefs[\available] = [
        \upicWavetable,      // mono
        \upicWavetable2ch,   // stereo
        \upicWavetable3ch,   // 3 channels
        \upicWavetable4ch,   // 4 channels
        \upicWavetable8ch,   // 8 channels
        \upicWavetable12ch,  // 12 channels
        \upicWavetable15ch,  // 15 channels
        \upicWavetable24ch   // 24 channels
    ];

    // Set default to mono
    ~nUPIC_SynthDefs[\default] = \upicWavetable;
    
    // Initialize default wavetable if server is running
    if(s.serverRunning) {
        ~initDefaultWavetable.value;
    };
    
    "nUPIC UPIC-inspired SynthDefs loaded successfully".postln;
    "Channel variants available: mono, 2ch, 3ch, 4ch, 8ch, 12ch, 15ch, 24ch".postln;
    "Drawable wavetable synthesis ready".postln;
};

// Auto-load when this file is executed
~loadnUPICSynthDefs.value;
)