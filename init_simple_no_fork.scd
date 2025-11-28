// Simple Initialization Without Fork
// This avoids potential timing issues with SynthDef compilation

(
"=== Simple nUPIC Initialization (No Fork) ===".postln;
"".postln;

// Step 1: Configure server
"Configuring server...".postln;
Server.default.options.memSize = 65536 * 2;
Server.default.options.numWireBufs = 128;
Server.default.options.maxNodes = 2048;
Server.default.options.sampleRate = 44100;
Server.default.options.blockSize = 64;
"Server configured.".postln;
"".postln;

// Step 2: Boot server if needed
if(Server.default.serverRunning.not) {
    "Server not running. Starting...".postln;
    Server.default.boot;
    "".postln;
    "Please wait for server to boot, then run:".postln;
    "  \"init_simple_no_fork.scd\".load".postln;
    "".postln;
} {
    "Server is running. Loading SynthDefs...".postln;
    "".postln;
    
    // Step 3: Define SynthDefs directly (not in fork)
    
    // Test with absolute minimal SynthDef first
    SynthDef(\testMinimal, { |freq = 440, amp = 0.1|
        Out.ar(0, SinOsc.ar(freq, 0, amp) ! 2);
    }).add;
    "✓ testMinimal SynthDef added".postln;
    
    // Simple VarSaw version
    SynthDef(\trajectorySimple, { |freq = 440, amp = 0.1, pan = 0|
        var sig = VarSaw.ar(freq, 0, 0.5, amp);
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    "✓ trajectorySimple SynthDef added".postln;
    
    // Version with envelope
    SynthDef(\trajectoryWithEnv, { |freq = 440, amp = 0.1, pan = 0, gate = 1|
        var sig, env;
        env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
        sig = VarSaw.ar(freq, 0, 0.5, amp * env);
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    "✓ trajectoryWithEnv SynthDef added".postln;
    
    // Full version with all parameters
    SynthDef(\trajectoryFull, { 
        |freq = 440, amp = 0.1, pan = 0, gate = 1, 
         mass = 1, velocity = 0, distance = 100, width = 0.5|
        
        var sig, env, dopplerFreq, radialVel;
        
        // Envelope
        env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
        
        // Doppler
        radialVel = velocity * 10;
        dopplerFreq = freq * (1 + (radialVel / 343));
        
        // Signal
        sig = VarSaw.ar(dopplerFreq, 0, width);
        sig = sig * amp * env * (100 / distance.max(1));
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    "✓ trajectoryFull SynthDef added".postln;
    
    // Another full version with Mix
    SynthDef(\gravObjectSimple, {
        |freq = 440, amp = 0.1, pan = 0, gate = 1,
         mass = 1, velocity = 0, distance = 100|
        
        var sig, env, dopplerFreq, radialVel, massNorm;
        
        massNorm = (mass / 10).clip(0, 1);
        env = EnvGen.kr(Env.asr(0.01, 1, 0.5), gate, doneAction: 2);
        
        radialVel = velocity * 20;
        dopplerFreq = freq * (1 + (radialVel / 343));
        
        sig = Mix([
            SinOsc.ar(dopplerFreq) * 0.5,
            Saw.ar(dopplerFreq * 0.5) * 0.3 * massNorm,
            Pulse.ar(dopplerFreq * 2, 0.3) * 0.2 * (1 - massNorm)
        ]);
        
        sig = sig * env * amp * (100 / distance.max(1));
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    "✓ gravObjectSimple SynthDef added".postln;
    
    "".postln;
    "All SynthDefs loaded!".postln;
    "".postln;
    
    // Step 4: Test the SynthDefs
    "Testing SynthDefs...".postln;
    
    fork {
        var testSynth;
        
        // Test each one
        [\testMinimal, \trajectorySimple, \trajectoryWithEnv, \trajectoryFull, \gravObjectSimple].do { |name|
            try {
                testSynth = Synth(name, [\freq, 440, \amp, 0, \gate, 1]);
                if(testSynth.notNil) {
                    ("✓ " ++ name ++ " works").postln;
                    testSynth.free;
                };
            } { |error|
                ("✗ " ++ name ++ " failed: " ++ error.errorString).postln;
            };
            0.2.wait;
        };
        
        "".postln;
        "=== Testing Complete ===".postln;
        "".postln;
        
        // Set up global registry
        ~nUPIC_SynthDefs = IdentityDictionary.new;
        ~nUPIC_SynthDefs[\available] = [\trajectoryFull, \gravObjectSimple];
        ~nUPIC_SynthDefs[\default] = \trajectoryFull;
        "✓ Global SynthDef registry created".postln;
        
        "".postln;
        "You can now load nUPIC:".postln;
        "  \"nUPIC_Main.scd\".load".postln;
    };
};
)
