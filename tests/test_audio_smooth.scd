// Test smooth audio playback improvements
// This file tests the fixes for choppy audio

(
// Load nUPIC system first
"Loading nUPIC...".postln;
[
    "Core/Constants.scd",
    "Audio/SynthDefs.scd",
    "Core/TrajectoryData.scd",
    "UI/MainWindow.scd",
    "UI/Drawing.scd",
    "UI/MouseHandlers.scd", 
    "UI/Controls.scd",
    "UI/AmplitudeEditor.scd"
].do { |file|
    var path = thisProcess.nowExecutingPath.dirname ++ "/" ++ file;
    if(File.exists(path)) {
        path.load;
        ("✓ " ++ file ++ " loaded").postln;
    } {
        ("✗ Missing: " ++ file).postln;
    };
};

// Wait for everything to initialize
{
    "Testing smooth audio with reduced frame rate and increased lag times...".postln;
    
    // Create some test trajectories
    ~nUPIC[\\data][\\initializeData].value;
    
    // Add a simple test trajectory with frequency changes
    ~nUPIC[\\data][\\addTrajectory].value([
        (x: 100, y: 400, freq: 220),
        (x: 200, y: 350, freq: 260),
        (x: 300, y: 300, freq: 330),
        (x: 400, y: 250, freq: 390),
        (x: 500, y: 200, freq: 440),
        (x: 600, y: 150, freq: 520),
        (x: 700, y: 100, freq: 660)
    ]);
    
    // Add amplitude envelope
    ~nUPIC[\\data][\\amplitudeEnvelopes][0] = [
        (x: 0, amp: 0.1),
        (x: 150, amp: 0.8),
        (x: 300, amp: 0.6),
        (x: 450, amp: 0.9),
        (x: 600, amp: 0.3)
    ];
    
    "Test trajectory created with smooth frequency changes".postln;
    "Frame rate reduced from 30 Hz to 15 Hz".postln;
    "Lag times increased: freq=0.25s, amp=0.15s, pan=0.2s".postln;
    "Debug output removed for cleaner console".postln;
    
    // Test should show much smoother audio transitions
    "Ready for testing! The audio should now be smooth without stepping artifacts.".postln;
    
}.defer(2.0);
)
