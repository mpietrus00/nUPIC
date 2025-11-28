// Test script to verify horizontal zoom is working correctly
// Run this after loading the nUPIC system and drawing a trajectory

(
"Testing horizontal zoom functionality...".postln;

if(~nUPIC.isNil or: { ~nUPIC[\ui].isNil } or: { ~nUPIC[\ui][\state].isNil }) {
    "ERROR: nUPIC system not loaded. Please run nUPIC_MAIN.scd first.".postln;
} {
    var state = ~nUPIC[\ui][\state];
    
    "Initial zoom state:".postln;
    "  Play duration: %s".format(state[\playDuration]).postln;
    "  Current zoom level: %".format(state[\currentZoomLevel]).postln;
    "  View start time: %s".format(state[\viewStartTime]).postln;
    "  View duration: %s".format(state[\viewDuration]).postln;
    "  View end time: %s".format(state[\viewEndTime]).postln;
    
    if(state[\zoomLevels].notNil) {
        "Available zoom levels:".postln;
        state[\zoomLevels].do { |level, i|
            "  %: %".format(i, level.name).postln;
        };
    };
    
    "\nTesting zoom in...".postln;
    
    // Test zoom in
    if(~nUPIC[\ui][\zoomIn].notNil) {
        ~nUPIC[\ui][\zoomIn].value;
        
        "After zoom in:".postln;
        "  Current zoom level: %".format(state[\currentZoomLevel]).postln;
        "  View start time: %s".format(state[\viewStartTime]).postln;
        "  View duration: %s".format(state[\viewDuration]).postln;
        "  View end time: %s".format(state[\viewEndTime]).postln;
        
        if(state[\zoomLevels].notNil and: { state[\currentZoomLevel].notNil }) {
            var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
            if(currentLevel.notNil) {
                "  Current level: %".format(currentLevel.name).postln;
            };
        };
        
        "".postln;
        "Testing zoom out...".postln;
        
        // Test zoom out
        ~nUPIC[\ui][\zoomOut].value;
        
        "After zoom out:".postln;
        "  Current zoom level: %".format(state[\currentZoomLevel]).postln;
        "  View start time: %s".format(state[\viewStartTime]).postln;
        "  View duration: %s".format(state[\viewDuration]).postln;
        "  View end time: %s".format(state[\viewEndTime]).postln;
        
        if(state[\zoomLevels].notNil and: { state[\currentZoomLevel].notNil }) {
            var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
            if(currentLevel.notNil) {
                "  Current level: %".format(currentLevel.name).postln;
            };
        };
    } {
        "ERROR: Zoom functions not available".postln;
    };
    
    "\nTesting pan functions...".postln;
    
    // Test pan right
    if(~nUPIC[\ui][\panView].notNil) {
        "Panning right...".postln;
        ~nUPIC[\ui][\panView].value(\right);
        
        "After pan right:".postln;
        "  View start time: %s".format(state[\viewStartTime]).postln;
        "  View end time: %s".format(state[\viewEndTime]).postln;
        
        "Panning left...".postln;
        ~nUPIC[\ui][\panView].value(\left);
        
        "After pan left:".postln;
        "  View start time: %s".format(state[\viewStartTime]).postln;
        "  View end time: %s".format(state[\viewEndTime]).postln;
    } {
        "ERROR: Pan functions not available".postln;
    };
    
    "\nChecking if display refresh is working...".postln;
    if(~nUPIC[\ui][\refreshDisplay].notNil) {
        ~nUPIC[\ui][\refreshDisplay].value;
        "Display refresh called successfully".postln;
    } {
        "ERROR: Display refresh function not available".postln;
    };
    
    "\nTest complete. If horizontal zoom is working correctly, you should see:".postln;
    "1. Zoom levels changing when you press + and - buttons".postln;
    "2. View start/end times changing".postln;
    "3. Trajectories appearing/disappearing or changing position when zoomed".postln;
    "4. Red playback cursor moving correctly within the zoomed view".postln;
    
    "\nTry drawing a trajectory across the full canvas, then use the zoom controls to see if it works!".postln;
};
)
