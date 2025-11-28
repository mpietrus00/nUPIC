// Test nUPIC system with new UPIC SynthDef
// Quick test to verify integration

(
s.waitForBoot {
    
    // Load the main nUPIC system
    "Loading nUPIC with UPIC SynthDef...".postln;
    "START_NUPIC.scd".loadRelative;
    
    // The system should now use upicWavetable as the default SynthDef
    
    fork {
        2.wait;  // Wait for system to initialize
        
        "".postln;
        "=====================================".postln;
        "nUPIC System with UPIC SynthDef Ready".postln;
        "=====================================".postln;
        "".postln;
        "The trajectory editor is now using the UPIC wavetable synthesizer!".postln;
        "".postln;
        "Features:".postln;
        "• Draw trajectories as usual in the main window".postln;
        "• The UPIC SynthDef will play them with wavetable synthesis".postln;
        "• Parameters like mass, velocity, distance affect the sound".postln;
        "• Default uses a sine wavetable".postln;
        "".postln;
        "To draw custom wavetables:".postln;
        "1. Draw a trajectory".postln;
        "2. Convert it to a wavetable with:".postln;
        "   ~customBuffer = ~createWavetableFromTrajectory.value(trajectory);".postln;
        "3. Set as default: ~nUPIC_DefaultWaveTable = ~customBuffer;".postln;
        "".postln;
        
        // Test that SynthDef is loaded
        if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            "Loaded SynthDefs: ".post;
            ~nUPIC_SynthDefs[\available].postln;
        };
        
        if(~nUPIC[\defaults].notNil) {
            "Default SynthDef: ".post;
            ~nUPIC[\defaults][\defaultSynthDef].postln;
        };
    };
};
)