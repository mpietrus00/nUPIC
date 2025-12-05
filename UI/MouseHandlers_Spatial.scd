// MouseHandlers extension for spatial envelope support
// This adds spatialization envelope buffer creation to the playback system

(
// Override or extend the startPlayback function to include spatial envelopes
~nUPIC[\ui][\startPlaybackWithSpatial] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var defaults = ~nUPIC[\defaults];
    var playDuration = state[\playDuration] ? 10;
    var synthGroup;
    
    // Stop any existing playback
    ~nUPIC[\ui][\stopPlayback].value;
    
    if(data[\arcs].isNil or: { data[\arcs].size == 0 }) {
        "No arcs to play".postln;
        ^nil;
    };
    
    // Create synth group
    synthGroup = Group.new;
    state[\synthGroup] = synthGroup;
    
    // Initialize synth list
    state[\synths] = List.new;
    
    // Create spatial envelope buffers for each arc
    state[\spatialBuffers] = List.new;
    
    // Play each arc
    data[\arcs].do { |arc, i|
        var synth, synthDef, ampEnvelope, spatialBuffer;
        var params, viewWidth;
        
        if(arc.notNil and: { arc.size > 0 }) {
            // Get synthdef for this arc
            synthDef = if(data[\arcSynthDefs].notNil and: { 
                i < data[\arcSynthDefs].size 
            }) {
                data[\arcSynthDefs][i]
            } {
                defaults[\defaultSynthDef] ? \upicWavetable
            };
            
            // Create spatial envelope buffer if using 8ch synthdef
            if(synthDef.asString.contains("8ch")) {
                spatialBuffer = ~nUPIC[\createSpatialEnvelopeBuffer].value(i);
                state[\spatialBuffers].add(spatialBuffer);
                
                "Created spatial buffer for arc % with % channels".format(i, 8).postln;
            };
            
            // Get amplitude envelope
            ampEnvelope = if(data[\amplitudeEnvelopes].notNil and: {
                i < data[\amplitudeEnvelopes].size
            }) {
                data[\amplitudeEnvelopes][i]
            } {
                nil
            };
            
            // Cache view width before fork to avoid Qt threading issues
            viewWidth = if(state[\drawView].notNil) {
                state[\drawView].bounds.width
            } { 800 };

            // Create playback routine for this arc
            fork {
                var startTime = Main.elapsedTime;
                var firstPoint = arc[0];
                var lastPoint = arc.last;
                var arcDuration = playDuration;
                var prevSynth = nil;

                arc.do { |point, j|
                    var nextPoint = if(j < (arc.size - 1)) { arc[j + 1] } { nil };
                    var timeToNextPoint, freq, amp, pan;
                    var playbackProgress;

                    // Calculate timing
                    if(nextPoint.notNil) {
                        var currentPos = (point.x - firstPoint.x) / (lastPoint.x - firstPoint.x);
                        var nextPos = (nextPoint.x - firstPoint.x) / (lastPoint.x - firstPoint.x);
                        timeToNextPoint = (nextPos - currentPos) * arcDuration;
                    } {
                        timeToNextPoint = 0.1; // Last point
                    };

                    // Get frequency
                    freq = point[\freq] ? point.y ? 440;

                    // Calculate amplitude from envelope
                    playbackProgress = (point.x - firstPoint.x) / (lastPoint.x - firstPoint.x);
                    amp = if(ampEnvelope.notNil) {
                        ~nUPIC[\ui][\getAmplitudeAtPosition].value(ampEnvelope, playbackProgress)
                    } {
                        0.1
                    };

                    // Calculate pan from X position (using cached viewWidth)
                    pan = point.x.linlin(0, viewWidth, -1, 1);
                    
                    // Stop previous synth
                    if(prevSynth.notNil) {
                        prevSynth.set(\gate, 0);
                    };
                    
                    // Create basic parameters
                    params = [
                        \freq, freq,
                        \amp, amp,
                        \pan, pan,
                        \gate, 1,
                        \numSynths, data[\arcs].size,
                        \mass, point[\mass] ? 1,
                        \velocity, point[\velocity] ? 0,
                        \distance, point[\distance] ? 100,
                        \width, point[\width] ? 0.5,
                        \radialVel, point[\radialVel] ? 0,
                        \dopplerSens, state[\dopplerSensitivity] ? 0
                    ];
                    
                    // Add spatial buffer if available
                    if(spatialBuffer.notNil) {
                        params = params ++ [
                            \spatialEnvBuf, spatialBuffer.bufnum,
                            \playbackRate, 1
                        ];
                    };
                    
                    // Create synth
                    synth = Synth(synthDef, params, synthGroup);
                    prevSynth = synth;
                    state[\synths].add(synth);
                    
                    // Wait for next point
                    if(timeToNextPoint > 0) {
                        timeToNextPoint.wait;
                    };
                };
                
                // Release last synth
                if(prevSynth.notNil) {
                    prevSynth.set(\gate, 0);
                };
            };
        };
    };
    
    state[\isPlaying] = true;
    "Playback started with spatial envelopes".postln;
};

// Function to get amplitude at a specific position in the envelope
~nUPIC[\ui][\getAmplitudeAtPosition] = { |envelope, position|
    var result = 0.1; // Default amplitude
    var x = position;
    
    if(envelope.notNil and: { envelope.size > 0 }) {
        // Find surrounding points
        var prevPoint, nextPoint;
        var prevIdx = 0;
        
        envelope.do { |point, i|
            if(point.x <= x) {
                prevIdx = i;
            };
        };
        
        prevPoint = envelope[prevIdx];
        nextPoint = if(prevIdx < (envelope.size - 1)) {
            envelope[prevIdx + 1]
        } {
            envelope.last
        };
        
        // Interpolate
        if(prevPoint.x == nextPoint.x) {
            result = prevPoint.amp;
        } {
            var alpha = (x - prevPoint.x) / (nextPoint.x - prevPoint.x);
            result = prevPoint.amp + (alpha * (nextPoint.amp - prevPoint.amp));
        };
    };
    
    result.clip(0, 1);
};

// Note: The main playback in MainWindow.scd now handles spatial envelopes
// directly via the pan parameter, so we don't need to override startPlayback.
// The startPlaybackWithSpatial function is kept for backwards compatibility
// but is no longer used by default.

"✓ Spatial envelope support loaded (spatial envelopes handled via pan in main playback)".postln;
)