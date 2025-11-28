// Advanced nUPIC SynthDefs with Oversampled Oscillators
// High-quality synthesis using OS (oversampled) UGens where available
// Based on modern synthesis techniques

(
"=== Loading Advanced OS-based SynthDefs for nUPIC ===".postln;
"".postln;

s.waitForBoot {
    "Server ready, loading high-quality SynthDefs...".postln;
    
    s.sync;
    
    // Advanced Pulsar Train synthesis with oversampling
    SynthDef(\pulsarTrain, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            formFreq = 2000, pulsarRate = 10;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var formant, pulsar, carrier;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Calculate Doppler-shifted frequency
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Multi-stage envelope for smooth note on/off
        env = EnvGen.kr(
            Env.adsr(0.005, 0.05, 0.8, 0.2),
            gate,
            doneAction: 2
        );
        
        // Pulsar train synthesis
        // Use oversampled oscillators for carrier
        carrier = SinOscOS.ar(finalFreq, 0, 1, 4); // 4x oversampling
        
        // Formant oscillator for spectral shaping
        formant = SinOscOS.ar(
            formFreq + (velocity * 100), // Velocity modulates formant
            0, 1, 4
        );
        
        // Pulsar modulation
        pulsar = LFPulse.ar(
            pulsarRate + (massNorm * 20), // Mass affects pulse rate
            0,
            width
        );
        
        // Combine components
        sig = carrier * formant * pulsar;
        
        // Add harmonics using oversampled oscillators
        sig = sig + (SawOS.ar(finalFreq * 2, 0.2 * massNorm, 4) * 0.3);
        sig = sig + (SawOS.ar(finalFreq * 3, 0.1 * massNorm, 4) * 0.2);
        
        // Distance-based filtering and amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = LPF.ar(sig, (finalFreq * 4).min(15000) * distAmp);
        
        // Apply amplitude scaling
        sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
        
        // Soft limiting with tanh
        sig = sig.tanh * 0.9;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ pulsarTrain loaded (advanced pulsar synthesis)".postln;
    
    // Granular-inspired oscillator bank with oversampling
    SynthDef(\grainBank, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            grainDensity = 20, grainDur = 0.05;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var grains, trigger, grainEnv;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Calculate Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Main envelope
        env = EnvGen.kr(
            Env.adsr(0.01, 0.1, 0.7, 0.3),
            gate,
            doneAction: 2
        );
        
        // Grain trigger
        trigger = Impulse.ar(grainDensity + (velocity * 5));
        
        // Grain envelope
        grainEnv = EnvGen.ar(
            Env.perc(0.001, grainDur),
            trigger
        );
        
        // Multiple oversampled oscillators for grains
        grains = Mix.ar([
            SinOscOS.ar(finalFreq, 0, grainEnv * 0.3, 4),
            SinOscOS.ar(finalFreq * 1.5, 0, grainEnv * 0.2 * massNorm, 4),
            SawOS.ar(finalFreq * 0.5, grainEnv * 0.2 * (1 - massNorm), 4),
            TriOS.ar(finalFreq * 2, grainEnv * 0.1, 4)
        ]);
        
        // Add continuous tone for stability
        sig = grains + (SinOscOS.ar(finalFreq, 0, 0.1, 4) * env);
        
        // Resonant filter sweep based on mass
        sig = RLPF.ar(sig, 
            finalFreq * (2 + (massNorm * 6)), 
            0.5 - (massNorm * 0.3)
        );
        
        // Distance effects
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Apply scaling
        sig = sig * amp * env * distAmp * (0.7 / numSynths.sqrt.max(1));
        
        // Compression and limiting
        sig = Compander.ar(sig, sig, 0.5, 1, 0.5, 0.01, 0.1);
        sig = sig.tanh * 0.85;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ grainBank loaded (granular synthesis bank)".postln;
    
    // FM synthesis with oversampled carriers
    SynthDef(\fmCascade, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            modIndex = 2, modRatio = 1.5;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var carrier, modulator1, modulator2, modEnv;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Complex envelope
        env = EnvGen.kr(
            Env.adsr(0.002, 0.1, 0.6, 0.5),
            gate,
            doneAction: 2
        );
        
        // Modulation envelope (faster)
        modEnv = EnvGen.kr(
            Env.perc(0.001, 0.5),
            gate
        );
        
        // Cascade FM synthesis with oversampled oscillators
        modulator2 = SinOscOS.ar(
            finalFreq * modRatio * 2,
            0,
            modIndex * 100 * massNorm,
            4
        );
        
        modulator1 = SinOscOS.ar(
            finalFreq * modRatio + modulator2,
            0,
            modIndex * 200 * modEnv,
            4
        );
        
        carrier = SinOscOS.ar(
            finalFreq + modulator1,
            0,
            1,
            4
        );
        
        sig = carrier;
        
        // Add sidebands for richness
        sig = sig + (SinOscOS.ar(finalFreq * 0.5, 0, 0.2, 4) * (1 - massNorm));
        sig = sig + (SawOS.ar(finalFreq * 4, 0.1 * massNorm, 4));
        
        // Velocity adds vibrato
        sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 8)) * 0.05));
        
        // Distance filtering
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = LPF.ar(sig, (finalFreq * 8).min(18000) * distAmp);
        
        // Amplitude scaling
        sig = sig * amp * env * distAmp * (0.3 / numSynths.sqrt.max(1));
        
        // Soft clipping
        sig = sig.softclip * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ fmCascade loaded (FM synthesis with oversampling)".postln;
    
    // Additive synthesis with oversampled partials
    SynthDef(\additiveOS, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            numPartials = 8;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var partials, partialAmps, partialFreqs;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Envelope
        env = EnvGen.kr(
            Env.adsr(0.01, 0.15, 0.7, 0.4),
            gate,
            doneAction: 2
        );
        
        // Generate additive synthesis with oversampled oscillators
        partials = numPartials.collect { |i|
            var harmonic = i + 1;
            var detune = 1 + (LFNoise2.kr(0.1 + (i * 0.1)).range(-0.001, 0.001));
            var ampScale = (1 / harmonic) * (1 - (i * 0.05)).max(0);
            
            // Use different OS oscillators for different harmonics
            if(i.even, {
                SinOscOS.ar(
                    finalFreq * harmonic * detune,
                    0,
                    ampScale * (1 - (massNorm * i * 0.1)).max(0),
                    4
                )
            }, {
                TriOS.ar(
                    finalFreq * harmonic * detune,
                    ampScale * (massNorm * (1 - (i * 0.05))).max(0),
                    4
                )
            })
        };
        
        sig = Mix.ar(partials);
        
        // Add sub-harmonic for depth
        sig = sig + (SinOscOS.ar(finalFreq * 0.5, 0, 0.2 * (1 - massNorm), 4));
        
        // Velocity modulation
        sig = sig * (1 + (LFTri.kr(velocity * 0.5) * 0.1));
        
        // Distance effects
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = BPF.ar(sig, finalFreq * 2, 2 / distAmp.max(0.5));
        
        // Amplitude
        sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
        
        // Limiting
        sig = Limiter.ar(sig, 0.95, 0.01) * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ additiveOS loaded (additive synthesis with oversampling)".postln;
    
    // Simple but high-quality reference synth
    SynthDef(\simpleOS, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        
        // Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        // Simple oversampled oscillator
        sig = SinOscOS.ar(finalFreq, 0, 1, 4);
        
        // Distance
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Output
        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ simpleOS loaded (simple oversampled reference)".postln;
    
    s.sync;
    
    "".postln;
    "All advanced SynthDefs loaded!".postln;
    
    // Update registry
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [
        \pulsarTrain,   // Advanced pulsar synthesis
        \grainBank,     // Granular synthesis
        \fmCascade,     // FM synthesis
        \additiveOS,    // Additive synthesis
        \simpleOS       // Simple reference
    ];
    ~nUPIC_SynthDefs[\default] = \pulsarTrain;
    
    // Update nUPIC defaults if loaded
    if(~nUPIC.notNil) {
        if(~nUPIC[\defaults].isNil) {
            ~nUPIC[\defaults] = IdentityDictionary.new;
        };
        ~nUPIC[\defaults][\defaultSynthDef] = \pulsarTrain;
        "✓ nUPIC defaults updated".postln;
    };
    
    "".postln;
    "Testing advanced SynthDefs...".postln;
    
    fork {
        [\pulsarTrain, \grainBank, \fmCascade, \additiveOS, \simpleOS].do { |name|
            var synth;
            
            ("Testing " ++ name ++ "...").postln;
            
            synth = Synth(name, [
                \freq, 440,
                \amp, 0.05,
                \pan, 0,
                \gate, 1,
                \mass, 5,
                \velocity, 10,
                \distance, 50,
                \numSynths, 1
            ]);
            
            if(synth.notNil) {
                ("  ✓ " ++ name ++ " created").postln;
                0.3.wait;
                
                // Test parameter changes
                synth.set(\freq, 660);
                0.3.wait;
                synth.set(\mass, 8);
                0.3.wait;
                synth.set(\gate, 0);
                0.5.wait;
            };
        };
        
        "".postln;
        "=== Advanced SynthDef Tests Complete ===".postln;
        "".postln;
        "These high-quality SynthDefs use oversampled oscillators for:".postln;
        "• Reduced aliasing".postln;
        "• Cleaner high frequencies".postln;
        "• Better sound quality at high pitches".postln;
        "".postln;
        "To use with nUPIC:".postln;
        "1. Load this file first: \"synthdefs_advanced_OS.scd\".load".postln;
        "2. Then load nUPIC: \"nUPIC_Main.scd\".load".postln;
        "".postln;
        "Or test individually:".postln;
        "(
var s = Synth(\\pulsarTrain, [\\freq, 440, \\amp, 0.1, \\gate, 1]);
fork { 2.wait; s.set(\\gate, 0); };
)".postln;
    };
};
)
