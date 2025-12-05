// SpatialPlayback - Clean playback with proper spatial envelope handling
// Uses SpatialModel for all pan calculations

(
// Load SpatialModel if not loaded
if(~nUPIC[\spatial].isNil) {
    (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "../Model/SpatialModel.scd").load;
};

~nUPIC[\playback] = ~nUPIC[\playback] ? IdentityDictionary.new;

// Main playback function using SpatialModel
~nUPIC[\playback][\startWithSpatial] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var duration = state[\playDuration] ? 10;
    var numTrajectories;

    // Stop existing playback
    ~nUPIC[\playback][\stop].value;

    if(data[\trajectories].isNil or: { data[\trajectories].size == 0 }) {
        "No trajectories to play".postln;
        ^nil;
    };

    numTrajectories = data[\trajectories].size;
    ("Starting playback: " ++ numTrajectories ++ " trajectories, " ++ duration ++ "s").postln;

    // Create synth group
    state[\synthGroup] = Group.new;
    state[\synths] = List.new;
    state[\isPlaying] = true;

    // Initialize spatial playback
    ~nUPIC[\spatial][\Playback][\init].value;
    ~nUPIC[\spatial][\Playback][\duration] = duration;

    fork {
        // Create synths for each trajectory
        data[\trajectories].do { |traj, i|
            var synthDefName, numChannels, params, synth;
            var firstPoint, startFreq;

            // Get SynthDef for this trajectory
            synthDefName = if(data[\trajectorySynthDefs].notNil and: {
                i < data[\trajectorySynthDefs].size and: {
                    data[\trajectorySynthDefs][i].notNil
                }
            }) {
                data[\trajectorySynthDefs][i]
            } {
                defaults[\defaultSynthDef] ? \upicWavetable
            };

            // Get starting frequency
            if(traj.size > 0) {
                firstPoint = traj[0];
                startFreq = firstPoint[\freq] ? firstPoint.y ? 440;
            } {
                startFreq = 440;
            };

            // Build params
            params = [
                \freq, startFreq,
                \amp, 0,  // Start silent
                \pan, 0,
                \gate, 1,
                \numSynths, numTrajectories
            ];

            // Add wavetable buffer
            if(synthDefName.asString.contains("upicWavetable") and: {
                ~nUPIC_wavetableBuffer.notNil
            }) {
                params = params ++ [\bufnum, ~nUPIC_wavetableBuffer.bufnum];
            };

            // Create synth
            try {
                synth = Synth(synthDefName, params, state[\synthGroup]);
                state[\synths].add(synth);
                ~nUPIC[\spatial][\Playback][\synths].add(synth);
                ("Synth " ++ i ++ ": " ++ synthDefName).postln;
            } { |error|
                ("Error creating synth " ++ i ++ ": " ++ error).postln;
                state[\synths].add(nil);
                ~nUPIC[\spatial][\Playback][\synths].add(nil);
            };
        };

        0.1.wait;  // Let synths initialize

        // Playback loop
        block { |break|
            var startTime = Main.elapsedTime;
            var frameTime = 1/60;
            var canvasWidth = state[\drawView].bounds.width;

            while { state[\isPlaying] and: { (Main.elapsedTime - startTime) < duration } } {
                var currentTime = Main.elapsedTime - startTime;
                var globalTimeNorm = currentTime / duration;

                // Update each trajectory
                data[\trajectories].do { |traj, i|
                    var synth = state[\synths][i];

                    if(synth.notNil and: { traj.size > 0 }) {
                        var firstPoint = traj[0];
                        var lastPoint = traj.last;
                        var trajStartNorm = firstPoint.x / canvasWidth;
                        var trajEndNorm = lastPoint.x / canvasWidth;

                        // Check if we're within trajectory time range
                        if(globalTimeNorm >= trajStartNorm and: { globalTimeNorm <= trajEndNorm }) {
                            var trajTimeNorm = (globalTimeNorm - trajStartNorm) / (trajEndNorm - trajStartNorm);
                            var freq, amp, pan;

                            trajTimeNorm = trajTimeNorm.clip(0, 1);

                            // Interpolate frequency
                            freq = ~nUPIC[\playback][\interpolateFreq].value(traj, trajTimeNorm);

                            // Get pan from spatial envelope
                            pan = ~nUPIC[\spatial][\Playback][\envelopes][i][\getPanAt].value(trajTimeNorm);

                            // Set amplitude (could use amplitude envelope too)
                            amp = 0.2;

                            synth.set(\freq, freq, \amp, amp, \pan, pan);
                        } {
                            // Outside trajectory - silence
                            synth.set(\amp, 0);
                        };
                    };
                };

                // Update UI
                state[\playbackPosition] = currentTime;
                if(state[\drawView].notNil) {
                    { state[\drawView].refresh }.defer;
                };

                frameTime.wait;
            };
        };

        // Cleanup
        ~nUPIC[\playback][\stop].value;
    };
};

// Helper: interpolate frequency along trajectory
~nUPIC[\playback][\interpolateFreq] = { |traj, timeNorm|
    var result = 440;
    var index = (timeNorm * (traj.size - 1)).floor.asInteger;
    var nextIndex = (index + 1).min(traj.size - 1);
    var localT = (timeNorm * (traj.size - 1)) - index;

    if(index >= 0 and: { index < traj.size }) {
        var pt1 = traj[index];
        var pt2 = traj[nextIndex];
        var freq1 = pt1[\freq] ? pt1.y ? 440;
        var freq2 = pt2[\freq] ? pt2.y ? 440;
        result = freq1 + (localT * (freq2 - freq1));
    };

    result;
};

// Stop playback
~nUPIC[\playback][\stop] = {
    var state = ~nUPIC[\ui][\state];

    state[\isPlaying] = false;

    // Release all synths
    if(state[\synths].notNil) {
        state[\synths].do { |synth|
            if(synth.notNil) {
                synth.set(\gate, 0);
            };
        };
        state[\synths] = List.new;
    };

    // Clear group
    if(state[\synthGroup].notNil) {
        state[\synthGroup].free;
        state[\synthGroup] = nil;
    };

    // Clear spatial playback synths
    if(~nUPIC[\spatial].notNil and: { ~nUPIC[\spatial][\Playback].notNil }) {
        ~nUPIC[\spatial][\Playback][\synths] = List.new;
    };

    "Playback stopped".postln;
};

"✓ SpatialPlayback loaded".postln;
"  Use: ~nUPIC[\playback][\startWithSpatial].value".postln;
)
