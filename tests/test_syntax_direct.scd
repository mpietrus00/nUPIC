// Test START_NUPIC.scd syntax by reading it directly
(
try {
    var path = "/Users/marcinpietruszewski/nUPIC/START_NUPIC.scd";
    var file = File.open(path, "r");
    
    if(file.isOpen) {
        var content = "";
        var line;
        
        // Read file line by line to avoid _FileLength issue
        while { 
            line = file.getLine;
            line.notNil 
        } {
            content = content ++ line ++ "\n";
        };
        file.close;
        
        "File read successfully, checking syntax...".postln;
        content.compile;
        "✓ Syntax check passed!".postln;
        "You can now try: \"START_NUPIC.scd\".load".postln;
        
    } {
        "Could not open file".postln;
    };
} { |error|
    "Syntax error found:".postln;
    error.errorString.postln;
    if(error.errorString.contains("unexpected VAR")) {
        "The 'unexpected VAR' error suggests there's still a problematic var declaration.".postln;
        "Let me try to find it...".postln;
    };
};
)