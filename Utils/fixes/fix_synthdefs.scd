// Complete troubleshooting and fix script for nUPIC SynthDefs
// Run this to diagnose and fix SynthDef loading issues

(
"=== nUPIC SynthDef Troubleshooting & Repair ===".postln;

// Step 1: Check server status
if(s.serverRunning.not) {
    "Starting SuperCollider server...".postln;
    s.boot;
    s.waitForBoot {
        "Server started. Continuing with SynthDef loading...".postln;
    };
} {
    "✓ Server is running".postln;
};

// Step 2: Clear any existing problematic SynthDefs
"Clearing existing SynthDefs...".postln;
s.freeAll; // Stop all synths
0.5.wait; // Brief pause

// Step 3: Reload SynthDefs with error checking
"Reloading SynthDefs...".postln;
try {
    (~nUPIC_basePath +/+ "Audio/SynthDefs.scd").load;
    "✓ SynthDefs file loaded successfully".postln;
} { |error|
    "ERROR loading SynthDefs: ".postln;
    error.errorString.postln;
    "Attempting manual SynthDef loading...".postln;
    
    // Manual fallback - load essential SynthDefs
    SynthDef(\simpleGravObject, {
        var sig, freq, amp, pan, gate;
        
        freq = Lag.kr(\freq.kr(300).clip(20, 8000), 0.1);
        amp = Lag.kr(\amp.kr(0.2).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.1);
        gate = \gate.kr(1);
        
        // Simple saw wave synthesis
        sig = Saw.ar(freq) * 0.3;
        sig = sig + (Saw.ar(freq * 2) * 0.1);
        sig = LPF.ar(sig, freq * 3);
        
        sig = sig * amp * EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
        sig = sig.tanh * 0.7;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    SynthDef(\richTexture, {
        var sig, freq, amp, pan, gate;
        var layer1, layer2, layer3;
        
        freq = Lag.kr(\freq.kr(440).clip(20, 8000), 0.08);
        amp = Lag.kr(\amp.kr(0.15).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.1);
        gate = \gate.kr(1);
        
        // Multi-layer synthesis
        layer1 = Saw.ar(freq) * 0.4;
        layer2 = Saw.ar(freq * 1.005) * 0.25; // Slight detune
        layer3 = Saw.ar(freq * 0.998) * 0.2;  // Counter detune
        
        sig = layer1 + layer2 + layer3;
        sig = sig + (Saw.ar(freq * 2) * 0.1); // Harmonic
        sig = sig + (Saw.ar(freq * 0.5) * 0.05); // Sub-harmonic
        
        // Multi-stage filtering for richness
        sig = LPF.ar(sig, freq * 4);
        sig = HPF.ar(sig, freq * 0.5);
        
        sig = sig * amp * EnvGen.kr(Env.asr(0.02, 1, 0.15), gate, doneAction: 2);
        sig = sig.tanh * 0.6;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    SynthDef(\percNoise, {
        var sig, freq, amp, pan, gate;
        
        freq = Lag.kr(\freq.kr(440).clip(20, 8000), 0.25);
        amp = Lag.kr(\amp.kr(0.2).clip(0, 0.5), 0.15);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.2);
        gate = \gate.kr(1);
        
        sig = BPF.ar(GrayNoise.ar, freq, 0.1, 3);
        sig = sig * EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
        
        Out.ar(0, Pan2.ar(sig * amp, pan));
    }).add;
    
    "✓ Fallback SynthDefs loaded manually".postln;
};

// Step 4: Wait for SynthDefs to compile
1.wait;

// Step 5: Verify SynthDefs are loaded
"Checking SynthDef availability:".postln;
[\simpleGravObject, \richTexture, \percNoise, \auditoryDistortion].do { |name|
    if(name.asSymbol.synthDefExists) {
        ("✓ " ++ name ++ " is loaded").postln;
    } {
        ("✗ " ++ name ++ " is NOT loaded").postln;
    };
};

// Step 6: Update the global SynthDef list
"Updating global SynthDef list...".postln;
~nUPIC_SynthDefs = ~nUPIC_SynthDefs ? IdentityDictionary.new;
~nUPIC_SynthDefs[\available] = [\simpleGravObject, \richTexture, \percNoise, \auditoryDistortion];

"Available SynthDefs:".postln;
~nUPIC_SynthDefs[\available].do { |name, i|
    ("  " ++ (i+1) ++ ". " ++ name).postln;
};

// Step 7: Update UI menus if they exist
"Updating UI menus...".postln;
if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil } and: { ~nUPIC[\ui][\state].notNil }) {
    var state = ~nUPIC[\ui][\state];
    var controls = state[\controls];
    
    if(controls.notNil and: { controls[\synthDefMenu].notNil }) {
        var menu = controls[\synthDefMenu];
        var newItems = ~nUPIC_SynthDefs[\available].collect(_.asString);
        
        menu.items_(newItems);
        menu.value_(0); // Set to first item (simpleGravObject)
        
        "✓ SynthDef menu updated with items:".postln;
        newItems.do { |item, i|
            ("  " ++ (i+1) ++ ". " ++ item).postln;
        };
    } {
        "UI menu not found - you may need to restart nUPIC".postln;
    };
} {
    "nUPIC UI not loaded yet".postln;
};

// Step 8: Test SynthDef playback
"Testing SynthDef playback...".postln;
fork {
    // Test simpleGravObject
    "Testing simpleGravObject...".postln;
    var testSynth = Synth(\simpleGravObject, [\freq, 440, \amp, 0.2]);
    2.wait;
    testSynth.set(\gate, 0);
    0.5.wait;
    
    // Test richTexture if available
    if(\richTexture.asSymbol.synthDefExists) {
        "Testing richTexture...".postln;
        testSynth = Synth(\richTexture, [\freq, 660, \amp, 0.15]);
        2.wait;
        testSynth.set(\gate, 0);
        0.5.wait;
    };
    
    "✓ SynthDef tests completed".postln;
};

// Step 9: Final status report
"=== REPAIR COMPLETE ===".postln;
"If you still don't see richTexture in the menu, try:".postln;
"1. Close and restart the nUPIC window".postln;
"2. Or run: (~nUPIC_basePath +/+ \"nUPIC_Main.scd\").load;".postln;
"3. Make sure to select trajectories first, then choose a SynthDef from the menu".postln;
)
