// Test Spatial Trajectory Mapping 
// This tests that trajectories are now purely spatial and duration changes affect the entire canvas

(
// Load the main nUPIC system first
"nUPIC_Main.scd".load;

// Wait for initialization, then test
fork {
    3.wait; // Wait for nUPIC to initialize
    
    if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil }) {
        "=== SPATIAL MAPPING TEST ===".postln;
        "1. Draw a trajectory".postln;
        "2. Test different durations:".postln;
        "   - Set to 5s and play - should play faster".postln;
        "   - Set to 30s and play - should play slower".postln;
        "   - Same trajectory should always play from left to right".postln;
        "".postln;
        
        // Test function to change duration and show the expected behavior
        ~testSpatialMapping = {
            var state = ~nUPIC[\ui][\state];
            var data = ~nUPIC[\data];
            
            if(state.isNil or: { data.isNil }) {
                "ERROR: nUPIC not initialized".postln;
            } {
                "Current trajectory count: ".post;
                if(data[\trajectories].notNil) {
                    data[\trajectories].size.postln;
                    
                    if(data[\trajectories].size > 0) {
                        var firstTraj = data[\trajectories][0];
                        "First trajectory info:".postln;
                        ("- Points: " ++ firstTraj.size).postln;
                        ("- First point: x=" ++ firstTraj[0].x ++ ", y=" ++ firstTraj[0].y ++ ", freq=" ++ (firstTraj[0].freq ? "nil")).postln;
                        ("- Last point: x=" ++ firstTraj.last.x ++ ", y=" ++ firstTraj.last.y ++ ", freq=" ++ (firstTraj.last.freq ? "nil")).postln;
                        
                        // Check if time coordinates are stored (should be nil/nonexistent)
                        if(firstTraj[0].respondsTo(\time) and: { firstTraj[0].time.notNil }) {
                            "WARNING: Time coordinates still being stored!".postln;
                        } {
                            "✓ Pure spatial storage confirmed - no time coordinates".postln;
                        };
                        
                        "".postln;
                        "Test different durations:".postln;
                        "~testDuration.(5)   // 5 seconds".postln;
                        "~testDuration.(30)  // 30 seconds".postln;
                        "~testDuration.(1)   // 1 second".postln;
                    } {
                        "No trajectories drawn yet. Draw some first!".postln;
                    };
                } {
                    0.postln;
                    "No trajectories drawn yet. Draw some first!".postln;
                };
            };
        };
        
        // Function to test duration changes
        ~testDuration = { |duration|
            var state = ~nUPIC[\ui][\state];
            
            if(state.notNil) {
                state[\playDuration] = duration;
                if(state[\controls][\durationNumberBox].notNil) {
                    { state[\controls][\durationNumberBox].value = duration }.defer;
                };
                ("Duration set to " ++ duration ++ " seconds").postln;
                ("Now the entire canvas will play in " ++ duration ++ " seconds").postln;
                "Click play to test!".postln;
                "".postln;
            };
        };
        
        // Run initial test
        ~testSpatialMapping.value;
        
    } {
        "ERROR: nUPIC system failed to load".postln;
    };
};
)
