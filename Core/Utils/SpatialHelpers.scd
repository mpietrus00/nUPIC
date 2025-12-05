// SpatialHelpers - Common utilities for spatial playback
// Provides consistent channel count extraction and pan conversion

(
~nUPIC[\utils] = ~nUPIC[\utils] ? IdentityDictionary.new;

// Extract channel count from SynthDef name
~nUPIC[\utils][\getChannelCount] = { |synthDefName|
    var name = synthDefName.asString;
    case
        { name.contains("24ch") } { 24 }
        { name.contains("15ch") } { 15 }
        { name.contains("12ch") } { 12 }
        { name.contains("8ch") } { 8 }
        { name.contains("4ch") } { 4 }
        { name.contains("3ch") } { 3 }
        { name.contains("2ch") } { 2 }
        { true } { 1 };  // mono
};

// Convert channel value to pan value for synth
// channel: 0 to (numChannels-1) continuous value
// numChannels: total channel count
// Returns: pan value suitable for Pan2 (-1 to 1) or PanAz (0 to 2)
~nUPIC[\utils][\channelToPan] = { |channel, numChannels|
    if(numChannels == 1) {
        0  // Mono - no panning
    } {
        if(numChannels == 2) {
            // Pan2 uses -1 to 1 range
            // channel 0 -> pan -1, channel 1 -> pan 1
            channel * 2 - 1
        } {
            // PanAz (3+ channels) uses 0 to 2 range
            // channel 0 -> pan 0, channel 1 -> pan 2/n, etc.
            channel * 2 / numChannels
        }
    }
};

// Get SynthDef name for a trajectory index
~nUPIC[\utils][\getSynthDefForTrajectory] = { |index|
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];

    if(data[\trajectorySynthDefs].notNil and: {
        index < data[\trajectorySynthDefs].size and: {
            data[\trajectorySynthDefs][index].notNil
        }
    }) {
        data[\trajectorySynthDefs][index]
    } {
        defaults[\defaultSynthDef] ? \upicWavetable
    }
};

// Get channel count for a trajectory index
~nUPIC[\utils][\getChannelCountForTrajectory] = { |index|
    var synthDef = ~nUPIC[\utils][\getSynthDefForTrajectory].value(index);
    ~nUPIC[\utils][\getChannelCount].value(synthDef);
};

// Interpolate along spatial envelope at a given normalized time (0-1)
// Returns channel value (continuous 0 to numChannels-1)
~nUPIC[\utils][\interpolateSpatialEnvelope] = { |spatialEnv, timeNorm, numChannels|
    var channelValue = (numChannels - 1) / 2;  // Default center

    if(spatialEnv.notNil and: { spatialEnv.size >= 2 }) {
        var firstX = spatialEnv.first.x;
        var lastX = spatialEnv.last.x;
        var totalLength = (lastX - firstX).max(1);
        var targetX = firstX + (timeNorm * totalLength);
        var prevPoint, nextPoint;

        // Find surrounding points
        spatialEnv.do { |pt|
            if(pt.x <= targetX) { prevPoint = pt };
            if(nextPoint.isNil and: { pt.x >= targetX }) { nextPoint = pt };
        };

        // Handle edge cases
        if(prevPoint.isNil) { prevPoint = spatialEnv.first };
        if(nextPoint.isNil) { nextPoint = spatialEnv.last };

        // Interpolate
        if(prevPoint.x == nextPoint.x) {
            channelValue = prevPoint.channel;
        } {
            var t = (targetX - prevPoint.x) / (nextPoint.x - prevPoint.x);
            channelValue = prevPoint.channel + (t * (nextPoint.channel - prevPoint.channel));
        };
    } {
        if(spatialEnv.notNil and: { spatialEnv.size == 1 }) {
            channelValue = spatialEnv.first.channel;
        };
    };

    channelValue.clip(0, numChannels - 1);
};

// Get pan value for a trajectory at normalized time
~nUPIC[\utils][\getPanForTrajectory] = { |trajIndex, timeNorm|
    var data = ~nUPIC[\data];
    var numChannels = ~nUPIC[\utils][\getChannelCountForTrajectory].value(trajIndex);
    var spatialEnv = data[\spatializationEnvelopes][trajIndex];
    var channel;

    if(spatialEnv.notNil and: { spatialEnv.size > 0 }) {
        channel = ~nUPIC[\utils][\interpolateSpatialEnvelope].value(spatialEnv, timeNorm, numChannels);
    } {
        channel = (numChannels - 1) / 2;  // Default center
    };

    ~nUPIC[\utils][\channelToPan].value(channel, numChannels);
};

"Utils/SpatialHelpers loaded".postln;
"  - getChannelCount: extract from SynthDef name".postln;
"  - channelToPan: convert channel to pan value".postln;
"  - getPanForTrajectory: get pan at normalized time".postln;
)
