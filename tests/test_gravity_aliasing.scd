// Test for aliasing in gravity ob synthdefs
// This test will sweep through high frequencies to check for aliasing artifacts

(
s.waitForBoot {
    var synthdef, testSynth;
    var startFreq = 2000;
    var endFreq = 8000;
    var duration = 10;
    
    // Load the SynthDefs if not already loaded
    ("Audio/SynthDefs.scd").loadRelative;
    
    s.sync;
    
    "Testing gravity ob synthdefs for aliasing...".postln;
    "Listen for aliasing artifacts (harsh digital noise, mirror frequencies)".postln;
    "".postln;
    
    // Test 1: simpleGravObject with frequency sweep
    "Test 1: simpleGravObject - Frequency sweep from % Hz to % Hz".format(startFreq, endFreq).postln;
    
    testSynth = Synth(\simpleGravObject, [
        \freq, startFreq,
        \amp, 0.2,
        \pan, 0,
        \mass, 2,
        \velocity, 5,
        \distance, 100,
        \width, 0.5
    ]);
    
    // Sweep frequency over time
    fork {
        100.do { |i|
            var freq = i.linexp(0, 99, startFreq, endFreq);
            testSynth.set(\freq, freq);
            ("Current frequency: % Hz".format(freq.round(1))).postln;
            0.1.wait;
        };
        
        testSynth.release;
        1.wait;
        
        "".postln;
        "Test 2: simpleGravObj2 - Frequency sweep from % Hz to % Hz".format(startFreq, endFreq).postln;
        
        // Test 2: simpleGravObj2 with frequency sweep
        testSynth = Synth(\simpleGravObj2, [
            \freq, startFreq,
            \amp, 0.2,
            \pan, 0,
            \mass, 2,
            \velocity, 5,
            \distance, 100,
            \width, 0.5,
            \radialVel, 0,
            \dopplerSens, 1.0
        ]);
        
        // Sweep frequency over time
        100.do { |i|
            var freq = i.linexp(0, 99, startFreq, endFreq);
            testSynth.set(\freq, freq);
            ("Current frequency: % Hz".format(freq.round(1))).postln;
            0.1.wait;
        };
        
        testSynth.release;
        1.wait;
        
        "".postln;
        "Test 3: High frequency static tones to check for aliasing".postln;
        
        // Test specific high frequencies that commonly show aliasing
        [3000, 4000, 5000, 6000, 7000, 7500].do { |freq|
            ("Testing % Hz for 2 seconds...".format(freq)).postln;
            testSynth = Synth(\simpleGravObject, [
                \freq, freq,
                \amp, 0.15,
                \pan, 0,
                \mass, 1,
                \velocity, 0,
                \distance, 100,
                \width, 0.5
            ]);
            2.wait;
            testSynth.release;
            0.5.wait;
        };
        
        "".postln;
        "Test 4: Checking oversampling settings in oscillators".postln;
        
        // Create a test with maximum mass and velocity to trigger all oscillator layers
        testSynth = Synth(\simpleGravObject, [
            \freq, 5000,
            \amp, 0.2,
            \pan, 0,
            \mass, 5,  // High mass triggers second harmonic
            \velocity, 20,  // High velocity for maximum modulation
            \distance, 20,  // Close distance for brightest sound
            \width, 0.8
        ]);
        
        "Playing high frequency (5000 Hz) with all modulation layers active...".postln;
        3.wait;
        
        testSynth.release;
        1.wait;
        
        "".postln;
        "Aliasing test complete!".postln;
        "".postln;
        "If you heard:".postln;
        "- Clean, pure tones at all frequencies: No aliasing (OS oscillators working correctly)".postln;
        "- Harsh digital noise, especially at high frequencies: Aliasing present".postln;
        "- Mirror frequencies or beating that shouldn't be there: Aliasing artifacts".postln;
    };
};
)
