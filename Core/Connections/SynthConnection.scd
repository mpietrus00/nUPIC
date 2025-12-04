// SynthConnection - Connects TrajectoryModel to Synths using Connection quark
// Handles reactive updates from model to synth parameters

(
~nUPIC[\connections] = ~nUPIC[\connections] ? IdentityDictionary.new;

// SynthConnection - links a trajectory model to a running synth
~nUPIC[\connections][\SynthConnection] = { |trajectoryModel, synth|
    var conn = IdentityDictionary.new;

    conn[\model] = trajectoryModel;
    conn[\synth] = synth;
    conn[\connected] = false;

    // Update function called when model changes
    conn[\update] = { |theModel, what, value|
        if(conn[\connected] and: { conn[\synth].notNil }) {
            case
            { what == \freq } {
                conn[\synth].set(\freq, value);
            }
            { what == \amp } {
                conn[\synth].set(\amp, value);
            }
            { what == \pan } {
                conn[\synth].set(\pan, value);
            }
            { what == \gate } {
                conn[\synth].set(\gate, value);
            }
            { what == \spatialEnvelope } {
                // Spatial envelope changed - will be applied during playback
            };
        };
    };

    // Connect to model
    conn[\connect] = {
        if(conn[\connected].not) {
            conn[\model][\addDependant].value(conn);
            conn[\connected] = true;
        };
        conn;
    };

    // Disconnect from model
    conn[\disconnect] = {
        if(conn[\connected]) {
            conn[\model][\removeDependant].value(conn);
            conn[\connected] = false;
        };
        conn;
    };

    // Free connection and synth
    conn[\free] = {
        conn[\disconnect].value;
        if(conn[\synth].notNil) {
            conn[\synth].set(\gate, 0);
            conn[\synth] = nil;
        };
    };

    // Set synth parameter with proper pan conversion
    conn[\setPan] = { |timeNorm|
        if(conn[\synth].notNil) {
            var pan = conn[\model][\getPanAtTime].value(timeNorm);
            conn[\synth].set(\pan, pan);
        };
    };

    conn;
};

// PlaybackEngine - manages playback with proper synth connections
~nUPIC[\connections][\PlaybackEngine] = {
    var engine = IdentityDictionary.new;

    engine[\connections] = List.new;
    engine[\synths] = List.new;
    engine[\isPlaying] = false;
    engine[\playbackRoutine] = nil;

    // Create synths and connections for all trajectories
    engine[\prepare] = { |trajectoryModels, synthGroup|
        // Clean up existing
        engine[\stop].value;

        trajectoryModels.do { |model, i|
            var synthDefName = model[\synthDefName];
            var params = [
                \freq, 440,
                \amp, 0,
                \pan, 0,
                \gate, 1,
                \numSynths, trajectoryModels.size
            ];

            // Add wavetable buffer if available
            if(synthDefName.asString.contains("upicWavetable") and: {
                ~nUPIC_wavetableBuffer.notNil
            }) {
                params = params ++ [\bufnum, ~nUPIC_wavetableBuffer.bufnum];
            };

            // Create synth
            try {
                var synth = Synth(synthDefName, params, synthGroup);
                var conn = ~nUPIC[\connections][\SynthConnection].value(model, synth);
                conn[\connect].value;

                engine[\synths].add(synth);
                engine[\connections].add(conn);

                ("Created synth " ++ i ++ " with " ++ synthDefName).postln;
            } { |error|
                ("Error creating synth " ++ i ++ ": " ++ error).postln;
            };
        };
    };

    // Start playback
    engine[\start] = { |duration = 10|
        if(engine[\isPlaying].not and: { engine[\synths].size > 0 }) {
            engine[\isPlaying] = true;

            engine[\playbackRoutine] = fork {
                var startTime = Main.elapsedTime;
                var frameTime = 1/60;  // 60 fps updates

                while { engine[\isPlaying] and: { (Main.elapsedTime - startTime) < duration } } {
                    var currentTime = Main.elapsedTime - startTime;
                    var timeNorm = currentTime / duration;

                    // Update all synth pans from spatial envelopes
                    engine[\connections].do { |conn, i|
                        var model = conn[\model];
                        var points = model[\points];

                        if(points.notNil and: { points.size > 0 }) {
                            var firstX = points.first.x;
                            var lastX = points.last.x;
                            var trajLength = lastX - firstX;
                            var trajStart = firstX / 800;  // Normalize to 0-1
                            var trajEnd = lastX / 800;
                            var trajTimeNorm;

                            // Check if we're within this trajectory's time range
                            if(timeNorm >= trajStart and: { timeNorm <= trajEnd }) {
                                trajTimeNorm = (timeNorm - trajStart) / (trajEnd - trajStart);
                                trajTimeNorm = trajTimeNorm.clip(0, 1);

                                // Get interpolated values
                                conn[\setPan].value(trajTimeNorm);

                                // Set amplitude (could also use envelope)
                                conn[\synth].set(\amp, 0.2);
                            } {
                                // Outside trajectory range - silence
                                conn[\synth].set(\amp, 0);
                            };
                        };
                    };

                    frameTime.wait;
                };

                engine[\stop].value;
            };
        };
    };

    // Stop playback
    engine[\stop] = {
        engine[\isPlaying] = false;

        if(engine[\playbackRoutine].notNil) {
            engine[\playbackRoutine].stop;
            engine[\playbackRoutine] = nil;
        };

        // Release all synths
        engine[\connections].do { |conn|
            conn[\free].value;
        };
        engine[\connections] = List.new;
        engine[\synths] = List.new;
    };

    engine;
};

"✓ SynthConnection loaded".postln;
"  - Reactive synth parameter updates".postln;
"  - PlaybackEngine with spatial envelope support".postln;
)
