// Simple direct test of nUPIC system
// This will help diagnose the audio issue

(
"=== SIMPLE nUPIC TEST ===".postln;

s.waitForBoot({
    "✓ Server booted".postln;
    
    // Load the SynthDef file directly
    "/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/Audio/SynthDefs.scd".loadPaths;
    
    // Wait for SynthDefs to compile and load
    s.sync;
    "✓ SynthDefs loaded".postln;
    
    // Test the synth with minimal parameters (no Doppler)
    "Testing simpleGravObject synth...".postln;
    
    ~testSynth = Synth(\simpleGravObject, [
        \freq, 440,
        \amp, 0.1,
        \pan, 0,
        \gate, 1
        // Note: radialVel and dopplerSens will default to 0, so no Doppler effect
    ]);
    
    "✓ Synth created - listening for 3 seconds...".postln;
    
    3.wait;
    
    ~testSynth.release;
    
    "✓ Test complete".postln;
    
    // Now test the nUPIC system
    1.wait;
    
    "Testing nUPIC initialization...".postln;
    "/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/nUPIC.scd".loadPaths;
    
    "=== TEST COMPLETE ===".postln;
    "If you heard a tone, the basic audio is working.".postln;
    "You can now try drawing trajectories in the main nUPIC window.".postln;
});
)
