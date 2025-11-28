// Update ALL SynthDef menus in the UI to show all available SynthDefs
// Run this script to ensure all menus are synchronized with available SynthDefs

(
// First, ensure SynthDefs are loaded
if(~nUPIC_SynthDefs.isNil or: { ~nUPIC_SynthDefs[\available].isNil }) {
    "Loading SynthDefs first...".postln;
    (~nUPIC_basePath +/+ "Audio/SynthDefs.scd").load;
    s.sync;
    "SynthDefs loaded".postln;
};

// Wait a moment for SynthDefs to load
fork {
    var availableSynthDefs, synthDefDisplayNames;
    
    0.5.wait;
    
    // Get the list of available SynthDefs
    availableSynthDefs = ~nUPIC_SynthDefs[\available];
    synthDefDisplayNames = availableSynthDefs.collect { |name|
        case
        { name == \simpleGravObject } { "GravObject" }
        { name == \simpleGravObj2 } { "GravObj2" }
        { name == \richTexture } { "RichTexture" }
        { name == \percNoise } { "PercNoise" }
        { name == \auditoryDistortion } { "Distortion" }
        { name == \testSinOsc } { "TestSine" }
        { name == \testSinOscVibrato } { "TestVibrato" }
        { name == \simpleSine } { "SimpleSine" }
        { name == \simpleVarSaw } { "SimpleVarSaw" }
        { name == \efficientDefault } { "Efficient" }
        { name == \ultraLightVarSaw } { "UltraLight" }
        { name == \optimizedSimple } { "Optimized" }
        { name.asString }  // Default: use the symbol as string
    };
    
    "Available SynthDefs:".postln;
    availableSynthDefs.do { |name, i|
        ("  " ++ (i+1) ++ ". " ++ name ++ " (" ++ synthDefDisplayNames[i] ++ ")").postln;
    };
    
    // Update the sidebar SynthDef menu if it exists
    if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil } and: { ~nUPIC[\ui][\state].notNil }) {
        var state = ~nUPIC[\ui][\state];
        
        // Update sidebar menu
        if(state[\controls].notNil and: { state[\controls][\synthDefMenu].notNil }) {
            var menu = state[\controls][\synthDefMenu];
            
            {
                // Update the menu items
                menu.items = synthDefDisplayNames;
                
                // Preserve current selection if possible
                if(menu.value >= availableSynthDefs.size) {
                    menu.value = 0;
                };
                
                // Update the action to use the correct synthdef names
                menu.action = { |m|
                    var selectedSynth = availableSynthDefs[m.value];
                    var data = ~nUPIC[\data];
                    var defaults = ~nUPIC[\defaults];
                    
                    if(data.notNil and: { data[\selectedTrajectories].notNil } and: { 
                        data[\selectedTrajectories].size > 0 
                    }) {
                        if(data[\trajectorySynthDefs].isNil) {
                            data[\trajectorySynthDefs] = List.new;
                        };
                        data[\selectedTrajectories].do { |idx|
                            if(idx < data[\trajectorySynthDefs].size) {
                                data[\trajectorySynthDefs][idx] = selectedSynth;
                                ("Trajectory " ++ idx ++ " set to use " ++ selectedSynth).postln;
                            };
                        };
                    } {
                        if(defaults.notNil) {
                            defaults[\defaultSynthDef] = selectedSynth;
                        };
                        ("Default SynthDef set to " ++ selectedSynth ++ " for new trajectories").postln;
                    };
                };
                
                "Sidebar SynthDef menu updated with all available SynthDefs".postln;
            }.defer;
        } {
            "Sidebar SynthDef menu control not found - may need to recreate UI".postln;
        };
        
        // The bottom panel menu should already be dynamic, but let's refresh it too
        if(state[\controls][\synthDefMenu].notNil) {
            {
                state[\controls][\synthDefMenu].items = synthDefDisplayNames;
            }.defer;
            "Bottom panel SynthDef menu refreshed".postln;
        };
        
    } {
        "UI state not found - please open the nUPIC window first".postln;
    };
    
    "\n✓ SynthDef menus update complete!".postln;
    "All " ++ availableSynthDefs.size ++ " SynthDefs should now appear in the menus.".postln;
};
)
