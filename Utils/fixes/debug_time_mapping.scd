// Debug script for nUPIC time mapping issues
// This will help identify why trajectories don't play at different durations

// Test the time scaling logic
(
var testTimeScaling = {
    var playDuration = 10;  // 10 seconds - your problem case
    var currentTime = 5;    // 5 seconds into playback
    var referenceTimeScale = 1200; // Canvas width
    var width = 1200;
    var correctTimeScaling;
    
    // Simulate a trajectory from x=300 to x=900 (middle portion of canvas)
    var firstX = 300;
    var lastX = 900;
    
    // Calculate trajectory time coordinates using FIXED mapping
    var firstTime = firstX / referenceTimeScale;  // Should be 0.25
    var lastTime = lastX / referenceTimeScale;    // Should be 0.75
    
    // Calculate time scaled by duration (this is the problematic part)
    var timeScaledByDuration = currentTime * referenceTimeScale / playDuration;
    
    "=== TIME SCALING DEBUG (10s duration) ===".postln;
    ("Play Duration: " ++ playDuration ++ "s").postln;
    ("Current Time: " ++ currentTime ++ "s").postln;
    ("Reference Time Scale: " ++ referenceTimeScale).postln;
    "".postln;
    
    ("Trajectory X range: " ++ firstX ++ " to " ++ lastX).postln;
    ("Trajectory time range: " ++ firstTime ++ " to " ++ lastTime).postln;
    ("Time scaled by duration: " ++ timeScaledByDuration).postln;
    "".postln;
    
    ("Is timeScaledByDuration >= firstTime? " ++ (timeScaledByDuration >= firstTime)).postln;
    ("Is timeScaledByDuration <= lastTime? " ++ (timeScaledByDuration <= lastTime)).postln;
    "".postln;
    
    // Test with 100s duration
    playDuration = 100;
    timeScaledByDuration = currentTime * referenceTimeScale / playDuration;
    
    "=== TIME SCALING DEBUG (100s duration) ===".postln;
    ("Play Duration: " ++ playDuration ++ "s").postln;
    ("Current Time: " ++ currentTime ++ "s").postln;
    ("Time scaled by duration: " ++ timeScaledByDuration).postln;
    ("Is timeScaledByDuration >= firstTime? " ++ (timeScaledByDuration >= firstTime)).postln;
    ("Is timeScaledByDuration <= lastTime? " ++ (timeScaledByDuration <= lastTime)).postln;
    "".postln;
    
    // Show the issue: at 10s duration, timeScaledByDuration = 600 (way beyond 0.25-0.75)
    // at 100s duration, timeScaledByDuration = 60 (still way beyond 0.25-0.75)
    "PROBLEM IDENTIFIED:".postln;
    "The timeScaledByDuration calculation is wrong!".postln;
    "It should map current playback time to trajectory coordinate space,".postln;
    "not multiply by referenceTimeScale.".postln;
    "".postln;
    
    // Correct calculation should be:
    correctTimeScaling = currentTime / playDuration; // 0 to 1 progress through playback
    
    "CORRECT TIME SCALING:".postln;
    ("Progress through playback (0-1): " ++ correctTimeScaling).postln;
    ("Should trajectory play at 50% through 10s? " ++ (correctTimeScaling >= firstTime and: { correctTimeScaling <= lastTime })).postln;
    
    playDuration = 100;
    correctTimeScaling = currentTime / playDuration;
    ("Should trajectory play at 5% through 100s? " ++ (correctTimeScaling >= firstTime and: { correctTimeScaling <= lastTime })).postln;
};

testTimeScaling.value;
)
