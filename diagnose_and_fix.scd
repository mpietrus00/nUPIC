// Quick diagnostic and system reload for nUPIC
(
"=== nUPIC System Diagnostic and Fix ===".postln;

// Check server status
"Server running: ".post; s.serverRunning.postln;

// Check if SynthDefs exist
"Checking SynthDefs:".postln;
[\simpleGravObject, \percNoise, \auditoryDistortion].do { |name|
    var exists = try { name.asSymbol.synthDefExists } { false };
    ("  " ++ name ++ ": " ++ if(exists) { "✓ loaded" } { "✗ missing" }).postln;
};

// Check nUPIC system state
"nUPIC system state:".postln;
("  ~nUPIC exists: " ++ ~nUPIC.notNil).postln;
if(~nUPIC.notNil) {
    ("  Data: " ++ ~nUPIC[\data].notNil).postln;
    ("  UI: " ++ ~nUPIC[\ui].notNil).postln;
    ("  Constants: " ++ ~nUPIC[\constants].notNil).postln;
    if(~nUPIC[\data].notNil) {
        ("  Trajectories: " ++ (~nUPIC[\data][\trajectories].size ? 0)).postln;
    };
    if(~nUPIC[\ui].notNil) {
        ("  Window open: " ++ (~nUPIC[\ui][\state][\window].notNil and: { 
            ~nUPIC[\ui][\state][\window].isClosed.not 
        })).postln;
    };
};

"".postln;
"=== Reloading nUPIC System ===".postln;

// Reload the main system
"nUPIC_Main.scd".loadRelative;
)
