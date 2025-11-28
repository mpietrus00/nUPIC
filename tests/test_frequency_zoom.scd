// Test frequency zoom functionality
// This verifies that trajectories move visually when frequency zoom changes

(
// Initialize nUPIC if not already done
if(~nUPIC.isNil) {
    "Loading nUPIC first...".postln;
    "nUPIC_MAIN.scd".load;
    2.wait;
};

// Create test trajectories at different frequency ranges
~lowFreqTraj = List[
    (x: 100, y: 600, freq: 200, time: 0),     // Low frequency
    (x: 200, y: 550, freq: 300, time: 1),     
    (x: 300, y: 500, freq: 400, time: 2)      
];

~midFreqTraj = List[
    (x: 400, y: 400, freq: 1000, time: 0),    // Mid frequency
    (x: 500, y: 350, freq: 1200, time: 1),     
    (x: 600, y: 300, freq: 1400, time: 2)      
];

~highFreqTraj = List[
    (x: 700, y: 100, freq: 3000, time: 0),    // High frequency
    (x: 800, y: 50, freq: 3500, time: 1),     
    (x: 900, y: 0, freq: 4000, time: 2)       
];

// Add trajectories to the system
"Adding test trajectories at different frequency ranges...".postln;
~nUPIC.data.addTrajectory(~lowFreqTraj);   // Index 0
~nUPIC.data.addTrajectory(~midFreqTraj);   // Index 1  
~nUPIC.data.addTrajectory(~highFreqTraj);  // Index 2

"Test trajectories created:".postln;
"• Low frequency trajectory: 200-400 Hz".postln;
"• Mid frequency trajectory: 1000-1400 Hz".postln; 
"• High frequency trajectory: 3000-4000 Hz".postln;
"".postln;

"To test frequency zoom:".postln;
"1. Look at the trajectory positions in the main window".postln;
"2. Use the F+ button to zoom in on frequency".postln;
"3. Notice that trajectories should move vertically to maintain their frequency relationships".postln;
"4. Use the F- button to zoom out".postln;
"5. Check that the frequency status label updates (should show the current frequency range)".postln;
"6. Verify there's only ONE set of frequency zoom controls (buttons F+ and F-)".postln;
"".postln;

"Expected behavior:".postln;
"• F+ (zoom in): Trajectories should spread out vertically, showing more detail".postln;
"• F- (zoom out): Trajectories should compress vertically, showing wider range".postln;
"• Status label should show current frequency range (e.g., '500-2500 Hz')".postln;
"• Frequency labels on the left should update to match the zoom level".postln;

~nUPIC.data.getStats();
)
