// Percussive Gravity Object SynthDef with Sharp Attack Click
// Based on simpleGravObject but with percussive envelope and transient

(
"Loading Percussive Gravity Object SynthDef...".postln;
"".postln;

s.waitForBoot {
    
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
        
        // DOPPLER EFFECT (same as original):
        radialVelocity = Lag.kr(\radialVel.kr(0).clip(-20, 20), 0.2);
        dopplerSensitivity = \dopplerSens.kr(1.0).clip(0, 3.0);
        dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1);
        dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05);
        dopplerShift = dopplerShift.clip(0.5, 2.0);
        dopplerFreq = freq * dopplerShift;
        
        // PERCUSSIVE ENVELOPE with sharp attack and sustained body
        // Main envelope - percussive attack then sustain
        env = EnvGen.kr(
            Env(
                [0, 1, 0.7, 0.7, 0],  // Sharp attack to sustain level
                [0.001, 0.01, 0.5, 0.2],  // Very fast attack, quick decay to sustain
                [2, -4, 0, -2],  // Curve shapes
                3  // Release node (sustain until gate = 0)
            ),
            gate,
            doneAction: 2
        );
        
        // Click envelope - very sharp transient
        clickEnv = EnvGen.kr(
            Env.perc(0.0001, 0.005, 1, -8),  // Ultra-fast percussive click
            gate
        );
        
        // CLICK GENERATION - sharp transient
        // 1. Impact click using filtered noise
        click = WhiteNoise.ar(clickEnv * 0.3);
        click = HPF.ar(click, 2000 + (freq * 2));  // High-pass filtered click
        click = click + (Impulse.ar(0, 0, clickEnv * 0.5));  // Add impulse for extra sharpness
        
        // 2. Pitched click component using high harmonics
        transient = SinOsc.ar(dopplerFreq * 4) * clickEnv * 0.2;
        transient = transient + (SinOsc.ar(dopplerFreq * 8) * clickEnv * 0.1);
        
        // Combine click components
        click = (click + transient) * (1 + (mass * 0.2));  // Mass affects click intensity
        
        // BODY GENERATION - sustained tone (from original)
        // Base oscillator - VarSawOS with Doppler-shifted frequency
        body = VarSawOS.ar(dopplerFreq, width: width, oversample: 4) * 0.4;
        
        // Mass affects harmonics
        body = body + (VarSawOS.ar(dopplerFreq * 2, width: width * 0.8, oversample: 4) * mass.linlin(0.1, 5, 0, 0.15));
        
        // Velocity affects frequency modulation
        body = body * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));
        
        // Distance affects brightness
        body = LPF.ar(body, dopplerFreq * distance.linlin(20, 500, 3, 1));
        
        // Apply envelope to body
        body = body * env;
        
        // COMBINE click and body
        sig = click + body;
        
        // Apply overall amplitude with numSynths scaling
        sig = sig * amp * (1 / numSynths.sqrt.max(1));
        
        // Safety limiter
        sig = sig.tanh;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Alternative version with more metallic click
    SynthDef(\metallicGravObject, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;
        var env, clickEnv, numSynths, gate;
        var click, body, ring;
        
        // Parameters (same as above)
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.01);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.1);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.05);
        gate = \gate.kr(1);
        numSynths = \numSynths.kr(1);
        
        // Doppler (same as above)
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
        
        // METALLIC CLICK - using ring modulation and comb filter
        click = Impulse.ar(0, 0, 1);
        click = CombL.ar(click, 0.1, 1/dopplerFreq, 0.03);  // Comb filter for metallic ring
        click = click * SinOsc.ar(dopplerFreq * 7.5);  // Ring modulation
        click = click * clickEnv * 0.5;
        
        // Additional metallic harmonics
        ring = Mix.ar([
            SinOsc.ar(dopplerFreq * 3.7) * 0.2,
            SinOsc.ar(dopplerFreq * 5.3) * 0.15,
            SinOsc.ar(dopplerFreq * 7.1) * 0.1
        ]) * clickEnv;
        
        click = click + ring;
        click = click * (1 + (mass * 0.3));  // Mass affects metallic brightness
        
        // BODY - sustained VarSawOS tone
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
        // Low frequency punch
        punch = SinOsc.ar(50 + (mass * 20)) * clickEnv * 0.5;
        
        // Mid frequency click
        click = WhiteNoise.ar(clickEnv * 0.2);
        click = BPF.ar(click, dopplerFreq * 2, 0.5);
        
        // Add pitched component with pitch sweep
        click = click + (SinOsc.ar(dopplerFreq * (1 + pitchEnv)) * clickEnv * 0.3);
        
        // Combine punch and click
        click = punch + click;
        
        // BODY - sustained tone with drum-like character
        body = VarSawOS.ar(dopplerFreq, width: width, oversample: 4) * 0.25;
        body = body + (SinOsc.ar(dopplerFreq * 0.5) * mass.linlin(0.1, 5, 0, 0.2));  // Sub-harmonic
        body = body * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));
        body = LPF.ar(body, dopplerFreq * distance.linlin(20, 500, 2, 0.5));
        body = body * env;
        
        // Combine
        sig = click + body;
        sig = sig * amp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ percussiveGravObject loaded".postln;
    "✓ metallicGravObject loaded".postln;
    "✓ drumGravObject loaded".postln;
    
    // Wait for compilation
    s.sync;
    
    "".postln;
    "Testing percussive synthdefs...".postln;
    
    fork {
        // Test percussiveGravObject
        var synth = Synth(\percussiveGravObject, [
            \freq, 440,
            \amp, 0.15,
            \gate, 1,
            \mass, 2,
            \velocity, 5,
            \distance, 100,
            \width, 0.5
        ]);
        
        "Playing percussiveGravObject (sharp click + sustain)...".postln;
        1.5.wait;
        
        synth.set(\gate, 0);
        "Released.".postln;
        
        1.wait;
        
        // Test metallicGravObject
        synth = Synth(\metallicGravObject, [
            \freq, 330,
            \amp, 0.15,
            \gate, 1,
            \mass, 3,
            \velocity, 8
        ]);
        
        "Playing metallicGravObject (metallic ring + sustain)...".postln;
        1.5.wait;
        
        synth.set(\gate, 0);
        "Released.".postln;
        
        1.wait;
        
        // Test drumGravObject
        synth = Synth(\drumGravObject, [
            \freq, 220,
            \amp, 0.15,
            \gate, 1,
            \mass, 4,
            \velocity, 10
        ]);
        
        "Playing drumGravObject (drum punch + sustain)...".postln;
        1.5.wait;
        
        synth.set(\gate, 0);
        "Released.".postln;
        
        0.5.wait;
        
        "".postln;
        "=== Percussive Gravity SynthDefs Ready ===".postln;
        "".postln;
        "Available percussive synthdefs:".postln;
        "  • percussiveGravObject - Sharp click attack with sustained body".postln;
        "  • metallicGravObject   - Metallic ring attack with sustain".postln;
        "  • drumGravObject       - Drum-like punch with sustain".postln;
        "".postln;
        
        // Update registry if it exists
        if(~nUPIC_SynthDefs.notNil) {
            ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available] ++ [
                \percussiveGravObject,
                \metallicGravObject,
                \drumGravObject
            ];
            "Added to nUPIC synthdef registry.".postln;
        };
        
        "".postln;
        "Try these for different percussive effects:".postln;
        "".postln;
        "// Sharp click:".postln;
        'Synth(\\percussiveGravObject, [\\freq, 440, \\amp, 0.2, \\mass, 2]);'.postln;
        "".postln;
        "// Metallic hit:".postln;
        'Synth(\\metallicGravObject, [\\freq, 660, \\amp, 0.2, \\mass, 3]);'.postln;
        "".postln;
        "// Drum punch:".postln;
        'Synth(\\drumGravObject, [\\freq, 220, \\amp, 0.2, \\mass, 5]);'.postln;
    };
};
)
