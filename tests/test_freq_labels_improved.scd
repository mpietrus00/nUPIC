// Test script to verify improved frequency label rendering
// This script reloads the drawing module and refreshes displays

(
"Testing improved frequency label display...".postln;

// Load the drawing module first
load("/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/UI/Drawing.scd");

// Wait a moment for the module to load
1.wait;

// Check if nUPIC system exists
if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil }) {
    "nUPIC UI system found.".postln;
    
    // Test frequency calculation explicitly with debug logging
    "Testing frequency range calculation...".postln;
    
    if(~nUPIC[\ui][\calculateGridFrequencies].notNil) {
        // Set up minimal state for testing if not available
        if(~nUPIC[\ui][\state].isNil) {
            ~nUPIC[\ui][\state] = IdentityDictionary.new;
            ~nUPIC[\ui][\state][\zoomFreqMin] = 20;
            ~nUPIC[\ui][\state][\zoomFreqMax] = 7500;
            ~nUPIC[\ui][\state][\gridType] = \equalTemperament;
            ~nUPIC[\ui][\state][\showGrid] = true;
            "Set up minimal UI state for testing.".postln;
        };
        
        var testFreqs = ~nUPIC[\ui][\calculateGridFrequencies].value(440, 20);
        if(testFreqs.size > 0) {
            "Generated % frequency labels from %Hz to %Hz".format(
                testFreqs.size, testFreqs.minItem.round(0.1), testFreqs.maxItem.round(0.1)
            ).postln;
        } else {
            "Warning: No frequencies generated!".postln;
        };
        
        // Force refresh all displays if they exist
        if(~nUPIC[\ui][\state][\drawView].notNil) {
            { ~nUPIC[\ui][\state][\drawView].refresh }.defer;
            "Main canvas refreshed".postln;
        };
        
        if(~nUPIC[\ui][\state][\freqLabelView].notNil) {
            { ~nUPIC[\ui][\state][\freqLabelView].refresh }.defer;
            "Frequency label view refreshed".postln;
        };
        
    } else {
        "Error: calculateGridFrequencies function not found!".postln;
    };
    
    "Test complete. The improved frequency label spacing should now be active.".postln;
} else {
    "Error: nUPIC system not loaded! Please run the main initialization first.".postln;
};
)
