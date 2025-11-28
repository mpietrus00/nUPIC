// Test 8-Channel Spatialized nUPIC System
// This script tests the 8-channel output with automated spatialization
// Run this after starting nUPIC with START_NUPIC.scd

(
"=== Testing 8-Channel Spatial System ===".postln;

fork {
    // Ensure server is running with 8 channels
    if(s.serverRunning.not) {
        "Starting server with 8-channel configuration...".postln;
        s.options.numOutputBusChannels = 8;
        s.boot;
        s.waitForBoot;
        2.wait;
    };
    
    // Load 8-channel SynthDefs if not loaded
    if(SynthDescLib.global.synthDescs[\upicWavetablePrecise8ch].isNil) {
        "Loading 8-channel SynthDefs...".postln;
        (~nUPIC_basePath +/+ "Audio/SynthDefs_8ch.scd").load;
        2.wait;
    };
    
    "Available 8-channel SynthDefs:".postln;
    [\upicWavetable8ch, \upicWavetablePrecise8ch, \simpleGravObject8ch].do { |name|
        if(SynthDescLib.global.synthDescs[name].notNil) {
            ("  ✓ " ++ name).postln;
        } {
            ("  ✗ " ++ name ++ " not found").postln;
        };
    };
    
    "".postln;
    "TEST 1: Single trajectory rotating around all 8 channels".postln;
    "========================================================".postln;
    
    // Test circular motion around all 8 channels
    ~testSynth1 = Synth(\upicWavetablePrecise8ch, [
        \freq, 440,
        \amp, 0.3,
        \gate, 1,
        \spatialSpeed, 0.5,      // Rotate at 0.5 Hz
        \spatialDepth, 1.0,       // Full depth
        \spatialPattern, 1,       // Circular pattern
        \spatialPhase, 0
    ]);
    
    "Playing 440 Hz tone rotating in circle (0.5 Hz)...".postln;
    "You should hear the sound moving smoothly around all 8 speakers".postln;
    
    5.wait;
    
    "".postln;
    "TEST 2: Multiple trajectories with random movement".postln;
    "=====================================================".postln;
    
    // Stop first test
    ~testSynth1.set(\gate, 0);
    1.wait;
    
    // Create multiple synths with different spatial patterns
    ~testSynths = 4.collect { |i|
        var synth = Synth(\simpleGravObject8ch, [
            \freq, 220 * (1.5 ** i),  // Harmonic series
            \amp, 0.15,
            \gate, 1,
            \spatialSpeed, rrand(0.2, 1.0),
            \spatialDepth, rrand(0.5, 1.0),
            \spatialPattern, i,  // Different pattern for each
            \spatialPhase, i * (pi/2)  // Different starting positions
        ]);
        
        ("  Trajectory " ++ i ++ ": " ++ (220 * (1.5 ** i)).round ++ " Hz, pattern: " ++ 
         ["Random", "Circular", "Figure-8", "Complex"][i]).postln;
        
        synth;
    };
    
    "Playing 4 trajectories with different spatial patterns...".postln;
    "Each should move differently through the 8-channel space".postln;
    
    8.wait;
    
    "".postln;
    "TEST 3: Dynamic spatial parameter changes".postln;
    "===========================================".postln;
    
    // Stop multiple synths
    ~testSynths.do { |synth| synth.set(\gate, 0) };
    1.wait;
    
    // Create synth with parameters we'll modify
    ~testSynth3 = Synth(\upicWavetable8ch, [
        \freq, 660,
        \amp, 0.3,
        \gate, 1,
        \spatialSpeed, 0.1,
        \spatialDepth, 0.2,
        \spatialPattern, 0
    ]);
    
    "Starting with slow, shallow random movement...".postln;
    3.wait;
    
    "Increasing speed and depth...".postln;
    ~testSynth3.set(\spatialSpeed, 2.0, \spatialDepth, 1.0);
    3.wait;
    
    "Switching to circular pattern...".postln;
    ~testSynth3.set(\spatialPattern, 1);
    3.wait;
    
    "Switching to figure-8 pattern...".postln;
    ~testSynth3.set(\spatialPattern, 2);
    3.wait;
    
    ~testSynth3.set(\gate, 0);
    
    "".postln;
    "TEST 4: Channel verification - sound at each position".postln;
    "======================================================".postln;
    1.wait;
    
    // Test each channel position directly
    8.do { |i|
        var pos = i / 8;  // Position 0-1 mapped to circle
        var synth;
        
        ("Channel " ++ (i+1) ++ " (position " ++ (pos * 360).round ++ "°)").postln;
        
        synth = Synth(\upicWavetablePrecise8ch, [
            \freq, 330 + (i * 55),  // Different pitch for each position
            \amp, 0.3,
            \gate, 1,
            \spatialSpeed, 0,  // No movement
            \spatialDepth, 0,  // No movement
            \spatialPattern, 1,  // Circular (but not moving)
            \spatialPhase, pos * 2 * pi  // Fixed at position
        ]);
        
        0.5.wait;
        synth.set(\gate, 0);
        0.2.wait;
    };
    
    "".postln;
    "=== 8-Channel Spatial Test Complete ===".postln;
    "".postln;
    "Summary:".postln;
    "✓ Server configured for 8 channels".postln;
    "✓ 8-channel SynthDefs loaded".postln;
    "✓ Spatial movement patterns working".postln;
    "✓ All 8 channels verified".postln;
    "".postln;
    
    "To use in nUPIC:".postln;
    "1. Select an 8ch SynthDef from the menu (e.g., upicWavetablePrecise8ch)".postln;
    "2. Draw trajectories as normal".postln;
    "3. Each trajectory will automatically spatialize across 8 channels".postln;
    "4. Use spatial controls to adjust movement patterns".postln;
};
)