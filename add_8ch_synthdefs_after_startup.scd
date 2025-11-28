// Add 8ch spatialization synthdefs to menu after nUPIC startup
// Run this after START_NUPIC.scd to ensure spatial synthdefs are available

(
fork {
    "Adding 8ch spatialization synthdefs to menu...".postln;
    
    // Wait for nUPIC to be fully loaded
    while { ~nUPIC.isNil or: { ~nUPIC[\ui].isNil } } {
        0.5.wait;
    };
    
    1.wait; // Extra time for UI to stabilize
    
    // Ensure 8ch synthdefs are in the registry
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
        ~nUPIC_SynthDefs[\available] = [];
    };
    
    var currentList = ~nUPIC_SynthDefs[\available].asArray;
    var spatialSynthDefs = [\upicWavetable8chEnv, \upicWavetablePrecise8chEnv, \simpleGravObject8chEnv];
    var added = false;
    
    spatialSynthDefs.do { |synthName|
        if(currentList.includes(synthName).not) {
            currentList = currentList ++ [synthName];
            ("  ✓ Added " ++ synthName).postln;
            added = true;
        };
    };
    
    if(added) {
        // Update global registry
        ~nUPIC_SynthDefs[\available] = currentList;
        
        // Update UI menus
        {
            if(~nUPIC[\ui][\state].notNil and: { ~nUPIC[\ui][\state][\controls].notNil }) {
                var controls = ~nUPIC[\ui][\state][\controls];
                var menuItems = ~nUPIC_SynthDefs[\available].collect { |name|
                    case
                    { name == \upicWavetable8chEnv } { "UPIC Wavetable 8ch Spatial" }
                    { name == \upicWavetablePrecise8chEnv } { "UPIC Precise 8ch Spatial" }
                    { name == \simpleGravObject8chEnv } { "Simple Grav 8ch Spatial" }
                    { true } { name.asString }
                };
                
                // Find and update synthdef menus
                controls.keysValuesDo { |key, control|
                    if(key.asString.toLower.contains("synth") and: { control.respondsTo(\items) }) {
                        control.items = menuItems;
                        ("  ✓ Updated " ++ key).postln;
                    };
                };
                
                "✓ 8ch spatial synthdefs added to menus".postln;
            };
        }.defer;
        
    } {
        "8ch spatial synthdefs already present".postln;
    };
    
    "".postln;
    "Available spatial synthdefs:".postln;
    "• upicWavetable8chEnv - UPIC wavetable with 8-channel spatial envelopes".postln;
    "• upicWavetablePrecise8chEnv - Precise version with spatial control".postln;
    "• simpleGravObject8chEnv - Simple gravity object with spatialization".postln;
};
)