// Ensure 8ch spatialization synthdefs are included in all UI menus
// This script updates the global synthdef registry and refreshes all UI menus

(
"=== Ensuring 8ch Spatialization SynthDefs are in Menu ===".postln;
"".postln;

// 1. First ensure the 8ch envelope synthdefs are loaded
if(~nUPIC_8ch_env_SynthDefs.isNil) {
    "Loading 8ch envelope synthdefs...".postln;
    (~nUPIC_basePath +/+ "Audio/SynthDefs_8ch_envelope.scd").load;
    1.wait;
} {
    "8ch envelope synthdefs already loaded".postln;
};

// 2. Check if they're in the global registry
"Checking global synthdef registry...".postln;

if(~nUPIC_SynthDefs.isNil) {
    ~nUPIC_SynthDefs = IdentityDictionary.new;
    ~nUPIC_SynthDefs[\available] = [];
};

// Get current list
var currentList = ~nUPIC_SynthDefs[\available].asArray;
"Current synthdefs: ".post; currentList.postln;

// Add 8ch synthdefs if not present
var synthsToAdd = [\upicWavetable8chEnv, \upicWavetablePrecise8chEnv, \simpleGravObject8chEnv];
var added = false;

synthsToAdd.do { |synthName|
    if(currentList.includes(synthName).not) {
        currentList = currentList ++ [synthName];
        ("  Added: " ++ synthName).postln;
        added = true;
    } {
        ("  Already present: " ++ synthName).postln;
    };
};

// Update the registry
~nUPIC_SynthDefs[\available] = currentList;

"".postln;
"Updated synthdef list: ".post; ~nUPIC_SynthDefs[\available].postln;
"".postln;

// 3. Update all UI menus if UI is loaded
if(~nUPIC[\ui].notNil and: { ~nUPIC[\ui][\state].notNil }) {
    var state = ~nUPIC[\ui][\state];
    var controls = state[\controls];
    
    if(controls.notNil) {
        var menuItems = ~nUPIC_SynthDefs[\available].collect { |name|
            // Create human-readable names
            case
            { name == \upicWavetable8chEnv } { "UPIC Wavetable 8ch (Envelope)" }
            { name == \upicWavetablePrecise8chEnv } { "UPIC Wavetable Precise 8ch (Envelope)" }
            { name == \simpleGravObject8chEnv } { "Simple Grav Object 8ch (Envelope)" }
            { name == \upicWavetable } { "UPIC Wavetable" }
            { name == \simpleGravObject } { "Simple Grav Object" }
            { name == \percNoise } { "Percussive Noise" }
            { name == \auditoryDistortion } { "Auditory Distortion" }
            { name == \richTexture } { "Rich Texture" }
            { name == \pulsarTrain } { "Pulsar Train" }
            { name == \grainBank } { "Grain Bank" }
            { name == \fmCascade } { "FM Cascade" }
            { name == \additiveOS } { "Additive OS" }
            { name == \simpleOS } { "Simple OS" }
            { name == \testOrbit } { "Test Orbit" }
            { true } { name.asString }
        };
        
        "Updating UI menus...".postln;
        
        // Use defer to update on AppClock
        {
            // Update all synthDefMenu instances
            if(controls[\synthDefMenu].notNil) {
                controls[\synthDefMenu].items = menuItems;
                "  ✓ Updated main synthDefMenu".postln;
            };
            
            // Also check for any other menu instances in the UI
            controls.keysValuesDo { |key, control|
                if(key.asString.contains("synthDef") and: { control.respondsTo(\items) }) {
                    control.items = menuItems;
                    ("  ✓ Updated " ++ key).postln;
                };
            };
        }.defer;
        
        "".postln;
        "UI menus updated successfully!".postln;
    } {
        "UI controls not found - menus will be updated when UI opens".postln;
    };
} {
    "UI not loaded - menus will include 8ch synthdefs when UI opens".postln;
};

"".postln;
"=== SUMMARY ===".postln;
if(added) {
    "✓ 8ch spatialization synthdefs added to registry".postln;
} {
    "✓ 8ch spatialization synthdefs were already in registry".postln;
};
"✓ Total available synthdefs: ".post; ~nUPIC_SynthDefs[\available].size.postln;
"".postln;
"The following 8ch synthdefs are now available:".postln;
"  • upicWavetable8chEnv - 8-channel spatialization with envelope control".postln;
"  • upicWavetablePrecise8chEnv - Precise 8-channel with envelope control".postln;  
"  • simpleGravObject8chEnv - Simple gravity object with 8-channel envelope".postln;
"".postln;
"Use the Spatialization Editor to create spatial envelopes for these synthdefs.".postln;
)