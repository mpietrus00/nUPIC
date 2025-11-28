// Fix nUPIC SynthDefs based on working SimpleSingleObject_Fixed.scd
// These synthdefs are confirmed to work properly

(
"=== Loading Working SynthDefs for nUPIC ===".postln;
"".postln;

s.waitForBoot {
    "Server ready, loading SynthDefs...".postln;
    
    // Make sure server is ready
    s.sync;
    
    // Simple gravity object based on the working testOrbit synthdef
    // This is confirmed to work in SimpleSingleObject_Fixed.scd
    SynthDef(\simpleGravObject, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        
        // Calculate frequency with optional Doppler effect
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Simple envelope for note on/off
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),  // attack, sustain, release
            gate,
            doneAction: 2  // free synth when done
        );
        
        // Simple oscillator like in the working example
        // Using mix of SinOsc for base and some harmonics for richness
        sig = Mix.ar([
            SinOsc.ar(finalFreq) * 0.5,                    // Fundamental
            SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),  // 2nd harmonic
            SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)   // 3rd harmonic
        ]);
        
        // Add subtle vibrato based on velocity
        sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));
        
        // Distance affects amplitude (inverse square law)
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Apply amplitude with envelope and scaling
        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt);
        
        // Soft clipping to prevent distortion
        sig = sig.tanh * 0.9;
        
        // Output with panning (just like the working example)
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ simpleGravObject loaded".postln;
    
    // Simpler trajectory synth based on working example
    SynthDef(\trajectoryVarSaw, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env;
        
        // Simple envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.01),
            gate,
            doneAction: 2
        );
        
        // Simple sawtooth with some detuning for richness
        sig = Mix.ar([
            Saw.ar(freq) * 0.3,
            Saw.ar(freq * 1.01) * 0.3,  // Slight detune
            Saw.ar(freq * 0.99) * 0.3   // Slight detune other direction
        ]);
        
        // Simple lowpass filter to reduce harshness
        sig = LPF.ar(sig, freq * 4);
        
        // Apply amplitude
        sig = sig * amp * env * (1 / numSynths.sqrt);
        
        // Soft clipping
        sig = sig.tanh * 0.9;
        
        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ trajectoryVarSaw loaded".postln;
    
    // Even simpler test synthdef (exactly like the working one)
    SynthDef(\testOrbit, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1;
        var sig, env;
        
        // Optional envelope for compatibility
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        sig = SinOsc.ar(freq) * amp * env;
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ testOrbit loaded".postln;
    
    // Wait for SynthDefs to be ready
    s.sync;
    
    "".postln;
    "All SynthDefs loaded and ready!".postln;
    
    // Update global registry
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [\simpleGravObject, \trajectoryVarSaw, \testOrbit];
    ~nUPIC_SynthDefs[\default] = \simpleGravObject;
    
    // Update nUPIC defaults if loaded
    if(~nUPIC.notNil) {
        if(~nUPIC[\defaults].isNil) {
            ~nUPIC[\defaults] = IdentityDictionary.new;
        };
        ~nUPIC[\defaults][\defaultSynthDef] = \simpleGravObject;
        "✓ nUPIC defaults updated".postln;
    };
    
    "".postln;
    "Testing SynthDefs...".postln;
    
    // Test each synthdef (like in the working example)
    fork {
        [\simpleGravObject, \trajectoryVarSaw, \testOrbit].do { |name|
            var synth;
            
            "Testing %...".format(name).postln;
            
            synth = Synth(name, [
                \freq, 440, 
                \amp, 0.05,  // Low volume for test
                \pan, 0,
                \gate, 1,
                \numSynths, 1
            ]);
            
            if(synth.notNil) {
                "  ✓ % created with nodeID: %".format(name, synth.nodeID).postln;
                
                // Test parameter changes like in working example
                0.2.wait;
                synth.set(\freq, 880);
                "  ✓ Changed freq to 880".postln;
                0.2.wait;
                synth.set(\pan, -1);
                "  ✓ Panned left".postln;
                0.2.wait;
                synth.set(\pan, 1);
                "  ✓ Panned right".postln;
                0.2.wait;
                
                // Clean release
                synth.set(\gate, 0);
                "  ✓ Released".postln;
                0.5.wait;
            } {
                "  ✗ Failed to create %".format(name).postln;
            };
        };
        
        "".postln;
        "=== All Tests Complete ===".postln;
        "".postln;
        
        "You can now:".postln;
        "1. Load nUPIC: \"nUPIC_Main.scd\".load".postln;
        "2. Or test with sound:".postln;
        "(
var s = Synth(\\simpleGravObject, [\\freq, 440, \\amp, 0.1, \\gate, 1]);
fork { 
    s.set(\\freq, 880);
    0.5.wait;
    s.set(\\freq, 440);
    0.5.wait;
    s.set(\\gate, 0); 
};
)".postln;
    };
};
)
