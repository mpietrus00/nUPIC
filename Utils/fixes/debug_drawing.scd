// Debug test for nUPIC drawing functionality
// Run this after the GUI is open to test mouse drawing

(
"=== nUPIC Drawing Debug Test ===".postln;

// Check if nUPIC is loaded
if(~nUPIC.isNil) {
    "ERROR: nUPIC not loaded. Load nUPIC_Main.scd first".postln;
} {
    "✓ nUPIC loaded".postln;
    
    // Check UI state
    if(~nUPIC[\ui].isNil) {
        "ERROR: UI not initialized".postln;
    } {
        "✓ UI initialized".postln;
        
        // Check state
        {
            var state = ~nUPIC[\ui][\state];
            if(state.isNil) {
                "ERROR: UI state not initialized".postln;
            } {
                "✓ UI state exists".postln;
                ("Drawing mode active: " ++ (state[\eraseMode].not and: { state[\selectMode].not })).postln;
                ("Erase mode: " ++ state[\eraseMode]).postln;
                ("Select mode: " ++ state[\selectMode]).postln;
                ("Is playing: " ++ state[\isPlaying]).postln;
                ("Is drawing: " ++ state[\isDrawing]).postln;
                
                if(state[\drawView].isNil) {
                    "ERROR: drawView not found".postln;
                } {
                    "✓ drawView exists".postln;
                    ("drawView bounds: " ++ state[\drawView].bounds).postln;
                };
            };
        }.value;
        
        // Check data manager
        if(~nUPIC[\data].isNil) {
            "ERROR: Data manager not loaded".postln;
        } {
            "✓ Data manager loaded".postln;
            {
                var data = ~nUPIC[\data];
                if(data[\trajectories].isNil) {
                    "Warning: trajectories list is nil - initializing".postln;
                    data[\trajectories] = List.new;
                };
                ("Current trajectories: " ++ data[\trajectories].size).postln;
            }.value;
        };
        
        // Check mouse handlers
        if(~nUPIC[\ui][\handleMouseDown].isNil) {
            "ERROR: Mouse down handler not loaded".postln;
        } {
            "✓ Mouse down handler loaded".postln;
        };
        
        // Test drawing mode setup
        if(~nUPIC[\ui][\setDrawMode].notNil) {
            "Setting draw mode...".postln;
            ~nUPIC[\ui][\setDrawMode].value;
        };
        
        // Manual trajectory test
        "".postln;
        "=== Manual Trajectory Test ===".postln;
        "Adding a test trajectory manually...".postln;
        
        {
            var testTraj = List[
                (x: 100, y: 400, freq: 440),
                (x: 300, y: 300, freq: 660),
                (x: 500, y: 200, freq: 880)
            ];
            
            if(~nUPIC[\data][\trajectories].isNil) {
                ~nUPIC[\data][\trajectories] = List.new;
            };
            if(~nUPIC[\data][\amplitudeEnvelopes].isNil) {
                ~nUPIC[\data][\amplitudeEnvelopes] = List.new;
            };
            if(~nUPIC[\data][\trajectorySynthDefs].isNil) {
                ~nUPIC[\data][\trajectorySynthDefs] = List.new;
            };
            
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
        
        "".postln;
        "=== Mouse Event Test ===".postln;
        "Testing mouse down event at (200, 300)...".postln;
        
        // Test a mouse event manually
        if(~nUPIC[\ui][\handleMouseDown].notNil) {
            try {
                {
                    var state = ~nUPIC[\ui][\state];
                    "Before: isDrawing = " ++ state[\isDrawing].postln;
                    ~nUPIC[\ui][\handleMouseDown].value(200, 300, (), 1200, 800);
                    "After: isDrawing = " ++ state[\isDrawing].postln;
                    if(state[\currentTrajectory].notNil) {
                        "Current trajectory points: " ++ state[\currentTrajectory].size.postln;
                    } {
                        "No current trajectory created".postln;
                    };
                }.value;
            } { |error|
                ("ERROR in mouse handler: " ++ error.errorString).postln;
            };
        };
        
        "".postln;
        "=== Instructions ===".postln;
        "If drawing still doesn't work:".postln;
        "1. Make sure you're not in select or erase mode".postln;
        "2. Try clicking the drawing mode button in the UI".postln;
        "3. Make sure the view has focus by clicking on it first".postln;
        "4. Check that the mouse position is within the drawing area".postln;
        
    };
};
)
