// Test zoom and pan system availability
(
// Load the nUPIC system first
if(~nUPIC.isNil) {
    "Loading nUPIC system first...".postln;
    load("../nUPIC_Main.scd");
    2.wait; // Give it time to load
};

// Test if zoom system functions are available
if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil }) {
    "nUPIC UI namespace exists".postln;
    "Available UI functions:".postln;
    ~nUPIC[\ui].keys.asArray.do { |key| 
        ("- " ++ key).postln;
    };
    
    "".postln;
    "Testing key zoom/pan functions:".postln;
    "- initializeZoomSystem: %".format(~nUPIC[\ui][\initializeZoomSystem].notNil).postln;
    "- panView: %".format(~nUPIC[\ui][\panView].notNil).postln;
    "- zoomIn: %".format(~nUPIC[\ui][\zoomIn].notNil).postln;
    "- zoomOut: %".format(~nUPIC[\ui][\zoomOut].notNil).postln;
    "- updateZoomView: %".format(~nUPIC[\ui][\updateZoomView].notNil).postln;
    "- getCurrentTimeRange: %".format(~nUPIC[\ui][\getCurrentTimeRange].notNil).postln;
    
    // Test if state exists and has zoom info
    if(~nUPIC[\ui][\state].notNil) {
        var state = ~nUPIC[\ui][\state];
        "".postln;
        "State analysis:".postln;
        "- playDuration: %".format(state[\playDuration]).postln;
        "- zoomLevels: %".format(state[\zoomLevels].notNil).postln;
        "- currentZoomLevel: %".format(state[\currentZoomLevel]).postln;
        "- viewStartTime: %".format(state[\viewStartTime]).postln;
        "- viewDuration: %".format(state[\viewDuration]).postln;
        
        if(state[\zoomLevels].notNil) {
            "- Zoom levels count: %".format(state[\zoomLevels].size).postln;
        };
    } {
        "State not initialized".postln;
    };
} {
    "nUPIC namespace not properly initialized".postln;
};
)
