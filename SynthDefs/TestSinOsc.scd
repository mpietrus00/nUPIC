// Simple SinOsc SynthDef for testing nUPIC trajectory frequency mapping
// This SynthDef uses basic sine wave oscillation to clearly demonstrate frequency changes

(
// Test SinOsc SynthDef - simple and clean for frequency testing
SynthDef(\testSinOsc, {
    arg freq = 440, amp = 0.1, gate = 1, pan = 0, 
        attack = 0.01, decay = 0.1, sustain = 0.7, release = 0.3;
    
    var sig, env;
    
    // Simple ADSR envelope
    env = EnvGen.kr(
        Env.adsr(attack, decay, sustain, release),
        gate,
        doneAction: 2
    );
    
    // Pure sine wave - most direct frequency representation
    sig = SinOsc.ar(freq, 0, amp * env);
    
    // Pan and output
    sig = Pan2.ar(sig, pan);
    Out.ar(0, sig);
}).add;

// Alternative with slight vibrato for more musical testing
SynthDef(\testSinOscVibrato, {
    arg freq = 440, amp = 0.1, gate = 1, pan = 0,
        attack = 0.01, decay = 0.1, sustain = 0.7, release = 0.3,
        vibratoRate = 5, vibratoDepth = 0.02;
    
    var sig, env, vibrato;
    
    // Simple ADSR envelope
    env = EnvGen.kr(
        Env.adsr(attack, decay, sustain, release),
        gate,
        doneAction: 2
    );
    
    // Add subtle vibrato for more musical character
    vibrato = SinOsc.kr(vibratoRate, 0, vibratoDepth);
    
    // Sine wave with vibrato
    sig = SinOsc.ar(freq * (1 + vibrato), 0, amp * env);
    
    // Pan and output
    sig = Pan2.ar(sig, pan);
    Out.ar(0, sig);
}).add;

// Very simple version - minimal parameters
SynthDef(\simpleSine, {
    arg freq = 440, amp = 0.1, gate = 1;
    
    var sig, env;
    
    // Simple envelope that follows gate
    env = EnvGen.kr(
        Env.asr(0.01, 1, 0.1),
        gate,
        doneAction: 2
    );
    
    // Pure sine wave
    sig = SinOsc.ar(freq, 0, amp * env);
    
    Out.ar(0, sig ! 2); // Stereo output
}).add;

"Test SinOsc SynthDefs loaded: \\testSinOsc, \\testSinOscVibrato, \\simpleSine".postln;

// Test function to quickly verify the SynthDefs work
~testSynthDefs = {
    "Testing SynthDefs...".postln;
    
    // Test simple sine
    Synth(\simpleSine, [\freq, 440, \amp, 0.1]);
    1.wait;
    
    // Test with vibrato
    Synth(\testSinOscVibrato, [\freq, 660, \amp, 0.1, \vibratoRate, 6]);
    1.wait;
    
    // Test main version
    Synth(\testSinOsc, [\freq, 880, \amp, 0.1]);
    
    "SynthDef test complete".postln;
};

"Call ~testSynthDefs.value; to test the SynthDefs".postln;
)
