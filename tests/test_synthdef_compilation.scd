// Test SynthDef Compilation
// This script tests if SynthDefs compile without errors

(
"=== Testing SynthDef Compilation ===".postln;
"".postln;

// Start server if needed
if(Server.default.serverRunning.not) {
    "Server not running. Please start it first with:".postln;
    "  Server.default.boot;".postln;
    "Then re-run this test.".postln;
} {
    var success = true;
    
    "Testing basic SynthDef compilation...".postln;
    
    // Test 1: Simple sine oscillator
    try {
        SynthDef(\testBasicSine, {
            arg freq = 440, amp = 0.1;
            var sig = SinOsc.ar(freq) * amp;
            Out.ar(0, sig ! 2);
        }).add;
        "✓ Basic sine SynthDef compiled".postln;
    } { |error|
        "✗ Basic sine failed: %".format(error.errorString).postln;
        success = false;
    };
    
    // Test 2: VarSaw with proper syntax
    try {
        SynthDef(\testVarSaw, {
            arg freq = 440, amp = 0.1, width = 0.5;
            var sig = VarSaw.ar(freq, 0, width) * amp;
            Out.ar(0, sig ! 2);
        }).add;
        "✓ VarSaw SynthDef compiled".postln;
    } { |error|
        "✗ VarSaw failed: %".format(error.errorString).postln;
        success = false;
    };
    
    // Test 3: Mix with multiple oscillators
    try {
        SynthDef(\testMix, {
            arg freq = 440, amp = 0.1;
            var sig = Mix.ar([
                SinOsc.ar(freq) * 0.5,
                Saw.ar(freq * 0.5) * 0.3,
                Pulse.ar(freq * 2, 0.3) * 0.2
            ]) * amp;
            Out.ar(0, sig ! 2);
        }).add;
        "✓ Mix SynthDef compiled".postln;
    } { |error|
        "✗ Mix failed: %".format(error.errorString).postln;
        success = false;
    };
    
    // Test 4: Envelope with gate
    try {
        SynthDef(\testEnvelope, {
            arg freq = 440, amp = 0.1, gate = 1;
            var env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.1),
                gate,
                doneAction: 2
            );
            var sig = SinOsc.ar(freq) * amp * env;
            Out.ar(0, sig ! 2);
        }).add;
        "✓ Envelope SynthDef compiled".postln;
    } { |error|
        "✗ Envelope failed: %".format(error.errorString).postln;
        success = false;
    };
    
    // Test 5: Pan2 output
    try {
        SynthDef(\testPan, {
            arg freq = 440, amp = 0.1, pan = 0;
            var sig = SinOsc.ar(freq) * amp;
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        "✓ Pan2 SynthDef compiled".postln;
    } { |error|
        "✗ Pan2 failed: %".format(error.errorString).postln;
        success = false;
    };
    
    "".postln;
    
    if(success) {
        "=== All basic tests passed! ===".postln;
        "".postln;
        "Now testing nUPIC SynthDefs...".postln;
        
        // Load the fixed synthdefs
        "init_synthdefs_fixed.scd".load;
        
    } {
        "=== Some tests failed ===".postln;
        "Check the error messages above.".postln;
        "".postln;
        "Common issues:".postln;
        "1. Server not running".postln;
        "2. SuperCollider version incompatibility".postln;
        "3. Missing UGens".postln;
    };
};
)
