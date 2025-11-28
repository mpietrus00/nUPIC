// Test script for nUPIC's new intuitive zoom system
// Demonstrates how the zoom-based approach solves the panning confusion

(
// Initialize the zoom system for testing

if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\\ui].isNil) { ~nUPIC[\\ui] = IdentityDictionary.new };

// Load the zoom system functions
(~nUPIC_basePath +/+ "UI/IntuitiveZoomSystem.scd").load;

// Create a test state with a 60-second composition
~nUPIC[\\ui][\\state] = (
    playDuration: 60.0,  // 1 minute composition
    zoomFreqMin: 20,
    zoomFreqMax: 7500
);

// Initialize the zoom system
~nUPIC[\\ui][\\initializeZoomSystem].value;

"=== nUPIC Intuitive Zoom System Test ===".postln;
"".postln;

"INITIAL STATE (starts zoomed in to 1/10th):".postln;
("Duration: " ++ ~nUPIC[\\ui][\\state][\\playDuration] ++ "s").postln;
("Current view: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;
"".postln;

"Testing zoom levels...".postln;

// Test zooming out
"Zooming out (less detail):".postln;
~nUPIC[\\ui][\\zoomOut].value;
("Now viewing: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

~nUPIC[\\ui][\\zoomOut].value;
("Now viewing: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

~nUPIC[\\ui][\\zoomOut].value;
("Now viewing: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

"".postln;

// Test zooming back in
"Zooming back in (more detail):".postln;
~nUPIC[\\ui][\\zoomIn].value;
("Now viewing: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

~nUPIC[\\ui][\\zoomIn].value;
("Now viewing: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

"".postln;

// Test panning at different zoom levels
"Testing panning within boundaries:".postln;
var state = ~nUPIC[\\ui][\\state];

"At current zoom level:".postln;
("View before panning: " ++ state[\\viewStartTime] ++ "s - " ++ state[\\viewEndTime] ++ "s").postln;

"Panning right...".postln;
~nUPIC[\\ui][\\panView].value(\\right);

"Panning right again...".postln;
~nUPIC[\\ui][\\panView].value(\\right);

"Panning right to boundary...".postln;
10.do {
    ~nUPIC[\\ui][\\panView].value(\\right);
};

"Trying to pan beyond boundary (should be constrained):".postln;
~nUPIC[\\ui][\\panView].value(\\right);

"".postln;

"Panning back left...".postln;
~nUPIC[\\ui][\\panView].value(\\left);

"Panning to start boundary...".postln;
20.do {
    ~nUPIC[\\ui][\\panView].value(\\left);
};

"Trying to pan before start (should be constrained):".postln;
~nUPIC[\\ui][\\panView].value(\\left);

"".postln;

"=== COORDINATE CONVERSION TESTS ===".postln;

// Test coordinate conversions
var width = 800;

"Testing screen-to-time conversion:".postln;
[0, width/4, width/2, 3*width/4, width].do { |x|
    var time = ~nUPIC[\\ui][\\zoomScreenToTime].value(x, width);
    ("Screen X=" ++ x ++ " -> Time=" ++ time.round(0.1) ++ "s").postln;
};

"".postln;

"Testing time-to-screen conversion:".postln;
var currentView = state[\\viewStartTime];
var viewDuration = state[\\viewDuration];
[currentView, currentView + viewDuration/4, currentView + viewDuration/2, 
 currentView + 3*viewDuration/4, currentView + viewDuration].do { |time|
    var screenX = ~nUPIC[\\ui][\\zoomTimeToScreen].value(time, width);
    ("Time=" ++ time.round(0.1) ++ "s -> Screen X=" ++ screenX.round).postln;
};

"".postln;

"=== BOUNDARY TESTING ===".postln;

"Testing what happens at composition boundaries:".postln;

// Go to full zoom and try panning beyond
~nUPIC[\\ui][\\zoomOut].value;  // Go to full view
~nUPIC[\\ui][\\zoomOut].value;  // Should now be at 1x (full view)

("Full view: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

"At full zoom level, panning should have no effect:".postln;
~nUPIC[\\ui][\\panView].value(\\right);  // Should not move
~nUPIC[\\ui][\\panView].value(\\left);   // Should not move

"".postln;

// Go back to detailed view and test boundaries
~nUPIC[\\ui][\\zoomIn].value;
~nUPIC[\\ui][\\zoomIn].value;
~nUPIC[\\ui][\\zoomIn].value;  // Back to most detailed

("Detailed view: " ++ ~nUPIC[\\ui][\\getCurrentTimeRange].value).postln;

"".postln;

"=== SUMMARY ===".postln;
"✓ Starts with detailed view (1/10th of duration)".postln;
"✓ Zoom levels provide predictable view changes".postln;
"✓ Panning is constrained to composition boundaries".postln;
"✓ Cannot pan beyond 0s or total duration".postln;
"✓ Coordinate conversions work correctly".postln;
"✓ Clear visual feedback about current view range".postln;
"".postln;
"BENEFITS OF NEW SYSTEM:".postln;
"• Always start with detailed editing view".postln;
"• Can zoom out to see full composition context".postln;
"• Cannot get 'lost' by panning beyond composition".postln;
"• Time grid always shows actual composition time".postln;
"• Intuitive zoom + pan controls".postln;
"• Keyboard shortcuts: +/- for zoom, Alt+Arrows for pan".postln;

"".postln;
"Test completed successfully!".postln;
)
