// Test script for verifying playback automatically stops at composition end
// This tests that the play button switches from "Stop" back to "Play" when playback completes

(
// Initialize nUPIC if not already done
if(~nUPIC.isNil) {
    "Loading nUPIC first...".postln;
    "nUPIC_MAIN.scd".load;
    2.wait;
};

// Create a simple test trajectory that lasts 3 seconds
~testTraj = List[
    (x: 50, y: 400, freq: 440, time: 0),      // Start at 0 seconds
    (x: 150, y: 350, freq: 660, time: 1),     // 1 second
    (x: 250, y: 300, freq: 880, time: 2),     // 2 seconds  
    (x: 350, y: 250, freq: 1100, time: 3)     // End at 3 seconds
];

// Add trajectory to the system
"Adding test trajectory...".postln;
~nUPIC.data.addTrajectory(~testTraj);

// Set playback duration to 4 seconds (slightly longer than trajectory)
if(~nUPIC[\ui][\state].notNil) {
    ~nUPIC[\ui][\state][\playDuration] = 4;
    "Set play duration to 4 seconds".postln;
};

"Test trajectory created. The trajectory runs from 0-3 seconds within a 4-second composition.".postln;
"Please test the following:".postln;
"1. Press SPACE or click the Play button to start playback".postln;
"2. Observe that playback runs for about 4 seconds".postln;
"3. Verify that when playback reaches the end, the Play button automatically".postln;
"   switches from 'Stop' back to 'Play' state without manual intervention".postln;
"4. You should see 'Playback completed - play button reset' in the console".postln;

~nUPIC.data.getStats();
)
