// nUPIC Safe Loader
// This script safely loads nUPIC regardless of execution context
// Handles cases where thisProcess.nowExecutingPath might be nil

(
// Function to safely get the base path
var getBasePath = {
    var path = nil;
    
    // Method 1: Try to get path from currently executing file
    if(thisProcess.nowExecutingPath.notNil) {
        path = PathName(thisProcess.nowExecutingPath).pathOnly;
        ("Base path from nowExecutingPath: " ++ path).postln;
    };
    
    // Method 2: Try to use Document.current if in IDE
    if(path.isNil and: { Document.respondsTo(\current) }) {
        try {
            if(Document.current.notNil and: { Document.current.path.notNil }) {
                path = PathName(Document.current.path).pathOnly;
                ("Base path from Document.current: " ++ path).postln;
            };
        } { |error|
            "Could not get path from Document.current".postln;
        };
    };
    
    // Method 3: Use working directory as fallback
    if(path.isNil) {
        path = File.getcwd +/+ "/";
        ("Base path from working directory: " ++ path).postln;
    };
    
    // Verify the path exists and contains nUPIC files
    if(File.exists(path +/+ "nUPIC_Main.scd").not) {
        "WARNING: nUPIC_Main.scd not found in base path".postln;
        "Please ensure you're running this from the nUPIC directory".postln;
        
        // Try to find nUPIC directory
        if(File.exists(File.getcwd +/+ "/nUPIC_Main.scd")) {
            path = File.getcwd +/+ "/";
            "Found nUPIC files in current directory".postln;
        } {
            // Ask user to specify path
            "".postln;
            "Could not automatically locate nUPIC files.".postln;
            "Please set the path manually:".postln;
            "~nUPIC_basePath = \"/path/to/nUPIC/\";".postln;
            "Then run: (~nUPIC_basePath +/+ \"nUPIC_Main.scd\").load;".postln;
            "".postln;
            nil; // Return nil to indicate failure
        };
    };
    
    path; // Return the path
};

"nUPIC Safe Loader".postln;
"==================".postln;

// Get the base path
~nUPIC_basePath = getBasePath.value;

if(~nUPIC_basePath.notNil) {
    ("nUPIC base path: " ++ ~nUPIC_basePath).postln;
    "".postln;
    
    // Load the main nUPIC file
    "Loading nUPIC_Main.scd...".postln;
    (~nUPIC_basePath +/+ "nUPIC_Main.scd").load;
} {
    "Failed to determine nUPIC base path.".postln;
    "Please load nUPIC manually by specifying the correct path.".postln;
};
)
