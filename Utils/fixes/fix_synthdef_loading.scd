// Fix SynthDef Loading Issues
// This script diagnoses and fixes the synthdef loading problems

(
"===================================================".postln;
"         FIXING SYNTHDEF LOADING ISSUES           ".postln;
"===================================================".postln;
"".postln;

s.waitForBoot {
    
    fork {
        var osUGensAvailable = false;
        var loadedDefs = [];
        var failedDefs = [];
        
        // Step 1: Check if oversampled UGens are available
        "STEP 1: Checking for Oversampled UGens...".postln;
        
        osUGensAvailable = SinOscOS.asClass.notNil;
        
        if(osUGensAvailable) {
            "  ✓ Oversampled UGens are available".postln;
        } {
            "  ✗ Oversampled UGens NOT available".postln;
            "  → Will use standard oscillators instead".postln;
        };
        
        "".postln;
        
        // Step 2: Clear any existing synthdefs to start fresh
        "STEP 2: Clearing existing SynthDefs...".postln;
        
        // Free all running synths first
        s.freeAll;
        0.5.wait;
        
        "".postln;
        
        // Step 3: Load appropriate synthdefs based on availability
        "STEP 3: Loading SynthDefs...".postln;
        
        if(osUGensAvailable) {
            // Try to load advanced synthdefs with proper error handling
            
            // grainBank - Granular synthesis (doesn't use OS UGens, should work)
            try {
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
                
                loadedDefs = loadedDefs.add(\grainBank);
                "  ✓ grainBank loaded".postln;
            } { |error|
                failedDefs = failedDefs.add(\grainBank);
                ("  ✗ grainBank failed: " ++ error.errorString).postln;
            };
            
            // simpleOS - uses oversampled oscillators
            try {
                SynthDef(\simpleOS, {
                    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                        mass = 1, velocity = 0, distance = 100, width = 0.5,
                        radialVel = 0, dopplerSens = 0, numSynths = 1;
                    
                    var sig, env, dopplerShift, finalFreq, distAmp;
                    
                    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
                    finalFreq = freq * dopplerShift.clip(0.5, 2.0);
                    
                    env = EnvGen.kr(
                        Env.asr(0.01, 1, 0.1),
                        gate,
                        doneAction: 2
                    );
                    
                    // Use oversampled oscillator
                    sig = SinOscOS.ar(finalFreq, 0, 1, 4);
                    
                    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
                    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
                    sig = sig.tanh * 0.9;
                    
                    Out.ar(0, Pan2.ar(sig, pan));
                }).add;
                
                loadedDefs = loadedDefs.add(\simpleOS);
                "  ✓ simpleOS loaded".postln;
            } { |error|
                failedDefs = failedDefs.add(\simpleOS);
                ("  ✗ simpleOS failed: " ++ error.errorString).postln;
            };
            
        };
        
        // Always load simple synthdefs as fallback
        
        // simpleGravObject - uses standard oscillators only
        try {
            SynthDef(\simpleGravObject, {
                arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                    mass = 1, velocity = 0, distance = 100, width = 0.5,
                    radialVel = 0, dopplerSens = 0, numSynths = 1;
                
                var sig, env, dopplerShift, finalFreq, distAmp;
                
                dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
                finalFreq = freq * dopplerShift.clip(0.5, 2.0);
                
                env = EnvGen.kr(
                    Env.asr(0.01, 1, 0.1),
                    gate,
                    doneAction: 2
                );
                
                // Use standard oscillators
                sig = Mix.ar([
                    SinOsc.ar(finalFreq) * 0.5,
                    SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),
                    SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)
                ]);
                
                sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));
                
                distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
                sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
                sig = sig.tanh * 0.9;
                
                Out.ar(0, Pan2.ar(sig, pan));
            }).add;
            
            loadedDefs = loadedDefs.add(\simpleGravObject);
            "  ✓ simpleGravObject loaded".postln;
        } { |error|
            failedDefs = failedDefs.add(\simpleGravObject);
            ("  ✗ simpleGravObject failed: " ++ error.errorString).postln;
        };
        
        // testOrbit - simplest possible synth
        try {
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
            
            loadedDefs = loadedDefs.add(\testOrbit);
            "  ✓ testOrbit loaded".postln;
        } { |error|
            failedDefs = failedDefs.add(\testOrbit);
            ("  ✗ testOrbit failed: " ++ error.errorString).postln;
        };
        
        // Wait for synthdefs to compile
        s.sync;
        
        "".postln;
        
        // Step 4: Test loaded synthdefs
        "STEP 4: Testing loaded SynthDefs...".postln;
        
        loadedDefs.do { |name|
            var synth;
            try {
                synth = Synth(name, [\freq, 440, \amp, 0, \gate, 1]);
                if(synth.notNil) {
                    ("  ✓ " ++ name ++ " plays correctly").postln;
                    synth.set(\gate, 0);
                    0.1.wait;
                };
            } { |error|
                ("  ✗ " ++ name ++ " playback failed").postln;
            };
        };
        
        "".postln;
        
        // Step 5: Update global registry
        "STEP 5: Updating SynthDef registry...".postln;
        
        ~nUPIC_SynthDefs = IdentityDictionary.new;
        ~nUPIC_SynthDefs[\available] = loadedDefs;
        ~nUPIC_SynthDefs[\default] = if(loadedDefs.includes(\simpleGravObject), 
            \simpleGravObject, 
            loadedDefs.first
        );
        
        ("  Default synthdef: " ++ ~nUPIC_SynthDefs[\default]).postln;
        
        "".postln;
        "===================================================".postln;
        "                  FIX COMPLETE                     ".postln;
        "===================================================".postln;
        "".postln;
        
        // Summary
        "SUMMARY:".postln;
        ("  Successfully loaded: " ++ loadedDefs).postln;
        if(failedDefs.size > 0) {
            ("  Failed to load: " ++ failedDefs).postln;
        };
        "".postln;
        
        if(osUGensAvailable.not) {
            "NOTE: Oversampled UGens are not available.".postln;
            "Using standard oscillators instead.".postln;
            "To enable advanced synthdefs:".postln;
            "1. Make sure OversamplingOscillators extension is installed".postln;
            "2. Restart SuperCollider completely".postln;
            "3. Run this script again".postln;
        } {
            "Oversampled UGens are available.".postln;
            if(failedDefs.size > 0) {
                "Some advanced synthdefs failed to load.".postln;
                "This might be due to missing dependencies.".postln;
            };
        };
        
        "".postln;
        "You can now load nUPIC:".postln;
        "  \"nUPIC_Main.scd\".load".postln;
    };
};
)
