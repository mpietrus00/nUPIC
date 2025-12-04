// SpatialModel - Uses Connection quark for reactive spatial data
// Connects spatial envelopes to synth pan parameters
//
// Requires: Quarks.install("Connection")

(
// Ensure Connection quark is loaded
if(\NumericControlValue.asClass.isNil) {
    "WARNING: Connection quark not loaded. Run: Quarks.install(\"Connection\")".postln;
};

~nUPIC[\spatial] = ~nUPIC[\spatial] ? IdentityDictionary.new;

// SpatialChannel - A ControlValue for channel position
// Wraps Connection quark's NumericControlValue if available
~nUPIC[\spatial][\SpatialChannel] = { |numChannels = 8, initialChannel = 0|
    var spatial = IdentityDictionary.new;

    spatial[\numChannels] = numChannels;
    spatial[\channel] = initialChannel;
    spatial[\dependants] = IdentitySet.new;

    // If Connection quark is available, use NumericControlValue
    if(\NumericControlValue.asClass.notNil) {
        spatial[\cv] = NumericControlValue(
            initialChannel,
            ControlSpec(0, numChannels - 1, \lin, 0.01, initialChannel)
        );

        // Forward changes from CV
        spatial[\cv].signal(\value).connectTo({
            spatial[\channel] = spatial[\cv].value;
            spatial[\notifyDependants].value(\channel, spatial[\channel]);
        });
    };

    // Notify dependants
    spatial[\notifyDependants] = { |what, value|
        spatial[\dependants].do { |dep|
            if(dep.respondsTo(\update)) {
                dep.update(spatial, what, value);
            };
        };
    };

    // Set channel
    spatial[\setChannel] = { |ch|
        spatial[\channel] = ch.clip(0, spatial[\numChannels] - 1);
        if(spatial[\cv].notNil) {
            spatial[\cv].value = spatial[\channel];
        };
        spatial[\notifyDependants].value(\channel, spatial[\channel]);
    };

    // Convert channel to pan for synth
    spatial[\toPan] = {
        if(~nUPIC[\utils].notNil and: { ~nUPIC[\utils][\channelToPan].notNil }) {
            ~nUPIC[\utils][\channelToPan].value(spatial[\channel], spatial[\numChannels]);
        } {
            // Fallback if utils not loaded
            var numCh = spatial[\numChannels];
            var ch = spatial[\channel];
            if(numCh == 1) { 0 }
            { if(numCh == 2) { ch * 2 - 1 }
            { ch * 2 / numCh }};
        };
    };

    // Add/remove dependants
    spatial[\addDependant] = { |dep| spatial[\dependants].add(dep) };
    spatial[\removeDependant] = { |dep| spatial[\dependants].remove(dep) };

    spatial;
};

// SpatialEnvelope - Stores and interpolates spatial curve
~nUPIC[\spatial][\SpatialEnvelope] = { |numChannels = 8|
    var env = IdentityDictionary.new;

    env[\numChannels] = numChannels;
    env[\points] = List.new;  // List of (time: 0-1, channel: 0-n)
    env[\dependants] = IdentitySet.new;

    // Set points from raw envelope data
    env[\setPoints] = { |rawPoints, trajectoryLength|
        env[\points] = List.new;

        if(rawPoints.notNil and: { rawPoints.size > 0 }) {
            var firstX = rawPoints.first.x;
            var lastX = rawPoints.last.x;
            var length = (lastX - firstX).max(1);

            rawPoints.do { |pt|
                var timeNorm = (pt.x - firstX) / length;
                env[\points].add((time: timeNorm, channel: pt.channel));
            };
        };

        env[\notifyDependants].value(\points, env[\points]);
    };

    // Get interpolated channel at normalized time (0-1)
    env[\getChannelAt] = { |timeNorm|
        var result = env[\numChannels] / 2;  // Default center
        var points = env[\points];

        if(points.notNil and: { points.size >= 2 }) {
            var prevPt, nextPt;

            points.do { |pt|
                if(pt.time <= timeNorm) { prevPt = pt };
                if(nextPt.isNil and: { pt.time >= timeNorm }) { nextPt = pt };
            };

            if(prevPt.isNil) { prevPt = points.first };
            if(nextPt.isNil) { nextPt = points.last };

            if(prevPt.time == nextPt.time) {
                result = prevPt.channel;
            } {
                var t = (timeNorm - prevPt.time) / (nextPt.time - prevPt.time);
                result = prevPt.channel + (t * (nextPt.channel - prevPt.channel));
            };
        };

        result.clip(0, env[\numChannels] - 1);
    };

    // Get pan value at normalized time
    env[\getPanAt] = { |timeNorm|
        var ch = env[\getChannelAt].value(timeNorm);

        if(~nUPIC[\utils].notNil and: { ~nUPIC[\utils][\channelToPan].notNil }) {
            ~nUPIC[\utils][\channelToPan].value(ch, env[\numChannels]);
        } {
            // Fallback if utils not loaded
            var numCh = env[\numChannels];
            if(numCh == 1) { 0 }
            { if(numCh == 2) { ch * 2 - 1 }
            { ch * 2 / numCh }};
        };
    };

    // Notify dependants
    env[\notifyDependants] = { |what, value|
        env[\dependants].do { |dep|
            if(dep.respondsTo(\update)) {
                dep.update(env, what, value);
            };
        };
    };

    env[\addDependant] = { |dep| env[\dependants].add(dep) };
    env[\removeDependant] = { |dep| env[\dependants].remove(dep) };

    env;
};

// SpatialPlayback - Manages playback with spatial envelopes
~nUPIC[\spatial][\Playback] = {
    var playback = IdentityDictionary.new;

    playback[\envelopes] = List.new;  // SpatialEnvelope per trajectory
    playback[\synths] = List.new;
    playback[\isPlaying] = false;
    playback[\routine] = nil;
    playback[\duration] = 10;

    // Initialize from current data
    playback[\init] = {
        var data = ~nUPIC[\data];

        playback[\envelopes] = List.new;

        if(data[\trajectories].notNil) {
            data[\trajectories].size.do { |i|
                var numCh = 8;  // Default
                var synthDef;

                // Get channel count from assigned synthdef
                if(data[\trajectorySynthDefs].notNil and: {
                    i < data[\trajectorySynthDefs].size and: {
                        data[\trajectorySynthDefs][i].notNil
                    }
                }) {
                    synthDef = data[\trajectorySynthDefs][i].asString;
                    if(synthDef.contains("24ch")) { numCh = 24 }
                    { if(synthDef.contains("15ch")) { numCh = 15 }
                    { if(synthDef.contains("12ch")) { numCh = 12 }
                    { if(synthDef.contains("8ch")) { numCh = 8 }
                    { if(synthDef.contains("4ch")) { numCh = 4 }
                    { if(synthDef.contains("3ch")) { numCh = 3 }
                    { if(synthDef.contains("2ch")) { numCh = 2 }
                    { numCh = 1 }}}}}}};
                };

                // Create envelope
                playback[\envelopes].add(
                    ~nUPIC[\spatial][\SpatialEnvelope].value(numCh)
                );

                // Load existing spatial data
                if(data[\spatializationEnvelopes].notNil and: {
                    i < data[\spatializationEnvelopes].size and: {
                        data[\spatializationEnvelopes][i].notNil
                    }
                }) {
                    var traj = data[\trajectories][i];
                    var trajLength = if(traj.notNil and: { traj.size > 0 }) {
                        traj.last.x - traj.first.x
                    } { 600 };

                    playback[\envelopes][i][\setPoints].value(
                        data[\spatializationEnvelopes][i],
                        trajLength
                    );
                };
            };
        };

        ("Initialized " ++ playback[\envelopes].size ++ " spatial envelopes").postln;
    };

    // Update synth pan during playback
    playback[\updatePan] = { |synthIndex, timeNorm|
        if(synthIndex < playback[\synths].size and: {
            synthIndex < playback[\envelopes].size and: {
                playback[\synths][synthIndex].notNil
            }
        }) {
            var pan = playback[\envelopes][synthIndex][\getPanAt].value(timeNorm);
            playback[\synths][synthIndex].set(\pan, pan);
        };
    };

    playback;
};

"✓ SpatialModel loaded".postln;
"  - SpatialChannel: single channel position".postln;
"  - SpatialEnvelope: interpolated spatial curve".postln;
"  - Playback: manages synth pan updates".postln;
)
