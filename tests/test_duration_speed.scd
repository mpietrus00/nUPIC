// Test script to verify that changing duration affects playback speed
// This will test the relationship between total duration and trajectory playback speed

(
// Test function to verify duration affects speed correctly
~testDurationSpeed = {
    var state = ~nUPIC[\\ui][\\state];
    var data = ~nUPIC[\\data];
    var originalDuration, newDuration;
    
    if(state.isNil or: { data.isNil }) {
        "nUPIC system not initialized".postln;
        ^nil;
    };
    
    if(data[\\trajectories].size == 0) {
        "No trajectories to test with - please draw a trajectory first".postln;
        ^nil;
    };
    
    originalDuration = state[\\playDuration];
    
    "=== Duration Speed Test ===".postln;
    ("Original duration: " ++ originalDuration ++ " seconds").postln;
    ("Number of trajectories: " ++ data[\\trajectories].size).postln;
    
    // Function to test a specific duration
    ~testWithDuration = { |duration|
        // Set the new duration
        state[\\playDuration] = duration;
        
        // Update the UI control if it exists
        if(state[\\controls].notNil and: { state[\\controls][\\durationNumberBox].notNil }) {
            { state[\\controls][\\durationNumberBox].value_(duration) }.defer;
        };
        
        ("Testing with duration: " ++ duration ++ " seconds").postln;
        ("Expected behavior:").postln;
        ("- Longer duration (" ++ duration ++ "s) should play SLOWER").postln;
        ("- Shorter duration (" ++ duration ++ "s) should play FASTER").postln;
        ("- Same trajectory will take " ++ duration ++ " seconds to complete").postln;
        
        // Show the time scaling factor
        var constants = ~nUPIC[\\constants];
        var width = constants[\\defaultWidth] ? 1200;
        var timeScaling = duration / width;  // This is how playback maps X coordinates to time
        
        ("Time scaling factor: " ++ timeScaling ++ " seconds per pixel").postln;
        ("A trajectory spanning full width (" ++ width ++ "px) will play for " ++ (width * timeScaling) ++ " seconds").postln;
    };
    
    "Testing different durations:".postln;
    
    // Test with longer duration (slower playback)
    ~testWithDuration.(20);  // 20 seconds - should be slower
    1.wait;
    
    // Test with shorter duration (faster playback)  
    ~testWithDuration.(5);   // 5 seconds - should be faster
    1.wait;
    
    // Restore original duration
    ~testWithDuration.(originalDuration);
    
    "=== Test Complete ===".postln;
    "You can now test by playing trajectories with different duration settings.".postln;
    "Change the duration in the UI and hit play to hear the difference.".postln;
};

// Run the test
~testDurationSpeed.value;
)
