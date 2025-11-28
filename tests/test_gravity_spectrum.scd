// Spectral analysis test for gravity ob synthdefs
// Opens a frequency analyzer to visually check for aliasing artifacts

(
s.waitForBoot {
    var testSynth;
    var testFreq = 5000;  // High frequency where aliasing is most visible
    
    // Load the SynthDefs if not already loaded
    ("Audio/SynthDefs.scd").loadRelative;
    
    s.sync;
    
    // Open frequency analyzer
    s.freqscope;
    
    "Spectral Analysis Test for Gravity Ob Synthdefs".postln;
    "".postln;
    "Watch the frequency analyzer for:".postln;
    "1. Clean peaks at the fundamental and harmonics = Good (no aliasing)".postln;
    "2. Mirror frequencies below fundamental = Aliasing!".postln;
    "3. Unexpected peaks that fold back from Nyquist = Aliasing!".postln;
    "".postln;
    
    fork {
        // Test simpleGravObject
        "Testing simpleGravObject at % Hz...".format(testFreq).postln;
        "Look for clean peak at % Hz and % Hz (2nd harmonic)".format(testFreq, testFreq * 2).postln;
        
        testSynth = Synth(\simpleGravObject, [
            \freq, testFreq,
            \amp, 0.3,
            \pan, 0,
            \mass, 5,  // High mass to trigger harmonics
            \velocity, 10,
            \distance, 50,
            \width, 0.5
        ]);
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // Test with very high frequency near Nyquist
        "".postln;
        "Testing at 15000 Hz (near Nyquist for 44.1kHz sample rate)...".postln;
        "If aliasing occurs, you'll see frequencies folding back below 15000 Hz".postln;
        
        testSynth = Synth(\simpleGravObject, [
            \freq, 15000,
            \amp, 0.2,
            \pan, 0,
            \mass, 1,
            \velocity, 0,
            \distance, 100,
            \width, 0.5
        ]);
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // Test with modulation that could cause aliasing
        "".postln;
        "Testing with high velocity modulation...".postln;
        "Modulation sidebands should be clean, not aliased".postln;
        
        testSynth = Synth(\simpleGravObject, [
            \freq, 8000,
            \amp, 0.25,
            \pan, 0,
            \mass, 3,
            \velocity, 20,  // High velocity for maximum modulation
            \distance, 30,
            \width, 0.7
        ]);
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // Compare with non-oversampled oscillator
        "".postln;
        "For comparison, here's a regular (non-oversampled) sawtooth at % Hz:".format(testFreq).postln;
        "You may see more aliasing artifacts with this".postln;
        
        testSynth = { 
            var sig = Saw.ar(testFreq) * 0.2;
            Out.ar(0, sig ! 2);
        }.play;
        
        5.wait;
        testSynth.free;
        1.wait;
        
        "".postln;
        "Now back to oversampled VarSawOS for comparison:".postln;
        
        testSynth = { 
            var sig = VarSawOS.ar(testFreq, 0, 0.5, oversample: 4) * 0.2;
            Out.ar(0, sig ! 2);
        }.play;
        
        5.wait;
        testSynth.free;
        
        "".postln;
        "Test complete! Check the frequency analyzer for any aliasing artifacts.".postln;
        "The oversampled oscillators should show cleaner spectra than regular ones.".postln;
    };
};
)
