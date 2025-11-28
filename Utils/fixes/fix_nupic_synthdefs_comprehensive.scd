// Comprehensive Fix for nUPIC SynthDef Loading
// This ensures SynthDefs are properly loaded and available on the server

(
"=== Comprehensive nUPIC SynthDef Fix ===".postln;
"".postln;

// Step 1: Ensure server is running
if(s.serverRunning.not) {
    "Server not running. Starting...".postln;
    s.boot;
    s.waitForBoot {
        "Server started. Please re-run this script.".postln;
    };
} {
    "Server is running. Proceeding with fix...".postln;
    "".postln;
    
    // Step 2: Define working SynthDefs directly (not using VarSawOS which might not exist)
    "Loading SynthDefs...".postln;
    
    // Simple gravity object with basic oscillators
    SynthDef(\simpleGravObject, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerFreq, radialVelocity, dopplerShift;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Gate-controlled envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        // Doppler effect calculation
        radialVelocity = radialVel.clip(-20, 20);
        dopplerShift = 1 + (radialVelocity * dopplerSens * 0.2);
        dopplerShift = dopplerShift.clip(0.3, 3.0);
        dopplerFreq = freq * dopplerShift;
        
        // Sound generation using standard UGens (not VarSawOS)
        sig = Mix.ar([
            // Base tone
            SinOsc.ar(dopplerFreq) * 0.4,
            // Add harmonics based on mass
            Saw.ar(dopplerFreq * 0.5) * 0.2 * massNorm,
            // Add some texture
            Pulse.ar(dopplerFreq * 2, width) * 0.1 * (1 - massNorm)
        ]);
        
        // Add velocity modulation
        sig = sig * (1 + (SinOsc.ar(velocity * 2 + 0.1) * velocity.linlin(0, 20, 0, 0.05)));
        
        // Distance filtering
        sig = LPF.ar(sig, dopplerFreq * distance.linlin(20, 500, 3, 1));
        
        // Apply amplitude scaling based on number of synths
        sig = sig * amp * env * (1 / numSynths.sqrt);
        
        // Safety limiter
        sig = sig.tanh * 0.8;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ simpleGravObject SynthDef loaded".postln;
    
    // Trajectory VarSaw - simplified version without VarSawOS
    SynthDef(\trajectoryVarSaw, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env;
        
        // Gate-controlled envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.01),
            gate,
            doneAction: 2
        );
        
        // Generate detuned oscillators for richness (instead of VarSawOS)
        sig = Mix.ar(
            5.collect { |i|
                var detune = i * 0.45;
                VarSaw.ar(freq + detune, 0, width) * 0.1
            }
        );
        
        // Apply amplitude scaling
        sig = sig * amp * env * (1 / numSynths.sqrt);
        
        // Soft limiting
        sig = sig.tanh * 0.8;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ trajectoryVarSaw SynthDef loaded".postln;
    
    // Additional minimal test synth
    SynthDef(\testSine, {
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
    
    "✓ testSine SynthDef loaded".postln;
    
    // Wait for SynthDefs to compile
    s.sync;
    
    "".postln;
    
    // Step 3: Update global registry to match what nUPIC expects
    "Updating global registry...".postln;
    
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [\simpleGravObject, \trajectoryVarSaw, \testSine];
    ~nUPIC_SynthDefs[\default] = \trajectoryVarSaw;
    
    "✓ Global registry updated".postln;
    
    // Step 4: Update nUPIC defaults if it exists
    if(~nUPIC.notNil) {
        if(~nUPIC[\defaults].isNil) {
            ~nUPIC[\defaults] = IdentityDictionary.new;
        };
        ~nUPIC[\defaults][\defaultSynthDef] = \trajectoryVarSaw;
        "✓ nUPIC defaults updated".postln;
    } {
        "Note: nUPIC not loaded yet - defaults will be set when it loads".postln;
    };
    
    "".postln;
    
    // Step 5: Test the SynthDefs
    "Testing SynthDefs...".postln;
    
    fork {
        [\simpleGravObject, \trajectoryVarSaw, \testSine].do { |name|
            var synth;
            try {
                synth = Synth(name, [
                    \freq, 440, 
                    \amp, 0,  // Silent test
                    \gate, 1,
                    \numSynths, 1
                ]);
                
                if(synth.notNil) {
                    ("✓ " ++ name ++ " works - nodeID: " ++ synth.nodeID).postln;
                    0.1.wait;
                    synth.set(\gate, 0);  // Proper release
                    0.2.wait;
                } {
                    ("✗ " ++ name ++ " failed to create").postln;
                };
            } { |error|
                ("✗ " ++ name ++ " error: " ++ error.errorString).postln;
            };
        };
        
        "".postln;
        "=== SynthDef Fix Complete ===".postln;
        "".postln;
        
        // Check what's on the server
        "SynthDefs available on server:".postln;
        SynthDescLib.global.synthDescs.keys.select({ |key|
            [\simpleGravObject, \trajectoryVarSaw, \testSine].includes(key)
        }).do { |key|
            ("  • \\" ++ key).postln;
        };
        
        "".postln;
        "You can now:".postln;
        "1. Load nUPIC if not already loaded:".postln;
        "   \"nUPIC_Main.scd\".load".postln;
        "2. Draw trajectories and press SPACE to play".postln;
        "".postln;
        
        // Optional: Test with actual sound
        "To test with sound, run:".postln;
        "(
    var synth = Synth(\\trajectoryVarSaw, [\\freq, 440, \\amp, 0.1, \\gate, 1]);
    fork { 1.wait; synth.set(\\gate, 0); };
)".postln;
    };
};
)
