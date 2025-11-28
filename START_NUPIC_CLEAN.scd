// Clean nUPIC Startup Script
// Simplified version without complex auto-update functions

(
"=================================================".postln;
"           nUPIC CLEAN STARTUP                   ".postln;  
"=================================================".postln;
"".postln;

fork {
    var serverReady = false;
    var synthDefsLoaded = false;
    var nupicLoaded = false;
    
    // PHASE 1: Server Configuration and Boot
    "PHASE 1: Configuring and starting server...".postln;
    
    // Configure server
    Server.default.options.memSize = 65536 * 2;
    Server.default.options.numWireBufs = 128;
    Server.default.options.maxNodes = 2048;
    Server.default.options.numAudioBusChannels = 1024;
    Server.default.options.numBuffers = 2048;
    Server.default.options.numInputBusChannels = 2;
    Server.default.options.numOutputBusChannels = 8; // 8 channels for spatialization
    
    if(Server.default.serverRunning.not) {
        "Starting server...".postln;
        Server.default.boot;
        Server.default.waitForBoot {
            serverReady = true;
            "✓ Server started".postln;
        };
        // Wait for server to boot
        while { serverReady.not } { 0.1.wait };
    } {
        serverReady = true;
        "✓ Server already running".postln;
    };
    
    0.5.wait;
    "".postln;
    
    // PHASE 2: Load Basic SynthDefs
    "PHASE 2: Loading basic SynthDefs...".postln;
    
    try {
        // Simple working synthdef
        SynthDef(\simpleGravObject, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1;
            var sig, env;
            
            env = EnvGen.kr(
                Env.asr(0.01, 1, 0.1),
                gate,
                doneAction: 2
            );
            
            sig = SinOsc.ar(freq) * amp * env;
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "✓ Basic synthdef loaded".postln;
        synthDefsLoaded = true;
    } { |error|
        "✗ Error loading synthdefs: ".post; error.errorString.postln;
    };
    
    Server.default.sync;
    1.wait;
    "".postln;
    
    // PHASE 3: Load nUPIC Main System
    "PHASE 3: Loading nUPIC system...".postln;
    
    if(thisProcess.nowExecutingPath.notNil) {
        var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
        var mainPath = dir +/+ "nUPIC_Main.scd";
        
        if(File.exists(mainPath)) {
            try {
                mainPath.load;
                "✓ nUPIC_Main.scd loaded".postln;
                nupicLoaded = true;
            } { |error|
                "✗ Error loading nUPIC_Main: ".post; error.errorString.postln;
            };
        } {
            "✗ Could not find nUPIC_Main.scd".postln;
        };
    } {
        try {
            "nUPIC_Main.scd".load;
            nupicLoaded = true;
            "✓ nUPIC loaded from relative path".postln;
        } { |error|
            "✗ Error loading nUPIC: ".post; error.errorString.postln;
        };
    };
    
    // Setup basic synthdef registry
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [\simpleGravObject];
    ~nUPIC_SynthDefs[\default] = \simpleGravObject;
    
    2.wait;
    
    // PHASE 4: Final Status Report
    "".postln;
    "=================================================".postln;
    "              STARTUP STATUS REPORT              ".postln;
    "=================================================".postln;
    ("Server:     " ++ if(serverReady, "✓ Running", "✗ Not Running")).postln;
    ("SynthDefs:  " ++ if(synthDefsLoaded, "✓ Basic Loaded", "✗ Not Loaded")).postln;
    ("nUPIC:      " ++ if(nupicLoaded, "✓ Loaded", "✗ Not Loaded")).postln;
    "".postln;
    
    if(serverReady and: synthDefsLoaded and: nupicLoaded) {
        "✓✓✓ nUPIC BASIC STARTUP COMPLETE ✓✓✓".postln;
        "".postln;
        "To add 8ch spatial synthdefs, run:".postln;
        "\"add_8ch_synthdefs_after_startup.scd\".load".postln;
    } {
        "✗✗✗ INITIALIZATION INCOMPLETE ✗✗✗".postln;
        "Check the errors above and try again.".postln;
    };
    
    "=================================================".postln;
};
)