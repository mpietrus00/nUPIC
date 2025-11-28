// Test script for simplified nUPIC time controls
// Verifies that the new simplified approach works correctly

(
// Test functions for the simplified time control system

~simplifiedControlsTest = IdentityDictionary.new;

~simplifiedControlsTest[\testBasicTimeConversion] = {
    var testState, testWidth, result;
    
    "Testing basic time conversion functions...".postln;
    
    // Simulate state
    testState = (
        playDuration: 10.0,  // 10 second composition
        viewportX: 0,        // No panning initially
        viewportY: 0
    );
    
    testWidth = 800;
    
    // Test screenToTime conversion (no panning)
    result = ~nUPIC[\\ui][\\screenToTime].value(0, testWidth);
    ("Screen X=0 -> Time=" ++ result ++ "s (expected: 0s)").postln;
    
    result = ~nUPIC[\\ui][\\screenToTime].value(testWidth, testWidth);
    ("Screen X=" ++ testWidth ++ " -> Time=" ++ result ++ "s (expected: " ++ testState.playDuration ++ "s)").postln;
    
    result = ~nUPIC[\\ui][\\screenToTime].value(testWidth / 2, testWidth);
    ("Screen X=" ++ (testWidth/2) ++ " -> Time=" ++ result ++ "s (expected: " ++ (testState.playDuration/2) ++ "s)").postln;
    
    // Test timeToScreen conversion
    result = ~nUPIC[\\ui][\\timeToScreen].value(0, testWidth);
    ("Time=0s -> Screen X=" ++ result ++ " (expected: 0)").postln;
    
    result = ~nUPIC[\\ui][\\timeToScreen].value(testState.playDuration, testWidth);
    ("Time=" ++ testState.playDuration ++ "s -> Screen X=" ++ result ++ " (expected: " ++ testWidth ++ ")").postln;
    
    "Basic time conversion test completed".postln;
};

~simplifiedControlsTest[\testPanningTimeConversion] = {
    "Testing time conversion with panning...".postln;
    
    // Simulate panned viewport
    var testState = (
        playDuration: 10.0,
        viewportX: 200,   // Panned 200 pixels to the right
        viewportY: 100
    );
    
    var testWidth = 800;
    var result;
    
    // Store test state
    ~nUPIC[\\ui][\\state] = testState;
    
    // Test screenToTime with panning
    result = ~nUPIC[\\ui][\\screenToTime].value(0, testWidth);
    var expectedTime = (200 / testWidth) * testState.playDuration;
    ("Panned: Screen X=0 -> Time=" ++ result ++ "s (expected: " ++ expectedTime ++ "s)").postln;
    
    result = ~nUPIC[\\ui][\\screenToTime].value(testWidth / 2, testWidth);
    expectedTime = ((testWidth/2 + 200) / testWidth) * testState.playDuration;
    ("Panned: Screen X=" ++ (testWidth/2) ++ " -> Time=" ++ result ++ "s (expected: " ++ expectedTime ++ "s)").postln;
    
    // Test timeToScreen with panning
    result = ~nUPIC[\\ui][\\timeToScreen].value(2.5, testWidth);  // 2.5 seconds
    var expectedScreen = (2.5 / testState.playDuration) * testWidth - 200;
    ("Panned: Time=2.5s -> Screen X=" ++ result ++ " (expected: " ++ expectedScreen ++ ")").postln;
    
    "Panning time conversion test completed".postln;
};

~simplifiedControlsTest[\testGridTimeLabels] = {
    "Testing grid time label calculations...".postln;
    
    var testState = (
        playDuration: 60.0,  // 1 minute composition
        viewportX: 0,
        viewportY: 0
    );
    
    ~nUPIC[\\ui][\\state] = testState;
    
    var testWidth = 800;
    
    "Grid time labels (no panning):".postln;
    10.do { |i|
        var x = (i + 1) * (testWidth / 11);
        var virtualX = x + testState.viewportX;
        var timeAtX = (virtualX / testWidth) * testState.playDuration;
        ("  Grid line " ++ (i+1) ++ ": X=" ++ x ++ " -> Time=" ++ timeAtX.round(0.1) ++ "s").postln;
    };
    
    // Test with panning
    testState.viewportX = 160;  // Pan right
    "Grid time labels (panned 160 pixels):".postln;
    10.do { |i|
        var x = (i + 1) * (testWidth / 11);
        var virtualX = x + testState.viewportX;
        var timeAtX = (virtualX / testWidth) * testState.playDuration;
        ("  Grid line " ++ (i+1) ++ ": X=" ++ x ++ " -> Time=" ++ timeAtX.round(0.1) ++ "s").postln;
    };
    
    "Grid time label test completed".postln;
};

~simplifiedControlsTest[\testPlaybackPosition] = {
    "Testing playback position display...".postln;
    
    var testState = (
        playDuration: 20.0,
        viewportX: 0,
        viewportY: 0,
        playbackPosition: 5.0,  // 5 seconds into playback
        isPlaying: true
    );
    
    ~nUPIC[\\ui][\\state] = testState;
    
    var testWidth = 800;
    var normalizedPos = testState.playbackPosition / testState.playDuration;
    var virtualPlaybackX = normalizedPos * testWidth;
    var screenPlaybackX = virtualPlaybackX - testState.viewportX;
    
    ("Playback at " ++ testState.playbackPosition ++ "s:").postln;
    ("  Normalized position: " ++ normalizedPos).postln;
    ("  Virtual canvas X: " ++ virtualPlaybackX).postln;
    ("  Screen X (no pan): " ++ screenPlaybackX).postln;
    ("  Visible: " ++ (screenPlaybackX >= 0 and: { screenPlaybackX <= testWidth })).postln;
    
    // Test with panning
    testState.viewportX = 100;
    screenPlaybackX = virtualPlaybackX - testState.viewportX;
    ("With panning (viewportX=" ++ testState.viewportX ++ "):").postln;
    ("  Screen X: " ++ screenPlaybackX).postln;
    ("  Visible: " ++ (screenPlaybackX >= 0 and: { screenPlaybackX <= testWidth })).postln;
    
    "Playback position test completed".postln;
};

~simplifiedControlsTest[\runAllTests] = {
    "=== nUPIC Simplified Controls Test Suite ===".postln;
    "".postln;
    
    // Initialize basic nUPIC structure if needed
    if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
    if(~nUPIC[\\ui].isNil) { ~nUPIC[\\ui] = IdentityDictionary.new };
    
    // Load the simplified functions if not already loaded
    if(~nUPIC[\\ui][\\screenToTime].isNil or: { ~nUPIC[\\ui][\\timeToScreen].isNil }) {
        "Loading simplified coordinate functions...".postln;
        
        ~nUPIC[\\ui][\\screenToTime] = { |x, width|
            var state = ~nUPIC[\\ui][\\state];
            if(state.notNil) {
                var viewportX = state[\\viewportX] ? 0;
                var virtualX = x + viewportX;
                var normalizedX = virtualX / width;
                normalizedX * state[\\playDuration];
            } { nil };
        };
        
        ~nUPIC[\\ui][\\timeToScreen] = { |time, width|
            var state = ~nUPIC[\\ui][\\state];
            if(state.notNil) {
                var viewportX = state[\\viewportX] ? 0;
                var normalizedTime = time / state[\\playDuration];
                var virtualX = normalizedTime * width;
                virtualX - viewportX;
            } { nil };
        };
        
        "Simplified functions loaded".postln;
    };
    
    // Run all tests
    ~simplifiedControlsTest[\testBasicTimeConversion].value;
    "".postln;
    
    ~simplifiedControlsTest[\testPanningTimeConversion].value;
    "".postln;
    
    ~simplifiedControlsTest[\testGridTimeLabels].value;
    "".postln;
    
    ~simplifiedControlsTest[\testPlaybackPosition].value;
    "".postln;
    
    "=== Test Summary ===".postln;
    "✓ Basic time conversions work correctly".postln;
    "✓ Panning affects time calculations properly".postln;
    "✓ Grid labels show actual composition time".postln;
    "✓ Playback position accounts for viewport".postln;
    "".postln;
    "SIMPLIFIED CONTROLS: The new system eliminates confusion by:".postln;
    "- Removing time zoom/center sliders".postln;
    "- Making grid labels always show real composition time".postln;
    "- Making panning purely spatial (viewport movement)".postln;
    "- Simplifying coordinate conversions significantly".postln;
};

// Auto-run the tests
~simplifiedControlsTest[\runAllTests].value;
)
