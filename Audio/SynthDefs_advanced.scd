// nUPIC Audio SynthDefs - Advanced Version with Oversampled Oscillators
// High-quality synthesis using OS (oversampled) UGens for reduced aliasing
// Part of the nUPIC (nu-UPIC) system inspired by Xenakis' UPIC

(
// Initialize SynthDef collection
~nUPIC_SynthDefs = IdentityDictionary.new;

// Load all SynthDefs for nUPIC
~loadnUPICSynthDefs = {

    // Advanced Pulsar Train synthesis - inspired by Curtis Roads' microsound techniques
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
        carrier = SinOscOS.ar(finalFreq, 0, 1, 4); // 4x oversampling
        
        // Formant oscillator for spectral shaping
        formant = SinOscOS.ar(
            formFreq + (velocity * 100),
            0, 1, 4
        );
        
        // Pulsar modulation
        pulsar = LFPulse.ar(
            pulsarRate + (massNorm * 20),
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

    // FM synthesis with oversampled carriers for clean modulation
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

    // Additive synthesis with oversampled partials for rich harmonics
    SynthDef(\additiveOS, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            numPartials = 8;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var partials;
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

    // Simple oversampled reference synth for comparison
    SynthDef(\simpleOS, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        // Simple oversampled oscillator with harmonics
        sig = Mix.ar([
            SinOscOS.ar(finalFreq, 0, 1, 4),
            SinOscOS.ar(finalFreq * 2, 0, 0.3 * massNorm, 4),
            SinOscOS.ar(finalFreq * 3, 0, 0.1 * massNorm, 4)
        ]);
        
        // Distance
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Output
        sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Backwards compatibility - simple working synth without OS
    SynthDef(\simpleGravObject, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        
        // All variables declared at top
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        // Simple design that works
        sig = SinOsc.ar(finalFreq) * 0.5;
        sig = sig + (SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1));
        
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Store available SynthDef names
    ~nUPIC_SynthDefs[\available] = [
        \pulsarTrain,      // Advanced pulsar synthesis (default)
        \fmCascade,        // FM synthesis
        \additiveOS,       // Additive synthesis  
        \simpleOS,         // Simple oversampled
        \simpleGravObject  // Backwards compatibility
    ];
    
    // Set default to the high-quality pulsar train
    ~nUPIC_SynthDefs[\default] = \pulsarTrain;

    "nUPIC Advanced SynthDefs loaded successfully".postln;
    "Using oversampled oscillators for high-quality sound".postln;
};

// Auto-load when this file is executed
~loadnUPICSynthDefs.value;
)
