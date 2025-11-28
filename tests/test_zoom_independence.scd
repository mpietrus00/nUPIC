// Test script to verify that zoom and duration are truly independent
// This tests the fix for the issue where changing total duration affected zoom level

(
"Testing zoom independence from duration changes...".postln;

// First, start the nUPIC system if it's not already running
if(~nUPIC.isNil) {
    "nUPIC system not found. Please run nUPIC_MAIN.scd first.".postln;
    thisFunction.halt;
};

// Check if the UI state is available
if(~nUPIC[\ui].isNil or: { ~nUPIC[\ui][\state].isNil }) {
    "nUPIC UI not initialized. Please run nUPIC_MAIN.scd first.".postln;
    thisFunction.halt;
};

var state = ~nUPIC[\ui][\state];

// Test function to log current zoom state
var logZoomState = {
    var spatialPos = state[\viewSpatialPos] ? "nil";
    var spatialWidth = state[\viewSpatialWidth] ? "nil";
    var duration = state[\playDuration] ? "nil";
    var zoomLevel = state[\currentZoomLevel] ? "nil";
    
    "Current state:".postln;
    ("  Spatial position: " ++ spatialPos).postln;
    ("  Spatial width: " ++ spatialWidth).postln;
    ("  Play duration: " ++ duration ++ " seconds").postln;
    ("  Zoom level: " ++ zoomLevel).postln;
    
    if(state[\viewStartTime].notNil and: { state[\viewEndTime].notNil }) {
        ("  Time view: " ++ state[\viewStartTime].round(0.1) ++ "s - " ++ state[\viewEndTime].round(0.1) ++ "s").postln;
    };
    "".postln;
};

// Initialize zoom system if not already done
if(state[\zoomLevels].isNil) {
    "Initializing zoom system...".postln;
    ~nUPIC[\ui][\initializeZoomSystem].value;
    1.wait;
};

"=== INITIAL STATE ===".postln;
logZoomState.value;

// Test 1: Zoom in to a detailed view
"Test 1: Zooming in to detailed view...".postln;
~nUPIC[\ui][\zoomIn].value;
1.wait;
logZoomState.value;

// Test 2: Change duration while zoomed in - this should NOT affect zoom
"Test 2: Changing duration from " ++ state[\playDuration] ++ "s to 30s (zoom should remain unchanged)...".postln;
var originalSpatialPos = state[\viewSpatialPos];
var originalSpatialWidth = state[\viewSpatialWidth];
var originalZoomLevel = state[\currentZoomLevel];

state[\playDuration] = 30;
~nUPIC[\ui][\updateZoomLevels].value;
~nUPIC[\ui][\updateZoomView].value;
1.wait;
logZoomState.value;

// Verify that spatial coordinates didn't change
if((state[\viewSpatialPos] - originalSpatialPos).abs < 0.001 and: {
    (state[\viewSpatialWidth] - originalSpatialWidth).abs < 0.001
} and: {
    state[\currentZoomLevel] == originalZoomLevel
}) {
    "✓ SUCCESS: Spatial zoom coordinates remained unchanged!".postln;
} {
    "✗ FAILURE: Spatial zoom coordinates changed when duration changed!".postln;
    ("  Expected spatial pos: " ++ originalSpatialPos ++ ", got: " ++ state[\viewSpatialPos]).postln;
    ("  Expected spatial width: " ++ originalSpatialWidth ++ ", got: " ++ state[\viewSpatialWidth]).postln;
    ("  Expected zoom level: " ++ originalZoomLevel ++ ", got: " ++ state[\currentZoomLevel]).postln;
};

// Test 3: Change duration again to a different value
"Test 3: Changing duration to 5s (zoom should still remain unchanged)...".postln;
state[\playDuration] = 5;
~nUPIC[\ui][\updateZoomLevels].value;
~nUPIC[\ui][\updateZoomView].value;
1.wait;
logZoomState.value;

// Verify again
if((state[\viewSpatialPos] - originalSpatialPos).abs < 0.001 and: {
    (state[\viewSpatialWidth] - originalSpatialWidth).abs < 0.001
} and: {
    state[\currentZoomLevel] == originalZoomLevel
}) {
    "✓ SUCCESS: Spatial zoom coordinates remained unchanged after second duration change!".postln;
} {
    "✗ FAILURE: Spatial zoom coordinates changed on second duration change!".postln;
};

// Test 4: Test that time coordinates update properly even though spatial doesn't
"Test 4: Verifying that time coordinates update correctly while spatial coordinates remain fixed...".postln;
var expectedStartTime = originalSpatialPos * state[\playDuration];
var expectedEndTime = (originalSpatialPos + originalSpatialWidth) * state[\playDuration];

if((state[\viewStartTime] - expectedStartTime).abs < 0.1 and: {
    (state[\viewEndTime] - expectedEndTime).abs < 0.1
}) {
    "✓ SUCCESS: Time coordinates updated correctly based on new duration!".postln;
} {
    "✗ FAILURE: Time coordinates not updated correctly!".postln;
    ("  Expected start time: " ++ expectedStartTime.round(0.1) ++ "s, got: " ++ state[\viewStartTime].round(0.1) ++ "s").postln;
    ("  Expected end time: " ++ expectedEndTime.round(0.1) ++ "s, got: " ++ state[\viewEndTime].round(0.1) ++ "s").postln;
};

// Test 5: Test coordinate conversion functions
"Test 5: Testing coordinate conversion functions...".postln;
var testScreenX = 300; // Middle of a 600px wide canvas
var spatialPos = ~nUPIC[\ui][\screenToSpatial].value(testScreenX, 600);
var timePos = ~nUPIC[\ui][\screenToTime].value(testScreenX, 600);
var expectedTimePos = spatialPos * state[\playDuration];

"Coordinate conversion test:".postln;
("  Screen X: " ++ testScreenX ++ "px").postln;
("  Spatial position: " ++ spatialPos.round(0.01)).postln;
("  Time position: " ++ timePos.round(0.01) ++ "s").postln;
("  Expected time position: " ++ expectedTimePos.round(0.01) ++ "s").postln;

if((timePos - expectedTimePos).abs < 0.01) {
    "✓ SUCCESS: Coordinate conversion functions work correctly!".postln;
} {
    "✗ FAILURE: Coordinate conversion functions are incorrect!".postln;
};

// Test 6: Reset zoom to full view
"Test 6: Resetting to full zoom view...".postln;
~nUPIC[\ui][\zoomOut].value;
~nUPIC[\ui][\zoomOut].value;
~nUPIC[\ui][\zoomOut].value;
~nUPIC[\ui][\zoomOut].value;
1.wait;
logZoomState.value;

// Verify we're at full view
if(state[\currentZoomLevel] == (state[\zoomLevels].size - 1) and: {
    (state[\viewSpatialWidth] - 1.0).abs < 0.001
}) {
    "✓ SUCCESS: Successfully returned to full zoom view!".postln;
} {
    "✗ FAILURE: Did not return to full zoom view correctly!".postln;
};

"=== TEST SUMMARY ===".postln;
"If all tests show SUCCESS, then zoom and duration are properly decoupled!".postln;
"The zoom system now uses spatial coordinates that are independent of playback duration.".postln;
"".postln;
)
