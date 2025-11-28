// Test upicWavetable audio output
(
fork {
    // Boot server if needed
    if(s.serverRunning.not) {
        s.boot;
        s.waitForBoot;
    };
    
    // Load the upicWavetable file
    (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "Audio/upicWavetable.scd").load;
    
    // Wait for buffer to be ready
    2.wait;
    
    // Check buffer
    if(~nUPIC_wavetableBuffer.notNil) {
        ("Buffer allocated: bufnum=" ++ ~nUPIC_wavetableBuffer.bufnum ++ 
         ", numFrames=" ++ ~nUPIC_wavetableBuffer.numFrames).postln;
        
        // Test synth
        "Creating test synth...".postln;
        fork {
            var synth = Synth(\upicWavetable, [
                \freq, 440,
                \amp, 0.2,
                \gate, 1,
                \bufnum, ~nUPIC_wavetableBuffer.bufnum
            ]);
            
            "Playing A4 (440Hz)...".postln;
            1.wait;
            
            synth.set(\freq, 550);
            "Playing C#5 (550Hz)...".postln;
            1.wait;
            
            synth.set(\freq, 330);
            "Playing E4 (330Hz)...".postln;
            1.wait;
            
            synth.set(\gate, 0);
            "Test complete!".postln;
        };
    } {
        "ERROR: Buffer not allocated!".postln;
    };
};
)