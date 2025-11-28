// Complete nUPIC Startup Script with Advanced OS-based SynthDefs
// This loads everything in the correct order with high-quality synthesis

(
"=================================================".postln;
"     nUPIC COMPLETE STARTUP - ADVANCED VERSION   ".postln;  
"=================================================".postln;
"".postln;

fork {
    var serverReady = false;
    var synthDefsLoaded = false;
    var nupicLoaded = false;
    
    // PHASE 1: Server Configuration and Boot
    "PHASE 1: Configuring and starting server...".postln;
    
    // Configure server for high-quality audio
    Server.default.options.memSize = 65536 * 4;  // More memory for OS oscillators
    Server.default.options.numWireBufs = 256;     // More wire buffers
    Server.default.options.maxNodes = 4096;       // More nodes for complex synthesis
    Server.default.options.numAudioBusChannels = 1024;
    Server.default.options.sampleRate = 48000;    // Higher sample rate for OS
    Server.default.options.blockSize = 64;
    Server.default.options.numBuffers = 2048;
    Server.default.options.numInputBusChannels = 2;
    Server.default.options.numOutputBusChannels = 2;
    
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
    
    // PHASE 2: Load Advanced SynthDefs
    "PHASE 2: Loading Advanced SynthDefs with Oversampling...".postln;
    
    // Define all advanced SynthDefs
    {
        // Advanced Pulsar Train synthesis
        SynthDef(\pulsarTrain, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1,
                formFreq = 2000, pulsarRate = 10;
            
            var sig, env, dopplerShift, finalFreq, distAmp;
            var formant, pulsar, carrier;
            var massNorm = (mass / 10).clip(0, 1);
            
            dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
            finalFreq = freq * dopplerShift.clip(0.5, 2.0);
            
            env = EnvGen.kr(
                Env.adsr(0.005, 0.05, 0.8, 0.2),
                gate,
                doneAction: 2
            );
            
            carrier = SinOscOS.ar(finalFreq, 0, 1, 4);
            formant = SinOscOS.ar(formFreq + (velocity * 100), 0, 1, 4);
            pulsar = LFPulse.ar(pulsarRate + (massNorm * 20), 0, width);
            
            sig = carrier * formant * pulsar;
            sig = sig + (SawOS.ar(finalFreq * 2, 0.2 * massNorm, 4) * 0.3);
            sig = sig + (SawOS.ar(finalFreq * 3, 0.1 * massNorm, 4) * 0.2);
            
            distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
            sig = LPF.ar(sig, (finalFreq * 4).min(15000) * distAmp);
            sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
            sig = sig.tanh * 0.9;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "  ✓ pulsarTrain loaded (advanced pulsar synthesis)".postln;
        
        // Granular-inspired oscillator bank
        SynthDef(\grainBank, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1,
                grainDensity = 20, grainDur = 0.05;
            
            var sig, env, dopplerShift, finalFreq, distAmp;
            var grains, trigger, grainEnv;
            var massNorm = (mass / 10).clip(0, 1);
            
            dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
            finalFreq = freq * dopplerShift.clip(0.5, 2.0);
            
            env = EnvGen.kr(
                Env.adsr(0.01, 0.1, 0.7, 0.3),
                gate,
                doneAction: 2
            );
            
            trigger = Impulse.ar(grainDensity + (velocity * 5));
            grainEnv = EnvGen.ar(Env.perc(0.001, grainDur), trigger);
            
            grains = Mix.ar([
                SinOscOS.ar(finalFreq, 0, grainEnv * 0.3, 4),
                SinOscOS.ar(finalFreq * 1.5, 0, grainEnv * 0.2 * massNorm, 4),
                SawOS.ar(finalFreq * 0.5, grainEnv * 0.2 * (1 - massNorm), 4),
                TriOS.ar(finalFreq * 2, grainEnv * 0.1, 4)
            ]);
            
            sig = grains + (SinOscOS.ar(finalFreq, 0, 0.1, 4) * env);
            sig = RLPF.ar(sig, finalFreq * (2 + (massNorm * 6)), 0.5 - (massNorm * 0.3));
            
            distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
            sig = sig * amp * env * distAmp * (0.7 / numSynths.sqrt.max(1));
            sig = Compander.ar(sig, sig, 0.5, 1, 0.5, 0.01, 0.1);
            sig = sig.tanh * 0.85;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "  ✓ grainBank loaded (granular synthesis)".postln;
        
        // FM synthesis with oversampling
        SynthDef(\fmCascade, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1,
                modIndex = 2, modRatio = 1.5;
            
            var sig, env, dopplerShift, finalFreq, distAmp;
            var carrier, modulator1, modulator2, modEnv;
            var massNorm = (mass / 10).clip(0, 1);
            
            dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
            finalFreq = freq * dopplerShift.clip(0.5, 2.0);
            
            env = EnvGen.kr(
                Env.adsr(0.002, 0.1, 0.6, 0.5),
                gate,
                doneAction: 2
            );
            
            modEnv = EnvGen.kr(Env.perc(0.001, 0.5), gate);
            
            modulator2 = SinOscOS.ar(
                finalFreq * modRatio * 2,
                0,
                modIndex * 100 * massNorm,
                4
            );
            
            modulator1 = SinOscOS.ar(
                finalFreq * modRatio + modulator2,
                0,
                modIndex * 200 * modEnv,
                4
            );
            
            carrier = SinOscOS.ar(finalFreq + modulator1, 0, 1, 4);
            sig = carrier;
            
            sig = sig + (SinOscOS.ar(finalFreq * 0.5, 0, 0.2, 4) * (1 - massNorm));
            sig = sig + (SawOS.ar(finalFreq * 4, 0.1 * massNorm, 4));
            sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 8)) * 0.05));
            
            distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
            sig = LPF.ar(sig, (finalFreq * 8).min(18000) * distAmp);
            sig = sig * amp * env * distAmp * (0.3 / numSynths.sqrt.max(1));
            sig = sig.softclip * 0.9;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "  ✓ fmCascade loaded (FM synthesis)".postln;
        
        // Additive synthesis with oversampling
        SynthDef(\additiveOS, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1,
                numPartials = 8;
            
            var sig, env, dopplerShift, finalFreq, distAmp;
            var partials;
            var massNorm = (mass / 10).clip(0, 1);
            
            dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
            finalFreq = freq * dopplerShift.clip(0.5, 2.0);
            
            env = EnvGen.kr(
                Env.adsr(0.01, 0.15, 0.7, 0.4),
                gate,
                doneAction: 2
            );
            
            partials = numPartials.collect { |i|
                var harmonic = i + 1;
                var detune = 1 + (LFNoise2.kr(0.1 + (i * 0.1)).range(-0.001, 0.001));
                var ampScale = (1 / harmonic) * (1 - (i * 0.05)).max(0);
                
                if(i.even, {
                    SinOscOS.ar(
                        finalFreq * harmonic * detune,
                        0,
                        ampScale * (1 - (massNorm * i * 0.1)).max(0),
                        4
                    )
                }, {
                    TriOS.ar(
                        finalFreq * harmonic * detune,
                        ampScale * (massNorm * (1 - (i * 0.05))).max(0),
                        4
                    )
                })
            };
            
            sig = Mix.ar(partials);
            sig = sig + (SinOscOS.ar(finalFreq * 0.5, 0, 0.2 * (1 - massNorm), 4));
            sig = sig * (1 + (LFTri.kr(velocity * 0.5) * 0.1));
            
            distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
            sig = BPF.ar(sig, finalFreq * 2, 2 / distAmp.max(0.5));
            sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
            sig = Limiter.ar(sig, 0.95, 0.01) * 0.9;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "  ✓ additiveOS loaded (additive synthesis)".postln;
        
        // Simple oversampled reference
        SynthDef(\simpleOS, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1;
            
            var sig, env, dopplerShift, finalFreq, distAmp;
            var massNorm = (mass / 10).clip(0, 1);
            
            dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
            finalFreq = freq * dopplerShift.clip(0.5, 2.0);
            
            env = EnvGen.kr(
                Env.asr(0.01, 1, 0.1),
                gate,
                doneAction: 2
            );
            
            sig = Mix.ar([
                SinOscOS.ar(finalFreq, 0, 1, 4),
                SinOscOS.ar(finalFreq * 2, 0, 0.3 * massNorm, 4),
                SinOscOS.ar(finalFreq * 3, 0, 0.1 * massNorm, 4)
            ]);
            
            distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
            sig = sig * amp * env * distAmp * (0.5 / numSynths.sqrt.max(1));
            sig = sig.tanh * 0.9;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "  ✓ simpleOS loaded (simple oversampled)".postln;
        
        // Backwards compatibility - simple working synth
        SynthDef(\simpleGravObject, {
            arg freq = 440, amp = 0.1, pan = 0, gate = 1,
                mass = 1, velocity = 0, distance = 100, width = 0.5,
                radialVel = 0, dopplerSens = 0, numSynths = 1;
            
            var sig, env, dopplerShift, finalFreq, distAmp;
            
            dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
            finalFreq = freq * dopplerShift.clip(0.5, 2.0);
            
            env = EnvGen.kr(
                Env.asr(0.01, 1, 0.1),
                gate,
                doneAction: 2
            );
            
            sig = SinOsc.ar(finalFreq) * 0.5;
            sig = sig + (SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1));
            
            distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
            sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
            sig = sig.tanh * 0.9;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "  ✓ simpleGravObject loaded (backwards compatibility)".postln;
        
        // Classic test synth
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
        
        "  ✓ testOrbit loaded (classic test)".postln;
        
    }.value;
    
    // Wait for SynthDefs to compile
    Server.default.sync;
    
    // Set up global registry with all synthdefs
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [
        \pulsarTrain,      // Advanced pulsar synthesis (default)
        \grainBank,        // Granular synthesis
        \fmCascade,        // FM synthesis
        \additiveOS,       // Additive synthesis
        \simpleOS,         // Simple oversampled
        \simpleGravObject, // Backwards compatibility
        \testOrbit         // Classic test
    ];
    ~nUPIC_SynthDefs[\default] = \pulsarTrain;  // Set to advanced default
    
    "✓ SynthDef registry created with " ++ ~nUPIC_SynthDefs[\available].size ++ " synthdefs".postln;
    
    // Test SynthDefs
    "Testing SynthDefs...".postln;
    ~nUPIC_SynthDefs[\available].do { |name|
        var synth;
        try {
            synth = Synth(name, [
                \freq, 440, 
                \amp, 0, // Silent test
                \gate, 1, 
                \numSynths, 1
            ]);
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
        var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
        var mainPath = dir +/+ "nUPIC_Main.scd";
        
        if(File.exists(mainPath)) {
            mainPath.load;
            "✓ nUPIC_Main.scd loaded".postln;
            nupicLoaded = true;
        } {
            "✗ Could not find nUPIC_Main.scd".postln;
            "  Try running: \"nUPIC_Main.scd\".load".postln;
        };
    } {
        // Fallback: try relative path
        "nUPIC_Main.scd".load;
        nupicLoaded = true;
    };
    
    // Override the default synthdef in nUPIC if it's loaded
    if(nupicLoaded and: { ~nUPIC.notNil }) {
        if(~nUPIC[\defaults].isNil) {
            ~nUPIC[\defaults] = IdentityDictionary.new;
        };
        ~nUPIC[\defaults][\defaultSynthDef] = \pulsarTrain;
        "✓ Set nUPIC default to pulsarTrain".postln;
    };
    
    2.wait;
    
    // PHASE 4: Final Status Report
    "".postln;
    "=================================================".postln;
    "              STARTUP STATUS REPORT              ".postln;
    "=================================================".postln;
    ("Server:      " ++ if(serverReady, "✓ Running (48kHz)", "✗ Not Running")).postln;
    ("SynthDefs:   " ++ if(synthDefsLoaded, "✓ " ++ ~nUPIC_SynthDefs[\available].size ++ " Loaded", "✗ Not Loaded")).postln;
    ("nUPIC:       " ++ if(nupicLoaded, "✓ Loaded", "✗ Not Loaded")).postln;
    ("Default:     " ++ ~nUPIC_SynthDefs[\default]).postln;
    "".postln;
    
    if(serverReady and: synthDefsLoaded and: nupicLoaded) {
        "✓✓✓ nUPIC ADVANCED is READY TO USE! ✓✓✓".postln;
        "".postln;
        "FEATURES:".postln;
        "• High-quality oversampled oscillators (4x)".postln;
        "• Advanced synthesis techniques".postln;
        "• Reduced aliasing at high frequencies".postln;
        "".postln;
        "INSTRUCTIONS:".postln;
        "1. Draw trajectories in the GUI window".postln;
        "2. Press SPACE to play/stop".postln;
        "3. Use G for select mode, E for erase mode".postln;
        "4. Select SynthDef from dropdown menu".postln;
        "".postln;
        
        // List available synthdefs with descriptions
        "Available SynthDefs:".postln;
        "  • pulsarTrain     - Advanced pulsar synthesis (default)".postln;
        "  • grainBank       - Granular synthesis bank".postln;
        "  • fmCascade       - FM synthesis cascade".postln;
        "  • additiveOS      - Additive synthesis with partials".postln;
        "  • simpleOS        - Simple oversampled reference".postln;
        "  • simpleGravObject - Classic compatibility".postln;
        "  • testOrbit       - Basic test synth".postln;
        "".postln;
        
        // Quick test commands
        "Quick audio tests:".postln;
        "// Test pulsar train (default):".postln;
        "(
var s = Synth(\\pulsarTrain, [\\freq, 440, \\amp, 0.1, \\gate, 1]);
fork { 2.wait; s.set(\\gate, 0); };
)".postln;
        "".postln;
        "// Test FM cascade:".postln;
        "(
var s = Synth(\\fmCascade, [\\freq, 330, \\amp, 0.1, \\modIndex, 3]);
fork { 2.wait; s.set(\\gate, 0); };
)".postln;
        
    } {
        "✗✗✗ INITIALIZATION INCOMPLETE ✗✗✗".postln;
        "Check the errors above and try again.".postln;
        "".postln;
        "To manually fix:".postln;
        "1. Boot server: s.boot;".postln;
        "2. Load synthdefs: \"synthdefs_advanced_OS.scd\".load".postln;
        "3. Load nUPIC: \"nUPIC_Main.scd\".load".postln;
    };
    
    "=================================================".postln;
};
)
