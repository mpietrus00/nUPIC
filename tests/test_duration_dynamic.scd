// Test Dynamic Duration Changes
// This tests if duration changes during playback affect the speed

(
// Simple test function to change duration during playback
~testDurationChange = {
    var state = ~nUPIC[\ui][\state];
    
    if(state.isNil) {
        "ERROR: nUPIC not initialized".postln;
    } {
        // Start at 10 seconds
        state[\playDuration] = 10.0;
        if(state[\controls][\durationNumberBox].notNil) {
            state[\controls][\durationNumberBox].value = 10.0;
        };
        ("Set to 10 seconds: " ++ state[\playDuration]).postln;
        
        // Schedule duration change during playback
        fork {
            3.wait;  // Wait 3 seconds
            if(state[\isPlaying]) {
                state[\playDuration] = 30.0;  // Much slower
                if(state[\controls][\durationNumberBox].notNil) {
                    { state[\controls][\durationNumberBox].value = 30.0 }.defer;
                };
                ("CHANGED to 30 seconds during playback: " ++ state[\playDuration]).postln;
            };
        };
    };
};

// Instructions
"Instructions:".postln;
"1. Make sure you have some trajectories drawn".postln;
"2. Execute ~testDurationChange.value".postln;
"3. Then start playback - it should start at 10s duration".postln;
"4. After 3 seconds, it will change to 30s duration".postln;
"5. Watch the console for debug messages".postln;
)
