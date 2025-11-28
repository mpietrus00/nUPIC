// Test Amplitude Application in Visual and Audio
// This script tests how amplitude envelopes affect both trajectory coloring and audio playback

(
"Loading nUPIC system...".postln;

// Load the full nUPIC system
thisProcess.interpreter.executeFile(thisProcess.nowExecutingPath.dirname +/+ "nUPIC_Main.scd");

// Wait for system to initialize
{
    var createTestTrajectories, testAmplitudeVisualAudio, testZoomedOutView;
    
    "Testing amplitude envelope application...".postln;
    
    // Function to create test trajectories with different amplitude envelopes
    createTestTrajectories = {
        var data = ~nUPIC[\data];
        var trajectories = List.new;
        var amplitudeEnvelopes = List.new;
        var width = 1200;
        var height = 800;
        var traj1, traj2, traj3, traj4; // Declare all variables at the top
        
        // Clear existing trajectories
        data[\trajectories] = List.new;
        data[\amplitudeEnvelopes] = List.new;
        
        "Creating test trajectories with different amplitude envelopes...".postln;
        
        // Trajectory 1: Fade In envelope (starts quiet, gets loud)
        traj1 = List.new;
        20.do { |i|
            var x = i * (width / 19);
            var freq = 440 * (i + 10) / 10;  // Rising frequency
            traj1.add((x: x, y: freq.linlin(7500, 20, 0, height), freq: freq));
        };
        trajectories.add(traj1);
        
        // Amplitude envelope: Fade In
        amplitudeEnvelopes.add(List[
            (x: 0, amp: 0.0),        // Silent at start
            (x: 300, amp: 0.3),      // Quarter way: quiet
            (x: 600, amp: 1.0)       // End: loud
        ]);
        
        // Trajectory 2: Fade Out envelope (starts loud, gets quiet) 
        traj2 = List.new;
        20.do { |i|
            var x = i * (width / 19);
            var freq = 880 - (i * 20);  // Falling frequency
            traj2.add((x: x, y: freq.linlin(7500, 20, 0, height), freq: freq));
        };
        trajectories.add(traj2);
        
        // Amplitude envelope: Fade Out
        amplitudeEnvelopes.add(List[
            (x: 0, amp: 1.0),        // Loud at start
            (x: 300, amp: 0.7),      // Quarter way: medium
            (x: 600, amp: 0.0)       // End: silent
        ]);
        
        // Trajectory 3: ADSR envelope (Attack, Decay, Sustain, Release)
        traj3 = List.new;
        20.do { |i|
            var x = i * (width / 19);
            var freq = 220 + (i * 10);  // Slowly rising frequency
            traj3.add((x: x, y: freq.linlin(7500, 20, 0, height), freq: freq));
        };
        trajectories.add(traj3);
        
        // Amplitude envelope: ADSR
        amplitudeEnvelopes.add(List[
            (x: 0, amp: 0.0),        // Start silent
            (x: 60, amp: 1.0),       // Attack: quick rise to loud
            (x: 180, amp: 0.6),      // Decay: drop to sustain level
            (x: 480, amp: 0.6),      // Sustain: hold steady
            (x: 600, amp: 0.0)       // Release: fade to silent
        ]);
        
        // Trajectory 4: Constant loud envelope
        traj4 = List.new;
        20.do { |i|
            var x = i * (width / 19);
            var freq = 1760;  // Constant high frequency
            traj4.add((x: x, y: freq.linlin(7500, 20, 0, height), freq: freq));
        };
        trajectories.add(traj4);
        
        // Amplitude envelope: Constant loud
        amplitudeEnvelopes.add(List[
            (x: 0, amp: 0.9),        // Loud throughout
            (x: 600, amp: 0.9)
        ]);
        
        // Store trajectories and envelopes
        data[\trajectories] = trajectories;
        data[\amplitudeEnvelopes] = amplitudeEnvelopes;
        
        "Created 4 test trajectories with different amplitude envelopes:".postln;
        "- Trajectory 0: Fade In (dark blue → bright red)".postln;
        "- Trajectory 1: Fade Out (bright red → dark blue)".postln;
        "- Trajectory 2: ADSR (dark → bright → medium → medium → dark)".postln;
        "- Trajectory 3: Constant Loud (consistently bright red)".postln;
    };
    
    // Function to test amplitude visual representation
    testAmplitudeVisualAudio = {
        var state = ~nUPIC[\ui][\state];
        var data = ~nUPIC[\data];
        
        "Testing amplitude visual and audio representation...".postln;
        
        // Ensure we're zoomed out to see full trajectories
        if(~nUPIC[\ui][\zoomToFull].notNil) {
            ~nUPIC[\ui][\zoomToFull].value;
            "Zoomed out to full view".postln;
        };
        
        // Set playback duration to 5 seconds for easy testing
        state[\playDuration] = 5.0;
        if(state[\controls].notNil and: { state[\controls][\durationControl].notNil }) {
            { state[\controls][\durationControl].value = 5.0 }.defer;
        };
        
        // Refresh display to show colored trajectories
        { state[\drawView].refresh }.defer;
        
        // Report color expectations
        "Visual Color Guide (HSV mapping):".postln;
        "- Silent (amp 0.0): Dark Blue (hue ~0.67, low saturation/brightness)".postln;
        "- Quiet (amp 0.33): Cyan (hue ~0.5, medium saturation/brightness)".postln;
        "- Medium (amp 0.66): Yellow (hue ~0.17, high saturation/brightness)".postln;
        "- Loud (amp 1.0): Bright Red (hue 0.0, full saturation/brightness)".postln;
        "";
        "Expected Visual Results:".postln;
        "- Trajectory 0 (top): Should transition from dark blue → cyan → yellow → red".postln;
        "- Trajectory 1 (upper-mid): Should transition from red → yellow → cyan → dark blue".postln;
        "- Trajectory 2 (lower-mid): Should show dark → red → yellow → yellow → dark".postln;
        "- Trajectory 3 (bottom): Should be consistently bright red throughout".postln;
    };
    
    // Function to test zoomed out view behavior
    testZoomedOutView = {
        "Testing zoomed out amplitude behavior...".postln;
        
        // Ensure horizontal zoom is at minimum (full view)
        if(~nUPIC[\ui][\setHorizontalZoomLevel].notNil) {
            ~nUPIC[\ui][\setHorizontalZoomLevel].value(0); // Minimum zoom = full view
        };
        
        // Ensure frequency zoom shows full range
        if(~nUPIC[\ui][\setFrequencyZoomLevel].notNil) {
            ~nUPIC[\ui][\setFrequencyZoomLevel].value(2); // Full frequency range
        };
        
        "Zoom Status:".postln;
        "- Horizontal: Full canvas width visible".postln;
        "- Frequency: Full 20Hz - 7500Hz range visible".postln;
        "- When zoomed out, entire trajectory envelope should control amplitude for whole trajectory".postln;
        "- Color should reflect amplitude envelope shape across entire visible trajectory".postln;
        
        // Test playback to hear amplitude differences
        "Starting test playback in 2 seconds...".postln;
        "Listen for:".postln;
        "- Trajectory 0: Should start silent and get louder".postln;  
        "- Trajectory 1: Should start loud and get quieter".postln;
        "- Trajectory 2: Should start quiet, get loud quickly, settle to medium, then fade".postln;
        "- Trajectory 3: Should be consistently loud throughout".postln;
        
        {
            if(~nUPIC[\ui][\startPlayback].notNil) {
                ~nUPIC[\ui][\startPlayback].value;
                "Test playback started - listen to amplitude differences".postln;
            };
        }.defer(2.0);
    };
    
    // Execute test sequence
    createTestTrajectories.value;
    1.0.wait;
    testAmplitudeVisualAudio.value;
    1.0.wait;
    testZoomedOutView.value;
    
    "Amplitude envelope test setup complete!".postln;
    "".postln;
    "MANUAL VERIFICATION STEPS:".postln;
    "1. Look at the drawing canvas - trajectories should show color gradients based on amplitude".postln;
    "2. Listen to playback - audio volume should match the amplitude envelopes".postln; 
    "3. Open amplitude editor (A key) to see/edit envelopes for selected trajectories".postln;
    "4. Try different zoom levels to verify amplitude behavior stays consistent".postln;
    "".postln;
    "EXPECTED BEHAVIOR:".postln;
    "- Visual: Colors change smoothly from blue (quiet) to red (loud) along each trajectory".postln;
    "- Audio: Volume follows the visual color - red sections should sound louder".postln;
    "- Zoomed out: Entire trajectory uses its amplitude envelope for both visual and audio".postln;
    
}.defer(2.0);
)
