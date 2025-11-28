// Script to reduce the amplitude envelope warning messages
// This modifies how amplitude envelope messages are handled to reduce console clutter

(
// Store the original implementation for reference
~originalCheckAmpEnv = ~nUPIC[\\ui][\\startPlayback];

// Replace the startPlayback function with a version that suppresses repeated messages
~nUPIC[\\ui][\\startPlayback] = {
    var state = ~nUPIC[\\ui][\\state];
    var data = ~nUPIC[\\data];
    var constants = ~nUPIC[\\constants];
    var defaults = ~nUPIC[\\defaults];
    var width, height, freqMin, freqMax, playDuration, frameRate, audioFrameRate, useHighResAudio;
    var trajCount;
    var reportedMissingEnvelopes = false;  // Flag to track if we've already reported missing envelopes
    
    if(state.isNil or: { data.isNil }) {
        "nUPIC not properly initialized".postln;
        ^nil;
    };
    
    if(data[\\trajectories].isNil or: { data[\\trajectories].size == 0 }) {
        "No trajectories to play".postln;
        ^nil;
    };
    
    if(state[\\isPlaying]) {
        "Playback already running".postln;
        ^nil;
    };
    
    // Get system parameters with safe defaults
    width = constants[\\defaultWidth] ? 1200;
    height = constants[\\defaultHeight] ? 800;
    freqMin = constants[\\freqMin] ? 20;
    freqMax = constants[\\freqMax] ? 7500;
    playDuration = state[\\playDuration] ? defaults[\\playDuration] ? 10;
    frameRate = constants[\\frameRate] ? 60;
    audioFrameRate = constants[\\audioFrameRate] ? 120;
    useHighResAudio = constants[\\useHighResAudio] ? true;
    
    state[\\isPlaying] = true;
    
    ("Starting playback with " ++ data[\\trajectories].size ++ " trajectories").postln;
    ("Play duration: " ++ playDuration ++ " seconds").postln;
    
    // Initialize synth group if not exists
    if(state[\\synthGroup].isNil) {
        state[\\synthGroup] = Group.new(s);
    };
    
    // Initialize synth array if not exists
    if(state[\\synths].isNil) {
        state[\\synths] = Array.new;
    };
    
    // Start master limiter for anti-clipping
    if(~nUPIC_voiceManager.notNil) {
        ~nUPIC_voiceManager.startMasterLimiter.value;
        // Ensure we pass a proper integer count
        trajCount = if(data[\\trajectories].notNil) { 
            data[\\trajectories].size.asInteger 
        } { 0 };
        ~nUPIC_voiceManager.updateVoiceCount.value(trajCount);
    };
    
    // Check and report amplitude envelope status once at the start
    if(data[\\amplitudeEnvelopes].isNil or: { data[\\amplitudeEnvelopes].size < data[\\trajectories].size }) {
        var missingCount = data[\\trajectories].size - (data[\\amplitudeEnvelopes].size ? 0);
        ("NOTE: " ++ missingCount ++ " trajectories don't have amplitude envelopes - using default amp=0.2").postln;
        reportedMissingEnvelopes = true;
    };
    
    // Create playback task with dual-rate updates
    state[\\playbackTask] = Task {
        var uiFrameTime = 1 / frameRate;
        var audioFrameTime = if(useHighResAudio) { 1 / audioFrameRate } { uiFrameTime };
        var timeScaling = playDuration / width;
        var synthStarted = Array.fill(data[\\trajectories].size, false);
        var frameCount = 0;
        var audioFrameCount = 0;
        var lastUIUpdateTime = 0;
        var numTrajectories = data[\\trajectories].size;
        
        // Limit number of trajectories to prevent clipping
        if(~nUPIC_voiceManager.notNil and: { numTrajectories > ~nUPIC_voiceManager.maxSynths }) {
            ("Warning: " ++ numTrajectories ++ " trajectories exceed maximum of " ++ ~nUPIC_voiceManager.maxSynths ++ ". Some will be skipped to prevent clipping.").postln;
            numTrajectories = ~nUPIC_voiceManager.maxSynths;
        };
        
        // Create synths for each trajectory
        fork {
            ("Creating " ++ data[\\trajectories].size ++ " synths").postln;
            data[\\trajectories].do { |traj, i|
                var hue, synth, startFreq, startPan, firstPoint, synthDefName;
                var synthCreated = false;
                var attempts = 0;
                var maxAttempts = 3;
                
                // Get the starting frequency from the first point of the trajectory
                if(traj.size > 0) {
                    firstPoint = if(traj[0].isKindOf(Event)) { traj[0] } { (x: traj[0].x, y: traj[0].y, freq: nil) };
                    startFreq = firstPoint.freq ?? { firstPoint.y.linlin(0, height, freqMax, freqMin) };
                    startPan = firstPoint.x.linlin(0, width, -1, 1);
                } {
                    startFreq = 300;
                    startPan = 0;
                };
                
                // Get SynthDef name with fallback
                synthDefName = if(data[\\trajectorySynthDefs].notNil and: { i < data[\\trajectorySynthDefs].size }) {
                    data[\\trajectorySynthDefs][i]
                } {
                    defaults[\\defaultSynthDef] ? \\simpleGravObject
                };
                
                // Create synth with error handling and retry mechanism
                while { synthCreated.not and: { attempts < maxAttempts } } {
                    attempts = attempts + 1;
                    
                    try {
                        synth = Synth(synthDefName, [
                            \\freq, startFreq,
                            \\amp, 0.0,  // Start silent until trajectory begins
                            \\pan, startPan,
                            \\mass, 1.5 + (i * 0.3),
                            \\velocity, 5,
                            \\distance, 100,
                            \\width, 0.3 + (i * 0.1),
                            \\modFreq, 0.5 + (i * 0.2),
                            \\modDepth, 0.3,
                            \\rq, 0.1,
                            \\radialVel, 0,  // Initialize Doppler parameters
                            \\dopplerSens, 0,  // Start with Doppler disabled by default
                            \\numSynths, numTrajectories  // Pass total number of synths for amplitude scaling
                        ], state[\\synthGroup]);
                        
                        // Wait a moment for synth to initialize
                        0.05.wait;
                        
                        // Verify synth was created and is running
                        if(synth.notNil and: { synth.nodeID.notNil }) {
                            synthCreated = true;
                            if(i == 0) {
                                ("First synth created with nodeID: " ++ synth.nodeID ++ " freq: " ++ startFreq).postln;
                            };
                        } {
                            ("Synth creation failed for trajectory " ++ i ++ ", attempt " ++ attempts).postln;
                            synth = nil;
                        };
                    } { |error|
                        ("ERROR creating synth " ++ i ++ " (attempt " ++ attempts ++ "): " ++ error.errorString).postln;
                        synth = nil;
                        if(attempts < maxAttempts) {
                            0.1.wait;  // Wait before retry
                        };
                    };
                };
                
                // Add synth to array (even if nil for indexing consistency)
                state[\\synths] = state[\\synths].add(synth);
                
                if(synth.isNil) {
                    ("FAILED to create synth " ++ i ++ " after " ++ maxAttempts ++ " attempts").postln;
                };
                
                // Stagger synth creation to avoid overwhelming the server
                if(i % 5 == 4) { 0.02.wait; };
            };
            
            // Small delay before starting playback
            0.1.wait;
            
            // Playback loop with dual-rate updates
            state[\\playbackPosition] = 0;
            while { state[\\playbackPosition] < playDuration and: { state[\\isPlaying] } } {
                var currentTime = state[\\playbackPosition];  // Current time in seconds
                var shouldUpdateUI = (state[\\playbackPosition] - lastUIUpdateTime) >= uiFrameTime;
                
                // Update each synth based on its trajectory with interpolation
                data[\\trajectories].do { |traj, i|
                    var point1, point2, interpFactor;
                    var freq, pan, velocity, amp;
                    var foundPoints = false;
                    
                    if(state[\\synths][i].notNil and: { traj.size > 1 }) {
                        var firstPoint = if(traj[0].isKindOf(Event)) { traj[0] } { (x: traj[0].x, y: traj[0].y, freq: nil, time: nil) };
                        var lastPoint = if(traj.last.isKindOf(Event)) { traj.last } { (x: traj.last.x, y: traj.last.y, freq: nil, time: nil) };
                        
                        // Get time coordinates - use time field if available, otherwise fall back to x-coordinate conversion
                        var firstTime = if(firstPoint.time.notNil) { 
                            firstPoint.time 
                        } { 
                            firstPoint.x.linlin(0, width, 0, playDuration) 
                        };
                        var lastTime = if(lastPoint.time.notNil) { 
                            lastPoint.time 
                        } { 
                            lastPoint.x.linlin(0, width, 0, playDuration) 
                        };
                        
                        // Check if we've reached the start of this trajectory
                        if(synthStarted[i].not and: { currentTime >= firstTime }) {
                            synthStarted[i] = true;
                            // Fade in the synth when its trajectory starts
                            if(state[\\synths][i].notNil) {
                                state[\\synths][i].set(\\amp, 0.1);
                                if(i == 0) {
                                    ("Trajectory 0 started at time=" ++ currentTime.round(0.1) ++ "s, firstTime=" ++ firstTime.round(0.1) ++ "s").postln;
                                };
                            };
                        };
                        
                        // Only process if we're within the trajectory time range
                        if(currentTime >= firstTime and: { currentTime <= lastTime }) {
                            // Find two points to interpolate between based on time
                            block { |break|
                                (traj.size - 1).do { |j|
                                    var p1 = if(traj[j].isKindOf(Event)) { traj[j] } { (x: traj[j].x, y: traj[j].y, freq: nil, time: nil) };
                                    var p2 = if(traj[j + 1].isKindOf(Event)) { traj[j + 1] } { (x: traj[j + 1].x, y: traj[j + 1].y, freq: nil, time: nil) };
                                    
                                    // Get time coordinates for interpolation points
                                    var t1 = if(p1.time.notNil) { p1.time } { p1.x.linlin(0, width, 0, playDuration) };
                                    var t2 = if(p2.time.notNil) { p2.time } { p2.x.linlin(0, width, 0, playDuration) };
                                    
                                    if((t1 <= currentTime) and: { (t2 >= currentTime) }) {
                                        point1 = p1;
                                        point2 = p2;
                                        interpFactor = (currentTime - t1) / (t2 - t1).max(0.001);
                                        foundPoints = true;
                                        break.value;
                                    };
                                };
                            };
                            
                            if(foundPoints) {
                                // Use stored frequencies if available
                                var freq1 = point1.freq ?? { point1.y.linlin(0, height, freqMax, freqMin) };
                                var freq2 = point2.freq ?? { point2.y.linlin(0, height, freqMax, freqMin) };
                                var radialVel = 0;
                                var dopplerSens = state[\\dopplerSensitivity] ? 0.0;
                                var timeDistance;
                                
                                // Interpolate frequency
                                freq = freq1.blend(freq2, interpFactor);
                                // Calculate pan based on current time position within total duration
                                pan = currentTime.linlin(0, playDuration, -1, 1);
                                
                                // Calculate velocity from frequency change over time
                                timeDistance = if(point1.time.notNil and: { point2.time.notNil }) {
                                    (point2.time - point1.time).max(0.001)
                                } {
                                    ((point2.x - point1.x) / width * playDuration).max(0.001)
                                };
                                velocity = ((freq2 - freq1).abs / timeDistance) * 0.01;
                                velocity = velocity.clip(0, 20);
                                
                                // Calculate radial velocity for Doppler effect
                                if(dopplerSens > 0) {
                                    var centerX, centerY, currentY, currentPos, centerPos;
                                    var directionX, directionY, directionLength;
                                    var velX, velY, currentX;
                                    
                                    centerX = width * 0.5;
                                    centerY = height * 0.5;
                                    currentY = point1.y.blend(point2.y, interpFactor);
                                    currentX = point1.x.blend(point2.x, interpFactor);
                                    currentPos = Point(currentX, currentY);
                                    centerPos = Point(centerX, centerY);
                                    
                                    // Calculate direction vector from center to current position
                                    directionX = (currentPos.x - centerPos.x) / width;
                                    directionY = (currentPos.y - centerPos.y) / height;
                                    directionLength = (directionX.squared + directionY.squared).sqrt.max(0.01);
                                    
                                    // Normalize direction vector
                                    directionX = directionX / directionLength;
                                    directionY = directionY / directionLength;
                                    
                                    // Calculate velocity vector
                                    velX = (point2.x - point1.x) / (point2.x - point1.x).abs.max(1);
                                    velY = (point2.y - point1.y) / (point2.x - point1.x).abs.max(1);
                                    
                                    // Calculate radial velocity (dot product of velocity and direction)
                                    // Positive = moving away from center, negative = moving toward center
                                    radialVel = (velX * directionX + velY * directionY) * velocity;
                                    radialVel = radialVel.clip(-20, 20);
                                };
                                
                                // Check if we have an amplitude envelope - avoid repeated messages
                                if(data[\\amplitudeEnvelopes].notNil and: { 
                                    data[\\amplitudeEnvelopes][i].notNil and: { 
                                        data[\\amplitudeEnvelopes][i].size > 1 
                                    }
                                }) {
                                    var ampEnv = data[\\amplitudeEnvelopes][i];
                                    var ampPoint1, ampPoint2, ampFound = false;
                                    var trajRelativeTime, trajRelativeX;
                                    
                                    // Calculate trajectory-relative time position (0 to trajectory duration)
                                    var firstTime = if(firstPoint.time.notNil) { 
                                        firstPoint.time 
                                    } { 
                                        firstPoint.x.linlin(0, width, 0, playDuration) 
                                    };
                                    trajRelativeTime = currentTime - firstTime;
                                    // Convert time to relative position for amplitude envelope lookup
                                    trajRelativeX = trajRelativeTime * 600 / (lastTime - firstTime);
                                    
                                    // Find amplitude points to interpolate
                                    block { |break|
                                        (ampEnv.size - 1).do { |j|
                                            if((ampEnv[j].x <= trajRelativeX) and: { (ampEnv[j + 1].x >= trajRelativeX) }) {
                                                ampPoint1 = ampEnv[j];
                                                ampPoint2 = ampEnv[j + 1];
                                                ampFound = true;
                                                break.value;
                                            };
                                        };
                                    };
                                    
                                    if(ampFound) {
                                        var ampInterpFactor = (trajRelativeX - ampPoint1.x) / (ampPoint2.x - ampPoint1.x).max(0.001);
                                        amp = ampPoint1.amp.blend(ampPoint2.amp, ampInterpFactor).clip(0, 1);
                                    } {
                                        // Check edges
                                        if(trajRelativeX <= ampEnv.first.x) {
                                            amp = ampEnv.first.amp.clip(0, 1);
                                        } {
                                            if(trajRelativeX >= ampEnv.last.x) {
                                                amp = ampEnv.last.amp.clip(0, 1);
                                            } {
                                                // Linear interpolation to nearest point if outside envelope range
                                                amp = 0.1;
                                            };
                                        };
                                    };
                                } {
                                    // No amplitude envelope - use default - no message here to avoid spam
                                    amp = 0.2;  // Increased default amplitude
                                };
                                
                                // Check if synth is still running before updating
                                if(state[\\synths][i].notNil) {
                                    state[\\synths][i].set(
                                        \\freq, freq,
                                        \\pan, pan,
                                        \\velocity, velocity,
                                        \\amp, amp,
                                        \\radialVel, radialVel,
                                        \\dopplerSens, dopplerSens
                                    );
                                };
                            } {
                                // Edge case: exactly on first point
                                if(currentTime == firstTime) {
                                    freq = firstPoint.freq ?? { firstPoint.y.linlin(0, height, freqMax, freqMin) };
                                    pan = currentTime.linlin(0, playDuration, -1, 1);
                                    if(state[\\synths][i].notNil) {
                                        state[\\synths][i].set(\\freq, freq, \\pan, pan, \\amp, 0.2);
                                    };
                                };
                            };
                        } {
                            // Outside trajectory range - stay silent
                            if(state[\\synths][i].notNil) {
                                state[\\synths][i].set(\\amp, 0.0);
                            };
                        };
                    } {
                        // Trajectory hasn't started yet or is too small
                        if(state[\\synths][i].notNil) {
                            state[\\synths][i].set(\\amp, 0.0);
                        };
                    };
                };
                
                // Refresh display at UI frame rate only
                if(shouldUpdateUI) {
                    { state[\\drawView].refresh }.defer;
                    lastUIUpdateTime = state[\\playbackPosition];
                };
                
                state[\\playbackPosition] = state[\\playbackPosition] + audioFrameTime;
                audioFrameCount = audioFrameCount + 1;
                if(shouldUpdateUI) { frameCount = frameCount + 1 };
                audioFrameTime.wait;
            };
            
            // End of playback
            state[\\isPlaying] = false;
            state[\\synths].do { |synth| 
                if(synth.notNil) { synth.set(\\gate, 0) };
            };
            state[\\synths].clear;
            state[\\playbackPosition] = 0;
            
            // Stop master limiter
            if(~nUPIC_voiceManager.notNil) {
                ~nUPIC_voiceManager.stopMasterLimiter.value;
                ~nUPIC_voiceManager.updateVoiceCount.value(0);
            };
            
            // Update play button to show 'Play' state (value 0) since playback ended
            if(state[\\controls].notNil and: { state[\\controls][\\playButton].notNil }) {
                { state[\\controls][\\playButton].value = 0 }.defer;
            };
            
            { state[\\drawView].refresh }.defer;
            "Playback completed - play button reset".postln;
        }; // End of fork
    }.play; // End of Task.play
    
    "Playback started".postln;
};

// Function to restore the original implementation
~restoreOriginalPlayback = {
    ~nUPIC[\\ui][\\startPlayback] = ~originalCheckAmpEnv;
    "Restored original playback function".postln;
};

"Amplitude envelope messages reduced - playback function replaced.".postln;
"Run ~restoreOriginalPlayback.value; to restore the original implementation.".postln;
)
