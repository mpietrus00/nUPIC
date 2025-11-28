// SuperCollider Installation Test Script
// Tests the availability of various UGens and the state of the system

(
"===================================================".postln;
"        SUPERCOLLIDER INSTALLATION TEST           ".postln;
"===================================================".postln;
"".postln;

fork {
    // 1. Server Status
    "1. SERVER STATUS:".postln;
    ("  Server running: " ++ s.serverRunning).postln;
    if(s.serverRunning.not) {
        "  Starting server...".postln;
        s.boot;
        s.waitForBoot {
            "  ✓ Server started".postln;
        };
        3.wait;
    };
    ("  Sample rate: " ++ s.sampleRate).postln;
    ("  Audio inputs: " ++ s.options.numInputBusChannels).postln;
    ("  Audio outputs: " ++ s.options.numOutputBusChannels).postln;
    "".postln;
    
    // 2. Test Standard UGens
    "2. TESTING STANDARD UGENS:".postln;
    
    // Test basic oscillators
    [\SinOsc, \Saw, \Pulse, \LFSaw, \LFPulse, \LFTri].do { |ugen|
        if(ugen.asClass.notNil) {
            ("  ✓ " ++ ugen ++ " available").postln;
        } {
            ("  ✗ " ++ ugen ++ " NOT available").postln;
        };
    };
    "".postln;
    
    // 3. Test Oversampled Oscillators
    "3. TESTING OVERSAMPLED OSCILLATORS:".postln;
    
    [\SinOscOS, \SawOS, \TriOS, \VarSawOS, \PMOscOS, \FM7OS].do { |ugen|
        if(ugen.asClass.notNil) {
            ("  ✓ " ++ ugen ++ " available").postln;
        } {
            ("  ✗ " ++ ugen ++ " NOT available").postln;
        };
    };
    "".postln;
    
    // 4. Check loaded SynthDefs
    "4. CURRENTLY LOADED SYNTHDEFS:".postln;
    
    SynthDescLib.global.synthDescs.keys.asArray.sort.do { |name|
        ("  • " ++ name).postln;
    };
    "".postln;
    
    // 5. Test creating simple synthdefs with oversampled oscillators
    "5. TESTING SYNTHDEF CREATION:".postln;
    
    // Test with standard oscillator
    try {
        SynthDef(\testStandard, {
            arg freq = 440, amp = 0.1;
            var sig = SinOsc.ar(freq) * amp;
            Out.ar(0, sig!2);
        }).add;
        "  ✓ Standard SinOsc synthdef created".postln;
    } { |error|
        ("  ✗ Standard synthdef failed: " ++ error.errorString).postln;
    };
    
    // Test with oversampled oscillator
    try {
        SynthDef(\testOversampled, {
            arg freq = 440, amp = 0.1;
            var sig = SinOscOS.ar(freq, 0, amp, 4);
            Out.ar(0, sig!2);
        }).add;
        "  ✓ Oversampled SinOscOS synthdef created".postln;
    } { |error|
        ("  ✗ Oversampled synthdef failed: " ++ error.errorString).postln;
    };
    
    s.sync;
    
    "".postln;
    
    // 6. Test playing synthdefs
    "6. TESTING SYNTHDEF PLAYBACK:".postln;
    
    // Test standard
    try {
        var synth = Synth(\testStandard, [\freq, 440, \amp, 0]);
        if(synth.notNil) {
            "  ✓ Standard synthdef plays".postln;
            synth.free;
        };
    } { |error|
        ("  ✗ Standard playback failed: " ++ error.errorString).postln;
    };
    
    // Test oversampled
    try {
        var synth = Synth(\testOversampled, [\freq, 440, \amp, 0]);
        if(synth.notNil) {
            "  ✓ Oversampled synthdef plays".postln;
            synth.free;
        };
    } { |error|
        ("  ✗ Oversampled playback failed: " ++ error.errorString).postln;
    };
    
    "".postln;
    
    // 7. Check Extensions
    "7. EXTENSIONS AND PLUGINS:".postln;
    
    if(Platform.userExtensionDir.notNil) {
        ("  User extensions: " ++ Platform.userExtensionDir).postln;
        if(File.exists(Platform.userExtensionDir +/+ "OversamplingOscillators")) {
            "  ✓ OversamplingOscillators extension found".postln;
        };
    };
    
    if(Platform.systemExtensionDir.notNil) {
        ("  System extensions: " ++ Platform.systemExtensionDir).postln;
    };
    
    "".postln;
    
    // 8. Memory and Configuration
    "8. SERVER CONFIGURATION:".postln;
    ("  Memory allocated: " ++ s.options.memSize ++ " KB").postln;
    ("  Max nodes: " ++ s.options.maxNodes).postln;
    ("  Wire buffers: " ++ s.options.numWireBufs).postln;
    ("  Block size: " ++ s.options.blockSize).postln;
    
    "".postln;
    "===================================================".postln;
    "                  TEST COMPLETE                    ".postln;
    "===================================================".postln;
    "".postln;
    
    // Provide recommendations
    "RECOMMENDATIONS:".postln;
    
    if(SinOscOS.asClass.isNil) {
        "• Oversampled oscillators not available in current environment".postln;
        "• You may need to restart SuperCollider after installing extensions".postln;
        "• Or use the simple synthdefs instead of advanced ones".postln;
    } {
        "• Oversampled oscillators are available".postln;
        "• Advanced synthdefs should work properly".postln;
    };
    
    "".postln;
    "To load nUPIC, run: \"START_NUPIC.scd\".load".postln;
};
)
