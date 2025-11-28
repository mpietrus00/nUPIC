// Check VarSaw Syntax
// VarSaw.ar(freq, iphase, width, mul, add)

(
"=== Checking VarSaw Syntax ===".postln;
"".postln;

if(s.serverRunning.not) {
    "Server not running. Starting...".postln;
    s.boot;
    s.waitForBoot {
        "Server started. Please re-run this script.".postln;
    };
} {
    var tests = [
        // Test different VarSaw syntaxes
        {
            "Test 1: VarSaw with 3 args (freq, phase, width)".postln;
            SynthDef(\varsaw3, {
                var sig = VarSaw.ar(440, 0, 0.5);
                Out.ar(0, sig * 0.1 ! 2);
            }).add;
            "✓ 3 args works".postln;
        },
        
        {
            "Test 2: VarSaw with 4 args (freq, phase, width, mul)".postln;
            SynthDef(\varsaw4, {
                var sig = VarSaw.ar(440, 0, 0.5, 0.1);
                Out.ar(0, sig ! 2);
            }).add;
            "✓ 4 args works".postln;
        },
        
        {
            "Test 3: VarSaw with 5 args (freq, phase, width, mul, add)".postln;
            SynthDef(\varsaw5, {
                var sig = VarSaw.ar(440, 0, 0.5, 0.1, 0);
                Out.ar(0, sig ! 2);
            }).add;
            "✓ 5 args works".postln;
        },
        
        {
            "Test 4: VarSaw with multiplication after".postln;
            SynthDef(\varsawMul, {
                var sig = VarSaw.ar(440, 0, 0.5) * 0.1;
                Out.ar(0, sig ! 2);
            }).add;
            "✓ Multiplication after works".postln;
        },
        
        {
            "Test 5: VarSaw with variable freq".postln;
            SynthDef(\varsawVar, { |freq = 440|
                var sig = VarSaw.ar(freq, 0, 0.5, 0.1);
                Out.ar(0, sig ! 2);
            }).add;
            "✓ Variable freq works".postln;
        },
        
        {
            "Test 6: Original problematic code".postln;
            SynthDef(\varsawProb, {
                arg freq = 440, width = 0.5, amp = 0.1;
                var dopplerFreq = freq * 1.1;
                // This was the issue - wrong syntax
                // var sig = VarSaw.ar(dopplerFreq, 0, width, amp);  // WRONG
                var sig = VarSaw.ar(dopplerFreq, 0, width) * amp;  // CORRECT
                Out.ar(0, sig ! 2);
            }).add;
            "✓ Fixed problematic code works".postln;
        }
    ];
    
    // Run each test
    tests.do { |test|
        try {
            test.value;
        } { |error|
            "✗ Test failed:".postln;
            error.errorString.postln;
        };
        "".postln;
    };
    
    "=== Syntax Summary ===".postln;
    "VarSaw.ar accepts these arguments:".postln;
    "  freq: Frequency in Hz".postln;
    "  iphase: Initial phase (0-1), default 0".postln;
    "  width: Pulse width (0-1), default 0.5".postln;
    "  mul: Amplitude multiplier (optional)".postln;
    "  add: DC offset (optional)".postln;
    "".postln;
    "If you need to multiply amplitude, either:".postln;
    "  1. Use the mul argument: VarSaw.ar(freq, 0, width, amp)".postln;
    "  2. Multiply after: VarSaw.ar(freq, 0, width) * amp".postln;
    "".postln;
    
    // Now test creating synths
    "Testing synth creation...".postln;
    fork {
        [\varsaw3, \varsaw4, \varsaw5, \varsawMul, \varsawVar, \varsawProb].do { |name|
            var synth;
            try {
                synth = Synth(name);
                ("✓ Synth \\" ++ name ++ " created").postln;
                0.1.wait;
                synth.free;
            } { |error|
                ("✗ Synth \\" ++ name ++ " failed: " ++ error.errorString).postln;
            };
        };
        
        "".postln;
        "=== All tests complete ===".postln;
    };
};
)
