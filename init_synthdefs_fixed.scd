// Fixed SynthDef Initialization
// This properly compiles and loads SynthDefs without errors

(
"=== Fixed SynthDef Initialization ===".postln;
"".postln;

// Ensure server is running
if(Server.default.serverRunning.not) {
    "Starting server...".postln;
    Server.default.boot;
    Server.default.waitForBoot {
        "Server started. Re-run this script to load SynthDefs.".postln;
    };
} {
    "Server is running. Loading SynthDefs...".postln;
    
    // Define SynthDefs directly without fork
    {
        // Simple working synthdef with VarSaw
        SynthDef(\trajectoryVarSaw, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5;
            
            var sig, env, dopplerFreq, radialVel;
            
            // Envelope with proper release
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.1),
                gate,
                doneAction: 2
            );
            
            // Calculate Doppler shift
            radialVel = velocity * 10;  // Scale for audibility
            dopplerFreq = freq * (1 + (radialVel / 343));
            
            // VarSaw with correct parameter order: freq, phase, width, mul
            sig = VarSaw.ar(
                dopplerFreq,  // frequency
                0,            // phase
                width         // width (0-1)
            ) * amp * env * (100 / distance.max(1));
            
            // Output with panning
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "✓ trajectoryVarSaw SynthDef compiled".postln;
        
        // Simple working synthdef with multiple oscillators
        SynthDef(\simpleGravObject, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100;
            
            var sig, env, dopplerFreq, radialVel;
            var massNorm = (mass / 10).clip(0, 1);
            
            // Gate-controlled envelope with release
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.5),
                gate,
                doneAction: 2
            );
            
            // Enhanced Doppler effect
            radialVel = velocity * 20;
            dopplerFreq = freq * (1 + (radialVel / 343));
            
            // Oscillator with mass-dependent timbre
            sig = Mix.ar([
                SinOsc.ar(dopplerFreq, 0) * 0.5,
                Saw.ar(dopplerFreq * 0.5) * 0.3 * massNorm,
                Pulse.ar(dopplerFreq * 2, 0.3) * 0.2 * (1 - massNorm)
            ]);
            
            // Apply envelope and distance attenuation
            sig = sig * env * amp * (100 / distance.max(1));
            
            // Output with panning
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "✓ simpleGravObject SynthDef compiled".postln;
        
        // Even simpler test synthdef
        SynthDef(\testSine, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1;
            var sig, env;
            
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.1),
                gate,
                doneAction: 2
            );
            
            sig = SinOsc.ar(freq) * amp * env;
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "✓ testSine SynthDef compiled".postln;
        
    }.value;
    
    // Wait for compilation
    Server.default.sync;
    
    "".postln;
    "Testing SynthDefs...".postln;
    
    // Test each synthdef
    fork {
        var testSynth;
        
        // Test testSine
        try {
            testSynth = Synth(\testSine, [\freq, 440, \amp, 0, \gate, 1]);
            if(testSynth.notNil) {
                "✓ testSine works".postln;
                testSynth.free;
            };
        } { |error|
            ("✗ testSine failed: " ++ error.errorString).postln;
        };
        
        0.2.wait;
        
        // Test trajectoryVarSaw
        try {
            testSynth = Synth(\trajectoryVarSaw, [
                \freq, 440, \amp, 0, \pan, 0, \gate, 1,
                \mass, 1, \velocity, 0, \distance, 100, \width, 0.5
            ]);
            if(testSynth.notNil) {
                "✓ trajectoryVarSaw works".postln;
                testSynth.free;
            };
        } { |error|
            ("✗ trajectoryVarSaw failed: " ++ error.errorString).postln;
        };
        
        0.2.wait;
        
        // Test simpleGravObject
        try {
            testSynth = Synth(\simpleGravObject, [
                \freq, 440, \amp, 0, \pan, 0, \gate, 1,
                \mass, 1, \velocity, 0, \distance, 100
            ]);
            if(testSynth.notNil) {
                "✓ simpleGravObject works".postln;
                testSynth.free;
            };
        } { |error|
            ("✗ simpleGravObject failed: " ++ error.errorString).postln;
        };
        
        0.5.wait;
        
        "".postln;
        "=== SynthDef Status ===".postln;
        "Available SynthDefs on server:".postln;
        SynthDescLib.global.synthDescs.keys.do { |key|
            if([\testSine, \trajectoryVarSaw, \simpleGravObject].includes(key)) {
                ("  • \\" ++ key).postln;
            };
        };
        
        "".postln;
        "SynthDefs are ready! You can now:".postln;
        "1. Load nUPIC: \"nUPIC_Main.scd\".load".postln;
        "2. Or test audio: \"audio_test.scd\".load".postln;
    };
};
)
