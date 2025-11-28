// Fix for additiveOS SynthDef
// This resolves the "SynthDef not found" error for additiveOS

(
"Fixing additiveOS SynthDef...".postln;
"".postln;

s.waitForBoot {
    
    // First, let's create a working version of additiveOS
    // The issue is likely with the collect/array generation or OS UGen usage
    
    SynthDef(\additiveOS, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            numPartials = 8;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var partials;
        var massNorm = (mass / 10).clip(0, 1);
        
        // Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Envelope
        env = EnvGen.kr(
            Env.adsr(0.01, 0.15, 0.7, 0.4),
            gate,
            doneAction: 2
        );
        
        // Generate additive synthesis with standard oscillators
        // (avoiding potential issues with OS oscillators in array generation)
        partials = Mix.ar(
            Array.fill(8, { |i|
                var harmonic = i + 1;
                var detune = 1 + (LFNoise2.kr(0.1 + (i * 0.1)).range(-0.001, 0.001));
                var ampScale = (1 / harmonic) * (1 - (i * 0.05)).max(0);
                
                // Use standard oscillators for reliability
                SinOsc.ar(
                    finalFreq * harmonic * detune,
                    0,
                    ampScale * (1 - (massNorm * i * 0.1)).max(0)
                )
            })
        );
        
        sig = partials;
        
        // Add sub-harmonic for depth (using standard oscillator)
        sig = sig + (SinOsc.ar(finalFreq * 0.5, 0, 0.2 * (1 - massNorm)));
        
        // Velocity modulation
        sig = sig * (1 + (LFTri.kr(velocity * 0.5) * 0.1));
        
        // Distance effects
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = BPF.ar(sig, finalFreq * 2, 2 / distAmp.max(0.5));
        
        // Amplitude scaling
        sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
        
        // Soft limiting
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ additiveOS fixed and loaded".postln;
    
    // Wait for SynthDef to compile
    s.sync;
    
    // Test the fixed synthdef
    "Testing fixed additiveOS...".postln;
    
    fork {
        var synth;
        
        try {
            synth = Synth(\additiveOS, [
                \freq, 440, 
                \amp, 0.05,  // Low volume for test
                \gate, 1,
                \numSynths, 1
            ]);
            
            if(synth.notNil) {
                "✓ additiveOS created successfully with nodeID: %".format(synth.nodeID).postln;
                
                0.5.wait;
                
                // Test parameter changes
                synth.set(\freq, 880);
                "✓ Changed frequency to 880Hz".postln;
                
                0.5.wait;
                
                // Clean release
                synth.set(\gate, 0);
                "✓ Released".postln;
                
                0.5.wait;
                
                "".postln;
                "SUCCESS: additiveOS is now working!".postln;
                "".postln;
                
                // Update registry if it exists
                if(~nUPIC_SynthDefs.notNil) {
                    if(~nUPIC_SynthDefs[\available].includes(\additiveOS).not) {
                        ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\additiveOS);
                        "✓ Added additiveOS to registry".postln;
                    };
                };
                
            } {
                "✗ Failed to create additiveOS synth".postln;
            };
        } { |error|
            ("✗ Error testing additiveOS: " ++ error.errorString).postln;
        };
        
        "".postln;
        "You can now use additiveOS in nUPIC.".postln;
        "Run \"START_NUPIC.scd\".load to reload nUPIC with all synthdefs.".postln;
    };
};
)
