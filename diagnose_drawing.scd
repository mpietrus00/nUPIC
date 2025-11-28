// Comprehensive diagnostic for nUPIC drawing issues
// Run this to find exactly what's wrong

(
"=== nUPIC Drawing Diagnosis ===".postln;
"".postln;

// Check if system is loaded
if(~nUPIC.isNil) {
    "❌ CRITICAL: nUPIC not loaded at all!".postln;
    "Solution: Run \"nUPIC_Main.scd\".load; first".postln;
} {
    "✅ nUPIC system is loaded".postln;
    
    // Check data manager
    if(~nUPIC[\data].isNil) {
        "❌ CRITICAL: Data manager missing!".postln;
    } {
        "✅ Data manager exists".postln;
        ("   Trajectories: " ++ (~nUPIC[\data][\trajectories].size ? "nil")).postln;
    };
    
    // Check UI state
    if(~nUPIC[\ui].isNil) {
        "❌ CRITICAL: UI system missing!".postln;
    } {
        "✅ UI system exists".postln;
        
        if(~nUPIC[\ui][\state].isNil) {
            "❌ CRITICAL: UI state missing!".postln;
        } {
            "✅ UI state exists".postln;
            {
                var state = ~nUPIC[\ui][\state];
                ("   Window exists: " ++ state[\window].notNil).postln;
                ("   DrawView exists: " ++ state[\drawView].notNil).postln;
                ("   Erase mode: " ++ state[\eraseMode]).postln;
                ("   Select mode: " ++ state[\selectMode]).postln;
                ("   Is playing: " ++ state[\isPlaying]).postln;
                ("   Is drawing: " ++ state[\isDrawing]).postln;
                
                if(state[\drawView].notNil) {
                    ("   DrawView bounds: " ++ state[\drawView].bounds).postln;
                    ("   DrawView background: " ++ state[\drawView].background).postln;
                    
                    // Check if mouse handlers are connected
                    {
                        var view = state[\drawView];
                        ("   mouseDownAction: " ++ view.mouseDownAction.notNil).postln;
                        ("   mouseMoveAction: " ++ view.mouseMoveAction.notNil).postln;
                        ("   mouseUpAction: " ++ view.mouseUpAction.notNil).postln;
                        
                        if(view.mouseDownAction.isNil) {
                            "❌ CRITICAL: mouseDownAction not connected!".postln;
                            "This is likely the main problem!".postln;
                        };
                    }.value;
                };
            }.value;
        };
        
        // Check mouse handlers
        ("   handleMouseDown exists: " ++ ~nUPIC[\ui][\handleMouseDown].notNil).postln;
        ("   handleMouseMove exists: " ++ ~nUPIC[\ui][\handleMouseMove].notNil).postln;
        ("   handleMouseUp exists: " ++ ~nUPIC[\ui][\handleMouseUp].notNil).postln;
        ("   refreshDisplay exists: " ++ ~nUPIC[\ui][\refreshDisplay].notNil).postln;
    };
    
    "".postln;
    "=== Manual Test ===".postln;
    
    // Test mouse handler directly
    if(~nUPIC[\ui][\handleMouseDown].notNil) {
        "Testing mouse handler directly...".postln;
        {
            var state = ~nUPIC[\ui][\state];
            "Before test - isDrawing: ".post; state[\isDrawing].postln;
            
            // Force drawing mode
            state[\eraseMode] = false;
            state[\selectMode] = false;
            state[\isPlaying] = false;
            
            // Test mouse down
            ~nUPIC[\ui][\handleMouseDown].value(300, 400, (), 1200, 800);
            "After mouseDown - isDrawing: ".post; state[\isDrawing].postln;
            
            if(state[\currentTrajectory].notNil) {
                ("Current trajectory points: " ++ state[\currentTrajectory].size).postln;
                "✅ Mouse handler works - problem is with mouse event connection".postln;
            } {
                "❌ Mouse handler not working properly".postln;
            };
        }.value;
    };
    
    "".postln;
    "=== FIX ATTEMPTS ===".postln;
    
    // Try to fix the mouse connection issue
    {
        var state = ~nUPIC[\ui][\state];
        var drawView = state[\drawView];
        
        if(drawView.notNil) {
            "Attempting to reconnect mouse handlers...".postln;
            
            // Reconnect mouse actions
            drawView.mouseDownAction = { |view, x, y, modifiers|
                "Mouse down detected at (%, %)".format(x, y).postln;
                ~nUPIC[\ui][\handleMouseDown].value(x, y, modifiers, view.bounds.width, view.bounds.height);
            };
            
            drawView.mouseMoveAction = { |view, x, y|
                ~nUPIC[\ui][\handleMouseMove].value(x, y, view.bounds.width, view.bounds.height);
            };
            
            drawView.mouseUpAction = { |view, x, y|
                "Mouse up detected at (%, %)".format(x, y).postln;
                ~nUPIC[\ui][\handleMouseUp].value(x, y, view.bounds.width, view.bounds.height);
            };
            
            // Force drawing mode
            state[\eraseMode] = false;
            state[\selectMode] = false;
            state[\isPlaying] = false;
            
            drawView.refresh;
            
            "✅ Mouse handlers reconnected!".postln;
            "✅ Drawing mode activated!".postln;
            "".postln;
            "🎯 NOW TRY DRAWING ON THE CANVAS".postln;
            "You should see 'Mouse down detected' messages when you click".postln;
        } {
            "❌ DrawView not found - cannot fix mouse connection".postln;
        };
    }.value;
};

"".postln;
"=== SUMMARY ===".postln;
"If you see 'Mouse down detected' messages when clicking on the canvas,".postln;
"the fix worked and drawing should now work!".postln;
"If not, there may be a deeper issue with the view setup.".postln;
)
