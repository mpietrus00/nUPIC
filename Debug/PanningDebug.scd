// Panning Debug Script for nUPIC
// This script helps debug and verify the panning functionality
// Part of the nUPIC (nu-UPIC) modular system

(
"=== nUPIC Panning Debug Tools ===".postln;

// Debug function to check current state
~nUPIC[\debug] = IdentityDictionary.new;

~nUPIC[\debug][\checkPanningState] = {
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    
    if(state.isNil) {
        "ERROR: nUPIC UI state not initialized".postln;
        ^nil;
    };
    
    var width = constants[\defaultWidth] ? 1200;
    var height = constants[\defaultHeight] ? 800;
    
    "=== Current Panning State ===".postln;
    ("Virtual Canvas Size: " ++ state[\virtualCanvasWidth] ++ " x " ++ state[\virtualCanvasHeight]).postln;
    ("Viewport Size: " ++ width ++ " x " ++ height).postln;
    ("Current Viewport Position: (" ++ state[\viewportX] ++ ", " ++ state[\viewportY] ++ ")").postln;
    ("Max Viewport X: " ++ (state[\virtualCanvasWidth] - width)).postln;
    ("Max Viewport Y: " ++ (state[\virtualCanvasHeight] - height)).postln;
    
    if(state[\drawView].notNil) {
        "Draw view is active".postln;
    } {
        "WARNING: No draw view found".postln;
    };
    
    "".postln;
};

// Function to manually test panning
~nUPIC[\debug][\testPanning] = { |direction = \right, step = 50|
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    
    if(state.isNil) {
        "ERROR: nUPIC UI state not initialized".postln;
        ^nil;
    };
    
    var width = constants[\defaultWidth] ? 1200;
    var height = constants[\defaultHeight] ? 800;
    var oldX = state[\viewportX];
    var oldY = state[\viewportY];
    
    ("Testing pan " ++ direction ++ " with step " ++ step).postln;
    ("Before: viewport at (" ++ oldX ++ ", " ++ oldY ++ ")").postln;
    
    case 
    { direction == \up } {
        state[\viewportY] = (state[\viewportY] - step).clip(0, state[\virtualCanvasHeight] - height);
    }
    { direction == \down } {
        state[\viewportY] = (state[\viewportY] + step).clip(0, state[\virtualCanvasHeight] - height);
    }
    { direction == \left } {
        state[\viewportX] = (state[\viewportX] - step).clip(0, state[\virtualCanvasWidth] - width);
    }
    { direction == \right } {
        state[\viewportX] = (state[\viewportX] + step).clip(0, state[\virtualCanvasWidth] - width);
    }
    { 
        "Invalid direction. Use \\up, \\down, \\left, or \\right".postln;
        ^nil;
    };
    
    ("After: viewport at (" ++ state[\viewportX] ++ ", " ++ state[\viewportY] ++ ")").postln;
    
    // Refresh the display
    if(state[\drawView].notNil) {
        { state[\drawView].refresh }.defer;
        "Display refreshed".postln;
    } {
        "WARNING: Could not refresh display - no draw view".postln;
    };
    
    // Check if anything actually changed
    if((oldX == state[\viewportX]) and: { oldY == state[\viewportY] }) {
        "WARNING: Viewport position did not change - may be at boundary".postln;
    } {
        "SUCCESS: Viewport position changed".postln;
    };
    
    "".postln;
};

// Function to test keyboard modifier detection
~nUPIC[\debug][\testKeyboardMods] = {
    var testWindow, testView;
    
    "Creating keyboard test window...".postln;
    "Press keys with different modifiers to test detection".postln;
    "Press ESC to close the test window".postln;
    
    testWindow = Window("Keyboard Modifier Test", Rect(400, 400, 300, 200));
    testView = StaticText(testWindow, Rect(10, 10, 280, 180));
    testView.string = "Press keys to test modifier detection\n\nPress ESC to close";
    testView.align = \center;
    
    testWindow.view.keyDownAction = { |view, char, mod, unicode, keycode|
        var modStr = "";
        
        if(mod.isAlt) { modStr = modStr ++ "Alt " };
        if(mod.isShift) { modStr = modStr ++ "Shift " };
        if(mod.isCmd) { modStr = modStr ++ "Cmd " };
        if(mod.isCtrl) { modStr = modStr ++ "Ctrl " };
        
        if(modStr == "") { modStr = "No modifiers" };
        
        ("Key pressed: " ++ char ++ " (keycode: " ++ keycode ++ ") with " ++ modStr).postln;
        
        // Test specific arrow keys
        case
        { keycode == 126 } { ("Up arrow detected with: " ++ modStr).postln; }
        { keycode == 125 } { ("Down arrow detected with: " ++ modStr).postln; }
        { keycode == 123 } { ("Left arrow detected with: " ++ modStr).postln; }
        { keycode == 124 } { ("Right arrow detected with: " ++ modStr).postln; };
        
        // Close on ESC
        if(keycode == 53) {
            testWindow.close;
            "Keyboard test window closed".postln;
        };
        
        testView.string = "Last key: " ++ char ++ " (" ++ keycode ++ ")\nModifiers: " ++ modStr ++ "\n\nPress ESC to close";
    };
    
    testWindow.front;
    testWindow.focus;
};

// Function to reset viewport to origin
~nUPIC[\debug][\resetViewport] = {
    var state = ~nUPIC[\ui][\state];
    
    if(state.isNil) {
        "ERROR: nUPIC UI state not initialized".postln;
        ^nil;
    };
    
    ("Resetting viewport from (" ++ state[\viewportX] ++ ", " ++ state[\viewportY] ++ ") to (0, 0)").postln;
    
    state[\viewportX] = 0;
    state[\viewportY] = 0;
    
    if(state[\drawView].notNil) {
        { state[\drawView].refresh }.defer;
        "Viewport reset and display refreshed".postln;
    } {
        "Viewport reset but could not refresh display".postln;
    };
};

// Function to check if Drawing.scd handles viewport offsets
~nUPIC[\debug][\checkDrawingIntegration] = {
    var drawingFunction = ~nUPIC[\ui][\initializeDrawing];
    
    "=== Checking Drawing System Integration ===".postln;
    
    if(drawingFunction.isNil) {
        "ERROR: Drawing system not loaded".postln;
        ^nil;
    };
    
    "Drawing system is loaded".postln;
    
    // We need to check if the drawing code uses viewport offsets
    "The drawing code should use state[\\viewportX] and state[\\viewportY] when rendering".postln;
    "Check Drawing.scd to ensure it translates coordinates based on viewport position".postln;
    "".postln;
};

// Function to stress test panning
~nUPIC[\debug][\stressPanning] = {
    var state = ~nUPIC[\ui][\state];
    
    if(state.isNil) {
        "ERROR: nUPIC UI state not initialized".postln;
        ^nil;
    };
    
    "Starting panning stress test...".postln;
    
    Task {
        var directions = [\right, \down, \left, \up];
        var steps = [10, 20, 50, 100];
        
        10.do { |i|
            var dir = directions.choose;
            var step = steps.choose;
            
            ("Test " ++ (i + 1) ++ ": Panning " ++ dir ++ " by " ++ step).postln;
            ~nUPIC[\debug][\testPanning].value(dir, step);
            
            0.5.wait; // Wait half second between tests
        };
        
        "Panning stress test complete".postln;
        ~nUPIC[\debug][\checkPanningState].value;
    }.play;
};

"Debug functions loaded:".postln;
"~nUPIC[\\debug][\\checkPanningState].value      - Check current panning state".postln;
"~nUPIC[\\debug][\\testPanning].value(\\right, 50) - Test manual panning".postln;
"~nUPIC[\\debug][\\testKeyboardMods].value       - Test keyboard modifier detection".postln;
"~nUPIC[\\debug][\\resetViewport].value          - Reset viewport to (0,0)".postln;
"~nUPIC[\\debug][\\checkDrawingIntegration].value - Check if drawing handles viewport".postln;
"~nUPIC[\\debug][\\stressPanning].value          - Automated panning stress test".postln;
"".postln;
"To start debugging:".postln;
"1. Run: ~nUPIC[\\debug][\\checkPanningState].value".postln;
"2. Test manual panning: ~nUPIC[\\debug][\\testPanning].value(\\right, 100)".postln;
"3. Test keyboard: ~nUPIC[\\debug][\\testKeyboardMods].value".postln;
)
