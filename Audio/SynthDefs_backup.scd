// nUPIC Audio SynthDef - UPIC-Inspired Wavetable Synthesis
// Based on Xenakis's UPIC system: drawable waveforms as wavetables
// Part of the nUPIC (nu-UPIC) system

(
// Initialize SynthDef collection
~nUPIC_SynthDefs = IdentityDictionary.new;

// Initialize wavetable buffers (will be filled by drawn trajectories)
~nUPIC_WavetableBuffers = IdentityDictionary.new;

// Create default wavetable buffer
~nUPIC_DefaultWaveTable = nil;

// Initialize default wavetable with a sine wave
~initDefaultWavetable = {
    var signal = Signal.sineFill(2048, [1], [0]); // Simple sine wave
    ~nUPIC_DefaultWaveTable = Buffer.loadCollection(s, signal);
    "Default wavetable initialized (sine wave)".postln;
    ~nUPIC_DefaultWaveTable;
};

// Function to create a wavetable from drawn points (trajectory)
~createWavetableFromTrajectory = { |trajectory, bufferSize = 2048|
    var signal, buffer;
    var points, normalized;
    
    // Extract Y values from trajectory for waveform
    points = trajectory.collect { |point| point.y };
    
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
    3.do { signal = signal.smooth };
    
    // Create and return buffer
    buffer = Buffer.loadCollection(s, signal, action: {
        "Wavetable created from trajectory".postln;
    });
    
    buffer;
};

// Load UPIC-inspired SynthDef
~loadnUPICSynthDefs = {
    
    // UPIC Wavetable Synthesis - Core synthesis method of Xenakis's UPIC
    // Uses OscOS for oversampled, anti-aliased wavetable playback
    SynthDef(\upicWavetable, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,           // Wavetable buffer number
            timeScale = 1,         // Time scaling (micro to macro time)
            modIndex = 0,          // Modulation depth for FM/AM
            modFreq = 5,           // Modulation frequency
            filtCutoff = 4,        // Filter cutoff multiplier
            resonance = 0.5;       // Filter resonance

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

    // Granular synthesis bank
    SynthDef(\grainBank, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            grainDur = 0.05, grainRate = 20;

        var sig, env, dopplerShift, finalFreq, distAmp;
        var grainTrig, grainEnv, grains;
        var massNorm = (mass / 10).clip(0, 1);

        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);

        env = EnvGen.kr(
            Env.adsr(0.01, 0.1, 0.7, 0.5),
            gate,
            doneAction: 2
        );

        grainTrig = Impulse.ar(grainRate + (velocity * 2));

        grains = 5.collect { |i|
            var freqMod = 1 + (i * 0.1 * massNorm);
            var phaseMod = LFNoise2.kr(0.5).range(0, 2pi);

            grainEnv = EnvGen.ar(
                Env.perc(0.001, grainDur),
                grainTrig,
                timeScale: LFNoise1.kr(1).range(0.8, 1.2)
            );

            SinOsc.ar(
                finalFreq * freqMod + LFNoise2.ar(100, 50 * massNorm),
                phaseMod
            ) * grainEnv * (1/(i+1))
        };

        sig = Mix.ar(grains);
        sig = sig + (WhiteNoise.ar(0.01 * massNorm) * env);

        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = LPF.ar(sig, (finalFreq * 8).min(15000) * distAmp);

        sig = sig * amp * env * distAmp * (0.4 / numSynths.sqrt.max(1));
        sig = sig.softclip * 0.9;

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

        // Generate additive synthesis - using Array.fill for better reliability
        partials = Mix.ar(
            Array.fill(8, { |i|
                var harmonic = i + 1;
                var detune = 1 + (LFNoise2.kr(0.1 + (i * 0.1)).range(-0.001, 0.001));
                var ampScale = (1 / harmonic) * (1 - (i * 0.05)).max(0);

                // Use standard oscillators to avoid issues with OS UGens in arrays
                SinOsc.ar(
                    finalFreq * harmonic * detune,
                    0,
                    ampScale * (1 - (massNorm * i * 0.1)).max(0)
                )
            })
        );

        sig = partials;

        // Add sub-harmonic for depth (using standard oscillator)
        sig = sig + (SinOsc.ar(finalFreq * 0.5, 0, 0.2 * (1 - massNorm)));

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
            SawOS.ar(finalFreq, 0, 1, 4),
            SawOS.ar(finalFreq * 2, 0, 0.3 * massNorm, 4),
            SawOS.ar(finalFreq * 3, 0, 0.1 * massNorm, 4)
        ]);

        // Distance
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);

        // Output
        sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;

        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // FM Organ synthesis - Hammond-inspired
    SynthDef(\fmOrgan, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            // Organ-specific parameters (drawbar positions 0-1)
            draw16 = 0.8, draw8 = 1.0, draw513 = 0.7, draw4 = 0.6,
            draw223 = 0.4, draw2 = 0.3, draw135 = 0.2, draw113 = 0.2, draw1 = 0.1,
            vibrato = 0.3, rotary = 0.5;

        var sig, env, dopplerShift, finalFreq, distAmp;
        var drawbarSignals, carrier, modulator;
        var massNorm = (mass / 10).clip(0, 1);
        var vibratoLFO, rotaryLFO;

        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);

        // Organ envelope - quick attack, full sustain
        env = EnvGen.kr(
            Env.adsr(0.002, 0.01, 1.0, 0.3),
            gate,
            doneAction: 2
        );

        // Vibrato/Chorus LFO
        vibratoLFO = SinOsc.kr(6.5 + (velocity * 0.5)) * vibrato * 0.01;

        // Rotary speaker simulation
        rotaryLFO = SinOsc.kr(
            Select.kr(velocity > 10, [0.7, 5.5])
        ) * rotary;

        // Generate drawbar harmonics
        drawbarSignals = [
            SinOsc.ar(finalFreq * 0.5 * (1 + vibratoLFO)) * draw16,
            SinOsc.ar(finalFreq * (1 + vibratoLFO)) * draw8,
            SinOsc.ar(finalFreq * 1.5 * (1 + vibratoLFO)) * draw513,
            SinOsc.ar(finalFreq * 2 * (1 + vibratoLFO)) * draw4,
            SinOsc.ar(finalFreq * 3 * (1 + vibratoLFO)) * draw223,
            SinOsc.ar(finalFreq * 4 * (1 + vibratoLFO)) * draw2,
            SinOsc.ar(finalFreq * 5 * (1 + vibratoLFO)) * draw135,
            SinOsc.ar(finalFreq * 6 * (1 + vibratoLFO)) * draw113,
            SinOsc.ar(finalFreq * 8 * (1 + vibratoLFO)) * draw1
        ];

        sig = Mix.ar(drawbarSignals);

        // Add FM modulation for extra harmonics
        modulator = SinOsc.ar(finalFreq * 2.01, 0, finalFreq * 0.5 * massNorm);
        carrier = SinOsc.ar(finalFreq + modulator);
        sig = sig + (carrier * 0.2);

        // Add key click
        sig = sig + (
            WhiteNoise.ar(0.01) *
            EnvGen.kr(Env.perc(0.0001, 0.005), gate)
        );

        sig = sig * 0.3;
        sig = LPF.ar(sig, 4000 + (mass * 2000));
        sig = sig * (1 + (rotaryLFO * 0.3));
        sig = Pan2.ar(sig, pan + (rotaryLFO * width * 0.5));

        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = sig * amp * env * distAmp * (0.7 / numSynths.sqrt.max(1));
        sig = (sig * 1.5).tanh * 0.8;

        Out.ar(0, sig);
    }).add;

    // Simple organ preset
    SynthDef(\simpleOrgan, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;

        var sig, env, dopplerShift, finalFreq, distAmp;
        var vibrato;

        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);

        env = EnvGen.kr(
            Env.adsr(0.002, 0.01, 1.0, 0.3),
            gate,
            doneAction: 2
        );

        vibrato = SinOsc.kr(5.5) * 0.005 * velocity.linlin(0, 20, 0, 1);

        // Classic organ sound with just a few drawbars
        sig = Mix.ar([
            SinOsc.ar(finalFreq * 0.5 * (1 + vibrato)) * 0.3,
            SinOsc.ar(finalFreq * (1 + vibrato)) * 1.0,
            SinOsc.ar(finalFreq * 2 * (1 + vibrato)) * 0.5,
            SinOsc.ar(finalFreq * 3 * (1 + vibrato)) * 0.3,
            SinOsc.ar(finalFreq * 4 * (1 + vibrato)) * 0.2,
            SinOsc.ar(finalFreq * 6 * (1 + vibrato)) * 0.1
        ]);

        sig = sig * 0.3;
        sig = LPF.ar(sig, 2000 + (mass * 3000));

        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = sig * amp * env * distAmp * (0.8 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;

        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // VarSawOS gravitational object synth with Doppler effect from MultiObjectBarycenterSonification.scd
    SynthDef(\simpleGravObject, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;
        var env, numSynths, gate;

        // Get parameters with safe defaults and add smoothing via lag filters
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.01);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.1);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.05);
        gate = \gate.kr(1);
        numSynths = \numSynths.kr(1);

        // DOPPLER EFFECT:
        // Radial velocity component (+ = moving away, - = moving towards barycenter)
        radialVelocity = Lag.kr(\radialVel.kr(0).clip(-20, 20), 0.2); // Increased lag for smoothing
        dopplerSensitivity = \dopplerSens.kr(1.0).clip(0, 3.0);

        // Anti-flicker: reduce Doppler effect when very close to barycenter
        dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1); // Fade out Doppler near barycenter

        // Doppler frequency shift: f' = f * (c + vr) / c
        // Simplified for audio: audible shifts based on radial velocity
        dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05); // Increased shift rate for audibility
        dopplerShift = dopplerShift.clip(0.5, 2.0); // Larger shift range ±100% for clear effect
        dopplerFreq = freq * dopplerShift;
        
        // Envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );

        // SOUND GENERATION:
        // 1. Base oscillator - VarSawOS with Doppler-shifted frequency
        sig = VarSawOS.ar(dopplerFreq, width: width, oversample: 4) * 0.4;

        // 2. Mass affects harmonics - bigger mass = more harmonics (also Doppler-shifted)
        sig = sig + (VarSawOS.ar(dopplerFreq * 2, width: width * 0.8, oversample: 4) * mass.linlin(0.1, 5, 0, 0.15));

        // 3. Velocity affects frequency modulation - faster = more wobble
        sig = sig * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));

        // 4. Distance affects brightness - closer = brighter
        sig = LPF.ar(sig, dopplerFreq * distance.linlin(20, 500, 3, 1));

        // Apply amplitude with envelope and numSynths scaling
        sig = sig * amp * env * (1 / numSynths.sqrt.max(1));

        // Safety limiter to prevent clipping
        sig = sig.tanh;

        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Percussive VarSawOS gravitational object with sharp click attack
    SynthDef(\percussiveGravObject, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;
        var env, clickEnv, numSynths, gate;
        var click, body, transient;
        
        // Get parameters with safe defaults and add smoothing via lag filters
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.01);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.1);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.05);
        gate = \gate.kr(1);
        numSynths = \numSynths.kr(1);
        
        // DOPPLER EFFECT:
        radialVelocity = Lag.kr(\radialVel.kr(0).clip(-20, 20), 0.2);
        dopplerSensitivity = \dopplerSens.kr(1.0).clip(0, 3.0);
        dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1);
        dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05);
        dopplerShift = dopplerShift.clip(0.5, 2.0);
        dopplerFreq = freq * dopplerShift;
        
        // PERCUSSIVE ENVELOPE with sharp attack and sustained body
        env = EnvGen.kr(
            Env(
                [0, 1, 0.7, 0.7, 0],
                [0.001, 0.01, 0.5, 0.2],
                [2, -4, 0, -2],
                3
            ),
            gate,
            doneAction: 2
        );
        
        // Click envelope - very sharp transient
        clickEnv = EnvGen.kr(
            Env.perc(0.0001, 0.005, 1, -8),
            gate
        );
        
        // CLICK GENERATION - sharp transient
        click = WhiteNoise.ar(clickEnv * 0.3);
        click = HPF.ar(click, 2000 + (freq * 2));
        click = click + (Impulse.ar(0, 0, clickEnv * 0.5));
        transient = SinOsc.ar(dopplerFreq * 4) * clickEnv * 0.2;
        transient = transient + (SinOsc.ar(dopplerFreq * 8) * clickEnv * 0.1);
        click = (click + transient) * (1 + (mass * 0.2));
        
        // BODY GENERATION - sustained tone
        body = VarSawOS.ar(dopplerFreq, width: width, oversample: 4) * 0.4;
        body = body + (VarSawOS.ar(dopplerFreq * 2, width: width * 0.8, oversample: 4) * mass.linlin(0.1, 5, 0, 0.15));
        body = body * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));
        body = LPF.ar(body, dopplerFreq * distance.linlin(20, 500, 3, 1));
        body = body * env;
        
        // COMBINE click and body
        sig = click + body;
        sig = sig * amp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Metallic percussive version
    SynthDef(\metallicGravObject, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;
        var env, clickEnv, numSynths, gate;
        var click, body, ring;
        
        // Parameters
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.01);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.1);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.05);
        gate = \gate.kr(1);
        numSynths = \numSynths.kr(1);
        
        // Doppler
        radialVelocity = Lag.kr(\radialVel.kr(0).clip(-20, 20), 0.2);
        dopplerSensitivity = \dopplerSens.kr(1.0).clip(0, 3.0);
        dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1);
        dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05);
        dopplerShift = dopplerShift.clip(0.5, 2.0);
        dopplerFreq = freq * dopplerShift;
        
        // Envelope with sharp metallic attack
        env = EnvGen.kr(
            Env(
                [0, 1, 0.5, 0.5, 0],
                [0.0001, 0.02, 0.5, 0.3],
                [4, -6, 0, -2],
                3
            ),
            gate,
            doneAction: 2
        );
        
        // Metallic click envelope
        clickEnv = EnvGen.kr(
            Env.perc(0.00001, 0.01, 1, -12),
            gate
        );
        
        // METALLIC CLICK
        click = Impulse.ar(0, 0, 1);
        click = CombL.ar(click, 0.1, 1/dopplerFreq, 0.03);
        click = click * SinOsc.ar(dopplerFreq * 7.5);
        click = click * clickEnv * 0.5;
        ring = Mix.ar([
            SinOsc.ar(dopplerFreq * 3.7) * 0.2,
            SinOsc.ar(dopplerFreq * 5.3) * 0.15,
            SinOsc.ar(dopplerFreq * 7.1) * 0.1
        ]) * clickEnv;
        click = click + ring;
        click = click * (1 + (mass * 0.3));
        
        // BODY
        body = VarSawOS.ar(dopplerFreq, width: width, oversample: 4) * 0.3;
        body = body + (VarSawOS.ar(dopplerFreq * 2, width: width * 0.8, oversample: 4) * mass.linlin(0.1, 5, 0, 0.12));
        body = body * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));
        body = LPF.ar(body, dopplerFreq * distance.linlin(20, 500, 3, 1));
        body = body * env;
        
        // Combine
        sig = click + body;
        sig = sig * amp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Drum-like percussive version
    SynthDef(\drumGravObject, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;
        var env, clickEnv, pitchEnv, numSynths, gate;
        var click, body, punch;
        
        // Parameters
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.01);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.1);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.05);
        gate = \gate.kr(1);
        numSynths = \numSynths.kr(1);
        
        // Doppler
        radialVelocity = Lag.kr(\radialVel.kr(0).clip(-20, 20), 0.2);
        dopplerSensitivity = \dopplerSens.kr(1.0).clip(0, 3.0);
        dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1);
        dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05);
        dopplerShift = dopplerShift.clip(0.5, 2.0);
        dopplerFreq = freq * dopplerShift;
        
        // Drum-like envelope
        env = EnvGen.kr(
            Env(
                [0, 1, 0.3, 0.3, 0],
                [0.0005, 0.03, 0.5, 0.2],
                [8, -4, 0, -2],
                3
            ),
            gate,
            doneAction: 2
        );
        
        // Click/punch envelope
        clickEnv = EnvGen.kr(
            Env.perc(0.0001, 0.002, 1, -12),
            gate
        );
        
        // Pitch envelope for drum-like pitch sweep
        pitchEnv = EnvGen.kr(
            Env.perc(0.0001, 0.05, 1, -4),
            gate
        );
        
        // DRUM CLICK/PUNCH
        punch = SinOsc.ar(50 + (mass * 20)) * clickEnv * 0.5;
        click = WhiteNoise.ar(clickEnv * 0.2);
        click = BPF.ar(click, dopplerFreq * 2, 0.5);
        click = click + (SinOsc.ar(dopplerFreq * (1 + pitchEnv)) * clickEnv * 0.3);
        click = punch + click;
        
        // BODY
        body = VarSawOS.ar(dopplerFreq, width: width, oversample: 4) * 0.25;
        body = body + (SinOsc.ar(dopplerFreq * 0.5) * mass.linlin(0.1, 5, 0, 0.2));
        body = body * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));
        body = LPF.ar(body, dopplerFreq * distance.linlin(20, 500, 2, 0.5));
        body = body * env;
        
        // Combine
        sig = click + body;
        sig = sig * amp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // SawBL-based synth with band-limited sawtooth
    SynthDef(\sawBLSynth, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            detune = 0.01, filterCutoff = 4, resonance = 0.5;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var saw1, saw2, saw3, subOsc, filter;
        var massNorm = (mass / 10).clip(0, 1);
        var velNorm = velocity.clip(0, 1000) / 1000;
        
        // Calculate Doppler-shifted frequency
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Multi-stage envelope with velocity sensitivity
        env = EnvGen.kr(
            Env.adsr(
                0.002 + (massNorm * 0.008),  // Slower attack for heavier objects
                0.05,
                0.7 - (velNorm * 0.2),        // Lower sustain for faster objects
                0.3 + (massNorm * 0.7)        // Longer release for heavier objects
            ),
            gate,
            doneAction: 2
        );
        
        // Main sawtooth oscillators with detuning for richness
        // Using SawOS (oversampled) for high quality
        saw1 = SawOS.ar(finalFreq, 0, 1, 4);
        saw2 = SawOS.ar(finalFreq * (1 + detune), 0, 1, 4);
        saw3 = SawOS.ar(finalFreq * (1 - detune), 0, 1, 4);
        
        // Sub oscillator for bass presence (one octave down)
        subOsc = SawOS.ar(finalFreq * 0.5, 0, 0.3 * massNorm, 4);
        
        // Mix oscillators with slight phase differences
        sig = (saw1 + saw2 + saw3) / 3;
        sig = sig + subOsc;
        
        // Add harmonics based on mass
        sig = sig + (SawOS.ar(finalFreq * 2, 0, 0.15 * massNorm, 4));
        sig = sig + (SawOS.ar(finalFreq * 3, 0, 0.08 * massNorm, 4));
        
        // Dynamic filter based on velocity and distance
        filter = RLPF.ar(
            sig,
            (finalFreq * filterCutoff * (1 + velNorm)).min(15000) * (distAmp = (100 / distance.max(10)).sqrt.clip(0, 2)),
            resonance + (massNorm * 0.3)
        );
        
        sig = SelectX.ar(width, [sig, filter]);
        
        // Waveshaping for character
        sig = (sig * (1 + massNorm)).tanh;
        
        // Apply envelopes and amplitude scaling
        sig = sig * amp * env * distAmp * (0.6 / numSynths.sqrt.max(1));
        
        // Soft limiting
        sig = sig.softclip * 0.9;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Test synth - simplest possible for testing
    SynthDef(\testOrbit, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1;
        var sig, env;

        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );

        sig = SinOsc.ar(freq) * amp * env;
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Store available SynthDef names
    ~nUPIC_SynthDefs[\available] = [
        \pulsarTrain,         // Advanced pulsar synthesis (default)
        \grainBank,           // Granular synthesis
        \fmCascade,           // FM synthesis cascade
        \fmOrgan,             // Hammond-style organ
        \simpleOrgan,         // Simple organ
        \percussiveGravObject,// Percussive with sharp click
        \metallicGravObject,  // Metallic percussive
        \drumGravObject,      // Drum-like percussive
        \additiveOS,          // Additive synthesis
        \simpleOS,            // Simple oversampled
        \simpleGravObject,    // VarSawOS gravity object
        \sawBLSynth,          // Band-limited sawtooth synth
        \testOrbit            // Basic test synth
    ];

    // Set default to the high-quality pulsar train
    ~nUPIC_SynthDefs[\default] = \pulsarTrain;

    "nUPIC Advanced SynthDefs loaded successfully".postln;
    "Using oversampled oscillators for high-quality sound".postln;
};

// Auto-load when this file is executed
~loadnUPICSynthDefs.value;
)
