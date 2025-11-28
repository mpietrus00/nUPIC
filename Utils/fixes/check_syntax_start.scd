// Quick syntax check for START_NUPIC.scd
(
try {
    var path = ~nUPIC_basePath +/+ "START_NUPIC.scd";
    if(path.isNil) {
        path = "START_NUPIC.scd";
    };
    
    "Checking syntax of START_NUPIC.scd...".postln;
    
    // Read file content
    var file = File(path, "r");
    if(file.isOpen) {
        var content = file.readAllString;
        file.close;
        
        // Try to interpret the content
        content.interpret;
        "✓ Syntax check passed!".postln;
    } {
        "✗ Could not open file".postln;
    };
} { |error|
    "✗ Syntax error found:".postln;
    error.errorString.postln;
    "".postln;
    "Line number info:".postln;
    error.postln;
};
)