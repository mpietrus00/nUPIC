// Test trajectory sound with correct SynthDef
// This creates a test trajectory and plays it using the nUPIC system

(
// Check if nUPIC is loaded
if(~nUPIC.isNil) {
    "ERROR: nUPIC not loaded. Run START_NUPIC.scd first".postln;
} {
    // Add a simple test trajectory if none exist
    if(~nUPIC[\data].isNil or: { ~nUPIC[\data][\trajectories].isNil } or: { ~nUPIC[\data][\trajectories].size == 0 }) {
        "Creating test trajectory...".postln;
        
        // Initialize data structure if needed
        if(~nUPIC[\data].isNil) {
            ~nUPIC[\data] = ();
        };
        
        // Create a simple diagonal trajectory
        var testTraj = [];
        var numPoints = 50;
        var width = ~nUPIC[\constants][\defaultWidth] ? 1200;
        var height = ~nUPIC[\constants][\defaultHeight] ? 670;
        
        numPoints.do { |i|
            var x = (i / (numPoints - 1)) * width;
            var y = height * 0.5 + (sin(i * 0.2) * height * 0.3);  // Sine wave pattern
            var freq = y.linlin(0, height, 7500, 20);  // Map Y to frequency
            
            testTraj = testTraj.add((
                x: x,
                y: y,
                freq: freq
            ));
        };
        
        // Set the trajectory
        ~nUPIC[\data][\trajectories] = [testTraj];
        ~nUPIC[\data][\trajectorySynthDefs] = [\simpleGravObject];  // Use the correct SynthDef
        
        ("Test trajectory created with " ++ testTraj.size ++ " points").postln;
        ("Using SynthDef: \simpleGravObject").postln;
    } {
        ("Using existing " ++ ~nUPIC[\data][\trajectories].size ++ " trajectories").postln;
    };
    
    // Check available SynthDefs
    if(~nUPIC_SynthDefs.notNil) {
        "Available SynthDefs:".postln;
        ~nUPIC_SynthDefs[\available].do { |name|
            ("  • " ++ name).postln;
        };
        ("Default: " ++ ~nUPIC_SynthDefs[\default]).postln;
    };
    
    // Verify SynthDef exists
    if(SynthDescLib.global.synthDescs[\simpleGravObject].notNil) {
        "✓ \simpleGravObject SynthDef is loaded".postln;
    } {
        "✗ WARNING: \simpleGravObject SynthDef not found!".postln;
    };
    
    // Start playback
    "".postln;
    "Starting playback test...".postln;
    "Press SPACE in the nUPIC window to stop".postln;
    
    // Call the startPlayback function
    if(~nUPIC[\ui].notNil and: { ~nUPIC[\ui][\startPlayback].notNil }) {
        ~nUPIC[\ui][\startPlayback].value;
    } {
        "ERROR: Playback function not found. Is the UI loaded?".postln;
    };
}
)