// Fix UI issues: drawing mode, frequency labels, default modes
(
"Fixing nUPIC UI issues...".postln;

// 1. Switch to drawing mode (disable erase mode)
if(~nUPIC[\ui][\state].notNil) {
    var state = ~nUPIC[\ui][\state];
    
    // Enable drawing mode
    state[\eraseMode] = false;
    state[\selectMode] = false;
    state[\drawingEnabled] = true;
    
    "✓ Drawing mode enabled".postln;
    
    // 2. Update UI controls to reflect correct state
    if(state[\controls].notNil) {
        var controls = state[\controls];
        
        // Update erase mode button
        if(controls[\eraseModeButton].notNil) {
            {
                controls[\eraseModeButton].value = 0; // Off
            }.defer;
        };
        
        // Update select mode button
        if(controls[\selectModeButton].notNil) {
            {
                controls[\selectModeButton].value = 0; // Off
            }.defer;
        };
        
        "✓ UI controls updated".postln;
    };
    
    // 3. Force refresh of drawing area
    if(~nUPIC[\ui][\refreshDisplay].notNil) {
        {
            ~nUPIC[\ui][\refreshDisplay].value;
        }.defer;
        "✓ Display refreshed".postln;
    };
    
    // 4. Enable frequency labels if they exist
    if(state[\showFreqLabels].notNil) {
        state[\showFreqLabels] = true;
    };
    
    "✓ UI issues fixed".postln;
    "".postln;
    "Current mode: DRAWING (click and drag to create trajectories)".postln;
    "- Press 'E' to toggle erase mode".postln;
    "- Press 'G' to toggle select mode".postln;
    "- Press SPACE to play/stop".postln;
    
} {
    "✗ nUPIC UI state not found".postln;
    "Try running this after nUPIC is fully loaded".postln;
};
)