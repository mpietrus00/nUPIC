// Fix for playback not stopping properly when spacebar is pressed
// This ensures all synths are properly freed and the synth group is cleaned

(
// Store the original stopPlayback function
if(~nUPIC[\ui][\stopPlaybackOriginal].isNil) {
    ~nUPIC[\ui][\stopPlaybackOriginal] = ~nUPIC[\ui][\stopPlayback];
};

// Replace with a more robust version
~nUPIC[\ui][\stopPlayback] = {
    var state = ~nUPIC[\ui][\state];
    
    "STOPPING PLAYBACK - Cleaning up all synths...".postln;
    
    if(state.isNil) { 
        "State is nil - nothing to stop".postln;
        ^nil 
    };
    
    // 1. Set playing flag to false immediately
    state[\isPlaying] = false;
    
    // 2. Stop the playback task
    if(state[\playbackTask].notNil) {
        state[\playbackTask].stop;
        state[\playbackTask] = nil;
        "Playback task stopped".postln;
    };
    
    // 3. Free all tracked synths with both gate and free methods
    if(state[\synths].notNil) {
        ("Freeing " ++ state[\synths].size ++ " tracked synths...").postln;
        state[\synths].do { |synth, i|
            if(synth.notNil) {
                try {
                    // First try to set gate to trigger release
                    synth.set(\gate, 0);
                    // Then schedule immediate free to ensure cleanup
                    { synth.free }.defer(0.1);
                } { |error|
                    ("Error freeing synth " ++ i ++ ": " ++ error).postln;
                    // Force free even if there's an error
                    try { synth.free } { };
                };
            };
        };
        state[\synths].clear;
        "Tracked synths cleared".postln;
    };
    
    // 4. Free the entire synth group to catch any orphaned synths
    if(state[\synthGroup].notNil) {
        try {
            state[\synthGroup].freeAll;
            // Recreate the group for next playback
            { state[\synthGroup] = Group.new(s) }.defer(0.2);
            "Synth group freed and recreated".postln;
        } { |error|
            ("Error freeing synth group: " ++ error).postln;
        };
    };
    
    // 5. Reset playback position
    state[\playbackPosition] = 0;
    
    // 6. Stop voice manager and master limiter
    if(~nUPIC_voiceManager.notNil) {
        ~nUPIC_voiceManager.stopMasterLimiter.value;
        ~nUPIC_voiceManager.updateVoiceCount.value(0);
        "Voice manager reset".postln;
    };
    
    // 7. Update UI - make sure play button shows "Play" state
    if(state[\controls].notNil and: { state[\controls][\playButton].notNil }) {
        { 
            state[\controls][\playButton].value = 0;
            state[\drawView].refresh if state[\drawView].notNil;
        }.defer;
    };
    
    // 8. Final safety measure - query and free any remaining synths on our group
    {
        if(state[\synthGroup].notNil) {
            s.sendMsg("/n_free", state[\synthGroup].nodeID);
        };
    }.defer(0.3);
    
    "Playback stopped completely".postln;
};

// Also improve the startPlayback to check for existing playback
if(~nUPIC[\ui][\startPlaybackOriginal].isNil) {
    ~nUPIC[\ui][\startPlaybackOriginal] = ~nUPIC[\ui][\startPlayback];
};

~nUPIC[\ui][\startPlayback] = {
    var state = ~nUPIC[\ui][\state];
    
    if(state.isNil) {
        "State not initialized".postln;
        ^nil;
    };
    
    // IMPORTANT: Stop any existing playback first
    if(state[\isPlaying] == true) {
        "Stopping existing playback before starting new one...".postln;
        ~nUPIC[\ui][\stopPlayback].value;
        // Wait a moment for cleanup
        {
            ~nUPIC[\ui][\startPlaybackOriginal].value;
        }.defer(0.3);
    } {
        // No existing playback, start normally
        ~nUPIC[\ui][\startPlaybackOriginal].value;
    };
};

// Create an emergency cleanup function
~nUPIC[\ui][\cleanupAllSynths] = {
    "Emergency cleanup - freeing all synths on server...".postln;
    
    // Nuclear option - free everything
    s.freeAll;
    
    // Reset state
    if(~nUPIC[\ui][\state].notNil) {
        ~nUPIC[\ui][\state][\isPlaying] = false;
        ~nUPIC[\ui][\state][\synths].clear if ~nUPIC[\ui][\state][\synths].notNil;
        ~nUPIC[\ui][\state][\playbackPosition] = 0;
        ~nUPIC[\ui][\state][\playbackTask] = nil;
        
        // Reset UI
        if(~nUPIC[\ui][\state][\controls].notNil and: { 
            ~nUPIC[\ui][\state][\controls][\playButton].notNil 
        }) {
            { ~nUPIC[\ui][\state][\controls][\playButton].value = 0 }.defer;
        };
    };
    
    "All synths freed, state reset".postln;
};

// Add a keyboard shortcut for emergency cleanup (Shift+ESC)
if(~nUPIC[\ui][\initializeKeyboard].notNil) {
    var originalKeyboard = ~nUPIC[\ui][\initializeKeyboard];
    
    ~nUPIC[\ui][\initializeKeyboard] = { |window|
        originalKeyboard.value(window);
        
        // Add to existing keyDownAction
        var originalKeyDown = window.view.keyDownAction;
        window.view.keyDownAction = { |view, char, mod, unicode, keycode|
            // Call original handler first
            originalKeyDown.value(view, char, mod, unicode, keycode);
            
            // Add Shift+ESC for emergency cleanup
            if(keycode == 53 and: { mod & 131072 > 0 }) { // ESC with Shift
                "SHIFT+ESC pressed - Emergency cleanup".postln;
                ~nUPIC[\ui][\cleanupAllSynths].value;
            };
        };
    };
};

"=== Playback stop fix applied ===".postln;
"The spacebar should now properly stop all playback.".postln;
"If synths still accumulate, press SHIFT+ESC for emergency cleanup.".postln;
"".postln;
"Test the fix:".postln;
"1. Start playback with spacebar".postln;
"2. Stop with spacebar - all sound should stop".postln;
"3. Start again - only new playback should be heard".postln;
)
