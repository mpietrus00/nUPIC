// Script to verify that duration changes now affect playback speed correctly
// Run this after the fix to confirm the behavior

(
~verifyDurationFix = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    
    "=== VERIFYING DURATION FIX ===".postln;
    "".postln;
    
    if(state.isNil or: { data.isNil }) {
        "ERROR: nUPIC not initialized".postln;
        ^nil;
    };
    
    if(data[\trajectories].size == 0) {
        "Please draw a trajectory first, then run this test.".postln;
        ^nil;
    };
    
    ("Current trajectories: " ++ data[\trajectories].size).postln;
    ("Current duration setting: " ++ state[\playDuration] ++ " seconds").postln;
    "".postln;
    
    "TESTING PROCEDURE:".postln;
    "1. Note the current duration: " ++ state[\playDuration] ++ " seconds".postln;
    "2. Play a trajectory and listen to the speed".postln;
    "3. Stop playback".postln;
    "4. Change duration to 20 seconds using the UI control".postln;
    "5. Play the SAME trajectory again".postln;
    "6. It should sound SLOWER (same trajectory over longer time)".postln;
    "7. Change duration to 5 seconds".postln;
    "8. Play again - it should sound FASTER".postln;
    "".postln;
    
    "TECHNICAL DETAILS:".postln;
    "The fix ensures that time calculations use the current state[\playDuration]".postln;
    "instead of a captured value, so changes take effect immediately.".postln;
    "".postln;
    
    // Quick function to test different durations programmatically
    ~testDurationValues = { |duration|
        state[\playDuration] = duration;
        // Update the UI control if it exists
        if(state[\controls].notNil and: { state[\controls][\durationNumberBox].notNil }) {
            { state[\controls][\durationNumberBox].value_(duration) }.defer;
        };
        ("Duration set to: " ++ duration ++ " seconds").postln;
        "Now play the trajectory to hear the difference.".postln;
    };
    
    "PROGRAMMATIC TEST FUNCTIONS:".postln;
    "~testDurationValues.(5)   - Set to 5 seconds (faster)".postln;
    "~testDurationValues.(10)  - Set to 10 seconds (medium)".postln;
    "~testDurationValues.(20)  - Set to 20 seconds (slower)".postln;
    "".postln;
    
    "EXPECTED BEHAVIOR:".postln;
    "- Same trajectory drawn on fixed canvas size".postln;
    "- Longer duration = SLOWER playback (trajectory takes more time)".postln;
    "- Shorter duration = FASTER playback (trajectory takes less time)".postln;
    "- Changes take effect immediately when you start new playback".postln;
    "".postln;
    
    "The fix has been applied! Test it now with the procedure above.".postln;
};

~verifyDurationFix.value;
)
