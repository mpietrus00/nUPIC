// Fix for nUPIC SynthDef menu showing only one option
// This script properly loads all SynthDefs and updates the menu

(
"=== Fixing SynthDef Menu ===".postln;

fork {
    var basePath, available;
    
    // 1. Set base path properly
    if(~nUPIC_basePath.isNil) {
        if(thisProcess.nowExecutingPath.notNil) {
            ~nUPIC_basePath = PathName(thisProcess.nowExecutingPath).pathOnly;
        } {
            ~nUPIC_basePath = "/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/";
        };
        ("Base path set to: " ++ ~nUPIC_basePath).postln;
    };
    
    // 2. Make sure server is ready
    if(s.serverRunning.not) {
        "Server not running - starting...".postln;
        s.boot;
        s.waitForBoot {
            "Server started".postln;
        };
    };
    
    1.wait;
    
    // 3. Load the upicWavetable SynthDefs
    "Loading upicWavetable SynthDefs...".postln;
    try {
        var upicPath = ~nUPIC_basePath +/+ "Audio/upicWavetable.scd";
        if(File.exists(upicPath)) {
            upicPath.load;
            "upicWavetable.scd loaded".postln;
        } {
            "upicWavetable.scd not found at expected path".postln;
        };
    } { |error|
        ("Error loading upicWavetable: " ++ error.errorString).postln;
    };
    
    // 4. Load the main SynthDefs
    "Loading main SynthDefs...".postln;
    try {
        var synthDefsPath = ~nUPIC_basePath +/+ "Audio/SynthDefs.scd";
        if(File.exists(synthDefsPath)) {
            synthDefsPath.load;
            "SynthDefs.scd loaded".postln;
        } {
            "SynthDefs.scd not found at expected path".postln;
        };
    } { |error|
        ("Error loading SynthDefs: " ++ error.errorString).postln;
    };
    
    // 5. Load simple working SynthDefs as fallback
    "Creating simple working SynthDefs...".postln;
    
    // Simple working synth
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
        
        sig = Mix.ar([
            SinOsc.ar(finalFreq) * 0.5,
            SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),
            SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)
        ]);
        
        sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Test sine oscillator
    SynthDef(\testSinOsc, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env;
        
        env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
        sig = SinOsc.ar(freq) * amp * env * (1 / numSynths.sqrt.max(1));
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Simple sawtooth
    SynthDef(\simpleSaw, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env;
        
        env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction: 2);
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
    
    "Simple SynthDefs created".postln;
    
    // Wait for SynthDefs to register
    s.sync;
    2.wait;
    
    // 6. Build the available SynthDef list
    var candidates, available;
    
    "Building SynthDef list...".postln;
    
    // List of all possible SynthDef names to check
    candidates = [
        // UPIC Wavetable variants
        \upicWavetable, 
        \upicWavetableAdditive, 
        \upicWavetableHarmonic,
        \upicWavetableRing,
        \upicWavetablePhase,
        \upicWavetablePrecise,
        
        // Simple SynthDefs
        \simpleGravObject,
        \simpleGravObjectPrecise,
        \testSinOsc,
        \simpleSaw,
        \testOrbit,
        \trajectoryVarSaw,
        
        // Advanced SynthDefs
        \pulsarTrain,
        \fmCascade,
        \additiveOS,
        \simpleOS,
        \richTexture,
        \percNoise,
        \auditoryDistortion,
        
        // Efficient SynthDefs
        \efficientDefault,
        \ultraLightVarSaw,
        \optimizedSimple
    ];
    
    // Initialize if needed
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
    };
    
    // Check which ones actually exist
    available = List.new;
    candidates.do { |name|
        if(SynthDescLib.global.synthDescs[name].notNil) {
            available.add(name);
            ("Found: " ++ name).postln;
        };
    };
    
    // Make sure we have at least the basic ones
    if(available.size == 0) {
        "WARNING: No SynthDefs found, using defaults".postln;
        available = [\simpleGravObject, \testSinOsc, \simpleSaw];
    };
    
    // Store the list
    ~nUPIC_SynthDefs[\available] = available.asArray;
    
    // Set default
    if(available.includes(\upicWavetable)) {
        ~nUPIC_SynthDefs[\default] = \upicWavetable;
    } {
        ~nUPIC_SynthDefs[\default] = available.first;
    };
    
    "".postln;
    ("Total SynthDefs available: " ++ available.size).postln;
    "Available SynthDefs:".postln;
    available.do { |name|
        ("  • " ++ name).postln;
    };
    
    // 7. Update the UI menu
    "".postln;
    "Updating UI menu...".postln;
    
    AppClock.sched(0, {
        var state = ~nUPIC[\ui][\state];
        var menuItems = ~nUPIC_SynthDefs[\available].collect(_.asString);
        
        if(state.notNil and: { state[\controls].notNil }) {
            var controls = state[\controls];
            
            // Update main synthDefMenu
            if(controls[\synthDefMenu].notNil) {
                controls[\synthDefMenu].items = menuItems;
                ("✓ Menu updated with " ++ menuItems.size ++ " items").postln;
                
                // Set default selection
                if(~nUPIC_SynthDefs[\default].notNil) {
                    var defaultIndex = ~nUPIC_SynthDefs[\available].indexOf(~nUPIC_SynthDefs[\default]);
                    if(defaultIndex.notNil) {
                        controls[\synthDefMenu].value = defaultIndex;
                    };
                };
            } {
                "synthDefMenu control not found".postln;
            };
            
            // Update any other menus
            [\synthDefMenu2, \synthDefMenuSidebar, \synthDefMenuCompact].do { |key|
                if(controls[key].notNil) {
                    controls[key].items = menuItems;
                    ("✓ Updated " ++ key).postln;
                };
            };
        } {
            "UI not ready - menu will update when window opens".postln;
        };
        nil;
    });
    
    1.wait;
    
    "".postln;
    "=== SYNTHDEF MENU FIX COMPLETE ===".postln;
    "".postln;
    
    // Store a refresh function for later use
    ~nUPIC[\ui][\refreshSynthDefMenus] = {
        fork {
            var available, candidates;
            
            available = List.new;
            candidates = [
                \upicWavetable, \upicWavetableAdditive, \upicWavetableHarmonic,
                \upicWavetableRing, \upicWavetablePhase, \upicWavetablePrecise,
                \simpleGravObject, \simpleGravObjectPrecise, \testSinOsc,
                \simpleSaw, \testOrbit, \trajectoryVarSaw,
                \pulsarTrain, \fmCascade, \additiveOS, \simpleOS,
                \richTexture, \percNoise, \auditoryDistortion,
                \efficientDefault, \ultraLightVarSaw, \optimizedSimple
            ];
            
            candidates.do { |name|
                if(SynthDescLib.global.synthDescs[name].notNil) {
                    available.add(name);
                };
            };
            
            ~nUPIC_SynthDefs[\available] = available.asArray;
            
            AppClock.sched(0, {
                var state = ~nUPIC[\ui][\state];
                if(state.notNil and: { state[\controls].notNil }) {
                    var controls = state[\controls];
                    if(controls[\synthDefMenu].notNil) {
                        controls[\synthDefMenu].items = available.collect(_.asString);
                    };
                };
                nil;
            });
            
            ("Menu refreshed with " ++ available.size ++ " SynthDefs").postln;
        };
    };
    
    "To refresh the menu again, run:".postln;
    "  ~nUPIC[\ui][\refreshSynthDefMenus].value;".postln;
    "".postln;
    "Or reload this script:".postln;
    "  \"fix_synthdef_menu.scd\".load;".postln;
};
)