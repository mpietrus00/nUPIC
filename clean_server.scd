// Clean up server and reset audio
// Removes all hanging synths and resets the server state

(
"Cleaning up server...".postln;

// Free all nodes on the server
s.freeAll;

// Clear any hanging synths in nUPIC state
if(~nUPIC.notNil and: { ~nUPIC[\ui].notNil } and: { ~nUPIC[\ui][\state].notNil }) {
    if(~nUPIC[\ui][\state][\synths].notNil) {
        ~nUPIC[\ui][\state][\synths].clear;
        "Cleared nUPIC synth array".postln;
    };
    
    // Reset playback state
    if(~nUPIC[\ui][\state][\isPlaying].notNil) {
        ~nUPIC[\ui][\state][\isPlaying] = false;
    };
};

// Wait a moment for cleanup
fork {
    0.5.wait;
    
    // Query server status
    s.queryAllNodes;
    
    0.5.wait;
    
    "Server cleaned!".postln;
    "".postln;
    "Current server status:".postln;
    ("  Sample rate: " ++ s.sampleRate ++ " Hz").postln;
    ("  Number of synths: " ++ s.numSynths).postln;
    ("  Number of groups: " ++ s.numGroups).postln;
    ("  Number of SynthDefs: " ++ s.numSynthDefs).postln;
    "".postln;
    
    // Reload synthdefs to ensure they're available
    if(File.exists("Audio/SynthDefs.scd")) {
        "Reloading SynthDefs...".postln;
        ("Audio/SynthDefs.scd").loadRelative;
        
        s.sync;
        
        if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ("Available synthdefs: " ++ ~nUPIC_SynthDefs[\available]).postln;
        };
    };
    
    "".postln;
    "Ready to play! You can now:".postln;
    "1. Try pressing play again in nUPIC".postln;
    "2. Or reload nUPIC: \"nUPIC_SafeLoader.scd\".load".postln;
};
)
