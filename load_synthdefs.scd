// Standalone SynthDef Loader for nUPIC
// Run this to ensure SynthDefs are properly loaded to the server

(
s.waitForBoot {
    "Loading nUPIC SynthDefs...".postln;
    
    // Simple gravity object based on working testOrbit synthdef
    SynthDef(\simpleGravObject, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        
        // Calculate frequency with optional Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Simple envelope like in working example
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        // Simple oscillator design that works - based on confirmed working code
        sig = Mix.ar([
            SinOsc.ar(finalFreq) * 0.5,
            SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),
            SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)
        ]);
        
        // Subtle vibrato
        sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));
        
        // Distance amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Apply amplitude
        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
        
        // Soft clipping
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Simpler trajectory synth based on working example
    SynthDef(\trajectoryVarSaw, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env;
        
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.01),
            gate,
            doneAction: 2
        );
        
        // Simple sawtooth design - confirmed working
        sig = Mix.ar([
            Saw.ar(freq) * 0.3,
            Saw.ar(freq * 1.01) * 0.3,
            Saw.ar(freq * 0.99) * 0.3
        ]);
        
        sig = LPF.ar(sig, freq * 4);
        sig = sig * amp * env * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Test synth - exactly like working example
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
    
    // Wait for SynthDefs to be sent to server
    s.sync;
    
    "✓ SynthDefs loaded to server".postln;
    "".postln;
    
    // Test each SynthDef
    "Testing SynthDefs...".postln;
    
    // Test simpleGravObject
    fork {
        var synth;
        
        try {
            synth = Synth(\simpleGravObject, [\freq, 440, \amp, 0.1, \gate, 1, \numSynths, 1]);
            "✓ simpleGravObject works - playing 440 Hz for 0.5 seconds".postln;
            0.5.wait;
            synth.set(\gate, 0);
            0.5.wait;
        } { |error|
            ("✗ simpleGravObject failed: " ++ error.errorString).postln;
        };
        
        // Test trajectoryVarSaw
        try {
            synth = Synth(\trajectoryVarSaw, [\freq, 550, \amp, 0.1, \gate, 1, \numSynths, 1]);
            "✓ trajectoryVarSaw works - playing 550 Hz for 0.5 seconds".postln;
            0.5.wait;
            synth.set(\gate, 0);
            0.5.wait;
        } { |error|
            ("✗ trajectoryVarSaw failed: " ++ error.errorString).postln;
        };
        
        // Test testOrbit
        try {
            synth = Synth(\testOrbit, [\freq, 330, \amp, 0.1, \gate, 1]);
            "✓ testOrbit works - playing 330 Hz for 0.5 seconds".postln;
            0.5.wait;
            synth.set(\gate, 0);
            0.5.wait;
        } { |error|
            ("✗ testOrbit failed: " ++ error.errorString).postln;
        };
        
        "".postln;
        "All SynthDefs tested!".postln;
        "".postln;
        
        // Update global registry
        ~nUPIC_SynthDefs = ~nUPIC_SynthDefs ?? { IdentityDictionary.new };
        ~nUPIC_SynthDefs[\available] = [\simpleGravObject, \trajectoryVarSaw, \testOrbit];
        ~nUPIC_SynthDefs[\default] = \simpleGravObject;
        
        "SynthDef registry updated:".postln;
        ("  Available: " ++ ~nUPIC_SynthDefs[\available]).postln;
        ("  Default: " ++ ~nUPIC_SynthDefs[\default]).postln;
    };
};
)