// Simple syntax check
(
"Checking IntuitiveZoomSystem.scd syntax...".postln;
try {
    "/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/UI/IntuitiveZoomSystem.scd".load;
    "✓ IntuitiveZoomSystem.scd loaded successfully".postln;
} { |error|
    "✗ ERROR in IntuitiveZoomSystem.scd:".postln;
    error.postln;
};

"Done.".postln;
)
