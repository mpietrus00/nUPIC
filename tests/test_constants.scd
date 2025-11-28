// Test Constants.scd loading in isolation
(
"Testing Constants.scd loading...".postln;

// Clear any existing nUPIC namespace
~nUPIC = nil;

try {
    // Load just the constants file
    (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "Core/Constants.scd").load;
    
    if(~nUPIC.notNil) {
        "✓ Constants loaded successfully".postln;
        ("Keys in nUPIC: " ++ ~nUPIC.keys.asArray).postln;
        
        if(~nUPIC[\constants].notNil) {
            "✓ Constants dictionary created".postln;
            ("Number of constants: " ++ ~nUPIC[\constants].keys.size).postln;
        } {
            "✗ Constants dictionary missing".postln;
        };
        
        if(~nUPIC[\colors].notNil) {
            "✓ Colors dictionary created".postln;
        } {
            "✗ Colors dictionary missing".postln;
        };
        
        if(~nUPIC[\defaults].notNil) {
            "✓ Defaults dictionary created".postln;
        } {
            "✗ Defaults dictionary missing".postln;
        };
        
        if(~nUPIC[\gridSystems].notNil) {
            "✓ Grid systems dictionary created".postln;
        } {
            "✗ Grid systems dictionary missing".postln;
        };
        
        if(~nUPIC[\amplitudePresets].notNil) {
            "✓ Amplitude presets dictionary created".postln;
        } {
            "✗ Amplitude presets dictionary missing".postln;
        };
        
    } {
        "✗ nUPIC namespace not created".postln;
    };
    
} { |error|
    ("✗ Failed to load Constants.scd: " ++ error.errorString).postln;
    error.postProtectedBacktrace;
};
)
