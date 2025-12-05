// ArcModel - Reactive data model for trajectories
// Uses Connection quark patterns for syncing data, synths, and GUI
//
// Install Connection quark: Quarks.install("Connection")

(
// Arc Model Class
// Stores all data for a single arc with reactive notifications
~nUPIC[\model] = ~nUPIC[\model] ? IdentityDictionary.new;

~nUPIC[\model][\ArcModel] = { |index|
    var model = IdentityDictionary.new;

    // Core identity
    model[\index] = index;

    // Data storage
    model[\points] = List.new;  // List of (x, y, freq, time) events
    model[\amplitudeEnvelope] = List.new;  // List of (x, amp) events
    model[\spatialEnvelope] = List.new;  // List of (x, channel) events

    // SynthDef assignment
    model[\synthDefName] = \upicWavetable;
    model[\numChannels] = 1;  // mono

    // Dependants for reactive updates
    model[\dependants] = IdentitySet.new;

    // Add dependant (Connection quark pattern)
    model[\addDependant] = { |dep|
        model[\dependants].add(dep);
    };

    // Remove dependant
    model[\removeDependant] = { |dep|
        model[\dependants].remove(dep);
    };

    // Notify all dependants of changes
    model[\changed] = { |what, value|
        model[\dependants].do { |dep|
            dep.update(model, what, value);
        };
    };

    // Set SynthDef and update channel count
    model[\setSynthDef] = { |synthDefName|
        var name = synthDefName.asString;
        var numCh = 1;

        // Extract channel count from name
        if(name.contains("24ch")) { numCh = 24 }
        { if(name.contains("15ch")) { numCh = 15 }
        { if(name.contains("12ch")) { numCh = 12 }
        { if(name.contains("8ch")) { numCh = 8 }
        { if(name.contains("4ch")) { numCh = 4 }
        { if(name.contains("3ch")) { numCh = 3 }
        { if(name.contains("2ch")) { numCh = 2 }
        }}}}}};

        model[\synthDefName] = synthDefName;
        model[\numChannels] = numCh;
        model[\changed].value(\synthDef, synthDefName);
    };

    // Set spatial envelope
    model[\setSpatialEnvelope] = { |envelope|
        model[\spatialEnvelope] = envelope;
        model[\changed].value(\spatialEnvelope, envelope);
    };

    // Get interpolated channel at time position (0-1 normalized)
    model[\getChannelAtTime] = { |timeNorm|
        var envelope = model[\spatialEnvelope];
        var result = model[\numChannels] / 2;  // Default center

        if(envelope.notNil and: { envelope.size >= 2 }) {
            var totalLength = envelope.last.x - envelope.first.x;
            var targetX = envelope.first.x + (timeNorm * totalLength);
            var prevPoint, nextPoint;

            // Find surrounding points
            envelope.do { |point, i|
                if(point.x <= targetX) { prevPoint = point };
                if(nextPoint.isNil and: { point.x >= targetX }) { nextPoint = point };
            };

            // Handle edge cases
            if(prevPoint.isNil) { prevPoint = envelope.first };
            if(nextPoint.isNil) { nextPoint = envelope.last };

            // Interpolate
            if(prevPoint.x == nextPoint.x) {
                result = prevPoint.channel;
            } {
                var t = (targetX - prevPoint.x) / (nextPoint.x - prevPoint.x);
                result = prevPoint.channel + (t * (nextPoint.channel - prevPoint.channel));
            };
        };

        result.clip(0, model[\numChannels] - 1);
    };

    // Convert channel to pan value for synth
    model[\channelToPan] = { |channel|
        var numCh = model[\numChannels];

        if(numCh == 1) {
            0  // Mono - no panning
        } {
            if(numCh == 2) {
                // Pan2 uses -1 to 1
                channel * 2 - 1
            } {
                // PanAz uses 0 to 2
                channel * 2 / numCh
            }
        };
    };

    // Get pan at normalized time position
    model[\getPanAtTime] = { |timeNorm|
        var channel = model[\getChannelAtTime].value(timeNorm);
        model[\channelToPan].value(channel);
    };

    model;
};

// Collection of all arc models
~nUPIC[\model][\arcs] = List.new;

// Create a new arc model
~nUPIC[\model][\createArc] = {
    var index = ~nUPIC[\model][\arcs].size;
    var model = ~nUPIC[\model][\ArcModel].value(index);
    ~nUPIC[\model][\arcs].add(model);
    model;
};

// Get arc model by index
~nUPIC[\model][\getArc] = { |index|
    if(index < ~nUPIC[\model][\arcs].size) {
        ~nUPIC[\model][\arcs][index];
    } {
        nil;
    };
};

"✓ ArcModel loaded".postln;
"  - Reactive data model for trajectories".postln;
"  - Automatic channel-to-pan conversion".postln;
"  - Supports Connection quark patterns".postln;
)
