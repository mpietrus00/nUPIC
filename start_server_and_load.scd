// Complete Server Startup and SynthDef Loading
// This ensures everything is properly initialized

(
// Step 1: Check server status
"=== SuperCollider Server Startup Sequence ===".postln;
"".postln;

if(Server.default.serverRunning.not) {
    "Server is not running. Starting server...".postln;
    Server.default.boot;
} {
    "Server is already running.".postln;
};

// Step 2: Wait for server to be ready and load everything
Server.default.waitForBoot {
    "Server is ready!".postln;
    "".postln;
    
    // Step 3: Load and compile SynthDefs
    "Loading SynthDef definitions...".postln;
    
    fork {
        // First, ensure the SynthDef file is loaded
        if(File.exists("Audio/SynthDefs.scd")) {
            ("Audio/SynthDefs.scd").loadRelative;
            "SynthDef file loaded.".postln;
        } {
            "ERROR: Audio/SynthDefs.scd not found!".postln;
            "Creating from current directory...".postln;
            (thisProcess.nowExecutingPath.dirname +/+ "Audio/SynthDefs.scd").load;
        };
        
        // Wait for definitions to compile
        1.wait;
        s.sync;
        
        // Step 4: Verify SynthDefs are available
        "".postln;
        "Verifying SynthDefs...".postln;
        
        // Create a test synth for each definition
        if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ~nUPIC_SynthDefs[\available].do { |synthDefName|
                var testSynth;
                
                // Try to create a silent test synth
                try {
                    testSynth = Synth(synthDefName, [
                        \freq, 440,
                        \amp, 0,  // Silent
                        \pan, 0,
                        \mass, 1,
                        \velocity, 0,
                        \distance, 100,
                        \width, 0.5
                    ]);
                    
                    if(testSynth.notNil) {
                        ("✓ SynthDef '\\" ++ synthDefName ++ "' is loaded on server").postln;
                        // Immediately free the test synth
                        testSynth.set(\gate, 0);
                    };
                } { |error|
                    ("✗ SynthDef '\\" ++ synthDefName ++ "' FAILED TO LOAD").postln;
                    ("  Error: " ++ error.errorString).postln;
                };
                
                0.2.wait;
            };
        } {
            "WARNING: SynthDef registry not found.".postln;
        };
        
        1.wait;
        
        // Step 5: Server status report
        "".postln;
        "=== Server Status ===".postln;
        ("Sample Rate: " ++ s.sampleRate ++ " Hz").postln;
        ("Audio Inputs: " ++ s.options.numInputBusChannels).postln;
        ("Audio Outputs: " ++ s.options.numOutputBusChannels).postln;
        ("Max Synths: " ++ s.options.maxNodes).postln;
        "".postln;
        
        // Step 6: Ready message
        "=== READY ===".postln;
        "Server and SynthDefs are loaded!".postln;
        "".postln;
        "You can now:".postln;
        "1. Load nUPIC: \"nUPIC_SafeLoader.scd\".load".postln;
        "2. Draw trajectories and press SPACE to play".postln;
        "".postln;
        
        // Optional: Query all loaded SynthDefs on server
        if(s.serverRunning) {
            "To see all SynthDefs on server, run:".postln;
            "SynthDescLib.global.synthDescs.keys.postln;".postln;
        };
    };
};
)
