// upicWavetable SynthDef - Custom wavetable synthesizer for nUPIC
// Uses a buffer to store the wavetable that can be edited in real-time

(
// Global buffer for the wavetable (2048 samples for better quality)
// OscOS uses standard buffers, NOT wavetable format
fork {
    var initialWave;
    
    // Wait for server
    if(s.serverRunning.not) { 
        "Waiting for server to boot...".postln;
        s.waitForBoot;
    };
    
    // Check if buffer already exists
    if(~nUPIC_wavetableBuffer.isNil) {
        // Create initial sine wave - NO wavetable conversion for OscOS!
        initialWave = Signal.sineFill(2048, [1], [0]);
        
        // Allocate and load buffer with standard signal data
        ~nUPIC_wavetableBuffer = Buffer.loadCollection(s, initialWave);
        "Wavetable buffer created with sine wave (size: 2048)".postln;
    } {
        "Wavetable buffer already exists".postln;
    };
};

// Function to generate a random wavetable
~nUPIC_generateRandomWavetable = {
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal;
        
        // Create truly random/noisy wavetable
        signal = Signal.fill(2048, { rrand(-1.0, 1.0) });
        
        // Optional: very light smoothing to prevent extreme spikes
        // Comment out for completely raw noise
        /*
        signal = signal.collect { |val, i|
            var prev = signal[(i - 1) % 2048];
            var next = signal[(i + 1) % 2048];
            (prev + (val * 4) + next) / 6;  // Mostly preserves original
        };
        */
        
        // Normalize to prevent clipping
        signal = signal.normalize;
        
        // Send to buffer
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        
        "Generated random/noise wavetable with 2048 samples".postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate harmonic series wavetable
~nUPIC_generateHarmonicWavetable = { |numHarmonics = 8|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal;
        var harmonics = Array.fill(numHarmonics, { |i| 1.0 / (i + 1) });
        
        signal = Signal.sineFill(2048, harmonics);
        signal = signal.normalize;
        
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        ("Generated harmonic wavetable with " ++ numHarmonics ++ " harmonics").postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate Chebyshev polynomial wavetable
~nUPIC_generateChebyshevWavetable = { |coeffs|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal;
        
        // Default Chebyshev coefficients if none provided
        coeffs = coeffs ?? [1, 0.5, 0.3, 0.2, 0.1];
        
        // Use Signal.chebyFill for Chebyshev polynomials
        signal = Signal.chebyFill(2048, coeffs);
        signal = signal.normalize;
        
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        ("Generated Chebyshev wavetable with coefficients: " ++ coeffs).postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate formant-like wavetable
~nUPIC_generateFormantWavetable = { |freq1 = 700, freq2 = 1220, freq3 = 2600|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal = Signal.newClear(2048);
        var formants = [freq1, freq2, freq3];
        var amps = [1, 0.5, 0.3];
        var fundamental = 100; // Base frequency for formant ratios
        
        formants.do { |formant, i|
            var harmonic = (formant / fundamental).round;
            if(harmonic < 1024) {
                signal = signal + Signal.sineFill(2048, 
                    Array.fill(harmonic, 0) ++ [amps[i]]
                );
            };
        };
        
        signal = signal.normalize;
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        ("Generated formant wavetable with formants at " ++ formants).postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate pulse width modulated wavetable
~nUPIC_generatePulseWavetable = { |width = 0.5|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal;
        var pulsePos = (2048 * width).asInteger;
        
        signal = Signal.fill(2048, { |i|
            if(i < pulsePos, 1, -1)
        });
        
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        ("Generated pulse wavetable with width " ++ width).postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate FM synthesis-like wavetable
~nUPIC_generateFMWavetable = { |carrier = 1, modulator = 3.7, index = 4|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal = Signal.fill(2048, { |i|
            var phase = i / 2048 * 2pi;
            sin(carrier * phase + (index * sin(modulator * phase)))
        });
        
        signal = signal.normalize;
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        ("Generated FM wavetable - carrier:" ++ carrier ++ " modulator:" ++ modulator ++ " index:" ++ index).postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate waveshaping wavetable (transfer function)
~nUPIC_generateWaveshapeWavetable = { |type = \tanh|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal = Signal.fill(2048, { |i|
            var x = i.linlin(0, 2047, -1, 1);
            type.switch(
                \tanh, { x.tanh },
                \clip, { x.clip(-0.5, 0.5) * 2 },
                \fold, { x.fold(-0.7, 0.7) * 1.4 },
                \wrap, { x.wrap(-0.5, 0.5) * 2 },
                \asymmetric, { if(x > 0, x.sqrt, x.cubed.neg) },
                \polynomial, { (3 * x) - x.cubed }, // Chebyshev T3
                { x } // Linear default
            )
        });
        
        signal = signal.normalize;
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        ("Generated waveshaping wavetable: " ++ type).postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Function to set a custom wavetable from an array
~nUPIC_setWavetable = { |array|
    if(~nUPIC_wavetableBuffer.notNil) {
        var signal;
        
        if(array.size != 2048) {
            ("Warning: Wavetable should be 2048 samples, got " ++ array.size ++ ". Resampling...").postln;
            array = array.resamp1(2048);
        };
        
        // Convert to Signal - NO wavetable format for OscOS
        signal = Signal.newFrom(array);
        
        ~nUPIC_wavetableBuffer.loadCollection(signal);
        "Custom wavetable loaded".postln;
    } {
        "WARNING: Buffer not initialized".postln;
    };
};

// Generate a random wavetable after buffer is ready
fork {
    1.wait;  // Wait for buffer allocation
    ~nUPIC_generateRandomWavetable.value;
};

// The upicWavetable SynthDef with 4x oversampling for anti-aliasing
SynthDef(\upicWavetable, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0,  // Buffer number for wavetable - default to 0
        detune = 1.0, filterFreq = 4000, resonance = 1;
    
    var sig, env, dopplerShift, finalFreq, distAmp;
    var phase;
    
    // Calculate frequency with optional Doppler
    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);
    
    // Very short envelope just to prevent clicks
    env = EnvGen.kr(
        Env.asr(0.002, 1, 0.002),  // Super short attack/release
        gate,
        doneAction: 2
    );
    
    // Single phase for raw sound
    phase = Phasor.ar(0, finalFreq / SampleRate.ir, 0, 1);
    
    // Raw oscillator output - no filtering, no processing
    // Use OscOS with 4x oversampling (oversample: 2 = 4x)
    sig = OscOS.ar(bufnum, phase, 1, 0, 2, 1.0);
    
    // Optional: Add very subtle detuning for richness without filtering
    // Uncomment if you want some stereo width
    // sig = sig + (OscOS.ar(bufnum, Phasor.ar(0, (finalFreq * 1.001) / SampleRate.ir, 0, 1), 1, 0, 2, 0.3));
    
    // Distance amplitude (keep this for spatial positioning)
    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    
    // Apply amplitude with voice scaling
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    
    // Very gentle soft limiting to prevent harsh digital clipping
    // Use a higher threshold for less coloration
    sig = sig.clip(-0.95, 0.95);

    // Mono output to bus 0
    Out.ar(0, sig);
}).add;

// ============================================================
// MULTI-CHANNEL VERSIONS
// ============================================================

// 2-channel (stereo) version with Pan2
SynthDef(\upicWavetable2ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, Pan2.ar(sig, pan));
}).add;

// 3-channel version with PanAz
SynthDef(\upicWavetable3ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, PanAz.ar(3, sig, pan, 1, width));
}).add;

// 4-channel version with PanAz
SynthDef(\upicWavetable4ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, PanAz.ar(4, sig, pan, 1, width));
}).add;

// 8-channel version with PanAz
SynthDef(\upicWavetable8ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, PanAz.ar(8, sig, pan, 1, width));
}).add;

// 12-channel version with PanAz
SynthDef(\upicWavetable12ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, PanAz.ar(12, sig, pan, 1, width));
}).add;

// 15-channel version with PanAz
SynthDef(\upicWavetable15ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, PanAz.ar(15, sig, pan, 1, width));
}).add;

// 24-channel version with PanAz
SynthDef(\upicWavetable24ch, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        bufnum = 0;

    var sig, phase, env, dopplerShift, finalFreq, distAmp;

    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    phase = LFSaw.ar(finalFreq).range(0, 1);
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
    sig = sig.tanh * 0.9;

    Out.ar(0, PanAz.ar(24, sig, pan, 1, width));
}).add;

"✓ upicWavetable SynthDef loaded (mono)".postln;
"✓ upicWavetable2ch SynthDef loaded (stereo)".postln;
"✓ upicWavetable3ch SynthDef loaded".postln;
"✓ upicWavetable4ch SynthDef loaded".postln;
"✓ upicWavetable8ch SynthDef loaded".postln;
"✓ upicWavetable12ch SynthDef loaded".postln;
"✓ upicWavetable15ch SynthDef loaded".postln;
"✓ upicWavetable24ch SynthDef loaded".postln;
"✓ All channel variants loaded successfully!".postln;
)
