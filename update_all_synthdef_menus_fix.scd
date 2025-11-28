// Update all synthdef menus to include 8ch spatialization synthdefs
// Run this after nUPIC is loaded to ensure all menus show spatial synthdefs

(
fork {
    "=== Updating All SynthDef Menus ===".postln;
    "".postln;
    
    // Wait a moment to ensure everything is loaded
    0.5.wait;
    
    // 1. Build complete list of available synthdefs
    var allSynthDefs = [];
    
    // Get standard synthdefs
    if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
        allSynthDefs = allSynthDefs ++ ~nUPIC_SynthDefs[\available];
    };
    
    // Ensure 8ch envelope synthdefs are included
    var spatialSynthDefs = [\upicWavetable8chEnv, \upicWavetablePrecise8chEnv, \simpleGravObject8chEnv];
    spatialSynthDefs.do { |synthName|
        if(allSynthDefs.includes(synthName).not) {
            allSynthDefs = allSynthDefs ++ [synthName];
        };
    };
    
    // Remove duplicates and sort
    allSynthDefs = allSynthDefs.asSet.asArray.sort;
    
    // Update global registry
    ~nUPIC_SynthDefs[\available] = allSynthDefs;
    
    "Available SynthDefs:".postln;
    allSynthDefs.do { |name, i|
        ("  " ++ (i+1) ++ ". " ++ name).postln;
    };
    "".postln;
    
    // 2. Create human-readable menu items
    var menuItems = allSynthDefs.collect { |name|
        case
        // 8-channel spatial synthdefs
        { name == \upicWavetable8chEnv } { "UPIC Wavetable 8ch Spatial" }
        { name == \upicWavetablePrecise8chEnv } { "UPIC Precise 8ch Spatial" }
        { name == \simpleGravObject8chEnv } { "Simple Grav 8ch Spatial" }
        // Standard synthdefs
        { name == \upicWavetable } { "UPIC Wavetable" }
        { name == \upicWavetablePrecise } { "UPIC Wavetable Precise" }
        { name == \simpleGravObject } { "Simple Grav Object" }
        { name == \percNoise } { "Percussive Noise" }
        { name == \auditoryDistortion } { "Auditory Distortion" }
        { name == \richTexture } { "Rich Texture" }
        // Advanced synthdefs
        { name == \pulsarTrain } { "Pulsar Train" }
        { name == \grainBank } { "Grain Bank" }
        { name == \fmCascade } { "FM Cascade" }
        { name == \additiveOS } { "Additive OS" }
        { name == \simpleOS } { "Simple OS" }
        { name == \testOrbit } { "Test Orbit" }
        // Percussive variants
        { name == \percussiveGravObject } { "Percussive Grav Object" }
        { name == \metallicGravObject } { "Metallic Grav Object" }
        { name == \drumGravObject } { "Drum Grav Object" }
        // FM organ variants
        { name == \fmOrgan } { "FM Organ" }
        { name == \simpleOrgan } { "Simple Organ" }
        // Default
        { true } { name.asString.replace("_", " ").capitalize }
    };
    
    // 3. Update UI menus on AppClock
    {
        if(~nUPIC[\ui].notNil and: { ~nUPIC[\ui][\state].notNil }) {
            var state = ~nUPIC[\ui][\state];
            var controls = state[\controls];
            
            if(controls.notNil) {
                var menusUpdated = 0;
                
                // Find and update all synthdef menus
                controls.keysValuesDo { |key, control|
                    if(control.notNil and: { control.respondsTo(\items) }) {
                        var keyStr = key.asString.toLower;
                        if(keyStr.contains("synth") or: { keyStr.contains("menu") }) {
                            // Check if this looks like a synthdef menu by its current items
                            var currentItems = control.items;
                            if(currentItems.notNil and: { currentItems.size > 0 }) {
                                var firstItem = currentItems[0].asString.toLower;
                                // If it contains synthdef-related terms, update it
                                if(firstItem.contains("grav") or: 
                                   { firstItem.contains("upic") } or: 
                                   { firstItem.contains("perc") } or:
                                   { firstItem.contains("test") } or:
                                   { firstItem.contains("pulsar") }) {
                                    control.items = menuItems;
                                    ("  ✓ Updated " ++ key).postln;
                                    menusUpdated = menusUpdated + 1;
                                };
                            };
                        };
                    };
                };
                
                if(menusUpdated > 0) {
                    ("Updated " ++ menusUpdated ++ " menu(s)").postln;
                } {
                    "No menus found to update - they may update when opened".postln;
                };
            };
        } {
            "UI not active - menus will show all synthdefs when opened".postln;
        };
    }.defer;
    
    0.5.wait;
    
    "".postln;
    "=== Menu Update Complete ===".postln;
    "".postln;
    "8-channel spatial synthdefs available:".postln;
    "  • UPIC Wavetable 8ch Spatial - Full wavetable synthesis with spatial envelopes".postln;
    "  • UPIC Precise 8ch Spatial - High-precision version for detailed work".postln;
    "  • Simple Grav 8ch Spatial - Gravity-based synthesis with spatial control".postln;
    "".postln;
    "To use spatial synthdefs:".postln;
    "1. Select a trajectory with 'G' key".postln;
    "2. Choose an 8ch spatial synthdef from the menu".postln;
    "3. Open the Spatialization Editor to draw spatial paths".postln;
    "".postln;
};
)