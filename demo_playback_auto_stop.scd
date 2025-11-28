// Demo: Playback automatically stops and resets play button when reaching composition end
// Run this after loading nUPIC to see the auto-stop functionality

(
if(~nUPIC.isNil) {
    "Please run nUPIC_MAIN.scd first to initialize the system".postln;
} {
    "=== Playback Auto-Stop Demo ===".postln;
    "".postln;
    "The system now includes automatic playback stopping:".postln;
    "".postln;
    "• When playback reaches the end of the composition duration,".postln;
    "  it automatically stops and resets the Play button to 'Play' state".postln;
    "".postln;
    "• You'll see the message 'Playback completed - play button reset'".postln;
    "  in the console when this happens".postln;
    "".postln;
    "• This prevents the need to manually stop playback after it ends".postln;
    "".postln;
    "To test this:".postln;
    "1. Draw some trajectories in the GUI window".postln;
    "2. Set a short duration (e.g., 3-5 seconds) using the duration slider".postln;
    "3. Press SPACE or click Play button".postln;
    "4. Watch the play button automatically return to 'Play' when finished".postln;
    "".postln;
    
    if(~nUPIC.data.getStats().totalTrajectories > 0) {
        ("Current system has " ++ ~nUPIC.data.getStats().totalTrajectories ++ " trajectories ready to play").postln;
        ("Current play duration: " ++ (~nUPIC[\ui][\state][\playDuration] ? "Unknown") ++ " seconds").postln;
    } {
        "Draw some trajectories first, then test the playback auto-stop".postln;
    };
};
)
