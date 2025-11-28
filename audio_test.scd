// Quick audio test for nUPIC system
// Run this to check if basic audio is working

(
"=== AUDIO DIAGNOSIS TEST ===".postln;
"Checking SuperCollider server status...".postln;

// Check server status
if(s.serverRunning, {
    "✓ Server is running".postln;
}, {
    "✗ Server is not running - starting it...".postln;
    s.boot;
});

s.waitForBoot({
    "Testing basic audio...".postln;
    
    // Test 1: Simple sine wave
    {
        var sig = SinOsc.ar(440, 0, 0.1);
        sig = sig * EnvGen.kr(Env.perc(0.1, 1), doneAction: 2);
        Out.ar(0, sig ! 2);
    }.play;
    
    2.wait;
    "✓ Basic sine wave test complete".postln;
    
    // Test 2: Load and test original SynthDef
    "Loading nUPIC SynthDefs...".postln;
    try {
        ~loadnUPICSynthDefs.value;
        "✓ SynthDefs loaded successfully".postln;
        
        // Test simple synth
        1.wait;
        "Testing simpleGravObject synth...".postln;
        
        ~testSynth = Synth(\simpleGravObject, [
            \freq, 440,
            \amp, 0.1,
            \pan, 0,
            \gate, 1,
            \radialVel, 0,  // No Doppler initially
            \dopplerSens, 0  // Doppler disabled for test
        ]);
        
        3.wait;
        ~testSynth.release;
        "✓ SynthDef test complete".postln;
        
    } { |error|
        "✗ Error loading SynthDefs:".postln;
        error.postln;
    };
    
    "=== DIAGNOSIS COMPLETE ===".postln;
    "If you heard sounds, basic audio is working".postln;
    "If not, there may be a deeper issue".postln;
});
)
