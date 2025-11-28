// Test Duration Playback Changes
// This script tests if duration changes affect playback speed

(
// First, let's check if we have trajectories and what the current duration is
var state = ~nUPIC[\ui][\state];
var data = ~nUPIC[\data];

if(state.isNil) {
    "ERROR: nUPIC UI state not initialized".postln;
} {
    ("Current playDuration in state: " ++ state[\\playDuration]).postln;

    if(data.isNil or: { data[\\trajectories].isNil }) {
        "ERROR: No trajectory data found. Please draw some trajectories first.".postln;
    } {
        ("Number of trajectories: " ++ data[\\trajectories].size).postln;

        // Test changing duration
        "Testing duration changes...".postln;

        // Set to 5 seconds (should be fast)
        state[\\playDuration] = 5.0;
        ("Set duration to 5 seconds: " ++ state[\\playDuration]).postln;

        // Update the duration control to reflect the change
        if(state[\\controls].notNil and: { state[\\controls][\\durationNumberBox].notNil }) {
            state[\\controls][\\durationNumberBox].value = 5.0;
            "Updated duration control to show 5 seconds".postln;
        };

        "Now try playing - it should take 5 seconds total".postln;
        "Then change duration to 20 seconds and play again - it should take 20 seconds".postln;

        // Let's also check what the first trajectory looks like
        if(data[\\trajectories].size > 0) {
            var firstTraj = data[\\trajectories][0];
            if(firstTraj.size > 0) {
                var firstPoint = firstTraj[0];
                var lastPoint = firstTraj.last;
                ("First trajectory: start at x=" ++ firstPoint.x ++ ", end at x=" ++ lastPoint.x).postln;
                ("This should play from 0 to " ++ state[\\playDuration] ++ " seconds proportionally").postln;
            };
        };
    };
};
)
