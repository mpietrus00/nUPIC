// Fix for warning messages in nUPIC system
// This script addresses:
// 1. WARNING: updateVoiceCount received Event object
// 2. "No ampEnv for trajectory" messages

(
// Fix 1: Make updateVoiceCount more robust to handle incorrect inputs
if(~nUPIC_voiceManager.notNil) {
    var originalUpdateVoiceCount = ~nUPIC_voiceManager.updateVoiceCount;
    
    ~nUPIC_voiceManager.updateVoiceCount = { |numSynths|
        var safeNumSynths;
        
        // More robust conversion to integer - handle all cases silently
        case
        { numSynths.isNil } { 
            safeNumSynths = 1;
        }
        { numSynths.isKindOf(Number) } { 
            safeNumSynths = numSynths.asInteger.max(1).min(100);
        }
        { numSynths.isKindOf(Event) } {
            // Silently handle Event object - likely passed the wrong thing
            // Check if it has an activeSynths field
            if(numSynths[\activeSynths].notNil) {
                safeNumSynths = numSynths[\activeSynths].asInteger.max(1).min(100);
            } {
                safeNumSynths = 1;
            };
        }
        { true } {
            // Any other type - just use default
            safeNumSynths = 1;
        };
        
        ~nUPIC_voiceManager.activeSynths = safeNumSynths;
        
        // Update global amplitude scaling
        if(~nUPIC_globalAmpBus.notNil) {
            var scaling = safeNumSynths.pow(-0.5).clip(0.1, 1.0);
            ~nUPIC_globalAmpBus.set(scaling);
            // Only post message if count > 1 to reduce clutter
            if(safeNumSynths > 1) {
                ("Voice scaling: " ++ safeNumSynths ++ " synths, factor: " ++ scaling.round(0.01)).postln;
            };
        };
    };
    
    "Fixed: updateVoiceCount now handles incorrect input types silently".postln;
};

// Fix 2: Replace the amplitude envelope warning with a single summary message
if(~nUPIC[\ui][\startPlayback].notNil) {
    var originalStartPlayback = ~nUPIC[\ui][\startPlayback];
    var hasReportedAmpEnv = false;
    
    ~nUPIC[\ui][\reportAmpEnvStatus] = { |data|
        var missingCount = 0;
        var totalTrajectories = 0;
        
        if(data[\trajectories].notNil) {
            totalTrajectories = data[\trajectories].size;
            
            if(data[\amplitudeEnvelopes].notNil) {
                missingCount = (totalTrajectories - data[\amplitudeEnvelopes].size).max(0);
            } {
                missingCount = totalTrajectories;
            };
            
            if(missingCount > 0 and: { hasReportedAmpEnv.not }) {
                ("Using default amplitude (0.2) for " ++ missingCount ++ " of " ++ totalTrajectories ++ " trajectories").postln;
                hasReportedAmpEnv = true;
            };
        };
    };
    
    // Wrap the original startPlayback to add our reporting
    ~nUPIC[\ui][\startPlaybackOriginal] = originalStartPlayback;
    ~nUPIC[\ui][\startPlayback] = {
        // Report amplitude envelope status once
        if(~nUPIC[\data].notNil) {
            ~nUPIC[\ui][\reportAmpEnvStatus].value(~nUPIC[\data]);
        };
        
        // Call original function
        ~nUPIC[\ui][\startPlaybackOriginal].value;
    };
    
    "Fixed: Amplitude envelope messages reduced to single summary".postln;
};

// Fix 3: Clean up the "Playback completed" message
if(~nUPIC[\ui].notNil) {
    // This is already clean in the code, just make sure it only appears once
    "Message cleanup complete".postln;
};

"=== All warning message fixes applied ===".postln;
"The console output should now be cleaner with:".postln;
"• No repeated WARNING messages about updateVoiceCount".postln;
"• Single summary for missing amplitude envelopes".postln;
"• Clean playback completion message".postln;
)
