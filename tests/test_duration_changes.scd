// Test script to verify that changing duration actually affects playback speed
// This will demonstrate the issue and help us verify the fix

(
~testDurationChanges = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var width = constants[\defaultWidth] ? 1200;
    
    if(state.isNil or: { data.isNil }) {
        "nUPIC system not initialized".postln;
        ^nil;
    };
    
    if(data[\trajectories].size == 0) {
        "No trajectories to test with - please draw a trajectory first".postln;
        ^nil;
    };
    
    "=== Testing Duration Changes ===".postln;
    ("Current duration: " ++ state[\playDuration] ++ " seconds").postln;
    ("Canvas width: " ++ width ++ " pixels").postln;
    ("Number of trajectories: " ++ data[\trajectories].size).postln;
    
    // Test with a trajectory that spans the full width
    if(data[\trajectories].size > 0) {
        var traj = data[\trajectories][0];  // First trajectory
        var firstPoint = if(traj[0].isKindOf(Event)) { traj[0] } { (x: traj[0].x, y: traj[0].y) };
        var lastPoint = if(traj.last.isKindOf(Event)) { traj.last } { (x: traj.last.x, y: traj.last.y) };
        var trajectoryWidth = lastPoint.x - firstPoint.x;
        
        ("First trajectory:").postln;
        ("  - Start X: " ++ firstPoint.x ++ " pixels").postln;
        ("  - End X: " ++ lastPoint.x ++ " pixels").postln; 
        ("  - Trajectory width: " ++ trajectoryWidth ++ " pixels").postln;
        
        // Calculate timing with different durations
        [5, 10, 20, 30].do { |testDuration|
            var startTime = firstPoint.x.linlin(0, width, 0, testDuration);
            var endTime = lastPoint.x.linlin(0, width, 0, testDuration);
            var playTime = endTime - startTime;
            
            ("With duration = " ++ testDuration ++ "s:").postln;
            ("  - Trajectory would start at: " ++ startTime.round(0.2) ++ "s").postln;
            ("  - Trajectory would end at: " ++ endTime.round(0.2) ++ "s").postln;
            ("  - Trajectory play time: " ++ playTime.round(0.2) ++ "s").postln;
            ("  - Speed: " ++ (trajectoryWidth / playTime).round(0.1) ++ " pixels/second").postln;
            "".postln;
        };
    };
    
    "The issue might be that the playback system calculates time mappings ONCE when playback starts,".postln;
    "so changing duration during playback or between playbacks doesn't affect already-calculated timings.".postln;
    "".postln;
    
    "Test this by:".postln;
    "1. Set duration to 10s and play a trajectory - note the speed".postln;
    "2. Stop playback".postln; 
    "3. Change duration to 20s".postln;
    "4. Play the SAME trajectory again - it should be slower".postln;
};

~testDurationChanges.value;
)
