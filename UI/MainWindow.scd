// nUPIC Main Window
// Main GUI window for trajectory drawing and control
// Part of the nUPIC (nu-UPIC) modular system

(
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };

// Initialize UI namespace (don't overwrite existing functions!)
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

// Main window creation function
~nUPIC[\ui][\createMainWindow] = {
    var window, drawView, controlsHeight = 32;  // Exact height for single row (20px controls + 12px padding)
    var width, height, constants, colors, defaults;
    var allMargin = 5; // Consistent 5px margin all around
    var freqLabelWidth = 80; // Width for frequency labels - made wider
    var freqLabelGap = 8; // Small gap between freq labels and drawing
    var freqLabelView;
    var drawingAreaLeft, drawingAreaWidth, trajectoryHeight;
    var rangeSliderHeight = 20; // Height for horizontal range slider
    var rangeSliderWidth = 20; // Width for vertical range slider
    var rangeSliderGap = 5; // Gap between drawing area and range sliders
    var verticalRangeSlider, horizontalRangeSlider;

    // Get system constants
    constants = ~nUPIC[\constants] ? (
        defaultWidth: 1200,
        defaultHeight: 350,  // Reduced from 800 to eliminate empty space
        controlPanelHeight: 32  // Exact height for single row (20px controls + 12px padding)
    );

    colors = ~nUPIC[\colors] ? (
        background: Color.white,
        grid: Color.gray(0.3, 0.5),
        trajectory: { |index, maxIndex = 200|
            Color.hsv((index / maxIndex) * 0.8, 0.7, 0.9)
        },
        selected: Color.blue,
        eraseMode: Color.red,
        drawMode: Color.gray
    );

    defaults = ~nUPIC[\defaults] ? (
        playDuration: 10,
        showGrid: true,
        gridType: \equalTemperament
    );

    width = constants[\defaultWidth];
    height = constants[\defaultHeight];
    controlsHeight = constants[\controlPanelHeight];

    // Calculate layout dimensions with space for RangeSliders
    drawingAreaLeft = allMargin + freqLabelWidth + freqLabelGap;
    drawingAreaWidth = width - drawingAreaLeft - allMargin - rangeSliderWidth - rangeSliderGap;
    trajectoryHeight = height - allMargin - allMargin - rangeSliderHeight - rangeSliderGap;

    // Initialize UI state if not exists
    if(~nUPIC[\ui][\state].isNil) {
        ~nUPIC[\ui][\state] = (
            // Window and view references
            window: nil,
            drawView: nil,

            // Drawing state
            isDrawing: false,
            currentTrajectory: nil,

            // Interaction modes
            eraseMode: false,
            selectMode: false,
            isDragging: false,

            // Mouse tracking
            mouseX: 0,
            mouseY: 0,
            dragStartX: 0,
            dragStartY: 0,
            draggedTrajectories: nil,

            // Zoom and view state
            zoomFreqMin: constants[\freqMin] ? 20,
            zoomFreqMax: constants[\freqMax] ? 7500,
            zoomTimeMin: 0,
            zoomTimeMax: 1,

            // Extended canvas state
            virtualCanvasWidth: (constants[\defaultWidth] ? 1200) * 4,  // 4x wider
            virtualCanvasHeight: (constants[\defaultHeight] ? 670) * 3,  // 3x taller
            viewportX: 0,  // Current viewport X offset
            viewportY: 0,  // Current viewport Y offset
            canvasScale: 1.0,  // Overall canvas scale (zoom)

            // Pan state
            isPanning: false,
            panStartX: 0,
            panStartY: 0,
            panStartViewportX: 0,
            panStartViewportY: 0,

            // Playback state
            isPlaying: false,
            playbackPosition: 0,
            playbackTask: nil,

            // Audio state
            synths: List.new,
            synthGroup: nil,

            // Other state
            showGrid: defaults[\showGrid],
            gridType: defaults[\gridType],
            playDuration: defaults[\playDuration],

            // Doppler effect state
            dopplerSensitivity: 0.0,  // Default disabled

            // UI element references
            controls: IdentityDictionary.new
        );
    };

    // Create main window with resizable set to false
    window = Window("nUPIC - Trajectory Synthesis System", 
        Rect(100, 100, width, height + controlsHeight + 20), resizable: false);
    window.background = Color.new(205/255, 250/255, 205/255); // B&K green

    // Store window reference
    ~nUPIC[\ui][\state][\window] = window;

    // Create frequency labels view (left area)
    freqLabelView = UserView(window, Rect(allMargin, allMargin, freqLabelWidth, trajectoryHeight));
    freqLabelView.background = Color.white;
    ~nUPIC[\ui][\state][\freqLabelView] = freqLabelView;

    // Set up frequency label drawing
    freqLabelView.drawFunc = {
        ~nUPIC[\ui][\drawFrequencyLabels].value(freqLabelWidth, trajectoryHeight);
    };

    // Create vertical RangeSlider for frequency zoom (positioned to the right of drawing area)
    verticalRangeSlider = RangeSlider(window,
        Rect(drawingAreaLeft + drawingAreaWidth + rangeSliderGap, allMargin, rangeSliderWidth, trajectoryHeight))
        .background_(Color.gray(0.8))
        .knobColor_(Color.green)
        .hi_(1.0)  // Top frequency (normalized)
        .lo_(0.0)  // Bottom frequency (normalized)
        .step_(0.001)
        .orientation_(\vertical)
        .action_({ |slider|
            ~nUPIC[\ui][\updateFrequencyZoomFromSlider].value(slider.lo, slider.hi);
        });

    // Store reference
    ~nUPIC[\ui][\state][\verticalRangeSlider] = verticalRangeSlider;

    // Create main trajectory drawing view
    drawView = UserView(window, Rect(drawingAreaLeft, allMargin, drawingAreaWidth, trajectoryHeight));
    drawView.background = Color.white;
    ~nUPIC[\ui][\state][\drawView] = drawView;

    // Create horizontal RangeSlider for time zoom (positioned below drawing area)
    horizontalRangeSlider = RangeSlider(window,
        Rect(drawingAreaLeft, allMargin + trajectoryHeight + rangeSliderGap, drawingAreaWidth, rangeSliderHeight))
        .background_(Color.gray(0.8))
        .knobColor_(Color.green)
        .hi_(1.0)  // End time (normalized)
        .lo_(0.0)  // Start time (normalized)
        .step_(0.001)
        .orientation_(\horizontal)
        .action_({ |slider|
            ~nUPIC[\ui][\updateTimeZoomFromSlider].value(slider.lo, slider.hi);
        });

    // Store reference
    ~nUPIC[\ui][\state][\horizontalRangeSlider] = horizontalRangeSlider;
    ~nUPIC[\ui][\state][\drawingMargins] = (
        left: drawingAreaLeft,
        right: allMargin,
        top: allMargin,
        bottom: allMargin
    );

    // Initialize zoom system FIRST - must be done before other modules
    if(~nUPIC[\ui][\initializeZoomSystem].notNil) {
        "[MAIN] About to initialize zoom system...".postln;
        ~nUPIC[\ui][\initializeZoomSystem].value;
        "[MAIN] Zoom system initialization completed".postln;

        // Sync RangeSliders with initial zoom state
        if(~nUPIC[\ui][\syncRangeSliders].notNil) {
            ~nUPIC[\ui][\syncRangeSliders].value;
            "[MAIN] RangeSliders synchronized with initial zoom state".postln;
        };
    } {
        "[MAIN] WARNING: initializeZoomSystem function not found!".postln;
    };

    // Load and initialize other UI modules
    if(~nUPIC[\ui][\initializeControls].notNil) {
        ~nUPIC[\ui][\initializeControls].value(window, width, height, controlsHeight);
    };

    if(~nUPIC[\ui][\initializeDrawing].notNil) {
        ~nUPIC[\ui][\initializeDrawing].value(drawView, drawingAreaWidth, trajectoryHeight);
    };

    // Keyboard handling is done by Controls.scd to avoid conflicts

    // Window cleanup
    window.onClose = {
        // Stop any playback
        if(~nUPIC[\ui][\state][\isPlaying]) {
            ~nUPIC[\ui][\stopPlayback].value;
        };

        // Close amplitude editor window
        if(~nUPIC[\ui][\closeAmplitudeEditor].notNil) {
            ~nUPIC[\ui][\closeAmplitudeEditor].value;
        };

        // Clear synths
        if(~nUPIC[\ui][\state][\synths].notNil) {
            ~nUPIC[\ui][\state][\synths].do { |synth|
                if(synth.notNil) { synth.free };
            };
            ~nUPIC[\ui][\state][\synths].clear;
        };

        // Clear references
        ~nUPIC[\ui][\state][\window] = nil;
        ~nUPIC[\ui][\state][\drawView] = nil;

        "nUPIC main window closed".postln;
    };

    // Make window front
    window.front;

    "nUPIC main window created".postln;
    window;
};

// Playback control functions
~nUPIC[\ui][\startPlayback] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var defaults = ~nUPIC[\defaults];
    var width, height, freqMin, freqMax, playDuration, frameRate, audioFrameRate, useHighResAudio;
    var trajCount;  // Add trajCount variable declaration

    if(state.isNil or: { data.isNil }) {
        "nUPIC not properly initialized".postln;
        ^nil;
    };

    if(data[\trajectories].isNil or: { data[\trajectories].size == 0 }) {
        "No trajectories to play".postln;
        ^nil;
    };

    if(state[\isPlaying]) {
        "Playback already running".postln;
        ^nil;
    };

    // Get system parameters with safe defaults
    width = constants[\defaultWidth] ? 1200;
    height = constants[\defaultHeight] ? 670;
    freqMin = constants[\freqMin] ? 20;
    freqMax = constants[\freqMax] ? 7500;
    playDuration = state[\playDuration] ? defaults[\playDuration] ? 10;
    frameRate = constants[\frameRate] ? 60;
    audioFrameRate = constants[\audioFrameRate] ? 120;
    useHighResAudio = constants[\useHighResAudio] ? true;

    state[\isPlaying] = true;

    ("Starting playback with " ++ data[\trajectories].size ++ " trajectories").postln;
    ("Play duration: " ++ playDuration ++ " seconds").postln;

    // Initialize synth group if not exists
    if(state[\synthGroup].isNil) {
        state[\synthGroup] = Group.new(s);
    };

    // Initialize synth array if not exists
    if(state[\synths].isNil) {
        state[\synths] = Array.new;
    };

    // Start master limiter for anti-clipping
    if(~nUPIC_voiceManager.notNil) {
        ~nUPIC_voiceManager.startMasterLimiter.value;
        // Ensure we pass a proper integer count
        trajCount = if(data[\trajectories].notNil) {
            data[\trajectories].size.asInteger
        } { 0 };
        ~nUPIC_voiceManager.updateVoiceCount.value(trajCount);
    };

    // Create playback task with dual-rate updates
    state[\playbackTask] = Task {
        var uiFrameTime = 1 / frameRate;
        var audioFrameTime = if(useHighResAudio) { 1 / audioFrameRate } { uiFrameTime };
        var synthStarted = Array.fill(data[\trajectories].size, false);
        var frameCount = 0;
        var audioFrameCount = 0;
        var lastUIUpdateTime = 0;
        var numTrajectories = data[\trajectories].size;

        // Limit number of trajectories to prevent clipping
        if(~nUPIC_voiceManager.notNil and: { numTrajectories > ~nUPIC_voiceManager.maxSynths }) {
            ("Warning: " ++ numTrajectories ++ " trajectories exceed maximum of " ++ ~nUPIC_voiceManager.maxSynths ++ ". Some will be skipped to prevent clipping.").postln;
            numTrajectories = ~nUPIC_voiceManager.maxSynths;
        };

        // Create synths for each trajectory
        fork {
            var startTime;  // Declare at beginning of fork block
            
            ("Creating " ++ data[\trajectories].size ++ " synths").postln;
            data[\trajectories].do { |traj, i|
                var hue, synth, startFreq, startPan, firstPoint, synthDefName;
                var synthCreated = false;
                var attempts = 0;
                var maxAttempts = 3;

                // Get the starting frequency from the first point of the trajectory
                if(traj.size > 0) {
                    firstPoint = if(traj[0].isKindOf(Event)) { traj[0] } { (x: traj[0].x, y: traj[0].y, freq: nil) };
                    startFreq = firstPoint.freq ?? { firstPoint.y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]) };
                    startPan = firstPoint.x.linlin(0, width, -1, 1);
                } {
                    startFreq = 300;
                    startPan = 0;
                };

                // Get SynthDef name with fallback
                synthDefName = if(data[\trajectorySynthDefs].notNil and: { i < data[\trajectorySynthDefs].size }) {
                    data[\trajectorySynthDefs][i]
                } {
                    defaults[\defaultSynthDef] ? \simpleGravObject
                };

                // Create synth with error handling and retry mechanism
                while { synthCreated.not and: { attempts < maxAttempts } } {
                    attempts = attempts + 1;

                    try {
                        var params = [
                            \freq, startFreq,
                            \amp, 0.0,  // Start silent until trajectory begins
                            \pan, startPan,
                            \mass, 1.5 + (i * 0.3),
                            \velocity, 5,
                            \distance, 100,
                            \width, 0.3 + (i * 0.1),
                            \modFreq, 0.5 + (i * 0.2),
                            \modDepth, 0.3,
                            \rq, 0.1,
                            \radialVel, 0,  // Initialize Doppler parameters
                            \dopplerSens, 0,  // Start with Doppler disabled by default
                            \numSynths, numTrajectories  // Pass total number of synths for amplitude scaling
                        ];
                        
                        // Add buffer number for all upicWavetable variants
                        if(synthDefName.asString.contains("upicWavetable") and: { ~nUPIC_wavetableBuffer.notNil }) {
                            params = params ++ [\bufnum, ~nUPIC_wavetableBuffer.bufnum];
                            ("Using wavetable synth: " ++ synthDefName).postln;
                        };
                        
                        synth = Synth(synthDefName, params, state[\synthGroup]);

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
                state[\synths] = state[\synths].add(synth);

                if(synth.isNil) {
                    ("FAILED to create synth " ++ i ++ " after " ++ maxAttempts ++ " attempts").postln;
                };

                // Stagger synth creation to avoid overwhelming the server
                if(i % 5 == 4) { 0.02.wait; };
            };

            // Small delay before starting playback
            0.1.wait;

            // Playback loop with dual-rate updates
            state[\playbackPosition] = 0;
            startTime = Main.elapsedTime;  // Record actual start time for sync
            
            while { state[\playbackPosition] < state[\playDuration] and: { state[\isPlaying] } } {
                var actualElapsedTime = Main.elapsedTime - startTime;  // Real elapsed time
                var currentTime = actualElapsedTime;  // Use real time for audio sync
                var shouldUpdateUI = (actualElapsedTime - lastUIUpdateTime) >= uiFrameTime;
                var currentDuration = state[\playDuration];  // Read current duration each frame
                var activeSynthCount = 0;  // Count synths that are actively playing
                
                // Update visual playback position to match actual time
                state[\playbackPosition] = actualElapsedTime;

                // Debug: print duration changes
                if((frameCount % 60 == 0) and: { frameCount > 0 }) {
                    ("Frame " ++ frameCount ++ ": duration=" ++ currentDuration ++ "s, time=" ++ currentTime.round(0.1) ++ "s").postln;
                };

                // ZOOM-INDEPENDENT PLAYBACK ENGINE
                // Audio playback is completely independent of current zoom/view state
                // Plays all trajectories based on their absolute stored positions
                data[\trajectories].do { |traj, i|
                    var point1, point2, interpFactor;
                    var freq, pan, velocity, amp;
                    var foundPoints = false;

                    if(state[\synths][i].notNil and: { traj.size > 1 }) {
                        var firstPoint = if(traj[0].isKindOf(Event)) { traj[0] } { (x: traj[0].x, y: traj[0].y, freq: nil, time: nil) };
                        var lastPoint = if(traj.last.isKindOf(Event)) { traj.last } { (x: traj.last.x, y: traj.last.y, freq: nil, time: nil) };

                        // CRITICAL: Use ABSOLUTE spatial coordinates - completely independent of zoom/view state
                        // Convert stored pixel coordinates to normalized spatial position (0.0-1.0)
                        // Then convert to time based on full composition duration
                        
                        // Get constants for proper coordinate conversion
                        var canvasWidth = constants[\defaultWidth] ? 1200;  // Full canvas width for normalization
                        
                        // Convert pixel coordinates to normalized spatial position (0.0 to 1.0)
                        var firstSpatialPos = firstPoint.x / canvasWidth;
                        var lastSpatialPos = lastPoint.x / canvasWidth;
                        
                        // Convert spatial position directly to time (independent of zoom)
                        var firstTime = firstSpatialPos * state[\playDuration];
                        var lastTime = lastSpatialPos * state[\playDuration];

                        // Check if we've reached the start of this trajectory - use absolute time
                        if(synthStarted[i].not and: { currentTime >= firstTime }) {
                            synthStarted[i] = true;
                            // Fade in the synth when its trajectory starts
                            if(state[\synths][i].notNil) {
                                state[\synths][i].set(\amp, 0.1);
                                if(i == 0) {
                                    ("Trajectory 0 started at time=" ++ currentTime.round(0.1) ++ "s, firstTime=" ++ firstTime.round(0.1) ++ "s").postln;
                                };
                            };
                        };

                        // Only process if we're within the trajectory time range - use absolute time
                        if(currentTime >= firstTime and: { currentTime <= lastTime }) {
                            // Find two points to interpolate between using ABSOLUTE time coordinates
                            block { |break|
                                (traj.size - 1).do { |j|
                                    var p1 = if(traj[j].isKindOf(Event)) { traj[j] } { (x: traj[j].x, y: traj[j].y, freq: nil, time: nil) };
                                    var p2 = if(traj[j + 1].isKindOf(Event)) { traj[j + 1] } { (x: traj[j + 1].x, y: traj[j + 1].y, freq: nil, time: nil) };

                                    // ABSOLUTE COORDINATE MAPPING: Use consistent spatial coordinate system
                                    // Convert pixel positions to spatial coordinates, then to time
                                    var spatialPos1 = p1.x / canvasWidth;
                                    var spatialPos2 = p2.x / canvasWidth;
                                    var t1 = spatialPos1 * state[\playDuration];
                                    var t2 = spatialPos2 * state[\playDuration];

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
                                // Use stored frequencies if available, or calculate using zoom-aware frequency ranges
                                var freq1 = point1.freq ?? { point1.y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]) };
                                var freq2 = point2.freq ?? { point2.y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]) };
                                var radialVel = 0;
                                var dopplerSens = state[\dopplerSensitivity] ? 0.0;
                                var timeDistance;

                                // Interpolate frequency
                                freq = freq1.blend(freq2, interpFactor);
                                // Calculate pan based on current time position within total duration
                                // Use current state playDuration for dynamic duration updates
                                pan = currentTime.linlin(0, state[\playDuration], -1, 1);
                                // Calculate velocity from frequency change over time
                                timeDistance = if(point1.time.notNil and: { point2.time.notNil }) {
                                    (point2.time - point1.time).max(0.001)
                                } {
                                    // Use spatial coordinate system for consistent timing
                                    var spatialDistance = (point2.x - point1.x) / canvasWidth;
                                    (spatialDistance * state[\playDuration]).max(0.001)
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

                                // Check if we have an amplitude envelope
                                if(data[\amplitudeEnvelopes].notNil and: {
                                    data[\amplitudeEnvelopes][i].notNil and: {
                                        data[\amplitudeEnvelopes][i].size > 1
                                    }
                                }) {
                                    var ampEnv = data[\amplitudeEnvelopes][i];
                                    var ampPoint1, ampPoint2, ampFound = false;
                                    var trajRelativeTime, trajRelativeX, trajPixelLength, firstTimeForAmp;

                                    // Calculate trajectory-relative time position (0 to trajectory duration)
                                    // CONSISTENT SPATIAL MAPPING: Use same coordinate system as main timing
                                    firstTimeForAmp = firstTime;  // Use the already calculated consistent firstTime
                                    trajRelativeTime = currentTime - firstTimeForAmp;
                                    // Convert time to relative position for amplitude envelope lookup using actual trajectory length
                                    trajPixelLength = (lastPoint.x - firstPoint.x).max(1);
                                    trajRelativeX = trajRelativeTime * trajPixelLength / (lastTime - firstTimeForAmp);

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
                                    // No amplitude envelope - use default
                                    amp = 0.2;  // Increased default amplitude
                                };

                                // Check if we have a spatial envelope
                                if(data[\spatializationEnvelopes].notNil and: {
                                    data[\spatializationEnvelopes][i].notNil and: {
                                        data[\spatializationEnvelopes][i].size > 1
                                    }
                                }) {
                                    var spatialEnv = data[\spatializationEnvelopes][i];
                                    var spatialPoint1, spatialPoint2, spatialFound = false;
                                    var spatialRelativeX, spatialPixelLength, firstTimeForSpatial;
                                    var channelValue, maxChannels;
                                    var trajSynthDefName;

                                    // Get channel count from trajectory's SynthDef
                                    trajSynthDefName = if(data[\trajectorySynthDefs].notNil and: {
                                        i < data[\trajectorySynthDefs].size and: {
                                            data[\trajectorySynthDefs][i].notNil
                                        }
                                    }) {
                                        data[\trajectorySynthDefs][i].asString
                                    } {
                                        (defaults[\defaultSynthDef] ? \upicWavetable8ch).asString
                                    };

                                    // Extract channel count from SynthDef name
                                    maxChannels = case
                                        { trajSynthDefName.contains("24ch") } { 24 }
                                        { trajSynthDefName.contains("15ch") } { 15 }
                                        { trajSynthDefName.contains("12ch") } { 12 }
                                        { trajSynthDefName.contains("8ch") } { 8 }
                                        { trajSynthDefName.contains("4ch") } { 4 }
                                        { trajSynthDefName.contains("3ch") } { 3 }
                                        { trajSynthDefName.contains("2ch") } { 2 }
                                        { true } { 1 };  // mono

                                    // Calculate trajectory-relative position for spatial envelope lookup
                                    // Use same coordinate system as amplitude envelope
                                    firstTimeForSpatial = firstTime;
                                    spatialRelativeX = (currentTime - firstTimeForSpatial) * (lastPoint.x - firstPoint.x).max(1) / (lastTime - firstTimeForSpatial);

                                    // Find spatial points to interpolate
                                    block { |break|
                                        (spatialEnv.size - 1).do { |j|
                                            if((spatialEnv[j].x <= spatialRelativeX) and: { (spatialEnv[j + 1].x >= spatialRelativeX) }) {
                                                spatialPoint1 = spatialEnv[j];
                                                spatialPoint2 = spatialEnv[j + 1];
                                                spatialFound = true;
                                                break.value;
                                            };
                                        };
                                    };

                                    if(spatialFound) {
                                        var spatialInterpFactor = (spatialRelativeX - spatialPoint1.x) / (spatialPoint2.x - spatialPoint1.x).max(0.001);
                                        channelValue = spatialPoint1.channel.blend(spatialPoint2.channel, spatialInterpFactor);
                                    } {
                                        // Check edges
                                        if(spatialRelativeX <= spatialEnv.first.x) {
                                            channelValue = spatialEnv.first.channel;
                                        } {
                                            if(spatialRelativeX >= spatialEnv.last.x) {
                                                channelValue = spatialEnv.last.channel;
                                            } {
                                                // Default to center
                                                channelValue = (maxChannels - 1) / 2;
                                            };
                                        };
                                    };

                                    // Convert channel to pan based on SynthDef type
                                    // Pan2 (2ch): uses range -1 to 1
                                    // PanAz (3ch+): uses range 0 to 2
                                    if(maxChannels == 2) {
                                        // 2ch uses Pan2: map channel 0→-1, channel 1→1
                                        pan = channelValue * 2 - 1;
                                    } {
                                        // 3ch+ uses PanAz: pos=0 is channel 0, pos=2/n is channel 1
                                        pan = channelValue * 2 / maxChannels;
                                    };
                                };
                                // If no spatial envelope, pan keeps its time-based value from above

                                // Check if synth is still running before updating
                                if(state[\synths][i].notNil) {
                                    state[\synths][i].set(
                                        \freq, freq,
                                        \pan, pan,
                                        \velocity, velocity,
                                        \amp, amp,
                                        \radialVel, radialVel,
                                        \dopplerSens, dopplerSens
                                    );

                                    // Count this as an active synth if it has audible amplitude
                                    if(amp > 0.01) {
                                        activeSynthCount = activeSynthCount + 1;
                                    };
                                };
                            } {
                                // Edge case: exactly on first point
                                if(currentTime == firstTime) {
                                    var edgePan;
                                    freq = firstPoint.freq ?? { firstPoint.y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]) };
                                    // Check for spatial envelope at start
                                    if(data[\spatializationEnvelopes].notNil and: {
                                        data[\spatializationEnvelopes][i].notNil and: {
                                            data[\spatializationEnvelopes][i].size > 0
                                        }
                                    }) {
                                        var startChannel = data[\spatializationEnvelopes][i].first.channel;
                                        var maxChannels;
                                        var edgeSynthDefName;

                                        // Get channel count from trajectory's SynthDef
                                        edgeSynthDefName = if(data[\trajectorySynthDefs].notNil and: {
                                            i < data[\trajectorySynthDefs].size and: {
                                                data[\trajectorySynthDefs][i].notNil
                                            }
                                        }) {
                                            data[\trajectorySynthDefs][i].asString
                                        } {
                                            (defaults[\defaultSynthDef] ? \upicWavetable8ch).asString
                                        };

                                        maxChannels = case
                                            { edgeSynthDefName.contains("24ch") } { 24 }
                                            { edgeSynthDefName.contains("15ch") } { 15 }
                                            { edgeSynthDefName.contains("12ch") } { 12 }
                                            { edgeSynthDefName.contains("8ch") } { 8 }
                                            { edgeSynthDefName.contains("4ch") } { 4 }
                                            { edgeSynthDefName.contains("3ch") } { 3 }
                                            { edgeSynthDefName.contains("2ch") } { 2 }
                                            { true } { 1 };

                                        // Pan2 (2ch) vs PanAz (3ch+) use different ranges
                                        if(maxChannels == 2) {
                                            edgePan = startChannel * 2 - 1;
                                        } {
                                            edgePan = startChannel * 2 / maxChannels;
                                        };
                                    } {
                                        // No spatial envelope - use time-based pan
                                        edgePan = currentTime.linlin(0, state[\playDuration], -1, 1);
                                    };
                                    if(state[\synths][i].notNil) {
                                        state[\synths][i].set(\freq, freq, \pan, edgePan, \amp, 0.2);
                                        activeSynthCount = activeSynthCount + 1;
                                    };
                                };
                            };
                        } {
                            // Outside trajectory range - stay silent
                            if(state[\synths][i].notNil) {
                                state[\synths][i].set(\amp, 0.0);
                            };
                        };
                        // End of trajectory processing
                    } {
                        // Trajectory hasn't started yet or is too small
                        if(state[\synths][i].notNil) {
                            state[\synths][i].set(\amp, 0.0);
                        };
                    };
                };

                // Let playback continue for full duration regardless of active synth count
                // This ensures visual playback line continues to the end even if audio stops
                // Only log when there are no active synths for debugging
                if(activeSynthCount == 0 and: { (frameCount % 120 == 0) and: { frameCount > 0 } }) {
                    ("No active synths at time " ++ currentTime.round(0.1) ++ "s (continuing playback)").postln;
                };

                // Debug: Occasionally log active synth count
                if((frameCount % 120 == 0) and: { frameCount > 0 }) {
                    ("Active synths: " ++ activeSynthCount ++ " at time " ++ currentTime.round(0.1) ++ "s").postln;
                };

                // Refresh display at UI frame rate only
                if(shouldUpdateUI) {
                    { state[\drawView].refresh }.defer;
                    lastUIUpdateTime = actualElapsedTime;
                };

                audioFrameCount = audioFrameCount + 1;
                if(shouldUpdateUI) { frameCount = frameCount + 1 };
                audioFrameTime.wait;
            };

            // End of playback
            state[\isPlaying] = false;
            state[\synths].do { |synth|
                if(synth.notNil) { synth.set(\gate, 0) };
            };
            state[\synths].clear;
            state[\playbackPosition] = 0;

            // Stop master limiter
            if(~nUPIC_voiceManager.notNil) {
                ~nUPIC_voiceManager.stopMasterLimiter.value;
                ~nUPIC_voiceManager.updateVoiceCount.value(0);
            };

            // Update play button to show 'Play' state (value 0) since playback ended
            if(state[\controls].notNil and: { state[\controls][\playButton].notNil }) {
                { state[\controls][\playButton].value = 0 }.defer;
            };

            { state[\drawView].refresh }.defer;
            "Playback completed - play button reset".postln;
        }; // End of fork
    }.play; // End of Task.play

    "Playback started".postln;
};

~nUPIC[\ui][\stopPlayback] = {
    var state = ~nUPIC[\ui][\state];

    if(state.isNil) { ^nil };

    state[\isPlaying] = false;

    if(state[\playbackTask].notNil) {
        state[\playbackTask].stop;
        state[\playbackTask] = nil;
    };

    if(state[\synths].notNil) {
        state[\synths].do { |synth|
            if(synth.notNil) {
                synth.set(\gate, 0);
            };
        };
        state[\synths].clear;
    };

    state[\playbackPosition] = 0;

    if(state[\drawView].notNil) {
        { state[\drawView].refresh }.defer;
    };

    "Playback stopped".postln;
};

// Window management functions
~nUPIC[\ui][\isWindowOpen] = {
    var state = ~nUPIC[\ui][\state];
    state.notNil and: {
        state[\window].notNil and: {
            state[\window].isClosed.not
        }
    }
};

~nUPIC[\ui][\closeMainWindow] = {
    var state = ~nUPIC[\ui][\state];
    if(state.notNil and: { state[\window].notNil }) {
        if(state[\window].isClosed.not) {
            state[\window].close;
        };
    };
};

~nUPIC[\ui][\refreshDisplay] = {
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        // Refresh main drawing view
        if(state[\drawView].notNil) {
            { state[\drawView].refresh }.defer;
        };
        // Also refresh frequency label view to update labels with zoom changes
        if(state[\freqLabelView].notNil) {
            { state[\freqLabelView].refresh }.defer;
        };
    };
};

// Emergency stop function
~nUPIC[\ui][\emergencyStop] = {
    "EMERGENCY STOP - Stopping all audio and processes".postln;

    ~nUPIC[\ui][\stopPlayback].value;

    // Free all synths on server
    s.freeAll;

    // Clear any tasks
    Task.allTasks.do { |task| task.stop };

    "Emergency stop complete".postln;
};

// Doppler effect control functions
~nUPIC[\ui][\setDopplerSensitivity] = { |sensitivity = 1.0|
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        state[\dopplerSensitivity] = sensitivity.clip(0, 3.0);
        ("Doppler sensitivity set to: " ++ state[\dopplerSensitivity]).postln;
        if(sensitivity == 0) {
            "Doppler effect DISABLED".postln;
        } {
            "Doppler effect ENABLED (sensitivity: " ++ sensitivity ++ ")".postln;
        };
    };
};

~nUPIC[\ui][\enableDoppler] = { |sensitivity = 1.0|
    ~nUPIC[\ui][\setDopplerSensitivity].value(sensitivity);
    "Doppler effect enabled with sensitivity " ++ sensitivity.postln;
};

~nUPIC[\ui][\disableDoppler] = {
    ~nUPIC[\ui][\setDopplerSensitivity].value(0);
    "Doppler effect disabled".postln;
};

~nUPIC[\ui][\getDopplerSensitivity] = {
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        state[\dopplerSensitivity] ? 0.0
    } {
        0.0
    }
};

"nUPIC Main Window module loaded".postln;
)
