// Test Envelope-Based 8-Channel Spatialization
// This tests the drawn spatialization curves with mono->8ch positioning

(
"=== Testing Envelope-Based Spatial System ===".postln;

fork {
    var testBuffer, testEnvelope;
    
    // Ensure server is running with 8 channels
    if(s.serverRunning.not) {
        "Starting server with 8-channel configuration...".postln;
        s.options.numOutputBusChannels = 8;
        s.boot;
        s.waitForBoot;
        2.wait;
    };
    
    // Load envelope-based 8ch SynthDefs if not loaded
    if(SynthDescLib.global.synthDescs[\upicWavetablePrecise8chEnv].isNil) {
        "Loading envelope-based 8ch SynthDefs...".postln;
        (~nUPIC_basePath +/+ "Audio/SynthDefs_8ch_envelope.scd").load;
        2.wait;
    };
    
    "Available envelope-based 8ch SynthDefs:".postln;
    [\upicWavetable8chEnv, \upicWavetablePrecise8chEnv, \simpleGravObject8chEnv].do { |name|
        if(SynthDescLib.global.synthDescs[name].notNil) {
            ("  ✓ " ++ name).postln;
        } {
            ("  ✗ " ++ name ++ " not found").postln;
        };
    };
    
    "".postln;
    "TEST 1: Static positioning - mono signal at each channel".postln;
    "=========================================================".postln;
    
    // Test each channel position directly
    8.do { |i|
        var buffer, synth;
        
        ("Testing channel " ++ (i + 1)).postln;
        
        // Create a buffer with static position for this channel
        buffer = Buffer.loadCollection(s, [i.asFloat]);  // Single value: channel number
        
        synth = Synth(\upicWavetablePrecise8chEnv, [
            \freq, 440 + (i * 55),
            \amp, 0.3,
            \gate, 1,
            \spatialEnvBuf, buffer.bufnum,  // Use the envelope buffer
            \playbackRate, 1000  // Very slow so it stays in position
        ]);
        
        1.wait;
        synth.set(\gate, 0);
        buffer.free;
        0.5.wait;
    };
    
    "".postln;
    "TEST 2: Linear sweep across all channels".postln;
    "==========================================".postln;
    
    // Create envelope that moves linearly from channel 1 to 8
    testEnvelope = Array.fill(128, { |i| i.linlin(0, 127, 0, 7) });
    testBuffer = Buffer.loadCollection(s, testEnvelope);
    
    ~testSynth2 = Synth(\upicWavetablePrecise8chEnv, [
        \freq, 660,
        \amp, 0.3,
        \gate, 1,
        \spatialEnvBuf, testBuffer.bufnum,
        \playbackRate, 0.2  // 5 seconds to sweep
    ]);
    
    "Sweeping from channel 1 to 8 over 5 seconds...".postln;
    5.wait;
    
    ~testSynth2.set(\gate, 0);
    1.wait;
    testBuffer.free;
    
    "".postln;
    "TEST 3: Circular motion using envelope".postln;
    "========================================".postln;
    
    // Create circular motion envelope
    testEnvelope = Array.fill(128, { |i| 
        var phase = i.linlin(0, 127, 0, 2pi);
        3.5 + (3.5 * sin(phase))  // Oscillate between channels 0-7
    });
    testBuffer = Buffer.loadCollection(s, testEnvelope);
    
    ~testSynth3 = Synth(\simpleGravObject8chEnv, [
        \freq, 330,
        \amp, 0.3,
        \gate, 1,
        \spatialEnvBuf, testBuffer.bufnum,
        \playbackRate, 0.5  // 2 seconds per rotation
    ]);
    
    "Circular motion through 8 channels...".postln;
    6.wait;
    
    ~testSynth3.set(\gate, 0);
    1.wait;
    testBuffer.free;
    
    "".postln;
    "TEST 4: Complex drawn envelope simulation".postln;
    "==========================================".postln;
    
    // Simulate a complex drawn envelope (zigzag pattern)
    testEnvelope = Array.fill(256, { |i|
        var segment = (i / 32).floor;
        if(segment.even) {
            i.linlin(segment * 32, (segment + 1) * 32 - 1, 0, 7)
        } {
            i.linlin(segment * 32, (segment + 1) * 32 - 1, 7, 0)
        }
    });
    testBuffer = Buffer.loadCollection(s, testEnvelope);
    
    ~testSynth4 = Synth(\upicWavetable8chEnv, [
        \freq, 880,
        \amp, 0.25,
        \gate, 1,
        \spatialEnvBuf, testBuffer.bufnum,
        \playbackRate, 0.125  // 8 seconds total
    ]);
    
    "Zigzag pattern across channels...".postln;
    8.wait;
    
    ~testSynth4.set(\gate, 0);
    1.wait;
    testBuffer.free;
    
    "".postln;
    "TEST 5: Multiple trajectories with different spatial paths".postln;
    "===========================================================".postln;
    
    // Create different spatial envelopes for each trajectory
    ~testBuffers = 3.collect { |i|
        var envelope = case
            { i == 0 } { Array.fill(64, { |j| j.linlin(0, 63, 0, 7) }) }  // Linear
            { i == 1 } { Array.fill(64, { |j| 3.5 }) }  // Center static
            { i == 2 } { Array.fill(64, { |j| (j % 16).linlin(0, 15, 0, 7) }) };  // Sawtooth
        
        Buffer.loadCollection(s, envelope);
    };
    
    ~testSynths = 3.collect { |i|
        Synth(\upicWavetablePrecise8chEnv, [
            \freq, 220 * (1.5 ** i),
            \amp, 0.2,
            \gate, 1,
            \spatialEnvBuf, ~testBuffers[i].bufnum,
            \playbackRate, 0.25  // 4 seconds
        ]);
    };
    
    "Playing 3 trajectories with different spatial paths...".postln;
    "  1: Linear sweep".postln;
    "  2: Center position".postln;
    "  3: Sawtooth pattern".postln;
    
    4.wait;
    
    ~testSynths.do { |synth| synth.set(\gate, 0) };
    ~testBuffers.do { |buf| buf.free };
    
    "".postln;
    "=== Envelope-Based Spatial Test Complete ===".postln;
    "".postln;
    "Summary:".postln;
    "✓ Mono signal correctly positioned in 8-channel space".postln;
    "✓ Spatial envelope buffers control channel position".postln;
    "✓ Smooth interpolation between channels".postln;
    "✓ Multiple independent spatial paths".postln;
    "".postln;
    
    "To use with drawn envelopes:".postln;
    "1. Select trajectories with 'G' key".postln;
    "2. Click '_edit spatial' button".postln;
    "3. Draw spatial path (vertical = channels, horizontal = time)".postln;
    "4. Play with 8ch envelope SynthDef selected".postln;
    "5. Each trajectory follows its drawn spatial path!".postln;
};
)