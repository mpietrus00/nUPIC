// Test script to verify that zoom system updates when duration changes
// Run this after the nUPIC system is loaded and initialized

(
\"Testing zoom system updates with duration changes...\".postln;

// Check if system is properly initialized
if(~nUPIC.isNil or: { ~nUPIC[\\ui].isNil } or: { ~nUPIC[\\ui][\\state].isNil }) {
    \"ERROR: nUPIC system not initialized. Run nUPIC_MAIN.scd first.\".postln;
} {
    var state = ~nUPIC[\\ui][\\state];
    var initialDuration, initialZoomLevels;
    
    \"Initial state:\".postln;
    \"Current duration: %\".format(state[\\playDuration]).postln;
    
    if(state[\\zoomLevels].notNil) {
        \"Current zoom levels:\".postln;
        state[\\zoomLevels].do { |level, i|
            \"  %: %\".format(i, level.name).postln;
        };
        \"Current zoom level: % (%)\".format(
            state[\\currentZoomLevel], 
            state[\\zoomLevels][state[\\currentZoomLevel]].name
        ).postln;
    } else {
        \"WARNING: Zoom levels not initialized\".postln;
    };
    
    // Save initial values
    initialDuration = state[\\playDuration];
    initialZoomLevels = state[\\zoomLevels].copy;
    
    \"\\nTesting duration change to 60s...\".postln;
    
    // Change duration to 60 seconds
    state[\\playDuration] = 60;
    
    // Call the duration change handler
    if(~nUPIC[\\ui][\\onDurationChange].notNil) {
        ~nUPIC[\\ui][\\onDurationChange].value;
        \"Duration change handler called\".postln;
    } else {
        \"WARNING: Duration change handler not found\".postln;
    };
    
    \"\\nAfter duration change:\".postln;
    \"New duration: %\".format(state[\\playDuration]).postln;
    
    if(state[\\zoomLevels].notNil) {
        \"New zoom levels:\".postln;
        state[\\zoomLevels].do { |level, i|
            \"  %: %\".format(i, level.name).postln;
        };
        \"Current zoom level: % (%)\".format(
            state[\\currentZoomLevel], 
            state[\\zoomLevels][state[\\currentZoomLevel]].name
        ).postln;
        
        // Check if zoom levels actually changed
        var levelsChanged = false;
        if(state[\\zoomLevels].size != initialZoomLevels.size) {
            levelsChanged = true;
        } else {
            state[\\zoomLevels].do { |level, i|
                if(level.window != initialZoomLevels[i].window) {
                    levelsChanged = true;
                };
            };
        };
        
        if(levelsChanged) {
            \"✓ SUCCESS: Zoom levels updated correctly for new duration\".postln;
        } else {
            \"⚠ WARNING: Zoom levels may not have updated\".postln;
        };
    } else {
        \"ERROR: Zoom levels are nil after update\".postln;
    };
    
    \"\\nTesting duration change to 5s...\".postln;
    
    // Change duration to 5 seconds (shorter)
    state[\\playDuration] = 5;
    
    if(~nUPIC[\\ui][\\onDurationChange].notNil) {
        ~nUPIC[\\ui][\\onDurationChange].value;
    };
    
    \"After changing to 5s:\".postln;
    \"Duration: %\".format(state[\\playDuration]).postln;
    if(state[\\zoomLevels].notNil) {
        \"Zoom levels:\".postln;
        state[\\zoomLevels].do { |level, i|
            \"  %: %\".format(i, level.name).postln;
        };
    };
    
    \"\\nRestoring original duration...\".postln;
    
    // Restore original duration
    state[\\playDuration] = initialDuration;
    if(~nUPIC[\\ui][\\onDurationChange].notNil) {
        ~nUPIC[\\ui][\\onDurationChange].value;
    };
    
    \"Restored to: %\".format(state[\\playDuration]).postln;
    if(state[\\zoomLevels].notNil) {
        \"Final zoom levels:\".postln;
        state[\\zoomLevels].do { |level, i|
            \"  %: %\".format(i, level.name).postln;
        };
    };
    
    \"\\nTest completed. The zoom system should now dynamically update when you change the duration control in the UI.\".postln;
};
)
