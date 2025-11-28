// Load nUPIC and run duration test
(
// Load the main nUPIC system first
"nUPIC_Main.scd".load;

// Wait a moment for initialization, then run the test
fork {
    2.wait; // Wait 2 seconds for nUPIC to initialize
    
    // Check if nUPIC is loaded
    if(~nUPIC.notNil) {
        "nUPIC system loaded successfully.".postln;
        
        // Load and run the duration test
        "test_duration_dynamic.scd".load;
        
        // Give instructions
        "\n=== DURATION TEST READY ===".postln;
        "To run the test:".postln;
        "1. Draw some trajectories in the nUPIC window".postln;
        "2. Execute: ~testDurationChange.value".postln;
        "3. Then click play - it should start at 10s duration".postln;
        "4. After 3 seconds, it will change to 30s duration".postln;
        "5. Watch the console for debug messages".postln;
        
    } {
        "ERROR: nUPIC system failed to load".postln;
    };
};
)
