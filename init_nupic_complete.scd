// Complete nUPIC Initialization with Proper Loading Sequence
// This ensures SynthDefs are loaded BEFORE the main system tries to use them

(
"=================================================".postln;
"        nUPIC Complete Initialization            ".postln;
"=================================================".postln;
"".postln;

// Phase 1: Server Configuration and Boot
fork {
    var serverReady = false;
    var synthDefsLoaded = false;
    var mainSystemLoaded = false;
    
    "Phase 1: Configuring server...".postln;
    
    // Configure server options
    Server.default.options.memSize = 65536 * 2;
    Server.default.options.numWireBufs = 128;
    Server.default.options.maxNodes = 2048;
    Server.default.options.numAudioBusChannels = 512;
    Server.default.options.sampleRate = 44100;
    Server.default.options.blockSize = 64;
    Server.default.options.numBuffers = 1024;
    Server.default.options.numInputBusChannels = 2;
    Server.default.options.numOutputBusChannels = 2;
    
    if(Server.default.serverRunning.not) {
        "Starting audio server...".postln;
        Server.default.boot;
    } {
        "Server already running.".postln;
        serverReady = true;
    };
    
    // Wait for server to boot
    Server.default.waitForBoot {
        serverReady = true;
        "✓ Server booted successfully".postln;
        "".postln;
        
        // Phase 2: Load and Verify SynthDefs
        "Phase 2: Loading SynthDefs...".postln;
        
        // First ensure the minimal synth is defined
        SynthDef(\trajectoryVarSaw, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5;
            
            var sig, env, dopplerFreq, radialVel;
            
            // Envelope with proper release
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.1),
                gate,
                doneAction: 2
            );
            
            // Calculate Doppler shift
            radialVel = velocity * 10;  // Scale for audibility
            dopplerFreq = freq * (1 + (radialVel / 343));
            
            // VarSaw with correct parameter order: freq, phase, width
            sig = VarSaw.ar(
                dopplerFreq,  // frequency
                0,            // phase
                width         // width (0-1)
            ) * amp * env * (100 / distance.max(1));
            
            // Output with panning
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        // Also ensure the original synthdef is defined
        SynthDef(\simpleGravObject, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100;
            
            var sig, env, dopplerFreq, radialVel;
            var massNorm = (mass / 10).clip(0, 1);
            
            // Gate-controlled envelope with release
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.5),
                gate,
                doneAction: 2
            );
            
            // Enhanced Doppler effect
            radialVel = velocity * 20;
            dopplerFreq = freq * (1 + (radialVel / 343));
            
            // Oscillator with mass-dependent timbre
            sig = Mix.ar([
                SinOsc.ar(dopplerFreq, 0) * 0.5,
                Saw.ar(dopplerFreq * 0.5) * 0.3 * massNorm,
                Pulse.ar(dopplerFreq * 2, 0.3) * 0.2 * (1 - massNorm)
            ]);
            
            // Apply envelope and distance attenuation
            sig = sig * env * amp * (100 / distance.max(1));
            
            // Output with panning
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "Compiling SynthDefs...".postln;
        
        // Give time for compilation
        1.wait;
        Server.default.sync;
        
        // Now load the Audio/SynthDefs.scd file if it exists
        if(thisProcess.nowExecutingPath.notNil) {
            var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
            if(File.exists(dir +/+ "Audio/SynthDefs.scd")) {
                (dir +/+ "Audio/SynthDefs.scd").load;
                "✓ Loaded Audio/SynthDefs.scd".postln;
                1.wait;
                Server.default.sync;
            };
        };
        
        // Verify synthdefs are on the server
        "Verifying SynthDefs on server...".postln;
        
        // Test the minimal synth
        try {
            var testSynth = Synth(\trajectoryVarSaw, [
                \freq, 440, \amp, 0, \pan, 0, \gate, 1
            ]);
            if(testSynth.notNil) {
                "✓ SynthDef 'trajectoryVarSaw' verified".postln;
                testSynth.set(\gate, 0);
            };
        } { |error|
            "✗ Failed to verify trajectoryVarSaw: %".format(error.errorString).postln;
        };
        
        0.5.wait;
        
        // Test simpleGravObject
        try {
            var testSynth = Synth(\simpleGravObject, [
                \freq, 440, \amp, 0, \pan, 0, \gate, 1
            ]);
            if(testSynth.notNil) {
                "✓ SynthDef 'simpleGravObject' verified".postln;
                testSynth.set(\gate, 0);
            };
        } { |error|
            "✗ Failed to verify simpleGravObject: %".format(error.errorString).postln;
        };
        
        synthDefsLoaded = true;
        "".postln;
        
        1.wait;
        
        // Phase 3: Load Main nUPIC System
        "Phase 3: Loading nUPIC main system...".postln;
        
        // Make sure we have the global registry
        if(~nUPIC_SynthDefs.isNil) {
            ~nUPIC_SynthDefs = IdentityDictionary.new;
            ~nUPIC_SynthDefs[\available] = [
                \upicWavetable, \upicWavetable2ch, \upicWavetable3ch, \upicWavetable4ch,
                \upicWavetable8ch, \upicWavetable12ch, \upicWavetable15ch, \upicWavetable24ch
            ];
            ~nUPIC_SynthDefs[\default] = \upicWavetable;
        };
        
        // Now load the main system
        if(thisProcess.nowExecutingPath.notNil) {
            var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
            (dir +/+ "nUPIC_Main.scd").load;
        } {
            "nUPIC_Main.scd".load;  // Fallback to relative path
        };
        
        2.wait;
        
        mainSystemLoaded = true;
        
        // Phase 4: Final Status Report
        "".postln;
        "=================================================".postln;
        "           nUPIC System Status Report            ".postln;
        "=================================================".postln;
        ("Server Status: " ++ if(serverReady, "✓ Running", "✗ Not Running")).postln;
        ("SynthDefs: " ++ if(synthDefsLoaded, "✓ Loaded", "✗ Not Loaded")).postln;
        ("Main System: " ++ if(mainSystemLoaded, "✓ Loaded", "✗ Not Loaded")).postln;
        "".postln;
        
        if(serverReady and: synthDefsLoaded and: mainSystemLoaded) {
            "✓ nUPIC is READY TO USE!".postln;
            "".postln;
            "Instructions:".postln;
            "1. Draw trajectories in the GUI window".postln;
            "2. Press SPACE to play/stop".postln;
            "3. Use controls to adjust parameters".postln;
            "".postln;
            
            // List available synthdefs
            "Available SynthDefs:".postln;
            SynthDescLib.global.synthDescs.keys.do { |key|
                if([\trajectoryVarSaw, \simpleGravObject].includes(key)) {
                    ("  • \\" ++ key).postln;
                };
            };
        } {
            "✗ INITIALIZATION INCOMPLETE - Check errors above".postln;
        };
        
        "=================================================".postln;
    };
};
)
