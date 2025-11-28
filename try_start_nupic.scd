// Try to load START_NUPIC.scd and capture any errors
(
"Attempting to load START_NUPIC.scd...".postln;
try {
    "START_NUPIC.scd".load;
    "✓ START_NUPIC.scd loaded successfully!".postln;
} { |error|
    "✗ Error loading START_NUPIC.scd:".postln;
    error.errorString.postln;
    "".postln;
    if(error.errorString.contains("unexpected VAR")) {
        "This is still the original syntax error.".postln;
        "The issue might be in a file that START_NUPIC loads.".postln;
    } {
        "This is a different error - progress!".postln;
    };
};
)