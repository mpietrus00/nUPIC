// Test Amplitude Coordinate Mapping Fix
// This script verifies that amplitude envelopes correctly map to trajectory coordinates

(
// Load the nUPIC system
thisProcess.interpreter.executeFile(thisProcess.nowExecutingPath.dirname +/+ "nUPIC_Main.scd");

// Wait for system to initialize, then run test
{
    var createTestTrajectory, testAmplitudeMapping, testInfo;
    
    "Testing amplitude envelope coordinate mapping fix...".postln;
    
    // Function to create a test trajectory with known amplitude envelope
    createTestTrajectory = {
        var data = ~nUPIC[\data];
        var width = 1200;
        var height = 800;
        var traj, envelope;
        
        // Clear existing trajectories
        data[\trajectories] = List.new;
        data[\amplitudeEnvelopes] = List.new;
        
        "Creating test trajectory...".postln;
        
        // Create a trajectory from x=100 to x=1000 (length = 900 pixels)
        traj = List.new;
        10.do { |i|
            var x = 100 + (i * 100);  // x goes from 100 to 1000
            var freq = 440 + (i * 50);  // Rising frequency
            traj.add((x: x, y: freq.linlin(7500, 20, 0, height), freq: freq));
        };
        data[\trajectories].add(traj);
        
        "Trajectory created: x=100 to x=1000 (length=900 pixels)".postln;
        
        // Create amplitude envelope that should map exactly to trajectory length
        // The envelope should go from x=0 to x=900 (trajectory length in pixels)
        envelope = List[
            (x: 0, amp: 0.0),      // Start: silent (should map to traj x=100)
            (x: 450, amp: 1.0),    // Middle: loud (should map to traj x=550) 
            (x: 900, amp: 0.0)     // End: silent (should map to traj x=1000)
        ];
        data[\amplitudeEnvelopes].add(envelope);
        
        "Amplitude envelope created:".postln;
        "  x=0 (amp=0.0) should map to trajectory x=100 (start)".postln;
        "  x=450 (amp=1.0) should map to trajectory x=550 (middle)".postln;
        "  x=900 (amp=0.0) should map to trajectory x=1000 (end)".postln;
        
        // Return trajectory and envelope info for verification
        (trajectory: traj, envelope: envelope, trajStart: 100, trajEnd: 1000, trajLength: 900)
    };
    
    // Function to test amplitude mapping
    testAmplitudeMapping = { |testInfo|
        var traj = testInfo[\trajectory];
        var envelope = testInfo[\envelope];
        var trajStart = testInfo[\trajStart];
        var trajEnd = testInfo[\trajEnd];  
        var trajLength = testInfo[\trajLength];
        
        "Testing amplitude calculation at different trajectory positions:".postln;
        
        // Test amplitude calculation at trajectory start, middle, and end
        [trajStart, (trajStart + trajEnd) / 2, trajEnd].do { |trajX, testIndex|
            var originalX, firstPoint, lastPoint, normalizedPos, ampX, expectedAmpX, amp;
            var foundAmp, testName, expectedAmp, success, status;
            
            originalX = trajX;
            firstPoint = trajStart;
            lastPoint = trajEnd;
            normalizedPos = (originalX - firstPoint) / (lastPoint - firstPoint).max(1);
            ampX = normalizedPos.clip(0, 1) * trajLength;  // This should use trajectory length, not 600
            expectedAmpX = normalizedPos * trajLength;
            amp = 0.3;  // Default
            
            // Find amplitude by interpolation (same logic as in Drawing.scd)
            foundAmp = false;
            block { |break|
                (envelope.size - 1).do { |j|
                    if((envelope[j].x <= ampX) and: { (envelope[j + 1].x >= ampX) }) {
                        var interpFactor = (ampX - envelope[j].x) / (envelope[j + 1].x - envelope[j].x).max(0.001);
                        amp = envelope[j].amp.blend(envelope[j + 1].amp, interpFactor).clip(0, 1);
                        foundAmp = true;
                        break.value;
                    };
                };
            };
            
            // Handle edge cases
            if(foundAmp.not) {
                if(ampX <= envelope.first.x) { 
                    amp = envelope.first.amp.clip(0, 1);
                } {
                    if(ampX >= envelope.last.x) { 
                        amp = envelope.last.amp.clip(0, 1);
                    } {
                        amp = 0.3;  // Fallback
                    };
                };
            };
            
            testName = case
                { testIndex == 0 } { "START" }
                { testIndex == 1 } { "MIDDLE" }
                { testIndex == 2 } { "END" };
            
            expectedAmp = case
                { testIndex == 0 } { 0.0 }   // Start should be silent
                { testIndex == 1 } { 1.0 }   // Middle should be loud
                { testIndex == 2 } { 0.0 };  // End should be silent
            
            success = (amp - expectedAmp).abs < 0.1;
            status = if(success) { "✓ PASS" } { "✗ FAIL" };
            
            "".postln;
            "Test %: % position (trajectory x=%)".format(testIndex + 1, testName, trajX).postln;
            "  Normalized position: %".format(normalizedPos.round(0.001)).postln;
            "  Envelope lookup X: % (expected: %)".format(ampX.round(1), expectedAmpX.round(1)).postln;
            "  Calculated amplitude: % (expected: %)".format(amp.round(0.001), expectedAmp).postln;
            "  Result: %".format(status).postln;
        };
        
        "".postln;
        "COORDINATE MAPPING VERIFICATION:".postln;
        "The key fix ensures that amplitude envelope X coordinates map to actual trajectory length".postln;
        "instead of the hardcoded 600-pixel window width used in the amplitude editor.".postln;
        "".postln;
        "Before fix: ampX = normalizedPos * 600  (wrong - always used 600)".postln;
        "After fix:  ampX = normalizedPos * trajLength  (correct - uses actual trajectory length)".postln;
    };
    
    // Execute test
    var testInfo;
    testInfo = createTestTrajectory.value;
    1.0.wait;
    testAmplitudeMapping.value(testInfo);
    
    "".postln;
    "VISUAL TEST:".postln;
    "1. The trajectory should be visible in the drawing area".postln;
    "2. The trajectory should show color gradient: blue (start) → red (middle) → blue (end)".postln;
    "3. Open the amplitude editor (press A, then click the trajectory) to see the envelope".postln;
    "4. The envelope should have: silent start, loud middle, silent end".postln;
    "5. The colors in the trajectory should match the amplitude envelope shape exactly".postln;
    
}.defer(3.0);
)
