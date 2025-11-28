// Test script to verify all SynthDefs are loaded and available
// Run this after loading nUPIC_Main.scd

(
"========================================".postln;
"Testing nUPIC SynthDef Loading".postln;
"========================================".postln;

// First, check if the SynthDefs module is loaded
if(~nUPIC_SynthDefs.notNil) {
    "✓ SynthDefs module loaded".postln;
    
    // Check if the available list exists
    if(~nUPIC_SynthDefs[\available].notNil) {
        "✓ Available SynthDef list found".postln;
        "\nAvailable SynthDefs:".postln;
        "--------------------".postln;
        
        ~nUPIC_SynthDefs[\available].do { |name, i|
            var displayName = case
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
                { name.asString };
            ("  " ++ (i+1).asString.padLeft(2) ++ ". " ++ name.asString.padRight(20) ++ " (" ++ displayName ++ ")").postln;
        };
        
        ("\n✓ Total: " ++ ~nUPIC_SynthDefs[\available].size ++ " SynthDefs available").postln;
        
        // Check if they're actually loaded in the server
        "\nChecking server SynthDesc library:".postln;
        "-----------------------------------".postln;
        ~nUPIC_SynthDefs[\available].do { |name|
            if(SynthDescLib.global.at(name).notNil) {
                ("  ✓ " ++ name ++ " is loaded in server").postln;
            } {
                ("  ✗ " ++ name ++ " NOT found in server!").postln;
            };
        };
        
    } {
        "✗ Available SynthDef list NOT found!".postln;
    };
} {
    "✗ SynthDefs module NOT loaded!".postln;
    "Try running: (~nUPIC_basePath +/+ \"Audio/SynthDefs.scd\").load;".postln;
};

// Check UI state
"\nChecking UI state:".postln;
"------------------".postln;
if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil }) {
    "✓ UI module loaded".postln;
    
    if(~nUPIC[\ui][\state].notNil) {
        "✓ UI state exists".postln;
        
        if(~nUPIC[\ui][\state][\controls].notNil) {
            "✓ UI controls exist".postln;
            
            // Check if synthDefMenu exists
            if(~nUPIC[\ui][\state][\controls][\synthDefMenu].notNil) {
                var menu = ~nUPIC[\ui][\state][\controls][\synthDefMenu];
                "✓ SynthDef menu control exists".postln;
                ("  Current menu items: " ++ menu.items.size).postln;
                if(menu.items.size < 12) {
                    "  ⚠ Menu has fewer than 12 items!".postln;
                    "  Current items: ".postln;
                    menu.items.do { |item, i|
                        ("    " ++ (i+1) ++ ". " ++ item).postln;
                    };
                };
            } {
                "✗ SynthDef menu control not found".postln;
            };
        } {
            "✗ UI controls not found".postln;
        };
    } {
        "✗ UI state not found".postln;
    };
} {
    "✗ UI module not loaded".postln;
};

"========================================".postln;
"Test complete".postln;
"========================================".postln;

// If everything is loaded but menus don't show all items, suggest fix
if(~nUPIC_SynthDefs.notNil and: { 
    ~nUPIC_SynthDefs[\available].notNil } and: { 
    ~nUPIC_SynthDefs[\available].size == 12 
}) {
    if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil } and: { 
        ~nUPIC[\ui][\state].notNil } and: { 
        ~nUPIC[\ui][\state][\controls].notNil } and: {
        ~nUPIC[\ui][\state][\controls][\synthDefMenu].notNil
    }) {
        var menu = ~nUPIC[\ui][\state][\controls][\synthDefMenu];
        if(menu.items.size < 12) {
            "\n⚠ ISSUE DETECTED: SynthDefs loaded but menu not updated".postln;
            "SOLUTION: Close and reopen the nUPIC window:".postln;
            "  1. Close the current nUPIC window".postln;
            "  2. Run: ~nUPIC[\ui][\createMainWindow].value;".postln;
            "This will recreate the window with all SynthDefs in the menus.".postln;
        } {
            "\n✓ SUCCESS: All SynthDefs are loaded and visible in menus!".postln;
        };
    };
};
)
