// Add new upicWavetable variants to SynthDef menu
// Run this after START_NUPIC.scd to update the menu with the new variants

(
"=== Adding Wavetable Variants to Menu ===".postln;

// 1. Update the global SynthDef list
~updateWavetableMenus = {
    var currentList;
    var wavetableVariants;
    
    // Initialize if needed
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
    };
    
    // Get current list or start fresh
    currentList = if(~nUPIC_SynthDefs[\available].notNil) {
        ~nUPIC_SynthDefs[\available]
    } {
        []
    };
    
    // All wavetable variants to add
    wavetableVariants = [
        \upicWavetable,
        \upicWavetableAdditive, 
        \upicWavetableHarmonic,
        \upicWavetableRing,
        \upicWavetablePhase
    ];
    
    // Add wavetable variants if they exist and aren't already in list
    wavetableVariants.do { |synthName|
        if(SynthDescLib.global.at(synthName).notNil) {
            if(currentList.includes(synthName).not) {
                currentList = currentList.add(synthName);
                ("Added " ++ synthName ++ " to available list").postln;
            } {
                (synthName ++ " already in list").postln;
            };
        } {
            ("WARNING: " ++ synthName ++ " SynthDef not found - make sure upicWavetable.scd is loaded").postln;
        };
    };
    
    // Store updated list
    ~nUPIC_SynthDefs[\available] = currentList;
    
    "".postln;
    ("Updated available SynthDefs: " ++ currentList).postln;
};

// 2. Update all existing menu widgets
~updateAllWavetableMenus = {
    var state = ~nUPIC[\ui][\state];
    
    if(~nUPIC_SynthDefs[\available].notNil) {
        var menuItems = ~nUPIC_SynthDefs[\available].collect(_.asString);
        
        "Updating menu widgets...".postln;
        
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
            "UI not open - menus will be updated when window opens".postln;
            "The SynthDef list has been updated for next window opening".postln;
        };
    } {
        "ERROR: No available SynthDefs found".postln;
    };
};

// 3. Execute updates
"".postln;
"Updating SynthDef list...".postln;
~updateWavetableMenus.value;

"".postln;
"Updating menu widgets...".postln;
~updateAllWavetableMenus.value;

"".postln;
"=== MENU UPDATE COMPLETE ===".postln;
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
~nUPIC[\ui][\refreshWavetableMenus] = {
    ~updateWavetableMenus.value;
    ~updateAllWavetableMenus.value;
};

"".postln;
"To refresh menus again later:".postln;
"  ~nUPIC[\ui][\refreshWavetableMenus].value;".postln;
)