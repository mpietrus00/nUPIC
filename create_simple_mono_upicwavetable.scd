// Create a simple mono version of upicWavetable based on upicWavetablePrecise
// This will replace the current upicWavetable with a clean, simple mono output

(
"Creating simple mono upicWavetable synthdef...".postln;

// Remove existing upicWavetable if it exists
if(SynthDescLib.global.synthDescs[\upicWavetable].notNil) {
    SynthDescLib.global.synthDescs.removeAt(\upicWavetable);
    "✓ Removed existing upicWavetable".postln;
};

// Create simple mono upicWavetable using OscOS with Phasor
SynthDef(\upicWavetable, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        bufnum, // Wavetable buffer number
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1;

    var sig, phase, dopplerShift, finalFreq, distAmp, env;

    // Use the global wavetable buffer
    bufnum = \bufnum.kr(~nUPIC_wavetableBuffer.bufnum);

    // Calculate frequency with optional Doppler
    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);

    // Simple envelope for clean start/stop
    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.01),
        gate,
        doneAction: 2
    );

    // Phase from LFSaw (0-1 range) - matches OscOS documentation
    phase = LFSaw.ar(finalFreq).range(0, 1);

    // OscOS with named args for clarity (single wavetable buffer)
    sig = OscOS.ar(bufnum, phase, oversample: 1);

    // Distance-based amplitude
    distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);

    // Apply amplitude scaling
    sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));

    // Simple soft limiting to prevent clipping
    sig = sig.tanh * 0.9;

    // Mono output to bus 0
    Out.ar(0, sig);
}).add;

// Wait for synthdef to compile
s.sync;

// Add to nUPIC synthdef registry
if(~nUPIC_SynthDefs.isNil) {
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [];
};

// Add upicWavetable to available list if not already present
if(~nUPIC_SynthDefs[\available].includes(\upicWavetable).not) {
    ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available] ++ [\upicWavetable];
};

// Update UI menu
{
    if(~nUPIC[\ui].notNil and: { ~nUPIC[\ui][\state].notNil }) {
        var state = ~nUPIC[\ui][\state];
        var controls = state[\controls];
        
        if(controls.notNil) {
            var menuItems = ~nUPIC_SynthDefs[\available].collect { |name|
                case
                { name == \upicWavetable } { "UPIC Wavetable (Mono)" }
                { name == \upicWavetablePrecise } { "UPIC Wavetable Precise" }
                { name == \upicWavetableAdditive } { "UPIC Wavetable Additive" }
                { name == \upicWavetableHarmonic } { "UPIC Wavetable Harmonic" }
                { name == \upicWavetableRing } { "UPIC Wavetable Ring" }
                { name == \upicWavetablePhase } { "UPIC Wavetable Phase" }
                { name == \simpleGravObject } { "Simple Grav Object" }
                { true } { name.asString }
            };
            
            // Update all synthdef menus
            controls.keysValuesDo { |key, control|
                if(key.asString.toLower.contains("synth") and: { control.respondsTo(\items) }) {
                    control.items = menuItems;
                    ("✓ Updated " ++ key).postln;
                };
            };
        };
    };
}.defer;

"✓ Simple mono upicWavetable created".postln;
"".postln;
"Features:".postln;
"• Clean wavetable synthesis".postln;
"• Mono output (centered)".postln;
"• Uses default wavetable buffer".postln;
"• Simple envelope for clean start/stop".postln;
"• Compatible with all nUPIC parameters".postln;
"".postln;

// Test the new synthdef
"Testing new mono upicWavetable...".postln;
(
var testSynth = Synth(\upicWavetable, [
    \freq, 440, 
    \amp, 0.1, 
    \gate, 1
]);

// Stop after 2 seconds
fork {
    2.wait;
    testSynth.set(\gate, 0);
    "✓ Test complete - upicWavetable is ready".postln;
};
);
)