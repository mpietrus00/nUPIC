// Debug SynthDef Error
// This script isolates and debugs the SynthDef compilation error

(
"=== Debugging SynthDef Error ===".postln;
"".postln;

// First, ensure server is running
if(s.serverRunning.not) {
    "Starting server...".postln;
    s.boot;
    s.waitForBoot {
        "Server started. Please re-run this script.".postln;
    };
} {
    "Server is running.".postln;
    "".postln;
    
    // Test 1: Most basic SynthDef possible
    "Test 1: Basic sine...".postln;
    try {
        SynthDef(\debugSine1, {
            Out.ar(0, SinOsc.ar(440, 0, 0.1) ! 2);
        }).add;
        "✓ Basic sine compiled".postln;
    } { |error|
        "✗ Basic sine failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 2: Sine with argument
    "Test 2: Sine with freq argument...".postln;
    try {
        SynthDef(\debugSine2, { |freq = 440|
            Out.ar(0, SinOsc.ar(freq, 0, 0.1) ! 2);
        }).add;
        "✓ Sine with arg compiled".postln;
    } { |error|
        "✗ Sine with arg failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 3: Multiple arguments
    "Test 3: Multiple arguments...".postln;
    try {
        SynthDef(\debugSine3, { |freq = 440, amp = 0.1|
            Out.ar(0, SinOsc.ar(freq, 0, amp) ! 2);
        }).add;
        "✓ Multiple args compiled".postln;
    } { |error|
        "✗ Multiple args failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 4: Using 'arg' keyword
    "Test 4: Using 'arg' keyword...".postln;
    try {
        SynthDef(\debugSine4, {
            arg freq = 440, amp = 0.1;
            Out.ar(0, SinOsc.ar(freq, 0, amp) ! 2);
        }).add;
        "✓ 'arg' keyword compiled".postln;
    } { |error|
        "✗ 'arg' keyword failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 5: Envelope
    "Test 5: Envelope...".postln;
    try {
        SynthDef(\debugEnv, { |gate = 1|
            var env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
            Out.ar(0, SinOsc.ar(440) * 0.1 * env ! 2);
        }).add;
        "✓ Envelope compiled".postln;
    } { |error|
        "✗ Envelope failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 6: VarSaw
    "Test 6: VarSaw...".postln;
    try {
        SynthDef(\debugVarSaw, { |freq = 440|
            Out.ar(0, VarSaw.ar(freq, 0, 0.5, 0.1) ! 2);
        }).add;
        "✓ VarSaw compiled".postln;
    } { |error|
        "✗ VarSaw failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 7: Pan2
    "Test 7: Pan2...".postln;
    try {
        SynthDef(\debugPan, { |pan = 0|
            var sig = SinOsc.ar(440, 0, 0.1);
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        "✓ Pan2 compiled".postln;
    } { |error|
        "✗ Pan2 failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 8: Mix
    "Test 8: Mix...".postln;
    try {
        SynthDef(\debugMix, {
            var sig = Mix([
                SinOsc.ar(440, 0, 0.1),
                SinOsc.ar(880, 0, 0.05)
            ]);
            Out.ar(0, sig ! 2);
        }).add;
        "✓ Mix compiled".postln;
    } { |error|
        "✗ Mix failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 9: Variables
    "Test 9: Variables...".postln;
    try {
        SynthDef(\debugVars, { |freq = 440|
            var sig, env;
            env = 1;
            sig = SinOsc.ar(freq, 0, 0.1);
            Out.ar(0, sig * env ! 2);
        }).add;
        "✓ Variables compiled".postln;
    } { |error|
        "✗ Variables failed:".postln;
        error.reportError;
    };
    
    "".postln;
    
    // Test 10: The problematic SynthDef structure
    "Test 10: Problematic structure...".postln;
    try {
        SynthDef(\debugProblem, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5;
            
            var sig, env, dopplerFreq, radialVel;
            
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.1),
                gate,
                doneAction: 2
            );
            
            radialVel = velocity * 10;
            dopplerFreq = freq * (1 + (radialVel / 343));
            
            sig = VarSaw.ar(dopplerFreq, 0, width, 0.1);
            sig = sig * amp * env * (100 / distance.max(1));
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        "✓ Problematic structure compiled".postln;
    } { |error|
        "✗ Problematic structure failed:".postln;
        error.reportError;
    };
    
    "".postln;
    "=== Debug Complete ===".postln;
    
    // List what's actually on the server
    "".postln;
    "SynthDefs on server:".postln;
    SynthDescLib.global.synthDescs.keys.select({ |key|
        key.asString.beginsWith("debug")
    }).do { |key|
        ("  • \\" ++ key).postln;
    };
};
)
