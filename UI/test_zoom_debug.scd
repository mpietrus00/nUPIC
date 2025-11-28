// Debug script to test zoom system syntax
(
// Load the zoom system first
"Loading IntuitiveZoomSystem...".postln;
"/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/UI/IntuitiveZoomSystem.scd".load;

// Initialize state if needed
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

if(~nUPIC[\ui][\state].isNil) {
    ~nUPIC[\ui][\state] = (
        playDuration: 10,
        showGrid: true
    );
    "Created basic state".postln;
};

// Test zoom system initialization
"Testing zoom system initialization...".postln;
if(~nUPIC[\ui][\initializeZoomSystem].notNil) {
    ~nUPIC[\ui][\initializeZoomSystem].value;
    "Zoom system initialized successfully".postln;
} {
    "ERROR: Zoom system initialization function not found".postln;
};

// Check if zoom system was initialized
"Zoom system state:".postln;
"  zoomLevels: %".format(~nUPIC[\ui][\state][\zoomLevels]).postln;
"  currentZoomLevel: %".format(~nUPIC[\ui][\state][\currentZoomLevel]).postln;
"  viewStartTime: %".format(~nUPIC[\ui][\state][\viewStartTime]).postln;
"  viewDuration: %".format(~nUPIC[\ui][\state][\viewDuration]).postln;
"  viewEndTime: %".format(~nUPIC[\ui][\state][\viewEndTime]).postln;

"Zoom system test completed. Exiting...".postln;
0.exit;  // Exit SuperCollider
)
