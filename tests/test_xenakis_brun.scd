// Test Xenakis and Herbert Brün inspired SynthDefs
// Demonstrates the aesthetic and sonic characteristics of each

(
s.waitForBoot {
    // Load the Xenakis/Brün SynthDefs
    ("Audio/XenakisBrun_SynthDefs.scd").loadRelative;
    
    s.sync;
    
    "Testing Xenakis and Herbert Brün inspired SynthDefs".postln;
    "===================================================".postln;
    "".postln;
    
    fork {
        var testSynth;
        
        // 1. Test stochasticXenakis - GENDYN-inspired
        "1. STOCHASTIC XENAKIS (GENDYN-inspired)".postln;
        "   Listen for: Evolving stochastic textures, random walks in frequency".postln;
        
        testSynth = Synth(\stochasticXenakis, [
            \freq, 200,
            \amp, 0.3,
            \pan, 0,
            \mass, 5,      // Medium complexity
            \velocity, 10,  // Moderate stochastic rate
            \distance, 150,
            \width, 0.5
        ]);
        
        // Modulate parameters over time
        fork {
            20.do { |i|
                testSynth.set(\velocity, i.linlin(0, 19, 2, 20));
                testSynth.set(\mass, i.linlin(0, 19, 1, 10));
                0.25.wait;
            };
        };
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // 2. Test sieveHarmonics - Mathematical sieves
        "".postln;
        "2. SIEVE HARMONICS (Xenakis' sieve theory)".postln;
        "   Listen for: Mathematically filtered harmonics, metallic timbres".postln;
        
        testSynth = Synth(\sieveHarmonics, [
            \freq, 150,
            \amp, 0.25,
            \pan, 0,
            \mass, 3,      // Sieve modulus
            \velocity, 5,   // Sieve residue
            \distance, 200,
            \width, 0.6
        ]);
        
        // Change sieve parameters
        fork {
            [2, 5, 3, 7, 4].do { |mass|
                1.wait;
                testSynth.set(\mass, mass);
                ("Sieve modulus: " ++ mass).postln;
            };
        };
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // 3. Test sawdustBrun - Micro-temporal composition
        "".postln;
        "3. SAWDUST BRÜN (Micro-temporal approach)".postln;
        "   Listen for: Granular textures, discontinuous segments".postln;
        
        testSynth = Synth(\sawdustBrun, [
            \freq, 400,
            \amp, 0.3,
            \pan, 0,
            \mass, 4,       // Complexity of links
            \velocity, 15,  // Grain rate
            \distance, 100,
            \width, 0.7
        ]);
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // 4. Test achorripsis - Stochastic distributions
        "".postln;
        "4. ACHORRIPSIS (Stochastic distributions)".postln;
        "   Listen for: Poisson-distributed events, exponential decays".postln;
        
        testSynth = Synth(\achorripsis, [
            \freq, 300,
            \amp, 0.25,
            \pan, 0,
            \mass, 6,       // Event density
            \velocity, 12,  // Duration distribution
            \distance, 150,
            \width, 0.5
        ]);
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // 5. Test infraudibles - Brün's unheard components
        "".postln;
        "5. INFRAUDIBLES (Brün's inaudible components)".postln;
        "   Listen for: Beating from sub-audio, ring modulation artifacts".postln;
        
        testSynth = Synth(\infraudibles, [
            \freq, 440,
            \amp, 0.25,
            \pan, 0,
            \mass, 5,       // Ultra-component ratio
            \velocity, 10,  // Sub-component frequency
            \distance, 200,
            \width, 0.6
        ]);
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // 6. Test metastaseis - Mass glissandi
        "".postln;
        "6. METASTASEIS (Mass glissandi)".postln;
        "   Listen for: Multiple sliding tones, dense glissando textures".postln;
        
        testSynth = Synth(\metastaseis, [
            \freq, 300,
            \amp, 0.2,
            \pan, 0,
            \mass, 4,       // Glissando range
            \velocity, 8,   // Glissando speed
            \distance, 100,
            \width, 0.7
        ]);
        
        // Modulate frequency to create additional glissandi
        fork {
            10.do { |i|
                testSynth.set(\freq, i.linexp(0, 9, 200, 800));
                0.5.wait;
            };
        };
        
        5.wait;
        testSynth.release;
        1.wait;
        
        // 7. Combined texture - Multiple voices
        "".postln;
        "7. COMBINED TEXTURE - Multiple voices".postln;
        "   Creating a Xenakis-like dense texture with multiple synthdefs".postln;
        
        // Create multiple overlapping voices
        fork {
            var synths = List.new;
            
            // Start different synthdefs at different times
            synths.add(Synth(\stochasticXenakis, [
                \freq, 100, \amp, 0.15, \pan, -0.7,
                \mass, 3, \velocity, 5, \distance, 200, \width, 0.4
            ]));
            
            0.5.wait;
            
            synths.add(Synth(\sieveHarmonics, [
                \freq, 200, \amp, 0.1, \pan, 0.7,
                \mass, 5, \velocity, 8, \distance, 150, \width, 0.6
            ]));
            
            0.5.wait;
            
            synths.add(Synth(\metastaseis, [
                \freq, 400, \amp, 0.1, \pan, 0,
                \mass, 2, \velocity, 10, \distance, 100, \width, 0.5
            ]));
            
            1.wait;
            
            synths.add(Synth(\achorripsis, [
                \freq, 150, \amp, 0.12, \pan, -0.3,
                \mass, 7, \velocity, 15, \distance, 180, \width, 0.7
            ]));
            
            // Let them play together
            5.wait;
            
            // Release them in sequence
            synths.do { |synth|
                synth.release;
                0.5.wait;
            };
        };
        
        8.wait;
        
        "".postln;
        "Test complete!".postln;
        "".postln;
        "These SynthDefs can be used in nUPIC for trajectory synthesis".postln;
        "The trajectory parameters (mass, velocity, distance, width) control:".postln;
        "  - Stochastic behavior and randomness".postln;
        "  - Mathematical sieve patterns".postln;
        "  - Granular density and texture".postln;
        "  - Glissando ranges and speeds".postln;
    };
};
)
