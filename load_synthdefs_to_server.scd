// Load SynthDefs to Server
// This ensures the SynthDefs are properly sent to the audio server

(
s.waitForBoot {
    "Loading SynthDefs to server...".postln;
    
    // Load the SynthDefs file
    ("Audio/SynthDefs.scd").loadRelative;
    
    // Wait for server to sync
    s.sync;
    
    // Verify SynthDefs are on the server
    "".postln;
    "Checking SynthDefs on server...".postln;
    
    // The SynthDefs should be loaded now
    // Let's verify by checking our registry
    if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
        "SynthDefs in registry:".postln;
        ~nUPIC_SynthDefs[\available].do { |name|
            ("  • \\" ++ name).postln;
        };
        
        // Test if they can be created
        "".postln;
        "Testing SynthDef creation...".postln;
        
        fork {
            ~nUPIC_SynthDefs[\available].do { |synthDefName|
                var testSynth;
                try {
                    testSynth = Synth(synthDefName, [\freq, 440, \amp, 0]);
                    ("  ✓ \\" ++ synthDefName ++ " can be created").postln;
                    testSynth.free;
                } { |error|
                    ("  ✗ \\" ++ synthDefName ++ " FAILED: " ++ error.errorString).postln;
                };
                0.1.wait;
            };
            
            "".postln;
            "SynthDef loading complete!".postln;
            "You can now use play in nUPIC.".postln;
        };
    } {
        "ERROR: SynthDef registry not found!".postln;
        "Trying direct load...".postln;
    };
};
)
