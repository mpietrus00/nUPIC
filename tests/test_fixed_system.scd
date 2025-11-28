// Test the fixed nUPIC system with correct time mapping
// Create a simple trajectory and test playback at different durations

(
// Make sure we have a clean start
s.boot;
s.waitForBoot {
    
    // Load the nUPIC system
    thisProcess.nowExecutingPath.dirname +/+ "nUPIC_MAIN.scd".load;
    
    // Wait for system to initialize
    2.0.wait;
    
    // Create some simple test trajectories
    ~nUPIC[\\data][\\trajectories] = [
        // Trajectory from x=240 to x=720 (20% to 60% of 1200px canvas)
        [
            (x: 240, y: 400),  // Start at low frequency
            (x: 480, y: 200),  // Go to higher frequency  
            (x: 720, y: 300)   // End at mid frequency
        ],
        // Another trajectory from x=600 to x=1080 (50% to 90% of canvas)
        [
            (x: 600, y: 300),
            (x: 840, y: 100),
            (x: 1080, y: 250)
        ]
    ];
    
    "Test trajectories created".postln;
    "Trajectory 1: x=240-720 (should play 20%-60% through playback)".postln;
    "Trajectory 2: x=600-1080 (should play 50%-90% through playback)".postln;
    "".postln;
    
    // Open the GUI
    if(~nUPIC[\\ui][\\createMainWindow].notNil) {
        ~nUPIC[\\ui][\\createMainWindow].value;
        "nUPIC GUI should now be open. Try playing with different durations:".postln;
        "- Set duration to 10s and play - first traj should play 2-6s, second 5-9s".postln;
        "- Set duration to 100s and play - first traj should play 20-60s, second 50-90s".postln;
        "".postln;
        "The time mapping fix should now work correctly!".postln;
    } {
        "ERROR: Main window function not found".postln;
    };
};
)
