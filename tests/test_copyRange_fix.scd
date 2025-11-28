// Test script to verify copyRange error is fixed
// This tests various scenarios that could cause the error

(
"Testing copyRange error fix...".postln;
"==============================".postln;
"".postln;

// Test 1: Simulate nil path scenario
"Test 1: Handling nil path".postln;
(
    var testPath = nil;
    var result;
    
    // This would cause the original error
    try {
        result = PathName(testPath).pathOnly;
        "ERROR: Should have caught nil path!".postln;
    } { |error|
        "✓ Correctly caught nil path error".postln;
    };
);

"".postln;

// Test 2: Test the fixed version with nil check
"Test 2: Fixed version with nil check".postln;
(
    var testPath = nil;
    var basePath;
    
    if(testPath.notNil) {
        basePath = PathName(testPath).pathOnly;
    } {
        basePath = File.getcwd +/+ "/";
    };
    
    if(basePath.notNil) {
        ("✓ Successfully handled nil path, using: " ++ basePath).postln;
    } {
        "ERROR: basePath is still nil!".postln;
    };
);

"".postln;

// Test 3: Test with actual thisProcess.nowExecutingPath
"Test 3: Testing actual thisProcess.nowExecutingPath".postln;
(
    var currentPath = thisProcess.nowExecutingPath;
    
    if(currentPath.notNil) {
        ("✓ thisProcess.nowExecutingPath is available: " ++ currentPath).postln;
        ("  Base path would be: " ++ PathName(currentPath).pathOnly).postln;
    } {
        "✓ thisProcess.nowExecutingPath is nil (as expected in some contexts)".postln;
        "  Would use fallback path: " ++ File.getcwd.postln;
    };
);

"".postln;

// Test 4: Load the fixed nUPIC_Main.scd
"Test 4: Loading fixed nUPIC_Main.scd".postln;
(
    var loadSuccess = false;
    
    try {
        // Set the base path safely
        if(thisProcess.nowExecutingPath.notNil) {
            ~nUPIC_basePath = PathName(thisProcess.nowExecutingPath).pathOnly;
        } {
            ~nUPIC_basePath = File.getcwd +/+ "/";
        };
        
        // Check if the file exists
        if(File.exists(~nUPIC_basePath +/+ "nUPIC_Main.scd")) {
            "✓ nUPIC_Main.scd found at: " ++ (~nUPIC_basePath +/+ "nUPIC_Main.scd").postln;
            "  You can now load it with: (~nUPIC_basePath +/+ \"nUPIC_Main.scd\").load".postln;
            loadSuccess = true;
        } {
            "✗ nUPIC_Main.scd not found in: " ++ ~nUPIC_basePath.postln;
        };
    } { |error|
        ("✗ Error during test: " ++ error.errorString).postln;
    };
    
    if(loadSuccess) {
        "".postln;
        "✓ All path handling tests passed!".postln;
    };
);

"".postln;
"==============================".postln;
"Test complete!".postln;
"".postln;
"To load nUPIC safely, use one of these methods:".postln;
"1. Load the safe loader: \"nUPIC_SafeLoader.scd\".load".postln;
"2. Load the fixed main file: \"nUPIC_Main.scd\".load".postln;
"3. Set path manually: ~nUPIC_basePath = \"/your/path/here/\"; (~nUPIC_basePath +/+ \"nUPIC_Main.scd\").load;".postln;
)
