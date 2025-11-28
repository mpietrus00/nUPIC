// Fix Drawing Display - Ensure trajectories are visually drawn
// This script diagnoses and fixes the drawFunc assignment and trajectory rendering

(
"=== Drawing Display Diagnostic ===".postln;

// Check if system is loaded
if(~nUPIC.isNil or: { ~nUPIC[\ui].isNil }) {
    "❌ nUPIC system not loaded".postln;
} {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    
    if(state.isNil) {
        "❌ UI state missing".postln;
    } {
        if(data.isNil) {
            "❌ Data system missing".postln;
        } {
            var drawView = state[\drawView];
            
            if(drawView.isNil) {
                "❌ DrawView missing".postln;
            } {
                "✅ Basic components found".postln;
                
                // Check if drawFunc is assigned
                if(drawView.drawFunc.isNil) {
                    "❌ DrawFunc not assigned - fixing...".postln;
                    
                    // Assign the main drawing function
                    drawView.drawFunc = {
                        ~nUPIC[\ui][\drawCanvas].value(drawView, drawView.bounds.width, drawView.bounds.height);
                    };
                    
                    "✅ DrawFunc assigned".postln;
                } {
                    "✅ DrawFunc already assigned".postln;
                };
                
                // Check trajectory storage
                if(data[\trajectories].isNil) {
                    "⚠️  No trajectories container - creating...".postln;
                    data[\trajectories] = [];
                };
                
                ("Current trajectory count: " ++ data[\trajectories].size).postln;
                
                // Add some test trajectories if none exist
                if(data[\trajectories].size == 0) {
                    "Adding test trajectory...".postln;
                    
                    // Create a simple test trajectory
                    {
                        var testTrajectory = [
                            (x: 100, freq: 440),
                            (x: 200, freq: 660),
                            (x: 300, freq: 880),
                            (x: 400, freq: 1100)
                        ];
                        
                        data[\trajectories] = data[\trajectories].add(testTrajectory);
                        ("Added test trajectory with " ++ testTrajectory.size ++ " points").postln;
                    }.value;
                };
                
                // Force a refresh
                "Forcing display refresh...".postln;
                { drawView.refresh }.defer;
                
                // Test the mouse handler to ensure trajectories are being added
                "Testing trajectory addition...".postln;
                
                // Create a test trajectory through mouse handler
                if(~nUPIC[\ui][\handleMouseDown].notNil) {
                    // Simulate mouse down
                    ~nUPIC[\ui][\handleMouseDown].value(150, 300, (), drawView.bounds.width, drawView.bounds.height);
                    
                    // Check if current trajectory was created
                    if(state[\currentTrajectory].notNil) {
                        "✅ Current trajectory created during mouse down".postln;
                    } {
                        "❌ Current trajectory not created".postln;
                    };
                    
                    // Simulate mouse move
                    ~nUPIC[\ui][\handleMouseMove].value(250, 350, drawView.bounds.width, drawView.bounds.height);
                    ~nUPIC[\ui][\handleMouseMove].value(350, 400, drawView.bounds.width, drawView.bounds.height);
                    
                    // Simulate mouse up to complete trajectory
                    ~nUPIC[\ui][\handleMouseUp].value(450, 450, drawView.bounds.width, drawView.bounds.height);
                    
                    ("Trajectory count after test: " ++ data[\trajectories].size).postln;
                    
                    // Force another refresh
                    { drawView.refresh }.defer;
                };
                
                // Verify drawing functions exist
                "=== Checking Drawing Functions ===".postln;
                ("drawCanvas exists: " ++ ~nUPIC[\ui][\drawCanvas].notNil).postln;
                ("drawTrajectory exists: " ++ ~nUPIC[\ui][\drawTrajectory].notNil).postln;
                ("drawCurrentTrajectory exists: " ++ ~nUPIC[\ui][\drawCurrentTrajectory].notNil).postln;
                
                // Test if Pen is working
                "Testing Pen functionality...".postln;
                {
                    drawView.drawFunc = {
                        // Clear background
                        Pen.fillColor = Color.white;
                        Pen.fillRect(drawView.bounds);
                        
                        // Draw a test line
                        Pen.strokeColor = Color.red;
                        Pen.width = 3;
                        Pen.line(Point(50, 50), Point(200, 100));
                        Pen.stroke;
                        
                        // Draw test trajectory if any exist
                        if(data[\trajectories].notNil and: { data[\trajectories].size > 0 }) {
                            Pen.strokeColor = Color.blue;
                            Pen.width = 2;
                            
                            data[\trajectories].do { |traj, index|
                                if(traj.notNil and: { traj.size > 1 }) {
                                    // Draw this trajectory
                                    {
                                        var firstPoint = traj[0];
                                        var startX = if(firstPoint.isKindOf(Event)) { firstPoint.x } { firstPoint.x };
                                        var startY = if(firstPoint.isKindOf(Event)) { 
                                            firstPoint.freq.linlin(20, 7500, drawView.bounds.height, 0) 
                                        } { firstPoint.y };
                                        
                                        Pen.moveTo(Point(startX, startY));
                                        
                                        traj.do { |point|
                                            var x = if(point.isKindOf(Event)) { point.x } { point.x };
                                            var y = if(point.isKindOf(Event)) { 
                                                point.freq.linlin(20, 7500, drawView.bounds.height, 0) 
                                            } { point.y };
                                            Pen.lineTo(Point(x, y));
                                        };
                                        Pen.stroke;
                                        
                                        ("Drawing trajectory " ++ index ++ " with " ++ traj.size ++ " points").postln;
                                    }.value;
                                };
                            };
                        };
                        
                        // Draw current trajectory being drawn
                        if(state[\currentTrajectory].notNil and: { state[\currentTrajectory].size > 1 }) {
                            Pen.strokeColor = Color.black;
                            Pen.width = 3;
                            
                            {
                                var currentTraj = state[\currentTrajectory];
                                var firstPoint = currentTraj[0];
                                var startX = if(firstPoint.isKindOf(Event)) { firstPoint.x } { firstPoint.x };
                                var startY = if(firstPoint.isKindOf(Event)) { 
                                    firstPoint.freq.linlin(20, 7500, drawView.bounds.height, 0) 
                                } { firstPoint.y };
                                
                                Pen.moveTo(Point(startX, startY));
                                
                                currentTraj.do { |point|
                                    var x = if(point.isKindOf(Event)) { point.x } { point.x };
                                    var y = if(point.isKindOf(Event)) { 
                                        point.freq.linlin(20, 7500, drawView.bounds.height, 0) 
                                    } { point.y };
                                    Pen.lineTo(Point(x, y));
                                };
                                Pen.stroke;
                            }.value;
                        };
                    };
                    
                    // Force refresh with new drawFunc
                    drawView.refresh;
                    
                    "✅ Custom drawFunc with test line and trajectories assigned".postln;
                    
                }.defer(0.1);
                
                "=== Instructions ===".postln;
                "You should now see:".postln;
                "- A red test line from (50,50) to (200,100)".postln;
                "- Any existing trajectories in blue".postln;
                "- Current trajectory being drawn in black".postln;
                "Try drawing now - trajectories should be visible!".postln;
            };
        };
    };
};
)
