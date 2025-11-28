// Debug script to check SynthDef menu state
// Run this in SuperCollider to diagnose the issue

(
"=== DEBUG: SynthDef Menu Status ===".postln;

// Check if nUPIC is loaded
if(~nUPIC.isNil) {
    "ERROR: ~nUPIC is not loaded. Please run nUPIC_Main.scd first.".postln;
} {
    "✓ ~nUPIC namespace exists".postln;
    
    // Check SynthDef availability
    if(~nUPIC_SynthDefs.isNil) {
        "ERROR: ~nUPIC_SynthDefs is not loaded".postln;
    } {
        "✓ ~nUPIC_SynthDefs exists".postln;
        
        if(~nUPIC_SynthDefs[\available].isNil) {
            "ERROR: ~nUPIC_SynthDefs[\\available] is nil".postln;
        } {
            "Available SynthDefs:".postln;
            ~nUPIC_SynthDefs[\available].do { |name, i|
                ("  " ++ (i+1) ++ ". " ++ name).postln;
            };
            
            if(~nUPIC_SynthDefs[\available].includes(\richTexture)) {
                "✓ richTexture is in the available SynthDefs list".postln;
            } {
                "✗ richTexture is NOT in the available SynthDefs list".postln;
                "Adding richTexture to the list...".postln;
                ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available] ++ [\richTexture];
                "✓ richTexture added to the list".postln;
            };
        };
    };
    
    // Check if UI exists
    if(~nUPIC[\ui].isNil) {
        "ERROR: ~nUPIC[\\ui] is not loaded".postln;
    } {
        "✓ ~nUPIC[\\ui] exists".postln;
        
        // Check UI state
        if(~nUPIC[\ui][\state].isNil) {
            "ERROR: ~nUPIC[\\ui][\\state] is not loaded".postln;
        } {
            "✓ UI state exists".postln;
            
            // Check controls
            if(~nUPIC[\ui][\state][\controls].isNil) {
                "ERROR: Controls not loaded".postln;
            } {
                "✓ Controls exist".postln;
                
                // Check SynthDef menu specifically
                if(~nUPIC[\ui][\state][\controls][\synthDefMenu].isNil) {
                    "ERROR: SynthDef menu not found in controls".postln;
                    "Available control names:".postln;
                    ~nUPIC[\ui][\state][\controls].keys.asArray.sort.do { |key|
                        ("  - " ++ key).postln;
                    };
                } {
                    "✓ SynthDef menu exists".postln;
                    
                    // Get current menu items
                    var currentItems = ~nUPIC[\ui][\state][\controls][\synthDefMenu].items;
                    "Current menu items:".postln;
                    currentItems.do { |item, i|
                        ("  " ++ (i+1) ++ ". " ++ item).postln;
                    };
                    
                    if(currentItems.includes("richTexture")) {
                        "✓ richTexture is in the menu".postln;
                    } {
                        "✗ richTexture is NOT in the menu".postln;
                        "Updating menu items...".postln;
                        
                        // Update the menu
                        var newItems = if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
                            ~nUPIC_SynthDefs[\available].collect(_.asString)
                        } { ["simpleGravObject", "percNoise", "auditoryDistortion", "richTexture"] };
                        
                        ~nUPIC[\ui][\state][\controls][\synthDefMenu].items_(newItems);
                        "✓ Menu updated with new items:".postln;
                        newItems.do { |item, i|
                            ("  " ++ (i+1) ++ ". " ++ item).postln;
                        };
                    };
                };
            };
        };
    };
};

// Check if the richTexture SynthDef actually exists on the server
if(\richTexture.asSymbol.synthDefExists) {
    "✓ richTexture SynthDef is loaded on the server".postln;
} {
    "✗ richTexture SynthDef is NOT loaded on the server".postln;
    "Reloading SynthDefs...".postln;
    (~nUPIC_basePath +/+ "Audio/SynthDefs.scd").load;
    
    // Check again
    if(\richTexture.asSymbol.synthDefExists) {
        "✓ richTexture SynthDef is now loaded".postln;
    } {
        "✗ richTexture SynthDef still failed to load - check for syntax errors".postln;
    };
};

"=== DEBUG COMPLETE ===".postln;
)
