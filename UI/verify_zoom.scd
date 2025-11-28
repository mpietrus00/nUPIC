// Verify zoom system works in isolation
(
~nUPIC = IdentityDictionary.new;
~nUPIC[\ui] = IdentityDictionary.new;
~nUPIC[\ui][\state] = (
    playDuration: 10,
    showGrid: true
);

"Loading IntuitiveZoomSystem...".postln;
"/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/UI/IntuitiveZoomSystem.scd".load;

// Test initialization
"Testing zoom initialization...".postln;
~nUPIC[\ui][\initializeZoomSystem].value;

// Check results
"Results:".postln;
"  playDuration: %".format(~nUPIC[\ui][\state][\playDuration]).postln;
"  viewStartTime: %".format(~nUPIC[\ui][\state][\viewStartTime]).postln;  
"  viewDuration: %".format(~nUPIC[\ui][\state][\viewDuration]).postln;
"  viewEndTime: %".format(~nUPIC[\ui][\state][\viewEndTime]).postln;

if(~nUPIC[\ui][\state][\viewDuration] == 1.0) {
    "✓ SUCCESS: Zoom system working! Showing 1 second of 10 second duration.".postln;
} {
    "✗ PROBLEM: Expected viewDuration=1.0, got %".format(~nUPIC[\ui][\state][\viewDuration]).postln;
};

"Test zoom functions...".postln;
~nUPIC[\ui][\zoomOut].value;  // Should go to 0.2 fraction (2 seconds)
if(~nUPIC[\ui][\state][\viewDuration] == 2.0) {
    "✓ SUCCESS: Zoom out working!".postln;
} {
    "✗ PROBLEM: Expected viewDuration=2.0 after zoom out, got %".format(~nUPIC[\ui][\state][\viewDuration]).postln;
};

~nUPIC[\ui][\zoomIn].value;   // Should go back to 0.1 fraction (1 second)
if(~nUPIC[\ui][\state][\viewDuration] == 1.0) {
    "✓ SUCCESS: Zoom in working!".postln;
} {
    "✗ PROBLEM: Expected viewDuration=1.0 after zoom in, got %".format(~nUPIC[\ui][\state][\viewDuration]).postln;
};

"All tests completed.".postln;
)
