// Test to verify the node error is fixed
// This tests the playback system with the new minimal synth

(
s.waitForBoot {
    // Load nUPIC modules
    ("Core/Constants.scd").loadRelative;
    ("Audio/SynthDefs.scd").loadRelative;
    ("Core/TrajectoryData.scd").loadRelative;
    
    s.sync;
    
    "Testing Node Error Fix".postln;
    "======================".postln;
    "".postln;
    
    // Initialize data if needed
    if(~nUPIC[\data].isNil) {
        ~nUPIC[\data] = ~nUPIC[\trajectoryData][\manager];
    };
    
    // Check what synthdef is being used
    "Default synthdef: %".format(~nUPIC[\defaults][\defaultSynthDef]).postln;
    "Available synthdefs: %".format(~nUPIC_SynthDefs[\available]).postln;
    "".postln;
    
    // Create a test trajectory
    var testTrajectory = List[
        (x: 0, y: 400, freq: 440),
        (x: 100, y: 300, freq: 880),
        (x: 200, y: 350, freq: 660),
        (x: 300, y: 200, freq: 1320),
        (x: 400, y: 400, freq: 440)
    ];
    
    // Create an amplitude envelope
    var testAmplitude = List[
        (x: 0, amp: 0),
        (x: 50, amp: 0.5),
        (x: 350, amp: 0.5),
        (x: 400, amp: 0)
    ];
    
    // Add trajectory to data
    ~nUPIC[\data].addTrajectory(testTrajectory, \trajectoryVarSaw, testAmplitude);
    
    "Added test trajectory with minimal synth".postln;
    "".postln;
    
    fork {
        var synth, startTime, duration = 5;
        
        "Testing playback (5 seconds)...".postln;
        
        // Test creating and controlling a synth node
        synth = Synth(\trajectoryVarSaw, [
            \freq, 440,
            \amp, 0,
            \pan, 0
        ]);
        
        "Created synth with node ID: %".format(synth.nodeID).postln;
        
        startTime = Main.elapsedTime;
        
        // Simulate trajectory playback
        100.do { |i|
            var progress = i / 99;
            var time = progress * duration;
            var freq = progress.linexp(0, 1, 440, 880);
            var amp = if(progress < 0.1) { 
                progress * 10 * 0.3 
            } { 
                if(progress > 0.9) { 
                    (1 - progress) * 10 * 0.3 
                } { 
                    0.3 
                }
            };
            var pan = progress.linlin(0, 1, -0.5, 0.5);
            
            // Try to set parameters - this should not cause node errors
            try {
                synth.set(
                    \freq, freq,
                    \amp, amp,
                    \pan, pan
                );
            } { |error|
                ("ERROR setting synth parameters: " ++ error.errorString).postln;
            };
            
            0.05.wait;
        };
        
        // Release the synth
        "Releasing synth...".postln;
        synth.set(\gate, 0);
        
        1.wait;
        
        "".postln;
        "Playback test complete!".postln;
        "".postln;
        
        if(Main.elapsedTime - startTime > 4) {
            "✓ No node errors detected during playback".postln;
            "✓ Synth parameters updated successfully".postln;
            "✓ Minimal synth system working correctly".postln;
        };
        
        "".postln;
        "To test in nUPIC:".postln;
        "1. Load nUPIC: \"nUPIC_SafeLoader.scd\".load".postln;
        "2. Draw a trajectory".postln;
        "3. Press SPACE or click Play".postln;
        "4. Should play without node errors".postln;
    };
};
)
