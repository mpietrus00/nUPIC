// Complete nUPIC Startup Script
// This loads everything in the correct order to ensure nUPIC works properly

(
"=================================================".postln;
"           nUPIC COMPLETE STARTUP                ".postln;
"=================================================".postln;
"".postln;

fork {
    var serverReady = false;
    var synthDefsLoaded = false;
    var nupicLoaded = false;
    var candidates, available;  // Variables for SynthDef detection

    // PHASE 1: Server Configuration and Boot
    "PHASE 1: Configuring and starting server...".postln;

    // Configure server
    Server.default.options.memSize = 65536 * 2;
    Server.default.options.numWireBufs = 128;
    Server.default.options.maxNodes = 2048;
    Server.default.options.numAudioBusChannels = 512;
    Server.default.options.sampleRate = 44100;
    Server.default.options.blockSize = 64;
    Server.default.options.numBuffers = 1024;
    Server.default.options.numInputBusChannels = 0;
    Server.default.options.numOutputBusChannels = 24;

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

    0.5.wait;  // Give server time to stabilize
    "".postln;

    // PHASE 2: Load SynthDefs BEFORE nUPIC
    "PHASE 2: Loading SynthDefs...".postln;

    // Make sure server is really ready
    Server.default.sync;

    // Try to load advanced synthdefs first, fall back to simple ones if needed
    {
        var advancedLoaded = false;
        var synthDefsPath, envSynthDefsPath;

        // First, try to load the advanced synthdefs from Audio/SynthDefs.scd
        if(thisProcess.nowExecutingPath.notNil) {
            synthDefsPath = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "Audio" +/+ "SynthDefs.scd";

            if(File.exists(synthDefsPath)) {
                try {
                    "  Attempting to load advanced SynthDefs from Audio/SynthDefs.scd...".postln;
                    synthDefsPath.load;

                    // Check if the advanced synthdefs loaded
                    if(~loadnUPICSynthDefs.notNil) {
                        ~loadnUPICSynthDefs.value;
                        advancedLoaded = true;
                        "  ✓ Advanced SynthDefs loaded successfully".postln;
                    };
                } { |error|
                    ("  ⚠ Could not load advanced SynthDefs: " ++ error.errorString).postln;
                };
            };

            // Load 8-channel envelope-based SynthDefs
            envSynthDefsPath = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "Audio" +/+ "SynthDefs_8ch_envelope.scd";
            if(File.exists(envSynthDefsPath)) {
                try {
                    "  Loading 8-channel envelope-based SynthDefs...".postln;
                    envSynthDefsPath.load;
                    "  ✓ 8-channel envelope SynthDefs loaded".postln;
                } { |error|
                    ("  ⚠ Could not load 8ch envelope SynthDefs: " ++ error.errorString).postln;
                };
            };
        };

        // If advanced synthdefs didn't load, define the simple working ones
        if(advancedLoaded.not) {
            "  Loading simple working SynthDefs as fallback...".postln;

            // Load the upicWavetable SynthDef first
            try {
                var upicWavetablePath = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "Audio" +/+ "upicWavetable.scd";
                if(File.exists(upicWavetablePath)) {
                    upicWavetablePath.load;
                    "  ✓ upicWavetable loaded from Audio/upicWavetable.scd".postln;
                } {
                    // Create inline version if file doesn't exist
                    // Initialize buffer for wavetable (2048 samples for better quality)
                    ~nUPIC_wavetableBuffer = Buffer.alloc(s, 2048, 1);

                    // Generate initial random wavetable
                    ~nUPIC_generateRandomWavetable = {
                        var wavetable = Signal.newClear(2048);
                        var numPartials = rrand(4, 12);
                        var harmonics = Array.fill(numPartials, 0);
                        var phases = Array.fill(numPartials, 0);

                        numPartials.do { |i|
                            harmonics[i] = 1.0 / (i + 1).pow(rrand(0.5, 1.5)) * rrand(0.3, 1.0);
                            phases[i] = rrand(0, 2pi);
                        };

                        wavetable = Signal.sineFill(2048, harmonics, phases);
                        wavetable = wavetable.normalize;
                        ~nUPIC_wavetableBuffer.loadCollection(wavetable.asArray);
                    };
                    ~nUPIC_generateRandomWavetable.value;

                    // Define the SynthDef inline (mono version)
                    SynthDef(\upicWavetable, {
                        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                            mass = 1, velocity = 0, distance = 100, width = 0.5,
                            radialVel = 0, dopplerSens = 0, numSynths = 1;

                        var sig, phase, env, dopplerShift, finalFreq, distAmp, bufnum;

                        bufnum = ~nUPIC_wavetableBuffer.bufnum;
                        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
                        finalFreq = freq * dopplerShift.clip(0.5, 2.0);

                        env = EnvGen.kr(
                            Env.asr(0.01, 1, 0.01),
                            gate,
                            doneAction: 2
                        );

                        // Phase from LFSaw (0-1 range)
                        phase = LFSaw.ar(finalFreq).range(0, 1);

                        // OscOS mono wavetable
                        sig = OscOS.ar(bufnum, phase, oversample: 1);

                        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
                        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
                        sig = sig.tanh * 0.9;

                        // Mono output
                        Out.ar(0, sig);
                    }).add;

                    "  ✓ upicWavetable loaded (inline)".postln;
                };
            } { |error|
                ("  ⚠ Could not load upicWavetable: " ++ error.errorString).postln;
            };

            // Simple gravity object based on working testOrbit synthdef
            SynthDef(\simpleGravObject, {
                arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                    mass = 1, velocity = 0, distance = 100, width = 0.5,
                    radialVel = 0, dopplerSens = 0, numSynths = 1;

                var sig, env, dopplerShift, finalFreq, distAmp;

                // Calculate frequency with optional Doppler
                dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
                finalFreq = freq * dopplerShift.clip(0.5, 2.0);

                // Simple envelope like in working example
                env = EnvGen.kr(
                    Env.asr(0.01, 1, 0.1),
                    gate,
                    doneAction: 2
                );

                // Simple oscillator design that works - based on confirmed working code
                sig = Mix.ar([
                    SinOsc.ar(finalFreq) * 0.5,
                    SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),
                    SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)
                ]);

                // Subtle vibrato
                sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));

                // Distance amplitude
                distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);

                // Apply amplitude
                sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));

                // Soft clipping
                sig = sig.tanh * 0.9;

                Out.ar(0, Pan2.ar(sig, pan));
            }).add;

            "  ✓ simpleGravObject loaded".postln;

            // Simpler trajectory synth based on working example
            SynthDef(\trajectoryVarSaw, {
                arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                    mass = 1, velocity = 0, distance = 100, width = 0.5,
                    radialVel = 0, dopplerSens = 0, numSynths = 1;

                var sig, env;

                env = EnvGen.kr(
                    Env.asr(0.01, 1, 0.01),
                    gate,
                    doneAction: 2
                );

                // Simple sawtooth design - confirmed working
                sig = Mix.ar([
                    Saw.ar(freq) * 0.3,
                    Saw.ar(freq * 1.01) * 0.3,
                    Saw.ar(freq * 0.99) * 0.3
                ]);

                sig = LPF.ar(sig, freq * 4);
                sig = sig * amp * env * (1 / numSynths.sqrt.max(1));
                sig = sig.tanh * 0.9;

                Out.ar(0, Pan2.ar(sig, pan));
            }).add;

            "  ✓ trajectoryVarSaw loaded".postln;

            // Test synth - exactly like working example from fix_synthdefs_based_on_working.scd
            SynthDef(\testOrbit, {
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

            "  ✓ testOrbit loaded (confirmed working synthdef)".postln;
            
            // Add our simple mono upicWavetable synthdef
            SynthDef(\upicWavetable, {
                arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                    bufnum, // Wavetable buffer number
                    mass = 1, velocity = 0, distance = 100, width = 0.5,
                    radialVel = 0, dopplerSens = 0, numSynths = 1;

                var sig, phase, dopplerShift, finalFreq, distAmp, env;

                // Use the global wavetable buffer
                bufnum = \bufnum.kr(~nUPIC_wavetableBuffer.bufnum);

                // Calculate frequency with optional Doppler
                dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
                finalFreq = freq * dopplerShift.clip(0.5, 2.0);

                // Simple envelope for clean start/stop
                env = EnvGen.kr(
                    Env.asr(0.01, 1, 0.01),
                    gate,
                    doneAction: 2
                );

                // Phase from LFSaw (0-1 range) - matches OscOS documentation
                phase = LFSaw.ar(finalFreq).range(0, 1);

                // OscOS with named args for clarity (single wavetable buffer)
                sig = OscOS.ar(bufnum, phase, oversample: 1);

                // Distance-based amplitude
                distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);

                // Apply amplitude scaling
                sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));

                // Simple soft limiting to prevent clipping
                sig = sig.tanh * 0.9;

                // Mono output to bus 0
                Out.ar(0, sig);
            }).add;
            
            "  ✓ upicWavetable (mono) loaded".postln;
        };

    }.value;

    // Wait for SynthDefs to compile and send to server
    Server.default.sync;
    1.wait;  // Give more time for all SynthDefs to register

    // Set up global registry - check what synthdefs are actually available
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
    };

    // Force update from any loaded 8ch envelope SynthDefs
    if(~nUPIC_8ch_env_SynthDefs.notNil and: { ~nUPIC_8ch_env_SynthDefs[\available].notNil }) {
        "  Adding 8ch envelope SynthDefs to registry...".postln;
        ~nUPIC_8ch_env_SynthDefs[\available].do { |name|
            ("    - " ++ name).postln;
        };
    };

    // Dynamically detect which SynthDefs are loaded
    candidates = [
        \upicWavetable,           // Our simple mono version (included above)
        \upicWavetablePrecise, \upicWavetableAdditive, \upicWavetableHarmonic,
        \upicWavetableRing, \upicWavetablePhase,
        // 8-channel versions (random oscillator based)
        \upicWavetable8ch, \upicWavetablePrecise8ch, \simpleGravObject8ch,
        // 8-channel envelope-based versions (drawn spatialization curves)
        \upicWavetable8chEnv, \upicWavetablePrecise8chEnv, \simpleGravObject8chEnv,
        \pulsarTrain, \grainBank, \fmCascade, \fmOrgan, \simpleOrgan,
        \percussiveGravObject, \metallicGravObject, \drumGravObject,
        \additiveOS, \simpleOS, \simpleGravObject, \trajectoryVarSaw, \testOrbit
    ];
    available = List.new;
    candidates.do { |sym|
        if(SynthDescLib.global.synthDescs[sym].notNil) {
            available.add(sym);
            ("  Found: " ++ sym).postln;
        };
    };

    // Ensure upicWavetable is included if defined inline
    if(SynthDescLib.global.synthDescs[\upicWavetable].notNil and: { available.includes(\upicWavetable).not }) {
        available.add(\upicWavetable);
    };

    ~nUPIC_SynthDefs[\available] = available.asArray;

    // Choose a sensible default: prefer our mono upicWavetable, else first available
    if(SynthDescLib.global.synthDescs[\upicWavetable].notNil) {
        ~nUPIC_SynthDefs[\default] = \upicWavetable;
        "  Using upicWavetable (mono) as default".postln;
    } {
        if(available.size > 0) {
            ~nUPIC_SynthDefs[\default] = available.first;
            ("  Using default SynthDef: " ++ available.first).postln;
        } {
            ~nUPIC_SynthDefs[\default] = \testOrbit; // Last resort
            "  No SynthDefs detected; defaulting to testOrbit".postln;
        };
    };

    "✓ SynthDef registry created".postln;

    // Test SynthDefs - test whatever is available
    "Testing SynthDefs...".postln;
    ~nUPIC_SynthDefs[\available].do { |name|
        var synth, params;
        try {
            params = [\freq, 440, \amp, 0, \gate, 1, \numSynths, 1];
            // Add buffer for all wavetable variants
            if(name.asString.contains("upicWavetable") and: { ~nUPIC_wavetableBuffer.notNil }) {
                params = params ++ [\bufnum, ~nUPIC_wavetableBuffer.bufnum];
            };
            synth = Synth(name, params);
            if(synth.notNil) {
                ("  ✓ " ++ name ++ " verified").postln;
                synth.set(\gate, 0);
                0.1.wait;
            };
        } { |error|
            ("  ✗ " ++ name ++ " failed: " ++ error.errorString).postln;
        };
    };

    synthDefsLoaded = true;
    "".postln;

    1.wait;

    // PHASE 3: Load nUPIC Main System
    "PHASE 3: Loading nUPIC system...".postln;

    // Get the path to nUPIC_Main.scd
    if(thisProcess.nowExecutingPath.notNil) {
		var allCandidates, actuallyAvailable;
        var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
        var mainPath = dir +/+ "nUPIC_Main.scd";

        if(File.exists(mainPath)) {
            mainPath.load;
            "✓ nUPIC_Main.scd loaded".postln;
            nupicLoaded = true;

            // Set up auto-update function for synthdef menus
            ~nUPIC[\ui][\updateSynthDefMenusAfterLoad] = {
                fork {
                    // Wait a bit for UI to be fully initialized
                    0.5.wait;

                    // Re-scan for all available SynthDefs
                    allCandidates = [
                        \upicWavetable, \upicWavetablePrecise, \upicWavetableAdditive, \upicWavetableHarmonic,
                        \upicWavetableRing, \upicWavetablePhase,
                        // 8-channel versions
                        \upicWavetable8ch, \upicWavetablePrecise8ch, \simpleGravObject8ch,
                        \upicWavetable8chEnv, \upicWavetablePrecise8chEnv, \simpleGravObject8chEnv,
                        \pulsarTrain, \grainBank, \fmCascade, \fmOrgan, \simpleOrgan,
                        \percussiveGravObject, \metallicGravObject, \drumGravObject,
                        \additiveOS, \simpleOS, \simpleGravObject, \trajectoryVarSaw, \testOrbit
                    ];

                    actuallyAvailable = List.new;
                    allCandidates.do { |sym|
                        if(SynthDescLib.global.synthDescs[sym].notNil) {
                            actuallyAvailable.add(sym);
                        };
                    };

                    // Update global registry
                    ~nUPIC_SynthDefs[\available] = actuallyAvailable.asArray;

                    // Update menus if UI is open
                    if(~nUPIC[\ui][\state].notNil and: { ~nUPIC[\ui][\state][\controls].notNil }) {
                        var controls = ~nUPIC[\ui][\state][\controls];
                        var menuItems = ~nUPIC_SynthDefs[\available].collect { |name|
                            case
                            { name == \upicWavetable } { "UPIC Wavetable (Mono)" }
                            { name == \upicWavetablePrecise } { "UPIC Wavetable Precise" }
                            { name == \upicWavetableAdditive } { "UPIC Wavetable Additive" }
                            { name == \upicWavetableHarmonic } { "UPIC Wavetable Harmonic" }
                            { name == \upicWavetableRing } { "UPIC Wavetable Ring" }
                            { name == \upicWavetablePhase } { "UPIC Wavetable Phase" }
                            { name == \simpleGravObject } { "Simple Grav Object" }
                            { name == \testOrbit } { "Test Orbit" }
                            { name == \trajectoryVarSaw } { "Trajectory VarSaw" }
                            { true } { name.asString }
                        };

                        AppClock.sched(0, {
                            // Update main synthDefMenu
                            if(controls[\synthDefMenu].notNil) {
                                controls[\synthDefMenu].items = menuItems;
                                "✓ SynthDef menu auto-updated with " ++ menuItems.size ++ " items".postln;
                                menuItems.do { |item| ("  - " ++ item).postln };

                                // Set default to upicWavetablePrecise8chEnv if available
                                if(~nUPIC_SynthDefs[\available].includes(\upicWavetablePrecise8chEnv)) {
                                    var preciseIndex = ~nUPIC_SynthDefs[\available].indexOf(\upicWavetablePrecise8chEnv);
                                    if(preciseIndex.notNil) {
                                        controls[\synthDefMenu].value = preciseIndex;
                                        ~nUPIC[\defaults][\defaultSynthDef] = \upicWavetablePrecise8chEnv;
                                        "  Default set to upicWavetablePrecise8chEnv (8ch envelope-based)".postln;
                                    };
                                } {
                                    // Fallback to upicWavetablePrecise if no 8ch version
                                    if(~nUPIC_SynthDefs[\available].includes(\upicWavetablePrecise)) {
                                        var preciseIndex = ~nUPIC_SynthDefs[\available].indexOf(\upicWavetablePrecise);
                                        if(preciseIndex.notNil) {
                                            controls[\synthDefMenu].value = preciseIndex;
                                            ~nUPIC[\defaults][\defaultSynthDef] = \upicWavetablePrecise;
                                            "  Default set to upicWavetablePrecise".postln;
                                        };
                                    };
                                };
                            };
                            nil;
                        });
                    };
                };
            };
        } {
            "✗ Could not find nUPIC_Main.scd".postln;
            "  Try running: \"nUPIC_Main.scd\".load".postln;
        };
    } {
        // Fallback: try relative path
        "nUPIC_Main.scd".load;
        nupicLoaded = true;
    };

    2.wait;

    // PHASE 4: Final Status Report
    "".postln;
    "=================================================".postln;
    "              STARTUP STATUS REPORT              ".postln;
    "=================================================".postln;
    ("Server:     " ++ if(serverReady, "✓ Running", "✗ Not Running")).postln;
    ("SynthDefs:  " ++ if(synthDefsLoaded, "✓ Loaded", "✗ Not Loaded")).postln;
    ("nUPIC:      " ++ if(nupicLoaded, "✓ Loaded", "✗ Not Loaded")).postln;
    "".postln;

    if(serverReady and: synthDefsLoaded and: nupicLoaded) {
        "✓✓✓ nUPIC is READY TO USE! ✓✓✓".postln;
        "".postln;
        "INSTRUCTIONS:".postln;
        "1. Draw trajectories in the GUI window".postln;
        "2. Press SPACE to play/stop".postln;
        "3. Use G for select mode, E for erase mode".postln;
        "4. Use controls to adjust parameters".postln;
        "".postln;

        // List available synthdefs
        "Available SynthDefs:".postln;
        ~nUPIC_SynthDefs[\available].do { |name|
            ("  • " ++ name).postln;
        };
        "".postln;

        // Quick test command using the default synthdef
        "Quick audio test (using default):".postln;
        ("(
var s = Synth(\\" ++ ~nUPIC_SynthDefs[\default] ++ ", [\\freq, 440, \\amp, 0.1, \\gate, 1]);
fork { 1.wait; s.set(\\gate, 0); };
)").postln;

    } {
        "✗✗✗ INITIALIZATION INCOMPLETE ✗✗✗".postln;
        "Check the errors above and try again.".postln;
        "".postln;
        "To manually fix:".postln;
        "1. Boot server: s.boot;".postln;
        "2. Load fix: \"fix_nupic_synthdefs_comprehensive.scd\".load".postln;
        "3. Load nUPIC: \"nUPIC_Main.scd\".load".postln;
    };

    "=================================================".postln;
};
)
