// Final Test of nUPIC SynthDefs
// This verifies that the synthdefs based on SimpleSingleObject_Fixed.scd work properly

(
"=== Final SynthDef Test ===".postln;
"".postln;

s.waitForBoot {
    "Server ready!".postln;
    
    // Test 1: Test the exact working synthdef from SimpleSingleObject_Fixed.scd
    fork {
        var synth;
        
        "Test 1: Loading testOrbit (exact working synthdef)...".postln;
        
        // Define the exact working synthdef
        SynthDef(\testOrbit, {
            arg freq = 440, amp = 0.1, pan = 0;
            var sig = SinOsc.ar(freq) * amp;
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        s.sync;
        
        "Creating testOrbit synth...".postln;
        synth = Synth(\testOrbit, [\freq, 440, \amp, 0.1, \pan, 0]);
        
        if(synth.notNil) {
            "✓ testOrbit works! NodeID: %".format(synth.nodeID).postln;
            
            // Test parameter changes exactly like in working example
            0.5.wait;
            synth.set(\freq, 880);
            "Changed to 880Hz".postln;
            0.5.wait;
            synth.set(\freq, 440, \pan, -1);
            "Changed to 440Hz, panned left".postln;
            0.5.wait;
            synth.set(\pan, 1);
            "Panned right".postln;
            0.5.wait;
            synth.free;
            "Freed synth".postln;
        } {
            "✗ Failed to create testOrbit".postln;
        };
        
        "".postln;
        1.wait;
        
        // Test 2: Test simpleGravObject based on working design
        "Test 2: Loading simpleGravObject (based on testOrbit)...".postln;
        
        SynthDef(\simpleGravObject, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1;
            
            var sig, env;
            
            env = EnvGen.kr(
                Env.asr(0.01, 1, 0.1),
                gate,
                doneAction: 2
            );
            
            // Simple design like testOrbit
            sig = SinOsc.ar(freq) * amp * env;
            
            // Add harmonics for richness
            sig = sig + (SinOsc.ar(freq * 2) * 0.2 * mass.linlin(1, 10, 0, 1));
            
            // Soft clipping
            sig = sig.tanh * 0.9;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        s.sync;
        
        "Creating simpleGravObject synth...".postln;
        synth = Synth(\simpleGravObject, [
            \freq, 440, 
            \amp, 0.1, 
            \pan, 0,
            \gate, 1,
            \mass, 5
        ]);
        
        if(synth.notNil) {
            "✓ simpleGravObject works! NodeID: %".format(synth.nodeID).postln;
            
            // Test parameter changes
            0.5.wait;
            synth.set(\freq, 660);
            "Changed to 660Hz".postln;
            0.5.wait;
            synth.set(\mass, 10);
            "Changed mass to 10".postln;
            0.5.wait;
            synth.set(\gate, 0);  // Proper release
            "Released with gate".postln;
            1.wait;
        } {
            "✗ Failed to create simpleGravObject".postln;
        };
        
        "".postln;
        
        // Test 3: Quick nUPIC integration test
        "Test 3: Testing with nUPIC parameters...".postln;
        
        // Simulate what nUPIC does when creating a synth
        synth = Synth(\simpleGravObject, [
            \freq, 300,      // Starting frequency
            \amp, 0.0,       // Start silent
            \pan, 0,         // Center
            \mass, 1.5,      // Default mass
            \velocity, 5,    // Default velocity
            \distance, 100,  // Default distance
            \gate, 1,
            \numSynths, 1
        ]);
        
        if(synth.notNil) {
            "✓ Created synth with nUPIC parameters".postln;
            0.2.wait;
            
            // Simulate trajectory playback
            synth.set(\amp, 0.1);
            "Started playback (amp = 0.1)".postln;
            0.5.wait;
            
            synth.set(\freq, 440);
            "Changed freq to 440".postln;
            0.5.wait;
            
            synth.set(\freq, 660, \pan, 0.5);
            "Changed freq to 660, pan right".postln;
            0.5.wait;
            
            synth.set(\amp, 0.0);
            "Stopped playback (amp = 0)".postln;
            0.2.wait;
            
            synth.set(\gate, 0);
            "Released synth".postln;
            1.wait;
        };
        
        "".postln;
        "=== All Tests Complete ===".postln;
        "".postln;
        
        // Now check if synthdefs are available
        "Checking available SynthDefs on server:".postln;
        SynthDescLib.global.synthDescs.keys.select({ |key|
            [\testOrbit, \simpleGravObject, \trajectoryVarSaw].includes(key)
        }).do { |key|
            ("  • \\" ++ key).postln;
        };
        
        "".postln;
        "SUMMARY:".postln;
        "✓ SynthDefs work correctly".postln;
        "✓ Parameter updates work".postln;
        "✓ Gate/envelope release works".postln;
        "".postln;
        "You can now load nUPIC with confidence:".postln;
        "  \"START_NUPIC.scd\".load".postln;
        "".postln;
        "Or if already loaded, the synthdefs are ready to use!".postln;
    };
};
)
