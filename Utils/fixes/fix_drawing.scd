// Quick fix for nUPIC drawing issues
// Run this after the GUI is open if drawing doesn't work

(
"=== nUPIC Drawing Fix ===".postln;

// 1. Ensure all data structures are initialized
{
    if(~nUPIC[\data][\trajectories].isNil) {
        ~nUPIC[\data][\trajectories] = List.new;
        "✓ Initialized trajectories list".postln;
    };
    
    if(~nUPIC[\data][\amplitudeEnvelopes].isNil) {
        ~nUPIC[\data][\amplitudeEnvelopes] = List.new;
        "✓ Initialized amplitude envelopes list".postln;
    };
    
    if(~nUPIC[\data][\trajectorySynthDefs].isNil) {
        ~nUPIC[\data][\trajectorySynthDefs] = List.new;
        "✓ Initialized synthDefs list".postln;
    };
    
    if(~nUPIC[\data][\selectedTrajectories].isNil) {
        ~nUPIC[\data][\selectedTrajectories] = Set.new;
        "✓ Initialized selected trajectories set".postln;
    };
}.value;

// 2. Reset UI state to drawing mode
{
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        state[\eraseMode] = false;
        state[\selectMode] = false;
        state[\isPlaying] = false;
        state[\isDrawing] = false;
        state[\currentTrajectory] = nil;
        "✓ UI state reset to drawing mode".postln;
    } {
        "✗ UI state not found".postln;
    };
}.value;

// 3. Test mouse handlers
{
    if(~nUPIC[\ui][\handleMouseDown].notNil) {
        "✓ Mouse handlers are loaded".postln;
    } {
        "✗ Mouse handlers not found - reloading...".postln;
        "UI/MouseHandlers.scd".load;
    };
}.value;

// 4. Test drawing by adding a test trajectory
{
    var testTraj = List[
        (x: 100, y: 400, freq: 440),
        (x: 300, y: 300, freq: 660), 
        (x: 500, y: 200, freq: 880)
    ];
    
    ~nUPIC[\data][\trajectories].add(testTraj);
    ~nUPIC[\data][\amplitudeEnvelopes].add(nil);
    ~nUPIC[\data][\trajectorySynthDefs].add(\simpleGravObject);
    
    "✓ Test trajectory added".postln;
    
    // Refresh display
    if(~nUPIC[\ui][\refreshDisplay].notNil) {
        ~nUPIC[\ui][\refreshDisplay].value;
        "✓ Display refreshed".postln;
    };
}.value;

// 5. Show current system status
{
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    
    "".postln;
    "=== System Status ===".postln;
    ("Drawing mode: " ++ (state[\eraseMode].not and: { state[\selectMode].not })).postln;
    ("Total trajectories: " ++ data[\trajectories].size).postln;
    ("UI state exists: " ++ state.notNil).postln;
    ("Draw view exists: " ++ state[\drawView].notNil).postln;
    ("Mouse handlers loaded: " ++ ~nUPIC[\ui][\handleMouseDown].notNil).postln;
}.value;

"".postln;
"=== Instructions ===".postln;
"Now try drawing on the canvas by clicking and dragging.".postln;
"You should see debug messages in the console when you draw.".postln;
"If drawing still doesn't work, the issue may be with the mouse event connection.".postln;
)

// Additional manual tests you can run:
/*

// Test mouse handler manually:
~nUPIC[\ui][\handleMouseDown].value(200, 300, (), 1200, 800);
~nUPIC[\ui][\state][\isDrawing].postln;  // Should be true

// Test mouse move:
~nUPIC[\ui][\handleMouseMove].value(250, 250, 1200, 800);
~nUPIC[\ui][\state][\currentTrajectory].size.postln;  // Should be 2

// Test mouse up:
~nUPIC[\ui][\handleMouseUp].value(300, 200, 1200, 800);
~nUPIC[\data][\trajectories].size.postln;  // Should be 2 (1 test + 1 drawn)

// Force drawing mode:
~nUPIC[\ui][\state][\eraseMode] = false;
~nUPIC[\ui][\state][\selectMode] = false;

*/
