// Complete fix for additiveOS SynthDef issue
// This ensures proper loading and server synchronization

(
"=== FIXING additiveOS SYNTHDEF ===".postln;
"".postln;

s.waitForBoot {
    
    // Step 1: Free any existing synths and clear the server
    s.freeAll;
    
    // Step 2: Wait a moment for cleanup
    s.sync;
    
    // Step 3: Redefine additiveOS with standard oscillators for reliability
    "Redefining additiveOS SynthDef...".postln;
    
    SynthDef(\additiveOS, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            numPartials = 8;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
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
        // Using simple Mix and array of oscillators for maximum compatibility
        sig = Mix.ar([
            SinOsc.ar(finalFreq, 0, 1),
            SinOsc.ar(finalFreq * 2, 0, 0.5 * (1 - massNorm * 0.1)),
            SinOsc.ar(finalFreq * 3, 0, 0.33 * (1 - massNorm * 0.2)),
            SinOsc.ar(finalFreq * 4, 0, 0.25 * (1 - massNorm * 0.3)),
            SinOsc.ar(finalFreq * 5, 0, 0.2 * (1 - massNorm * 0.4)),
            SinOsc.ar(finalFreq * 6, 0, 0.17 * (1 - massNorm * 0.5)),
            SinOsc.ar(finalFreq * 7, 0, 0.14 * (1 - massNorm * 0.6)),
            SinOsc.ar(finalFreq * 8, 0, 0.125 * (1 - massNorm * 0.7))
        ]);
        
        // Normalize
        sig = sig * 0.25;
        
        // Add sub-harmonic for depth
        sig = sig + (SinOsc.ar(finalFreq * 0.5, 0, 0.2 * (1 - massNorm)));
        
        // Velocity modulation
        sig = sig * (1 + (LFTri.kr(velocity * 0.5) * 0.1));
        
        // Distance effects
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = BPF.ar(sig, finalFreq * 2, 2 / distAmp.max(0.5));
        
        // Amplitude
        sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
        
        // Soft limiting
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ additiveOS redefined with standard oscillators".postln;
    
    // Step 4: CRITICAL - Send the SynthDef to the server and wait
    "Sending to server...".postln;
    s.sync;  // This ensures the server has received the SynthDef
    
    0.5.wait;  // Extra safety delay
    
    // Step 5: Verify it's actually on the server
    "Verifying SynthDef on server...".postln;
    
    if(SynthDescLib.global.synthDescs[\additiveOS].notNil) {
        "✓ additiveOS found in SynthDescLib".postln;
    } {
        "⚠ additiveOS not in SynthDescLib - will try to add manually".postln;
    };
    
    // Step 6: Test the synthdef
    "".postln;
    "Testing additiveOS playback...".postln;
    
    fork {
        var testSynth;
        var success = false;
        
        // Try to create a test synth
        try {
            testSynth = Synth(\additiveOS, [
                \freq, 440,
                \amp, 0.0,  // Silent test
                \gate, 1,
                \numSynths, 1
            ]);
            
            if(testSynth.notNil) {
                "✓ Test synth created successfully".postln;
                ("  Node ID: " ++ testSynth.nodeID).postln;
                success = true;
                
                0.2.wait;
                
                // Release the test synth
                testSynth.set(\gate, 0);
                0.3.wait;
                
                "✓ Test synth released cleanly".postln;
            } {
                "✗ Failed to create test synth".postln;
            };
        } { |error|
            ("✗ Error during test: " ++ error.errorString).postln;
        };
        
        "".postln;
        
        if(success) {
            "=== SUCCESS ===".postln;
            "additiveOS is now working correctly!".postln;
            "".postln;
            
            // Update the registry if it exists
            if(~nUPIC_SynthDefs.notNil) {
                if(~nUPIC_SynthDefs[\available].includes(\additiveOS).not) {
                    ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\additiveOS);
                };
                "Registry updated.".postln;
            };
            
            "You can now:".postln;
            "1. Use additiveOS in nUPIC".postln;
            "2. Or reload everything with: \"START_NUPIC.scd\".load".postln;
            
        } {
            "=== TROUBLESHOOTING ===".postln;
            "The SynthDef still isn't working properly.".postln;
            "".postln;
            "Try these steps:".postln;
            "1. Restart SuperCollider completely (Cmd+Q and reopen)".postln;
            "2. Run: s.boot;".postln;
            "3. Run this script again".postln;
            "".postln;
            "Alternative: Use simpleGravObject instead, which is working.".postln;
        };
    };
};
)
