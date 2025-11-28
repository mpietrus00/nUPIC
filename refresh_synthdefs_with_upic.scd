// Refresh nUPIC UI with upicWavetable SynthDefs
// Run this after START_NUPIC.scd to add the wavetable variants to the menu

(
"=== Refreshing SynthDefs with UPIC Wavetable Variants ===".postln;

// 1. First, ensure the upicWavetable SynthDefs are loaded
~loadUpicWavetableSynthDefs = {
    var upicPath;
    
    // Determine the base path
    if(~nUPIC_basePath.isNil) {
        // Try to set it based on current script location
        if(thisProcess.nowExecutingPath.notNil) {
            ~nUPIC_basePath = PathName(thisProcess.nowExecutingPath).pathOnly;
            ("Set base path to: " ++ ~nUPIC_basePath).postln;
        } {
            // Fall back to current directory
            ~nUPIC_basePath = "/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/";
            ("Using fallback base path: " ++ ~nUPIC_basePath).postln;
        };
    };
    
    upicPath = ~nUPIC_basePath +/+ "Audio/upicWavetable.scd";
    
    if(File.exists(upicPath)) {
        "Loading upicWavetable SynthDefs...".postln;
        upicPath.load;
        
        // Wait for SynthDefs to compile
        s.sync;
        
        "upicWavetable SynthDefs loaded".postln;
    } {
        "ERROR: Could not find Audio/upicWavetable.scd".postln;
        "Make sure the file exists at: " ++ upicPath;
        "Attempting direct load...".postln;
        // Try direct load as fallback
        "Audio/upicWavetable.scd".loadRelative;
    };
};

// 2. Update the global SynthDef list
~refreshSynthDefList = {
    var candidates, available;
    
    // Initialize if needed
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
    };
    
    // List of all possible SynthDefs to check for
    candidates = [
        // UPIC Wavetable variants
        \upicWavetable, 
        \upicWavetableAdditive, 
        \upicWavetableHarmonic,
        \upicWavetableRing,
        \upicWavetablePhase,
        
        // Advanced SynthDefs
        \pulsarTrain, \grainBank, \fmCascade, \fmOrgan, \simpleOrgan,
        \percussiveGravObject, \metallicGravObject, \drumGravObject,
        \additiveOS, \simpleOS,
        
        // Simple SynthDefs
        \simpleGravObject, \trajectoryVarSaw, \testOrbit,
        \richTexture, \percNoise, \auditoryDistortion,
        \testSinOsc, \testSinOscVibrato, \simpleSine,
        
        // Efficient SynthDefs
        \efficientDefault, \ultraLightVarSaw, \optimizedSimple
    ];
    
    // Check which ones are actually available
    available = List.new;
    candidates.do { |sym|
        if(SynthDescLib.global.synthDescs[sym].notNil) { 
            available.add(sym);
            ("Found: " ++ sym).postln;
        };
    };
    
    // Update the global registry
    ~nUPIC_SynthDefs[\available] = available.asArray;
    
    // Set default to upicWavetable if available
    if(available.includes(\upicWavetable)) {
        ~nUPIC_SynthDefs[\default] = \upicWavetable;
        "Default set to: upicWavetable".postln;
    };
    
    "".postln;
    ("Total SynthDefs available: " ++ available.size).postln;
    available;
};

// 3. Update all menu widgets in the UI
~updateAllSynthDefMenus = {
    var state = ~nUPIC[\ui][\state];
    var menuItems;
    
    if(~nUPIC_SynthDefs[\available].notNil) {
        menuItems = ~nUPIC_SynthDefs[\available].collect(_.asString);
        
        "Updating menu widgets...".postln;
        
        // Schedule UI updates on AppClock to avoid threading issues
        AppClock.sched(0, {
            if(state.notNil and: { state[\controls].notNil }) {
                var controls = state[\controls];
                
                // Update main synthDefMenu (bottom panel)
                if(controls[\synthDefMenu].notNil) {
                    controls[\synthDefMenu].items = menuItems;
                    "✓ Updated main synthDefMenu".postln;
                    ("  Menu now has " ++ menuItems.size ++ " items").postln;
                } {
                    "Main synthDefMenu not found - window may not be open".postln;
                };
                
                // Update any other synth menus that might exist
                [\synthDefMenu2, \synthDefMenuSidebar, \synthDefMenuCompact].do { |key|
                    if(controls[key].notNil) {
                        controls[key].items = menuItems;
                        ("✓ Updated " ++ key).postln;
                    };
                };
            } {
                "UI not open yet - SynthDefs will be available when window opens".postln;
            };
            nil; // Return nil to stop scheduling
        });
    } {
        "ERROR: No available SynthDefs found".postln;
    };
};

// 4. Execute the refresh process
fork {
    "".postln;
    "Step 1: Loading upicWavetable SynthDefs...".postln;
    ~loadUpicWavetableSynthDefs.value;
    
    1.wait; // Wait for SynthDefs to load
    
    "".postln;
    "Step 2: Refreshing SynthDef list...".postln;
    ~refreshSynthDefList.value;
    
    0.5.wait;
    
    "".postln;
    "Step 3: Updating UI menus...".postln;
    ~updateAllSynthDefMenus.value;
    
    "".postln;
    "=== REFRESH COMPLETE ===".postln;
    "The following SynthDefs are now available:".postln;
    ~nUPIC_SynthDefs[\available].do { |name, i|
        ("  " ++ (i+1) ++ ". " ++ name).postln;
    };
    
    "".postln;
    "WAVETABLE VARIANTS:".postln;
    "• upicWavetable         - Original single oscillator (raw)".postln;
    "• upicWavetableAdditive - 5 detuned voices (spread parameter)".postln;
    "• upicWavetableHarmonic - Harmonic stack (mass controls emphasis)".postln;
    "• upicWavetableRing     - Ring modulation (velocity controls mod freq)".postln;
    "• upicWavetablePhase    - Phase modulation (width controls depth)".postln;
    
    "".postln;
    "To set a default for new trajectories:".postln;
    "  ~nUPIC[\defaults][\defaultSynthDef] = \upicWavetableAdditive;".postln;
    
    // Store refresh function for later use
    ~nUPIC[\ui][\refreshSynthDefMenus] = {
        fork {
            ~refreshSynthDefList.value;
            0.1.wait;
            ~updateAllSynthDefMenus.value;
        };
    };
    
    "".postln;
    "To refresh menus again later:".postln;
    "  ~nUPIC[\ui][\refreshSynthDefMenus].value;".postln;
};
)