// Test script to verify the corrected time mapping
(
var testCorrectTimeMapping = {
    var playDuration, currentTime, referenceTimeScale;
    var firstX = 300, lastX = 900;  // Trajectory from x=300 to x=900
    var firstTime, lastTime, timeScaledByDuration;
    
    referenceTimeScale = 1200;
    firstTime = firstX / referenceTimeScale;  // 0.25
    lastTime = lastX / referenceTimeScale;    // 0.75
    
    "=== CORRECTED TIME MAPPING TEST ===".postln;
    ("Trajectory X range: " ++ firstX ++ " to " ++ lastX).postln;
    ("Trajectory time range: " ++ firstTime ++ " to " ++ lastTime).postln;
    "".postln;
    
    // Test 10 second playback
    playDuration = 10;
    
    "--- 10 second playback ---".postln;
    
    // Test at different playback positions
    [0, 2.5, 5.0, 7.5, 10].do { |time|
        currentTime = time;
        timeScaledByDuration = currentTime / playDuration;  // CORRECTED formula
        
        ("Time " ++ currentTime ++ "s: progress=" ++ timeScaledByDuration.round(0.01) ++ 
         ", should play? " ++ (timeScaledByDuration >= firstTime and: { timeScaledByDuration <= lastTime })).postln;
    };
    
    "".postln;
    
    // Test 100 second playback
    playDuration = 100;
    
    "--- 100 second playback ---".postln;
    
    // Test at different playback positions
    [0, 25, 50, 75, 100].do { |time|
        currentTime = time;
        timeScaledByDuration = currentTime / playDuration;  // CORRECTED formula
        
        ("Time " ++ currentTime ++ "s: progress=" ++ timeScaledByDuration.round(0.01) ++ 
         ", should play? " ++ (timeScaledByDuration >= firstTime and: { timeScaledByDuration <= lastTime })).postln;
    };
    
    "".postln;
    "EXPECTED BEHAVIOR:".postln;
    "- 10s playback: trajectory should play from 2.5s to 7.5s".postln;
    "- 100s playback: trajectory should play from 25s to 75s".postln;
};

testCorrectTimeMapping.value;
)
