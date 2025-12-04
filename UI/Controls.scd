// nUPIC UI Controls Module
// UI controls like sliders, buttons, menus for zoom, playback, mode switching
// Part of the nUPIC (nu-UPIC) modular system

(
// Ensure nUPIC UI namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

// Initialize controls
~nUPIC[\ui][\initializeControls] = { |window, width, height, controlsHeight|
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var defaults = ~nUPIC[\defaults];
    var yStart = height + 8;  // Match freqLabelGap from MainWindow.scd
    
    if(state.isNil) {
        "UI state not initialized".postln;
        ^nil;
    };
    
    // Store control references
    if(state[\controls].isNil) {
        state[\controls] = IdentityDictionary.new;
    };
    
    // CLEAN LAYOUT: All controls at bottom only
    
    // Bottom panel with all controls organized in compact rows
    ~nUPIC[\ui][\createBottomPanel].value(window, width, yStart, controlsHeight);
    
    // Set up keyboard controls
    ~nUPIC[\ui][\initializeKeyboard].value(window);
    
    "UI Controls initialized with proper spacing".postln;
};

// Total Duration control
~nUPIC[\ui][\createDurationControl] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var defaults = ~nUPIC[\defaults];
    var durationNumberBox, durationLabel;
    
    // Duration control label
    durationLabel = StaticText(window, Rect(10, yStart, 120, 20))
        .string_("Total Duration (s):")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    // Duration number box
    durationNumberBox = NumberBox(window, Rect(140, yStart, 80, 25))
        .value_(state[\playDuration] ? defaults[\playDuration] ? 10)
        .decimals_(1)
        .step_(0.5)
        .clipLo_(0.1)
        .clipHi_(240.0)
        .action_({ |nb|
            var newDuration = nb.value.clip(0.1, 240.0);
            state[\playDuration] = newDuration;
            ("Total playback duration set to " ++ newDuration ++ " seconds").postln;
            
            // Update zoom system when duration changes
            if(~nUPIC[\ui][\onDurationChange].notNil) {
                ~nUPIC[\ui][\onDurationChange].value;
            };
        });
    
    // Duration status
    StaticText(window, Rect(230, yStart, 300, 20))
        .string_("(Range: 0.1-240 seconds, controls total playback time for entire trajectory drawing)")
        .stringColor_(Color.gray(0.6))
        .font_(Font("Arial", 10));
    
    // Store references
    state[\controls][\durationNumberBox] = durationNumberBox;
    state[\controls][\durationLabel] = durationLabel;
};

// Duration controls removed - now using variable speed function
// The drawing area represents musical space rather than fixed time duration

// Frequency zoom controls
~nUPIC[\ui][\createFrequencyZoomControls] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var freqMin = constants[\freqMin] ? 20;
    var freqMax = constants[\freqMax] ? 7500;
    var zoomSlider, zoomLabel, centerFreqSlider, centerFreqLabel;
    
    StaticText(window, Rect(10, yStart, 100, 20))
        .string_("Freq Zoom:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    zoomLabel = StaticText(window, Rect(width - 150, yStart, 140, 20))
        .string_(freqMin.round(1).asString ++ "-" ++ freqMax.round(1).asString ++ " Hz")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    zoomSlider = Slider(window, Rect(120, yStart, 200, 20))
        .value_(0.0)  // 0.0 = no zoom, 1.0 = max zoom
        .action_({ |sl|
            var centerFreqSlider = state[\controls][\centerFreqSlider];
            if(sl.value == 0) {
                // No zoom - show full range
                state[\zoomFreqMin] = freqMin;
                state[\zoomFreqMax] = freqMax;
            } {
                // Apply zoom based on center frequency
                var zoomFactor = sl.value.linexp(0.001, 1, 1.001, 50); // exponential zoom up to 50x
                var centerFreq = if(centerFreqSlider.notNil) {
                    centerFreqSlider.value.linlin(0, 1, freqMin, freqMax)
                } { (freqMin + freqMax) / 2 };
                var range = (freqMax - freqMin) / zoomFactor;
                state[\zoomFreqMin] = (centerFreq - (range / 2)).clip(freqMin, freqMax);
                state[\zoomFreqMax] = (centerFreq + (range / 2)).clip(freqMin, freqMax);
            };
            zoomLabel.string = "%-%Hz".format(state[\zoomFreqMin].round(1), state[\zoomFreqMax].round(1));
            ~nUPIC[\ui][\refreshDisplay].value;
        });
    
    StaticText(window, Rect(340, yStart, 100, 20))
        .string_("Center Freq:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    centerFreqLabel = StaticText(window, Rect(width - 400, yStart, 80, 20))
        .string_(((freqMin + freqMax) / 2).round(1).asString ++ " Hz")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    centerFreqSlider = Slider(window, Rect(450, yStart, 200, 20))
        .value_(0.5)  // center of range
        .action_({ |sl|
            var centerFreq = sl.value.linlin(0, 1, freqMin, freqMax);
            centerFreqLabel.string = centerFreq.round(1).asString ++ " Hz";
            if(zoomSlider.notNil) { zoomSlider.doAction }; // update zoom with new center
        });
    
    state[\controls][\zoomSlider] = zoomSlider;
    state[\controls][\zoomLabel] = zoomLabel;
    state[\controls][\centerFreqSlider] = centerFreqSlider;
    state[\controls][\centerFreqLabel] = centerFreqLabel;
};

// Intuitive zoom view controls - starts at 1/10th duration view
~nUPIC[\ui][\createZoomViewControls] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var zoomInButton, zoomOutButton, zoomLevelLabel, timeRangeLabel, freqZoomInButton, freqZoomOutButton;
    var freqStatusLabel;
    
    // Initialize zoom system if not already done
    if(state[\zoomLevels].isNil) {
        ~nUPIC[\ui][\initializeZoomSystem].value;
    };
    
    // Zoom Horizontal section
    StaticText(window, Rect(10, yStart, 120, 20))
        .string_("Zoom Horizontal:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    // Horizontal Zoom In button (more detail)
    zoomInButton = Button(window, Rect(10, yStart + 25, 40, 25))
        .states_([["+", Color.black, Color.green.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\zoomIn].value;
            // Update labels
            if(zoomLevelLabel.notNil and: { state[\zoomLevels].notNil } and: { state[\currentZoomLevel].notNil }) {
                var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                if(currentLevel.notNil) {
                    zoomLevelLabel.string = currentLevel.name;
                };
            };
            if(timeRangeLabel.notNil) {
                timeRangeLabel.string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    // Horizontal Zoom Out button (less detail)
    zoomOutButton = Button(window, Rect(60, yStart + 25, 40, 25))
        .states_([["-", Color.black, Color.red.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\zoomOut].value;
            // Update labels
            if(zoomLevelLabel.notNil and: { state[\zoomLevels].notNil } and: { state[\currentZoomLevel].notNil }) {
                var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                if(currentLevel.notNil) {
                    zoomLevelLabel.string = currentLevel.name;
                };
            };
            if(timeRangeLabel.notNil) {
                timeRangeLabel.string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    // Zoom Vertical section (with large spacing)
    StaticText(window, Rect(150, yStart, 100, 20))
        .string_("Zoom Vertical:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    // Vertical Zoom In button
    freqZoomInButton = Button(window, Rect(150, yStart + 25, 40, 25))
        .states_([["+", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\freqZoomIn].value;
            // Update frequency status if label exists
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    // Vertical Zoom Out button  
    freqZoomOutButton = Button(window, Rect(200, yStart + 25, 40, 25))
        .states_([["-", Color.black, Color.magenta.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\freqZoomOut].value;
            // Update frequency status if label exists
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    // Current zoom level display (moved further right)
    zoomLevelLabel = StaticText(window, Rect(280, yStart, 150, 20))
        .string_(if(state[\zoomLevels].notNil and: { state[\currentZoomLevel].notNil }) {
            state[\zoomLevels][state[\currentZoomLevel]].name
        } { "Not initialized" })
        .stringColor_(Color.blue)
        .font_(Font("Arial", 12, true));
    
    // Current time range display (moved further right)
    timeRangeLabel = StaticText(window, Rect(450, yStart, 200, 20))
        .string_(if(~nUPIC[\ui][\getCurrentTimeRange].notNil) {
            ~nUPIC[\ui][\getCurrentTimeRange].value
        } { "Initializing..." })
        .stringColor_(Color.gray(0.3))
        .font_(Font("Arial", 11));
    
    // Frequency status display (moved to align under vertical zoom)
    freqStatusLabel = StaticText(window, Rect(280, yStart + 25, 150, 20))
        .string_(state[\zoomFreqMin].round(1).asString ++ "-" ++ state[\zoomFreqMax].round(1).asString ++ " Hz")
        .stringColor_(Color.gray(0.3))
        .font_(Font("Arial", 10));
    
    state[\controls][\freqStatusLabel] = freqStatusLabel;
    
    // Navigation arrows section
    StaticText(window, Rect(450, yStart + 25, 80, 20))
        .string_("Navigate:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 11));
    
    // Arrow buttons for navigation - arranged in cross pattern
    // Up arrow (frequency up)
    Button(window, Rect(550, yStart + 5, 30, 20))
        .states_([["↑", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panFrequency].value(\up);
            // Update frequency status label
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    // Left arrow (time left)
    Button(window, Rect(520, yStart + 25, 30, 20))
        .states_([["←", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panView].value(\left);
            // Update time range label
            if(state[\controls][\timeRangeLabel].notNil) {
                state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    // Right arrow (time right)
    Button(window, Rect(580, yStart + 25, 30, 20))
        .states_([["→", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panView].value(\right);
            // Update time range label
            if(state[\controls][\timeRangeLabel].notNil) {
                state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    // Down arrow (frequency down)
    Button(window, Rect(550, yStart + 45, 30, 20))
        .states_([["↓", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panFrequency].value(\down);
            // Update frequency status label
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    state[\controls][\zoomInButton] = zoomInButton;
    state[\controls][\zoomOutButton] = zoomOutButton;
    state[\controls][\zoomLevelLabel] = zoomLevelLabel;
    state[\controls][\timeRangeLabel] = timeRangeLabel;
    state[\controls][\freqZoomInButton] = freqZoomInButton;
    state[\controls][\freqZoomOutButton] = freqZoomOutButton;
};

// Mode and tool controls
~nUPIC[\ui][\createModeControls] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var playButton, eraseModeButton, gridButton, gridTypeMenu;
    
    // Play/Stop button
    playButton = Button(window, Rect(10, yStart, 60, 25))
        .states_([
            ["Play", Color.white, Color.green],
            ["Stop", Color.white, Color.red]
        ])
        .value_(0)
        .action_({ |btn|
            if(btn.value == 1) {
                ~nUPIC[\ui][\startPlayback].value;
            } {
                ~nUPIC[\ui][\stopPlayback].value;
            };
        });
    
    // Erase mode button
    eraseModeButton = Button(window, Rect(80, yStart, 80, 25))
        .states_([
            ["Erase", Color.black, Color.gray(0.9)],
            ["ERASING", Color.white, Color.red]
        ])
        .value_(0)
        .action_({ |btn|
            state[\eraseMode] = btn.value == 1;
            if(state[\eraseMode]) {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;  // Clear selections when entering erase mode
                };
                state[\selectMode] = false;  // Turn off select mode when entering erase mode
                ~nUPIC[\ui][\refreshDisplay].value;
                "Erase mode ON - click and drag to erase trajectories".postln;
            } {
                "Erase mode OFF".postln;
            };
        });
    
    // Select mode button
    Button(window, Rect(170, yStart, 80, 25))
        .states_([
            ["Select", Color.black, Color.gray(0.9)],
            ["SELECTING", Color.white, Color.blue]
        ])
        .value_(0)
        .action_({ |btn|
            state[\selectMode] = btn.value == 1;
            if(state[\selectMode]) {
                state[\eraseMode] = false;  // Turn off erase mode
                if(eraseModeButton.notNil) { eraseModeButton.value = 0 };
                "Select mode ON - click trajectories to select".postln;
            } {
                // Clear trajectory selections when switching to draw mode
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                    ~nUPIC[\ui][\refreshDisplay].value;
                };
                "Select mode OFF - draw mode active (selections cleared)".postln;
            };
        });
    
    // Grid controls
    gridButton = Button(window, Rect(260, yStart, 80, 25))
        .states_([
            ["Grid ON", Color.black, Color.gray(0.9)],
            ["Grid OFF", Color.white, Color.gray(0.6)]
        ])
        .value_(0)
        .action_({ |btn|
            state[\showGrid] = btn.value == 0;
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid " ++ if(state[\showGrid]) { "ON" } { "OFF" }).postln;
        });
    
    gridTypeMenu = PopUpMenu(window, Rect(350, yStart, 150, 25))
        .items_([
            "Equal Temperament",
            "31-tone Fokker", 
            "Harmonic Series",
            "Just Intonation",
            "Quarter-tone (24-TET)",
            "Pythagorean"
        ])
        .value_(0)
        .action_({ |menu|
            var gridTypes = [\equalTemperament, \fokker31, \harmonicSeries, \just, \quarterTone, \pythagorean];
            state[\gridType] = gridTypes[menu.value];
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid type: " ++ state[\gridType]).postln;
        });
    
    // Help text
    StaticText(window, Rect(510, yStart, 300, 20))
        .string_("(E: Erase | G: Select | T: Grid | SPACE: Play | H: Help)")
        .stringColor_(Color.gray(0.5))
        .font_(Font("Arial", 10));
    
    state[\controls][\playButton] = playButton;
    state[\controls][\eraseModeButton] = eraseModeButton;
    state[\controls][\gridButton] = gridButton;
    state[\controls][\gridTypeMenu] = gridTypeMenu;
};

// Action buttons and settings
~nUPIC[\ui][\createActionControls] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var synthDefMenu, synthDefLabel;
    
    // Clear button
    Button(window, Rect(10, yStart, 60, 25))
        .states_([["Clear All", Color.white, Color.red.alpha_(0.8)]])
        .action_({
            if(data.notNil) {
                if(data[\trajectories].notNil) { data[\trajectories].clear };
                if(data[\amplitudeEnvelopes].notNil) { data[\amplitudeEnvelopes].clear };
                if(data[\trajectorySynthDefs].notNil) { data[\trajectorySynthDefs].clear };
                if(data[\selectedTrajectories].notNil) { data[\selectedTrajectories].clear };
            };
            state[\currentTrajectory] = nil;
            
            // Stop any playing synths
            if(state[\synths].notNil) {
                state[\synths].do { |synth| 
                    if(synth.notNil) { synth.set(\gate, 0) } 
                };
                state[\synths].clear;
            };
            
            ~nUPIC[\ui][\refreshDisplay].value;
            "All trajectories cleared".postln;
        });
    
    // Amplitude editor button
    Button(window, Rect(80, yStart, 120, 25))
        .states_([["Edit Amplitudes", Color.white, Color.blue]])
        .action_({
            "Edit Amplitudes button clicked".postln;
            
            // Check for selected trajectories and open amplitude editor
            if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
                // Try to load AmplitudeEditor if not loaded
                if(~nUPIC[\ui][\openAmplitudeEditorForSelected].isNil) {
                    "Loading AmplitudeEditor module...".postln;
                    try {
                        // Use correct path with basePath
                        (~nUPIC_basePath +/+ "UI/AmplitudeEditor.scd").load;
                        "AmplitudeEditor module loaded".postln;
                    } { |error|
                        ("ERROR loading AmplitudeEditor: " ++ error.errorString).postln;
                    };
                };
                
                // Call the amplitude editor function
                if(~nUPIC[\ui][\openAmplitudeEditorForSelected].notNil) {
                    "Opening amplitude editor for selected trajectories...".postln;
                    try {
                        ~nUPIC[\ui][\openAmplitudeEditorForSelected].value;
                    } { |error|
                        ("ERROR calling amplitude editor: " ++ error.errorString).postln;
                    };
                } {
                    "ERROR: AmplitudeEditor functions still not available".postln;
                    "Attempting to manually load and register amplitude editor functions...".postln;
                    
                    // Create the amplitude editor functions directly as a fallback
                    ~nUPIC[\ui][\openAmplitudeEditorForSelected] = {
                        var selectedTrajs = data[\selectedTrajectories];
                        if(selectedTrajs.notNil and: { selectedTrajs.size > 0 }) {
                            var selectedArray = selectedTrajs.asArray.sort;
                            ("Creating basic amplitude editor for trajectories: " ++ selectedArray).postln;
                            
                            // Try to create the full amplitude editor
                            try {
                                ~nUPIC[\ui][\createDrawableAmplitudeEditor] = { |trajIndices|
                                    var ampWin, drawView, controlView;
                                    var winWidth = 800, winHeight = 500;
                                    var drawHeight = 350, controlHeight = 150;
                                    var isDrawing = false, currentTraj = 0;
                                    var currentEnvelope = List.new;
                                    var trajectoryLength, trajectoryStart;
                                    
                                    // Get trajectory info for the first selected trajectory
                                    var firstTraj = if(trajIndices.size > 0) {
                                        data[\trajectories][trajIndices[0]]
                                    } { nil };
                                    
                                    if(firstTraj.notNil and: { firstTraj.size > 0 }) {
                                        trajectoryStart = firstTraj[0].x ? firstTraj[0].x ? 0;
                                        trajectoryLength = (firstTraj.last.x ? firstTraj.last.x ? 600) - trajectoryStart;
                                    } {
                                        trajectoryStart = 0;
                                        trajectoryLength = 600;
                                    };
                                    
                                    // Create window
                                    try {
                                        ampWin = Window.new("Amplitude Envelope Editor", 
                                            Rect(100, 100, winWidth, winHeight));
                                    } { |error|
                                        ("Window creation failed: " ++ error.errorString).postln;
                                        ^nil;
                                    };
                                    
                                    ampWin.background = Color.gray(0.95);
                                    
                                    // Create drawing area
                                    drawView = UserView(ampWin, Rect(0, 0, winWidth, drawHeight));
                                    drawView.background = Color.white;
                                    
                                    // Initialize amplitude envelopes if needed
                                    if(data[\amplitudeEnvelopes].isNil) {
                                        data[\amplitudeEnvelopes] = List.new;
                                    };
                                    
                                    // Ensure amplitude envelopes exist for selected trajectories
                                    trajIndices.do { |trajIdx|
                                        while(data[\amplitudeEnvelopes].size <= trajIdx) {
                                            data[\amplitudeEnvelopes].add(nil);
                                        };
                                        
                                        // Initialize with default envelope if needed
                                        if(data[\amplitudeEnvelopes][trajIdx].isNil) {
                                            data[\amplitudeEnvelopes][trajIdx] = List[
                                                (x: 0, amp: 0.5),
                                                (x: trajectoryLength, amp: 0.5)
                                            ];
                                        };
                                    };
                                    
                                    currentEnvelope = data[\amplitudeEnvelopes][trajIndices[currentTraj]] ? List.new;
                                    
                                    // Draw function
                                    drawView.drawFunc = {
                                        var currentTrajIdx, envelope, y, ampLevel, x, timePos, screenX, screenY;
                                        
                                        currentTrajIdx = trajIndices[currentTraj];
                                        envelope = data[\amplitudeEnvelopes][currentTrajIdx];
                                        
                                        // Clear background
                                        Pen.fillColor = Color.white;
                                        Pen.fillRect(Rect(0, 0, winWidth, drawHeight));
                                        
                                        // Draw grid
                                        Pen.strokeColor = Color.gray(0.8);
                                        Pen.width = 1;
                                        
                                        // Horizontal grid lines (amplitude levels)
                                        5.do { |i|
                                            y = i * (drawHeight / 4);
                                            Pen.line(Point(0, y), Point(winWidth, y));
                                            Pen.stroke;
                                            
                                            // Amplitude labels
                                            ampLevel = (4 - i) * 0.25;
                                            Pen.fillColor = Color.black;
                                            Pen.stringAtPoint(ampLevel.round(0.01).asString, 
                                                Point(5, y - 10), Font("Arial", 10));
                                        };
                                        
                                        // Vertical grid lines (time)
                                        10.do { |i|
                                            x = (i + 1) * (winWidth / 11);
                                            Pen.strokeColor = Color.gray(0.9);
                                            Pen.line(Point(x, 0), Point(x, drawHeight));
                                            Pen.stroke;
                                            
                                            // Time labels
                                            timePos = ((i + 1) / 11) * trajectoryLength;
                                            Pen.fillColor = Color.black;
                                            Pen.stringAtPoint(timePos.round(1).asString, 
                                                Point(x - 15, drawHeight - 15), Font("Arial", 9));
                                        };
                                        
                                        // Draw current envelope
                                        if(envelope.notNil and: { envelope.size > 1 }) {
                                            Pen.strokeColor = Color.red;
                                            Pen.fillColor = Color.red.alpha_(0.3);
                                            Pen.width = 2;
                                            
                                            // Draw envelope as filled area
                                            Pen.moveTo(Point(0, drawHeight)); // Start at bottom left
                                            
                                            envelope.do { |point, i|
                                                var screenX = (point.x / trajectoryLength) * winWidth;
                                                var screenY = drawHeight - (point.amp * drawHeight);
                                                Pen.lineTo(Point(screenX, screenY));
                                            };
                                            
                                            // Close the shape
                                            Pen.lineTo(Point(winWidth, drawHeight));
                                            Pen.lineTo(Point(0, drawHeight));
                                            Pen.fill;
                                            
                                            // Draw envelope line
                                            Pen.strokeColor = Color.red;
                                            Pen.width = 3;
                                            envelope.do { |point, i|
                                                var screenX = (point.x / trajectoryLength) * winWidth;
                                                var screenY = drawHeight - (point.amp * drawHeight);
                                                if(i == 0) {
                                                    Pen.moveTo(Point(screenX, screenY));
                                                } {
                                                    Pen.lineTo(Point(screenX, screenY));
                                                };
                                            };
                                            Pen.stroke;
                                            
                                            // Draw control points
                                            Pen.fillColor = Color.blue;
                                            envelope.do { |point|
                                                var screenX = (point.x / trajectoryLength) * winWidth;
                                                var screenY = drawHeight - (point.amp * drawHeight);
                                                Pen.fillOval(Rect(screenX - 4, screenY - 4, 8, 8));
                                            };
                                        };
                                        
                                        // Draw instructions
                                        Pen.fillColor = Color.black;
                                        Pen.stringAtPoint("Click and drag to draw amplitude envelope. Trajectory " ++ currentTrajIdx ++ " (" ++ (currentTraj + 1) ++ " of " ++ trajIndices.size ++ ")", 
                                            Point(10, 5), Font("Arial", 12));
                                    };
                                    
                                    // Mouse interaction
                                    drawView.mouseDownAction = { |view, x, y, modifiers, buttonNumber, clickCount|
                                        var currentTrajIdx, timePos, ampValue;
                                        
                                        isDrawing = true;
                                        currentTrajIdx = trajIndices[currentTraj];
                                        
                                        // Start new envelope
                                        currentEnvelope = List.new;
                                        
                                        // Add first point
                                        timePos = (x / winWidth) * trajectoryLength;
                                        ampValue = (drawHeight - y) / drawHeight;
                                        currentEnvelope.add((x: timePos, amp: ampValue.clip(0, 1)));
                                        
                                        view.refresh;
                                    };
                                    
                                    drawView.mouseMoveAction = { |view, x, y, modifiers|
                                        var timePos, ampValue;
                                        
                                        if(isDrawing) {
                                            timePos = (x / winWidth) * trajectoryLength;
                                            ampValue = (drawHeight - y) / drawHeight;
                                            
                                            // Add point if it's far enough from the last one
                                            if(currentEnvelope.size == 0 or: {
                                                (timePos - currentEnvelope.last.x).abs > (trajectoryLength / 100)
                                            }) {
                                                currentEnvelope.add((x: timePos, amp: ampValue.clip(0, 1)));
                                                view.refresh;
                                            };
                                        };
                                    };
                                    
                                    drawView.mouseUpAction = { |view, x, y, modifiers, buttonNumber|
                                        var currentTrajIdx;
                                        
                                        if(isDrawing) {
                                            isDrawing = false;
                                            currentTrajIdx = trajIndices[currentTraj];
                                            
                                            // Ensure envelope starts at 0 and ends at trajectory length
                                            if(currentEnvelope.size > 0) {
                                                if(currentEnvelope[0].x > 0) {
                                                    currentEnvelope = List[(x: 0, amp: currentEnvelope[0].amp)] ++ currentEnvelope;
                                                };
                                                if(currentEnvelope.last.x < trajectoryLength) {
                                                    currentEnvelope.add((x: trajectoryLength, amp: currentEnvelope.last.amp));
                                                };
                                                
                                                // Sort by x position
                                                currentEnvelope = currentEnvelope.sort({ |a, b| a.x < b.x });
                                                
                                                // Store the envelope
                                                data[\amplitudeEnvelopes][currentTrajIdx] = currentEnvelope;
                                                
                                                ("Amplitude envelope drawn for trajectory " ++ currentTrajIdx).postln;
                                            };
                                            
                                            view.refresh;
                                        };
                                    };
                                    
                                    // Create controls area
                                    controlView = CompositeView(ampWin, 
                                        Rect(0, drawHeight, winWidth, controlHeight));
                                    controlView.background = Color.gray(0.9);
                                    
                                    // Trajectory selector (if multiple trajectories)
                                    if(trajIndices.size > 1) {
                                        StaticText(controlView, Rect(10, 10, 100, 20))
                                            .string_("Trajectory:")
                                            .font_(Font("Arial", 12));
                                        
                                        PopUpMenu(controlView, Rect(110, 10, 150, 25))
                                            .items_(trajIndices.collect({ |idx| "Trajectory " ++ idx }))
                                            .value_(0)
                                            .action_({ |menu|
                                                currentTraj = menu.value;
                                                currentEnvelope = data[\amplitudeEnvelopes][trajIndices[currentTraj]] ? List.new;
                                                drawView.refresh;
                                            });
                                    };
                                    
                                    // Preset buttons
                                    Button(controlView, Rect(10, 50, 80, 30))
                                        .states_([["Fade In", Color.black, Color.green]])
                                        .action_({
                                            var currentTrajIdx = trajIndices[currentTraj];
                                            data[\amplitudeEnvelopes][currentTrajIdx] = List[
                                                (x: 0, amp: 0),
                                                (x: trajectoryLength, amp: 1)
                                            ];
                                            drawView.refresh;
                                        });
                                    
                                    Button(controlView, Rect(100, 50, 80, 30))
                                        .states_([["Fade Out", Color.black, Color.blue]])
                                        .action_({
                                            var currentTrajIdx = trajIndices[currentTraj];
                                            data[\amplitudeEnvelopes][currentTrajIdx] = List[
                                                (x: 0, amp: 1),
                                                (x: trajectoryLength, amp: 0)
                                            ];
                                            drawView.refresh;
                                        });
                                    
                                    Button(controlView, Rect(190, 50, 80, 30))
                                        .states_([["Constant", Color.black, Color.gray]])
                                        .action_({
                                            var currentTrajIdx = trajIndices[currentTraj];
                                            data[\amplitudeEnvelopes][currentTrajIdx] = List[
                                                (x: 0, amp: 0.7),
                                                (x: trajectoryLength, amp: 0.7)
                                            ];
                                            drawView.refresh;
                                        });
                                    
                                    Button(controlView, Rect(280, 50, 80, 30))
                                        .states_([["Clear", Color.white, Color.red]])
                                        .action_({
                                            var currentTrajIdx = trajIndices[currentTraj];
                                            data[\amplitudeEnvelopes][currentTrajIdx] = List[
                                                (x: 0, amp: 0),
                                                (x: trajectoryLength, amp: 0)
                                            ];
                                            drawView.refresh;
                                        });
                                    
                                    // Copy envelope to all selected trajectories
                                    Button(controlView, Rect(400, 50, 120, 30))
                                        .states_([["Copy to All", Color.black, Color.yellow]])
                                        .action_({
                                            var currentTrajIdx = trajIndices[currentTraj];
                                            var currentEnv = data[\amplitudeEnvelopes][currentTrajIdx];
                                            trajIndices.do { |trajIdx|
                                                if(trajIdx != currentTrajIdx) {
                                                    data[\amplitudeEnvelopes][trajIdx] = currentEnv.copy;
                                                };
                                            };
                                            "Copied amplitude envelope to all selected trajectories".postln;
                                        });
                                    
                                    Button(controlView, Rect(winWidth - 100, 100, 90, 30))
                                        .states_([["Close", Color.white, Color.red]])
                                        .action_({ ampWin.close });
                                    
                                    // Instructions
                                    StaticText(controlView, Rect(10, 90, 600, 40))
                                        .string_("Click and drag in the drawing area to create amplitude envelopes.\nUse preset buttons for common shapes. Red area shows amplitude over time.")
                                        .font_(Font("Arial", 10))
                                        .stringColor_(Color.gray(0.3));
                                    
                                    ampWin.front;
                                    drawView.refresh;
                                    "Drawable amplitude editor opened for " ++ trajIndices.size ++ " trajectories".postln;
                                    ampWin;
                                };
                                
                                ~nUPIC[\ui][\createDrawableAmplitudeEditor].value(selectedArray);
                            } { |error|
                                ("Could not create amplitude editor window: " ++ error.errorString).postln;
                                "You can manually set amplitude envelopes using:".postln;
                                "~nUPIC[\\data][\\amplitudeEnvelopes][trajIndex] = List[(x: 0, amp: 0.5), (x: 600, amp: 0.5)];".postln;
                            };
                        } {
                            "No trajectories selected for amplitude editing".postln;
                        };
                    };
                    
                    // Now call the newly created function
                    "Calling basic amplitude editor...".postln;
                    ~nUPIC[\ui][\openAmplitudeEditorForSelected].value;
                };
            } {
                "No trajectories selected. Select trajectories first by pressing G and clicking on them.".postln;
            };
        });
    
    // Reset zoom button
    Button(window, Rect(210, yStart, 80, 25))
        .states_([["Reset Zoom", Color.black, Color.gray(0.9)]])
        .action_({
            var zoomSlider = state[\controls][\zoomSlider];
            var timeZoomSlider = state[\controls][\timeZoomSlider];
            if(zoomSlider.notNil) {
                zoomSlider.value = 0.0;
                zoomSlider.doAction;
            };
            if(timeZoomSlider.notNil) {
                timeZoomSlider.value = 0.0;
                timeZoomSlider.doAction;
            };
            "Zoom reset to full range".postln;
        });
    
    // SynthDef selection
    synthDefLabel = StaticText(window, Rect(300, yStart, 80, 20))
        .string_("SynthDef:")
        .font_(Font("Arial", 12));
    
    synthDefMenu = PopUpMenu(window, Rect(380, yStart, 150, 25))
        .items_(if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ~nUPIC_SynthDefs[\available].collect(_.asString)
        } { ["upicWavetable"] })
        .value_(0)
        .action_({ |menu|
            var synthDefNames = if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
                ~nUPIC_SynthDefs[\available]
            } { [\upicWavetable] };
            var selectedSynth = synthDefNames[menu.value];
            if(data.notNil and: { data[\selectedTrajectories].notNil } and: {
                data[\selectedTrajectories].size > 0
            }) {
                if(data[\trajectorySynthDefs].isNil) {
                    data[\trajectorySynthDefs] = List.new;
                };
                data[\selectedTrajectories].do { |idx|
                    // Expand list if needed
                    while { idx >= data[\trajectorySynthDefs].size } {
                        data[\trajectorySynthDefs].add(nil);
                    };
                    data[\trajectorySynthDefs][idx] = selectedSynth;
                    ("Trajectory " ++ idx ++ " set to use " ++ selectedSynth).postln;
                    // Refresh spatial editor if open
                    ("DEBUG Controls: refresh func exists? " ++ ~nUPIC[\ui][\refreshSpatializationEditor].notNil).postln;
                    if(~nUPIC[\ui][\refreshSpatializationEditor].notNil) {
                        ("DEBUG Controls: calling refresh(" ++ idx ++ ")").postln;
                        ~nUPIC[\ui][\refreshSpatializationEditor].value(idx);
                    } {
                        "DEBUG Controls: refresh func is nil!".postln;
                    };
                };
            } {
                // Set default for new trajectories - always use fresh reference
                if(~nUPIC[\defaults].notNil) {
                    ~nUPIC[\defaults][\defaultSynthDef] = selectedSynth;
                };
                ("Default SynthDef set to " ++ selectedSynth ++ " for new trajectories").postln;
            };
        });

    // Help text
    StaticText(window, Rect(540, yStart, 300, 20))
        .string_("(Select trajectories then choose SynthDef)")
        .stringColor_(Color.gray(0.5))
        .font_(Font("Arial", 10));
    
    state[\controls][\synthDefMenu] = synthDefMenu;
    state[\controls][\synthDefLabel] = synthDefLabel;
};

// Status and help controls (row 6)
~nUPIC[\ui][\createStatusControls] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    
    // Status text
    StaticText(window, Rect(10, yStart, 400, 40))
        .string_("Status: Ready\nPress G for select mode, E for erase mode, SPACE to play")
        .font_(Font("Arial", 10))
        .stringColor_(Color.gray(0.5));
    
    // Help button
    Button(window, Rect(width - 100, yStart, 80, 25))
        .states_([["Help", Color.black, Color.gray(0.9)]])
        .action_({
            ~nUPIC[\ui][\showHelp].value;
        });
};

// Keyboard controls initialization
~nUPIC[\ui][\initializeKeyboard] = { |window|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    
    window.view.keyDownAction = { |view, char, mod, unicode, keycode|
        case
        // Spacebar - play/stop
        { keycode == 49 } {
            var playButton = state[\controls][\playButton];
            if(playButton.notNil) {
                playButton.value = 1 - playButton.value;
                playButton.doAction;
            };
        }
        // C - clear all
        { char == $c } {
            if(data.notNil) {
                if(data[\trajectories].notNil) { data[\trajectories].clear };
                if(data[\amplitudeEnvelopes].notNil) { data[\amplitudeEnvelopes].clear };
                if(data[\trajectorySynthDefs].notNil) { data[\trajectorySynthDefs].clear };
                if(data[\selectedTrajectories].notNil) { data[\selectedTrajectories].clear };
            };
            state[\currentTrajectory] = nil;
            ~nUPIC[\ui][\refreshDisplay].value;
            "All trajectories cleared".postln;
        }
        // E - toggle erase mode
        { char == $e } {
            var eraseButton = state[\controls][\eraseModeButton];
            if(eraseButton.notNil) {
                eraseButton.value = 1 - eraseButton.value;
                eraseButton.doAction;
            };
        }
        // G - toggle select mode
        { char == $g } {
            state[\selectMode] = state[\selectMode].not;
            if(state[\selectMode]) {
                state[\eraseMode] = false;  // Turn off erase mode
                if(state[\controls][\eraseModeButton].notNil) {
                    state[\controls][\eraseModeButton].value = 0;
                };
                "Select mode ON - click trajectories to select".postln;
            } {
                // Clear trajectory selections when switching to draw mode
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                    ~nUPIC[\ui][\refreshDisplay].value;
                };
                "Select mode OFF - draw mode active (selections cleared)".postln;
            };
        }
        // R - reset zoom
        { char == $r } {
            var zoomSlider = state[\controls][\zoomSlider];
            var timeZoomSlider = state[\controls][\timeZoomSlider];
            if(zoomSlider.notNil) {
                zoomSlider.value = 0.0;
                zoomSlider.doAction;
            };
            if(timeZoomSlider.notNil) {
                timeZoomSlider.value = 0.0;
                timeZoomSlider.doAction;
            };
            "Zoom reset".postln;
        }
        // ESC - emergency stop
        { keycode == 53 } {
            ~nUPIC[\ui][\emergencyStop].value;
        }
        // H - help
        { char == $h } {
            ~nUPIC[\ui][\showHelp].value;
        }
        // Arrow keys with Alt - pan view (new zoom system)
        // Left arrow with Alt
        { keycode == 123 and: { mod & 524288 > 0 } } {
            if(~nUPIC[\ui][\panView].notNil) {
                ~nUPIC[\ui][\panView].value(\left);
                // Update UI labels if they exist
                if(state[\controls][\timeRangeLabel].notNil) {
                    state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
                };
            } {
                "Pan system not initialized".postln;
            };
        }
        // Right arrow with Alt
        { keycode == 124 and: { mod & 524288 > 0 } } {
            if(~nUPIC[\ui][\panView].notNil) {
                ~nUPIC[\ui][\panView].value(\right);
                // Update UI labels if they exist
                if(state[\controls][\timeRangeLabel].notNil) {
                    state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
                };
            } {
                "Pan system not initialized".postln;
            };
        }
        // Up arrow with Alt - frequency zoom in
        { keycode == 126 and: { mod & 524288 > 0 } } {
            if(~nUPIC[\ui][\freqZoomIn].notNil) {
                ~nUPIC[\ui][\freqZoomIn].value;
                // Update frequency status if label exists
                if(state[\controls][\freqStatusLabel].notNil) {
                    var freqMin = state[\zoomFreqMin].round(1);
                    var freqMax = state[\zoomFreqMax].round(1);
                    state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
                };
            } {
                "Frequency zoom system not initialized".postln;
            };
        }
        // Down arrow with Alt - frequency zoom out
        { keycode == 125 and: { mod & 524288 > 0 } } {
            if(~nUPIC[\ui][\freqZoomOut].notNil) {
                ~nUPIC[\ui][\freqZoomOut].value;
                // Update frequency status if label exists
                if(state[\controls][\freqStatusLabel].notNil) {
                    var freqMin = state[\zoomFreqMin].round(1);
                    var freqMax = state[\zoomFreqMax].round(1);
                    state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
                };
            } {
                "Frequency zoom system not initialized".postln;
            };
        }
        // Plus/Minus keys for zooming
        { char == $= } { // Plus key (Shift + =)
            if(~nUPIC[\ui][\zoomIn].notNil) {
                ~nUPIC[\ui][\zoomIn].value;
                // Update UI labels
                if(state[\controls][\zoomLevelLabel].notNil and: { state[\zoomLevels].notNil } and: { state[\currentZoomLevel].notNil }) {
                    var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                    if(currentLevel.notNil) {
                        state[\controls][\zoomLevelLabel].string = currentLevel.name;
                    };
                };
                if(state[\controls][\timeRangeLabel].notNil) {
                    state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
                };
            };
        }
        { char == $- } { // Minus key
            if(~nUPIC[\ui][\zoomOut].notNil) {
                ~nUPIC[\ui][\zoomOut].value;
                // Update UI labels
                if(state[\controls][\zoomLevelLabel].notNil and: { state[\zoomLevels].notNil } and: { state[\currentZoomLevel].notNil }) {
                    var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                    if(currentLevel.notNil) {
                        state[\controls][\zoomLevelLabel].string = currentLevel.name;
                    };
                };
                if(state[\controls][\timeRangeLabel].notNil) {
                    state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
                };
            };
        }
        // Arrow keys without Alt - move selected trajectories
        // Left arrow (no Alt)
        { keycode == 123 and: { mod & 524288 == 0 } } {
            ~nUPIC[\ui][\moveSelectedTrajectories].value(-1, 0);
        }
        // Right arrow (no Alt)
        { keycode == 124 and: { mod & 524288 == 0 } } {
            ~nUPIC[\ui][\moveSelectedTrajectories].value(1, 0);
        }
        // Up arrow (no Alt)
        { keycode == 126 and: { mod & 524288 == 0 } } {
            ~nUPIC[\ui][\moveSelectedTrajectories].value(0, -1);
        }
        // Down arrow (no Alt)
        { keycode == 125 and: { mod & 524288 == 0 } } {
            ~nUPIC[\ui][\moveSelectedTrajectories].value(0, 1);
        }
        // Cmd+C - copy selected trajectories
        { char == $c and: { mod & 1048576 > 0 } } {
            ~nUPIC[\ui][\copySelected].value;
        }
        // Cmd+V - paste trajectories
        { char == $v and: { mod & 1048576 > 0 } } {
            ~nUPIC[\ui][\pasteTrajectories].value;
        }
        // T - toggle grid (moved from G key)
        { char == $t } {
            var gridButton = state[\controls][\gridButton];
            if(gridButton.notNil) {
                gridButton.value = 1 - gridButton.value;
                gridButton.doAction;
            };
        };
    };
    
    window.view.canFocus = true;
    window.view.focus;
};

// Help system
~nUPIC[\ui][\showHelp] = {
    var helpWindow, helpText;
    
    helpWindow = Window("nUPIC Help", Rect(200, 200, 600, 400));
    helpWindow.background = Color.white;
    
    helpText = StaticText(helpWindow, Rect(10, 10, 580, 380))
        .string_("nUPIC - Trajectory Synthesis System\n\n" ++
        "DRAWING:\n" ++
        "• Click and drag to draw frequency trajectories\n" ++
        "• Release mouse to complete trajectory\n\n" ++
        "SELECTION:\n" ++
        "• Press G to enter select mode\n" ++
        "• Click on trajectories to select them\n" ++
        "• Shift+click to toggle selection\n" ++
        "• Cmd+click to add to selection\n" ++
        "• Drag selected trajectories to move them\n\n" ++
        "EDITING:\n" ++
        "• Press E to toggle erase mode\n" ++
        "• Click and drag to erase parts of trajectories\n" ++
        "• Use 'Edit Amplitudes' button to open amplitude editors\n\n" ++
        "PLAYBACK:\n" ++
        "• Press SPACE to play/stop\n" ++
        "• Use Duration slider to change playback length\n\n" ++
        "ZOOM & VIEW:\n" ++
        "• Use F+ and F- buttons to zoom frequency range (20-7500Hz)\n" ++
        "• Use +/- keys for time zoom\n" ++
        "• Press R to reset all zoom\n" ++
        "• Press T to toggle grid display\n\n" ++
        "KEYBOARD SHORTCUTS:\n" ++
        "• SPACE: Play/Stop\n" ++
        "• G: Toggle select mode (clears selections when exiting)\n" ++
        "• E: Toggle erase mode\n" ++
        "• T: Toggle grid display\n" ++
        "• C: Clear all trajectories\n" ++
        "• Cmd+C: Copy selected trajectories\n" ++
        "• Cmd+V: Paste trajectories\n" ++
        "• Arrow Keys: Move selected trajectories\n" ++
        "• Option+Left/Right: Pan time view\n" ++
        "• Option+Up/Down: Frequency zoom in/out\n" ++
        "• +/-: Time zoom in/out\n" ++
        "• R: Reset zoom\n" ++
        "• ESC: Emergency stop\n" ++
        "• H: Show this help")
        .font_(Font("Arial", 12))
        .stringColor_(Color.black);
    
    helpWindow.front;
};

// NEW COMPACT LAYOUT FUNCTIONS

// ROW 1: Playback controls and Duration
~nUPIC[\ui][\createPlaybackRow] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var playButton, durationNumberBox;
    
    // Play/Stop button
    playButton = Button(window, Rect(10, yStart, 60, 25))
        .states_([
            ["Play", Color.white, Color.green],
            ["Stop", Color.white, Color.red]
        ])
        .value_(0)
        .action_({ |btn|
            if(btn.value == 1) {
                ~nUPIC[\ui][\startPlayback].value;
            } {
                ~nUPIC[\ui][\stopPlayback].value;
            };
        });
    
    // Duration control (compact)
    StaticText(window, Rect(80, yStart, 80, 20))
        .string_("Duration:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 11));
    
    durationNumberBox = NumberBox(window, Rect(160, yStart, 60, 25))
        .value_(state[\playDuration] ? defaults[\playDuration] ? 10)
        .decimals_(1)
        .step_(0.5)
        .clipLo_(0.1)
        .clipHi_(240.0)
        .action_({ |nb|
            var newDuration = nb.value.clip(0.1, 240.0);
            state[\playDuration] = newDuration;
            ("Total playback duration set to " ++ newDuration ++ " seconds").postln;
            
            if(~nUPIC[\ui][\onDurationChange].notNil) {
                ~nUPIC[\ui][\onDurationChange].value;
            };
        });
    
    StaticText(window, Rect(230, yStart, 30, 20))
        .string_("sec")
        .stringColor_(Color.gray(0.6))
        .font_(Font("Arial", 10));
    
    // Emergency Stop button
    Button(window, Rect(280, yStart, 80, 25))
        .states_([["STOP ALL", Color.white, Color.red]])
        .action_({
            ~nUPIC[\ui][\emergencyStop].value;
        });
    
    // Clear All button
    Button(window, Rect(370, yStart, 70, 25))
        .states_([["Clear All", Color.white, Color.red.alpha_(0.8)]])
        .action_({
            if(data.notNil) {
                if(data[\trajectories].notNil) { data[\trajectories].clear };
                if(data[\amplitudeEnvelopes].notNil) { data[\amplitudeEnvelopes].clear };
                if(data[\trajectorySynthDefs].notNil) { data[\trajectorySynthDefs].clear };
                if(data[\selectedTrajectories].notNil) { data[\selectedTrajectories].clear };
            };
            state[\currentTrajectory] = nil;
            
            if(state[\synths].notNil) {
                state[\synths].do { |synth| 
                    if(synth.notNil) { synth.set(\gate, 0) } 
                };
                state[\synths].clear;
            };
            
            ~nUPIC[\ui][\refreshDisplay].value;
            "All trajectories cleared".postln;
        });
    
    // Status indicator (compact)
    StaticText(window, Rect(460, yStart, 200, 25))
        .string_("Ready | Keys: SPACE=Play G=Select E=Erase T=Grid")
        .stringColor_(Color.gray(0.5))
        .font_(Font("Arial", 9));
    
    state[\controls][\playButton] = playButton;
    state[\controls][\durationNumberBox] = durationNumberBox;
};

// ROW 2: Zoom and navigation controls  
~nUPIC[\ui][\createZoomNavigationRow] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var zoomInButton, zoomOutButton, freqZoomInButton, freqZoomOutButton;
    var zoomLevelLabel, timeRangeLabel, freqStatusLabel;
    
    // Initialize zoom system if needed
    if(state[\zoomLevels].isNil) {
        ~nUPIC[\ui][\initializeZoomSystem].value;
    };
    
    // Time Zoom controls (compact)
    StaticText(window, Rect(10, yStart, 70, 20))
        .string_("Time Zoom:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 11));
    
    zoomInButton = Button(window, Rect(80, yStart, 30, 23))
        .states_([["+", Color.black, Color.green.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\zoomIn].value;
            if(zoomLevelLabel.notNil and: { state[\zoomLevels].notNil } and: { state[\currentZoomLevel].notNil }) {
                var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                if(currentLevel.notNil) {
                    zoomLevelLabel.string = currentLevel.name;
                };
            };
            if(timeRangeLabel.notNil) {
                timeRangeLabel.string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    zoomOutButton = Button(window, Rect(115, yStart, 30, 23))
        .states_([["-", Color.black, Color.red.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\zoomOut].value;
            if(zoomLevelLabel.notNil and: { state[\zoomLevels].notNil } and: { state[\currentZoomLevel].notNil }) {
                var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                if(currentLevel.notNil) {
                    zoomLevelLabel.string = currentLevel.name;
                };
            };
            if(timeRangeLabel.notNil) {
                timeRangeLabel.string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    // Frequency Zoom controls
    StaticText(window, Rect(170, yStart, 70, 20))
        .string_("Freq Zoom:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 11));
    
    freqZoomInButton = Button(window, Rect(240, yStart, 30, 23))
        .states_([["+", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\freqZoomIn].value;
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    freqZoomOutButton = Button(window, Rect(275, yStart, 30, 23))
        .states_([["-", Color.black, Color.magenta.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\freqZoomOut].value;
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    // Navigation arrows (compact cross layout)
    StaticText(window, Rect(320, yStart, 50, 20))
        .string_("Navigate:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 10));
    
    // Arrow buttons in compact cross pattern
    Button(window, Rect(380, yStart - 8, 25, 18))  // Up
        .states_([["↑", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panFrequency].value(\up);
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    Button(window, Rect(355, yStart + 7, 25, 18))  // Left
        .states_([["←", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panView].value(\left);
            if(state[\controls][\timeRangeLabel].notNil) {
                state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    Button(window, Rect(405, yStart + 7, 25, 18))  // Right
        .states_([["→", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panView].value(\right);
            if(state[\controls][\timeRangeLabel].notNil) {
                state[\controls][\timeRangeLabel].string = ~nUPIC[\ui][\getCurrentTimeRange].value;
            };
        });
    
    Button(window, Rect(380, yStart + 22, 25, 18))  // Down
        .states_([["↓", Color.black, Color.yellow.alpha_(0.3)]])
        .action_({
            ~nUPIC[\ui][\panFrequency].value(\down);
            if(state[\controls][\freqStatusLabel].notNil) {
                var freqMin = state[\zoomFreqMin].round(1);
                var freqMax = state[\zoomFreqMax].round(1);
                state[\controls][\freqStatusLabel].string = freqMin.asString ++ "-" ++ freqMax.asString ++ " Hz";
            };
        });
    
    // Status displays (compact)
    zoomLevelLabel = StaticText(window, Rect(450, yStart, 120, 20))
        .string_(if(state[\zoomLevels].notNil and: { state[\currentZoomLevel].notNil }) {
            state[\zoomLevels][state[\currentZoomLevel]].name
        } { "Full View" })
        .stringColor_(Color.blue)
        .font_(Font("Arial", 10, true));
    
    timeRangeLabel = StaticText(window, Rect(580, yStart, 150, 20))
        .string_(if(~nUPIC[\ui][\getCurrentTimeRange].notNil) {
            ~nUPIC[\ui][\getCurrentTimeRange].value
        } { "0-100%" })
        .stringColor_(Color.gray(0.4))
        .font_(Font("Arial", 9));
    
    freqStatusLabel = StaticText(window, Rect(450, yStart + 12, 120, 20))
        .string_(state[\zoomFreqMin].round(1).asString ++ "-" ++ state[\zoomFreqMax].round(1).asString ++ " Hz")
        .stringColor_(Color.gray(0.4))
        .font_(Font("Arial", 9));
    
    // Store references
    state[\controls][\zoomInButton] = zoomInButton;
    state[\controls][\zoomOutButton] = zoomOutButton;
    state[\controls][\freqZoomInButton] = freqZoomInButton;
    state[\controls][\freqZoomOutButton] = freqZoomOutButton;
    state[\controls][\zoomLevelLabel] = zoomLevelLabel;
    state[\controls][\timeRangeLabel] = timeRangeLabel;
    state[\controls][\freqStatusLabel] = freqStatusLabel;
};

// ROW 3: Mode controls, tools and settings
~nUPIC[\ui][\createToolsAndSettingsRow] = { |window, width, yStart|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var eraseModeButton, selectModeButton, gridButton, gridTypeMenu, synthDefMenu;
    
    // Mode buttons (compact)
    eraseModeButton = Button(window, Rect(10, yStart, 60, 23))
        .states_([
            ["Erase", Color.black, Color.gray(0.9)],
            ["ERASING", Color.white, Color.red]
        ])
        .value_(0)
        .action_({ |btn|
            state[\eraseMode] = btn.value == 1;
            if(state[\eraseMode]) {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                };
                state[\selectMode] = false;
                if(selectModeButton.notNil) { selectModeButton.value = 0 };
                ~nUPIC[\ui][\refreshDisplay].value;
                "Erase mode ON".postln;
            } {
                "Erase mode OFF".postln;
            };
        });
    
    selectModeButton = Button(window, Rect(75, yStart, 60, 23))
        .states_([
            ["Select", Color.black, Color.gray(0.9)],
            ["SELECTING", Color.white, Color.blue]
        ])
        .value_(0)
        .action_({ |btn|
            state[\selectMode] = btn.value == 1;
            if(state[\selectMode]) {
                state[\eraseMode] = false;
                if(eraseModeButton.notNil) { eraseModeButton.value = 0 };
                "Select mode ON".postln;
            } {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                    ~nUPIC[\ui][\refreshDisplay].value;
                };
                "Draw mode active".postln;
            };
        });
    
    // Grid controls
    gridButton = Button(window, Rect(140, yStart, 50, 23))
        .states_([
            ["Grid ON", Color.black, Color.gray(0.9)],
            ["Grid OFF", Color.white, Color.gray(0.6)]
        ])
        .value_(0)
        .action_({ |btn|
            state[\showGrid] = btn.value == 0;
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid " ++ if(state[\showGrid]) { "ON" } { "OFF" }).postln;
        });
    
    gridTypeMenu = PopUpMenu(window, Rect(195, yStart, 140, 23))
        .items_([
            "Equal Temperament",
            "31-tone Fokker", 
            "Harmonic Series",
            "Just Intonation",
            "Quarter-tone",
            "Pythagorean"
        ])
        .value_(0)
        .action_({ |menu|
            var gridTypes = [\equalTemperament, \fokker31, \harmonicSeries, \just, \quarterTone, \pythagorean];
            state[\gridType] = gridTypes[menu.value];
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid: " ++ state[\gridType]).postln;
        });
    
    // Tools
    Button(window, Rect(345, yStart, 80, 23))
        .states_([["Edit Amps", Color.white, Color.blue]])
        .action_({
            if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
                if(~nUPIC[\ui][\openAmplitudeEditorForSelected].isNil) {
                    try {
                        (~nUPIC_basePath +/+ "UI/AmplitudeEditor.scd").load;
                    } { |error|
                        "Error loading AmplitudeEditor".postln;
                    };
                };
                if(~nUPIC[\ui][\openAmplitudeEditorForSelected].notNil) {
                    ~nUPIC[\ui][\openAmplitudeEditorForSelected].value;
                } {
                    "Select trajectories first (G key, then click)".postln;
                };
            } {
                "Select trajectories first (G key, then click)".postln;
            };
        });
    
    Button(window, Rect(430, yStart, 60, 23))
        .states_([["Reset View", Color.black, Color.gray(0.9)]])
        .action_({
            if(~nUPIC[\ui][\resetAllZoom].notNil) {
                ~nUPIC[\ui][\resetAllZoom].value;
            };
            "View reset".postln;
        });
    
    // SynthDef selection (compact)
    StaticText(window, Rect(500, yStart, 60, 20))
        .string_("SynthDef:")
        .font_(Font("Arial", 10));
    
    synthDefMenu = PopUpMenu(window, Rect(560, yStart, 130, 23))
        .items_(if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ~nUPIC_SynthDefs[\available].collect(_.asString)
        } { ["simpleGravObject", "percNoise", "auditoryDistortion", "richTexture"] })
        .value_(0)
        .action_({ |menu|
            var synthDefNames = if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
                ~nUPIC_SynthDefs[\available]
            } { [\simpleGravObject, \percNoise, \auditoryDistortion, \richTexture] };
            var selectedSynth = synthDefNames[menu.value];
            if(data.notNil and: { data[\selectedTrajectories].notNil } and: {
                data[\selectedTrajectories].size > 0
            }) {
                if(data[\trajectorySynthDefs].isNil) {
                    data[\trajectorySynthDefs] = List.new;
                };
                data[\selectedTrajectories].do { |idx|
                    // Expand list if needed
                    while { idx >= data[\trajectorySynthDefs].size } {
                        data[\trajectorySynthDefs].add(nil);
                    };
                    data[\trajectorySynthDefs][idx] = selectedSynth;
                    ("Trajectory " ++ idx ++ " → " ++ selectedSynth).postln;
                    // Refresh spatial editor if open
                    ("DEBUG Controls2: refresh func exists? " ++ ~nUPIC[\ui][\refreshSpatializationEditor].notNil).postln;
                    if(~nUPIC[\ui][\refreshSpatializationEditor].notNil) {
                        ("DEBUG Controls2: calling refresh(" ++ idx ++ ")").postln;
                        ~nUPIC[\ui][\refreshSpatializationEditor].value(idx);
                    } {
                        "DEBUG Controls2: refresh func is nil!".postln;
                    };
                };
            } {
                // Always use fresh reference to ~nUPIC[\defaults]
                if(~nUPIC[\defaults].notNil) {
                    ~nUPIC[\defaults][\defaultSynthDef] = selectedSynth;
                };
                ("Default SynthDef: " ++ selectedSynth).postln;
            };
        });

    // Store references
    state[\controls][\eraseModeButton] = eraseModeButton;
    state[\controls][\gridButton] = gridButton;
    state[\controls][\gridTypeMenu] = gridTypeMenu;
    state[\controls][\synthDefMenu] = synthDefMenu;
};

// Compact help at bottom
~nUPIC[\ui][\createCompactHelp] = { |window, width, yStart|
    // Help button and quick reference
    Button(window, Rect(10, yStart, 60, 20))
        .states_([["Help", Color.black, Color.gray(0.9)]])
        .action_({
            ~nUPIC[\ui][\showHelp].value;
        });
    
    StaticText(window, Rect(80, yStart, width - 90, 20))
        .string_("Quick Keys: SPACE=Play/Stop | G=Select | E=Erase | T=Grid | +/-=Zoom | Arrows=Navigate | R=Reset | H=Help | ESC=Emergency Stop")
        .stringColor_(Color.gray(0.5))
        .font_(Font("Arial", 9));
};

// NEW SIDEBAR-BASED LAYOUT FUNCTIONS

// Left Tools Sidebar
~nUPIC[\ui][\createToolsSidebar] = { |window, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var x = 80, y = 40, buttonWidth = 35, buttonHeight = 30;
    var eraseModeButton, selectModeButton, gridButton;
    
    // Mode tools vertically arranged
    
    // Select mode button (top)
    selectModeButton = Button(window, Rect(x, y, buttonWidth, buttonHeight))
        .states_([
            ["SEL", Color.black, Color.gray(0.9)],
            ["SEL", Color.white, Color.blue]
        ])
        .value_(0)
        .action_({ |btn|
            state[\selectMode] = btn.value == 1;
            if(state[\selectMode]) {
                state[\eraseMode] = false;
                if(eraseModeButton.notNil) { eraseModeButton.value = 0 };
                "Select mode ON".postln;
            } {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                    ~nUPIC[\ui][\refreshDisplay].value;
                };
                "Draw mode active".postln;
            };
        });
    
    // Erase mode button
    eraseModeButton = Button(window, Rect(x, y + 35, buttonWidth, buttonHeight))
        .states_([
            ["ERA", Color.black, Color.gray(0.9)],
            ["ERA", Color.white, Color.red]
        ])
        .value_(0)
        .action_({ |btn|
            state[\eraseMode] = btn.value == 1;
            if(state[\eraseMode]) {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                };
                state[\selectMode] = false;
                if(selectModeButton.notNil) { selectModeButton.value = 0 };
                ~nUPIC[\ui][\refreshDisplay].value;
                "Erase mode ON".postln;
            } {
                "Erase mode OFF".postln;
            };
        });
    
    // Grid toggle button  
    gridButton = Button(window, Rect(x, y + 70, buttonWidth, buttonHeight))
        .states_([
            ["GRD", Color.black, Color.gray(0.9)],
            ["GRD", Color.white, Color.gray(0.6)]
        ])
        .value_(0)
        .action_({ |btn|
            state[\showGrid] = btn.value == 0;
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid " ++ if(state[\showGrid]) { "ON" } { "OFF" }).postln;
        });
    
    // Clear button
    Button(window, Rect(x, y + 105, buttonWidth, buttonHeight))
        .states_([["CLR", Color.white, Color.red.alpha_(0.8)]])
        .action_({
            if(data.notNil) {
                if(data[\trajectories].notNil) { data[\trajectories].clear };
                if(data[\amplitudeEnvelopes].notNil) { data[\amplitudeEnvelopes].clear };
                if(data[\trajectorySynthDefs].notNil) { data[\trajectorySynthDefs].clear };
                if(data[\selectedTrajectories].notNil) { data[\selectedTrajectories].clear };
            };
            state[\currentTrajectory] = nil;
            
            if(state[\synths].notNil) {
                state[\synths].do { |synth| 
                    if(synth.notNil) { synth.set(\gate, 0) } 
                };
                state[\synths].clear;
            };
            
            ~nUPIC[\ui][\refreshDisplay].value;
            "All cleared".postln;
        });
    
    // Reset view button
    Button(window, Rect(x, y + 140, buttonWidth, buttonHeight))
        .states_([["RST", Color.black, Color.gray(0.9)]])
        .action_({
            if(~nUPIC[\ui][\resetAllZoom].notNil) {
                ~nUPIC[\ui][\resetAllZoom].value;
            };
            "View reset".postln;
        });
    
    // Store references
    state[\controls][\eraseModeButton] = eraseModeButton;
    state[\controls][\gridButton] = gridButton;
};

// Right Settings Sidebar
~nUPIC[\ui][\createSettingsSidebar] = { |window, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var x = width - 115, y = 40, sidebarWidth = 110;
    var gridTypeMenu, synthDefMenu, freqStatusLabel, timeRangeLabel, zoomLevelLabel;
    
    // Tuning system selection
    StaticText(window, Rect(x, y, sidebarWidth, 15))
        .string_("Tuning System:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 9, true));
    
    gridTypeMenu = PopUpMenu(window, Rect(x, y + 18, sidebarWidth, 20))
        .items_([
            "Equal Temp",
            "31-tone", 
            "Harmonic",
            "Just Inton",
            "Quarter-tone",
            "Pythagorean"
        ])
        .value_(0)
        .font_(Font("Arial", 9))
        .action_({ |menu|
            var gridTypes = [\equalTemperament, \fokker31, \harmonicSeries, \just, \quarterTone, \pythagorean];
            state[\gridType] = gridTypes[menu.value];
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid: " ++ state[\gridType]).postln;
        });
    
    // SynthDef selection
    StaticText(window, Rect(x, y + 50, sidebarWidth, 15))
        .string_("Synthesis:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 9, true));
    
    synthDefMenu = PopUpMenu(window, Rect(x, y + 68, sidebarWidth, 20))
        .items_(if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ~nUPIC_SynthDefs[\available].collect { |name|
                case
                { name == \simpleGravObject } { "GravObject" }
                { name == \simpleGravObj2 } { "GravObj2" }
                { name == \richTexture } { "RichTexture" }
                { name == \percNoise } { "PercNoise" }
                { name == \auditoryDistortion } { "Distortion" }
                { name == \testSinOsc } { "TestSine" }
                { name == \testSinOscVibrato } { "TestVibrato" }
                { name == \simpleSine } { "SimpleSine" }
                { name == \simpleVarSaw } { "SimpleVarSaw" }
                { name == \efficientDefault } { "Efficient" }
                { name == \ultraLightVarSaw } { "UltraLight" }
                { name == \optimizedSimple } { "Optimized" }
                { name.asString }
            }
        } { ["GravObject", "PercNoise", "Distortion", "RichTexture"] })
        .value_(0)
        .font_(Font("Arial", 9))
        .action_({ |menu|
            var synthDefNames = if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
                ~nUPIC_SynthDefs[\available]
            } { [\simpleGravObject, \percNoise, \auditoryDistortion, \richTexture] };
            var selectedSynth = synthDefNames[menu.value];
            if(data.notNil and: { data[\selectedTrajectories].notNil } and: { 
                data[\selectedTrajectories].size > 0 
            }) {
                if(data[\trajectorySynthDefs].isNil) {
                    data[\trajectorySynthDefs] = List.new;
                };
                data[\selectedTrajectories].do { |idx|
                    if(idx < data[\trajectorySynthDefs].size) {
                        data[\trajectorySynthDefs][idx] = selectedSynth;
                        ("Traj " ++ idx ++ " → " ++ selectedSynth).postln;
                    };
                };
            } {
                // Always use fresh reference to ~nUPIC[\defaults]
                if(~nUPIC[\defaults].notNil) {
                    ~nUPIC[\defaults][\defaultSynthDef] = selectedSynth;
                };
                ("Default: " ++ selectedSynth).postln;
            };
        });

    // Status displays
    StaticText(window, Rect(x, y + 100, sidebarWidth, 15))
        .string_("View Status:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 9, true));
    
    // Initialize zoom system if needed
    if(state[\zoomLevels].isNil) {
        ~nUPIC[\ui][\initializeZoomSystem].value;
    };
    
    zoomLevelLabel = StaticText(window, Rect(x, y + 118, sidebarWidth, 12))
        .string_(if(state[\zoomLevels].notNil and: { state[\currentZoomLevel].notNil }) {
            state[\zoomLevels][state[\currentZoomLevel]].name
        } { "Full View" })
        .stringColor_(Color.blue)
        .font_(Font("Arial", 8));
    
    timeRangeLabel = StaticText(window, Rect(x, y + 132, sidebarWidth, 12))
        .string_(if(~nUPIC[\ui][\getCurrentTimeRange].notNil) {
            ~nUPIC[\ui][\getCurrentTimeRange].value
        } { "0-100%" })
        .stringColor_(Color.gray(0.4))
        .font_(Font("Arial", 8));
    
    freqStatusLabel = StaticText(window, Rect(x, y + 146, sidebarWidth, 12))
        .string_(state[\zoomFreqMin].round(1).asString ++ "-" ++ state[\zoomFreqMax].round(1).asString ++ " Hz")
        .stringColor_(Color.gray(0.4))
        .font_(Font("Arial", 8));
    
    // Store references
    state[\controls][\gridTypeMenu] = gridTypeMenu;
    state[\controls][\synthDefMenu] = synthDefMenu;
    state[\controls][\freqStatusLabel] = freqStatusLabel;
    state[\controls][\timeRangeLabel] = timeRangeLabel;
    state[\controls][\zoomLevelLabel] = zoomLevelLabel;
};

// Bottom Panel with ALL controls organized in rows
~nUPIC[\ui][\createBottomPanel] = { |window, width, yStart, panelHeight|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var playButton, durationNumberBox;
    var zoomInButton, zoomOutButton, freqZoomInButton, freqZoomOutButton;
    var gridTypeMenu, synthDefMenu, eraseModeButton, selectModeButton, gridButton;
    var row2Y, row3Y, row4Y, zoomLevelLabel, timeRangeLabel, freqStatusLabel;
    var playbackGroupView, totalControlWidth, startX, controlY;
    var playbackBorderView, modeActionBorderView, modeActionGroupView;
    var modeActionControlY, buttonGap, modeStartX;
    var bAndKGreen, bgColor;
    var playbackGroupWidth, playbackGroupHeight, modeActionContentWidth, modeActionGroupWidth, modeActionGroupHeight;
    var navX;
    var tuningContentWidth, tuningGroupWidth, tuningGroupHeight, tuningGroupX, tuningBorderView, tuningGroupView;
    var synthDefLabel;
    var navContentWidth, navGroupWidth, navGroupHeight, navGroupX, navBorderView, navGroupView, centerX, centerY;
    // Amplitude editing group variables
    var ampEditContentWidth, ampEditGroupWidth, ampEditGroupHeight, ampEditGroupX;
    var ampEditBorderView, ampEditGroupView, editAmpsButton;
    // Wavetable editor group variables
    var wavetableContentWidth, wavetableGroupWidth, wavetableGroupHeight, wavetableGroupX;
    var wavetableBorderView, wavetableGroupView, editWavetableButton;
    // Help controls group variables
    var helpContentWidth, helpGroupWidth, helpGroupHeight, helpGroupX;
    var helpBorderView, helpGroupView, helpButton;
    // Analysis tools group variables
    var analysisContentWidth, analysisGroupWidth, analysisGroupHeight, analysisGroupX;
    var analysisBorderView, analysisGroupView, scMeterButton, freqScopeButton;
    // Spatialization editor group variables
    var spatialEditContentWidth, spatialEditGroupWidth, spatialEditGroupHeight, spatialEditGroupX;
    var spatialEditBorderView, spatialEditGroupView, editSpatialButton;
    
    // ROW 1: Playback Controls Group
    // Calculate content size: 70 + 3 + 75 + 3 + 50 + 3 + 25 = 229px content + 10px margins (5px left + 5px right) = 239px
    totalControlWidth = 70 + 3 + 75 + 3 + 50 + 3 + 25; // 229px total content
    playbackGroupWidth = totalControlWidth + 10; // Add 5px left + 5px right margins
    playbackGroupHeight = 20 + 10; // 20px button height + 5px top + 5px bottom margins
    
    // Create background view with white border (5px margin from left edge)
    playbackBorderView = UserView(window, Rect(5, yStart, playbackGroupWidth, playbackGroupHeight));
    playbackBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(205/255, 250/255, 205/255)
        );
        
        // Use bAndKGreen (controlBackground) with increased alpha for lighter appearance
        bAndKGreen = colors[\controlBackground] ? Color.new(205/255, 250/255, 205/255);
        bgColor = bAndKGreen.alpha_(0.4);  // Increased alpha for lighter appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, playbackGroupWidth, playbackGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, playbackGroupWidth, playbackGroupHeight));
    };
    
    // Create the actual composite view inside the border with 5px margins
    playbackGroupView = CompositeView(playbackBorderView, Rect(5, 5, totalControlWidth, 20));
    
    // Calculate positions for controls with proper spacing
    startX = 0;  // Start at 0 within the composite view (margins handled by composite view position)
    controlY = 0;  // Start at 0 within the composite view
    
    // Play button (centered)
    playButton = Button(playbackGroupView, Rect(startX, controlY, 70, 20))
        .states_([
            ["_play", Color.white, Color.green],
            ["_stop", Color.white, Color.red]
        ])
        .value_(0)
        .font_(Font("Arial", 11, true))
        .action_({ |btn|
            if(btn.value == 1) {
                ~nUPIC[\ui][\startPlayback].value;
            } {
                ~nUPIC[\ui][\stopPlayback].value;
            };
        });
    
    // Duration label (centered) - made wider to fit text in one line, with 3px gap
    StaticText(playbackGroupView, Rect(startX + 70 + 3, controlY, 75, 20))
        .string_("_total duration")
        .stringColor_(Color.black)
        .background_(Color.white)
        .font_(Font("Arial", 11))
        .align_(\center);
    
    // Duration number box (centered) - adjusted position for wider label, with 3px gap
    durationNumberBox = NumberBox(playbackGroupView, Rect(startX + 70 + 3 + 75 + 3, controlY, 50, 20))
        .value_(state[\playDuration] ? defaults[\playDuration] ? 10)
        .decimals_(1)
        .step_(0.5)
        .clipLo_(0.1)
        .clipHi_(240.0)
        .font_(Font("Arial", 11))
        .action_({ |nb|
            var newDuration = nb.value.clip(0.1, 240.0);
            state[\playDuration] = newDuration;
            ("Duration: " ++ newDuration ++ "s").postln;
            
            if(~nUPIC[\ui][\onDurationChange].notNil) {
                ~nUPIC[\ui][\onDurationChange].value;
            };
        });
    
    // Seconds label (centered) - adjusted position for wider duration label, with 3px gap
    StaticText(playbackGroupView, Rect(startX + 70 + 3 + 75 + 3 + 50 + 3, controlY, 25, 20))
        .string_("sec")
        .stringColor_(Color.gray(0.6))
        .font_(Font("Arial", 11))
        .align_(\center);
    
    // Mode/Action Controls Group - similar to playback group
    // Calculate content size: 50 + 3 + 50 + 3 + 50 = 156px content + 10px margins = 166px
    modeActionContentWidth = 50 + 3 + 50 + 3 + 50; // 156px total content
    modeActionGroupWidth = modeActionContentWidth + 10; // Add 5px left + 5px right margins
    modeActionGroupHeight = 20 + 10; // 20px button height + 5px top + 5px bottom margins
    
    // Create background view with white border (positioned after playback group with 5px gap)
    modeActionBorderView = UserView(window, Rect(5 + playbackGroupWidth + 5, yStart, modeActionGroupWidth, modeActionGroupHeight));
    modeActionBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(250/255, 205/255, 205/255) // Light red tint for mode/action
        );
        
        // Use light red background for mode/action controls
        var modeActionColor = colors[\controlBackground] ? Color.new(250/255, 205/255, 205/255);
        var bgColor = modeActionColor.alpha_(0.4);  // Light appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, modeActionGroupWidth, modeActionGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, modeActionGroupWidth, modeActionGroupHeight));
    };
    
    // Create the actual composite view inside the border with 5px margins
    modeActionGroupView = CompositeView(modeActionBorderView, Rect(5, 5, modeActionContentWidth, 20));
    
    // Calculate positions for controls with proper spacing
    modeActionControlY = 0;  // Start at 0 within the composite view
    buttonGap = 3; // Minimum gap between buttons
    modeStartX = 0; // Start at 0 within the composite view
    
    // Select mode button (first button in the group)
    selectModeButton = Button(modeActionGroupView, Rect(modeStartX, modeActionControlY, 50, 20))
        .states_([
            ["_select", Color.black, Color.gray(0.9)],
            ["_selecting", Color.white, Color.blue]
        ])
        .value_(0)
        .font_(Font("Arial", 9))
        .action_({ |btn|
            state[\selectMode] = btn.value == 1;
            if(state[\selectMode]) {
                state[\eraseMode] = false;
                if(eraseModeButton.notNil) { eraseModeButton.value = 0 };
                "Select mode ON".postln;
            } {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                    ~nUPIC[\ui][\refreshDisplay].value;
                };
                "Draw mode active".postln;
            };
        });
    
    // Eraser mode button (second button in the group)
    eraseModeButton = Button(modeActionGroupView, Rect(modeStartX + 50 + buttonGap, modeActionControlY, 50, 20))
        .states_([
            ["_eraser", Color.black, Color.gray(0.9)],
            ["_erasing", Color.white, Color.red]
        ])
        .value_(0)
        .font_(Font("Arial", 9))
        .action_({ |btn|
            state[\eraseMode] = btn.value == 1;
            if(state[\eraseMode]) {
                if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                    data[\selectedTrajectories].clear;
                };
                state[\selectMode] = false;
                if(selectModeButton.notNil) { selectModeButton.value = 0 };
                ~nUPIC[\ui][\refreshDisplay].value;
                "Erase mode ON".postln;
            } {
                "Erase mode OFF".postln;
            };
        });
    
    // Grid button (third button in the group) - positioned after eraser button with proper spacing
    gridButton = Button(modeActionGroupView, Rect(modeStartX + 50 + buttonGap + 50 + buttonGap, modeActionControlY, 50, 20))
        .states_([
            ["_grid on", Color.black, Color.gray(0.9)],
            ["_grid off", Color.white, Color.gray(0.6)]
        ])
        .value_(0)
        .font_(Font("Arial", 8))
        .action_({ |btn|
            state[\showGrid] = btn.value == 0;
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid " ++ if(state[\showGrid]) { "ON" } { "OFF" }).postln;
        });
    
    // Mode buttons properly centered and fit within the white border group
    // Clear All functionality moved to another location if needed

    // Scale/SynthDef Controls group
    tuningContentWidth = 45 + 2 + 140 + 5 + 60 + 2 + 130; // Label + reduced margin + menu widths
    tuningGroupWidth = tuningContentWidth + 10; // Margins
    tuningGroupHeight = modeActionGroupHeight; // Match height of mode/action group
    tuningGroupX = 5 + playbackGroupWidth + 5 + modeActionGroupWidth + 5; // To the right of modeActionGroup

    tuningBorderView = UserView(window, Rect(tuningGroupX, yStart, tuningGroupWidth, tuningGroupHeight));
    tuningBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.white
        );
        Pen.fillColor = colors[\controlBackground].alpha_(0.4);
        Pen.fillRect(Rect(0, 0, tuningGroupWidth, tuningGroupHeight));
        
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, tuningGroupWidth, tuningGroupHeight));
    };

    tuningGroupView = CompositeView(tuningBorderView, Rect(5, 5, tuningContentWidth, 20));

    // Scale label
    StaticText(tuningGroupView, Rect(0, 0, 45, 20))
        .string_("_scale")
        .font_(Font("Arial", 10))
        .stringColor_(Color.black)
        .background_(Color.white)
        .align_(\center);

    // Scale menu
    gridTypeMenu = PopUpMenu(tuningGroupView, Rect(47, 0, 140, 20))
        .items_([
            "Equal Temperament",
            "31-tone Fokker",
            "Harmonic Series",
            "Just Intonation",
            "Quarter-tone",
            "Pythagorean"
        ])
        .value_(0)
        .font_(Font("Arial", 9))
        .action_({ |menu|
            var gridTypes = [\equalTemperament, \fokker31, \harmonicSeries, \just, \quarterTone, \pythagorean];
            state[\gridType] = gridTypes[menu.value];
            ~nUPIC[\ui][\refreshDisplay].value;
            ("Grid: " ++ state[\gridType]).postln;
        });

    // SynthDef label
    synthDefLabel = StaticText(tuningGroupView, Rect(192, 0, 60, 20))
        .string_("_synthdef")
        .font_(Font("Arial", 10))
        .stringColor_(Color.black)
        .background_(Color.white)
        .align_(\center);

    // SynthDef menu
    synthDefMenu = PopUpMenu(tuningGroupView, Rect(254, 0, 130, 20))
        .items_(if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ~nUPIC_SynthDefs[\available].collect(_.asString)
        } { ["upicWavetable"] })
        .value_(0)
        .font_(Font("Arial", 9))
        .action_({ |menu|
            var synthDefNames = if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
                ~nUPIC_SynthDefs[\available]
            } { [\upicWavetable] };
            var selectedSynth = synthDefNames[menu.value];
            if(data.notNil and: { data[\selectedTrajectories].notNil } and: {
                data[\selectedTrajectories].size > 0
            }) {
                if(data[\trajectorySynthDefs].isNil) {
                    data[\trajectorySynthDefs] = List.new;
                };
                data[\selectedTrajectories].do { |idx|
                    // Expand list if needed
                    while { idx >= data[\trajectorySynthDefs].size } {
                        data[\trajectorySynthDefs].add(nil);
                    };
                    data[\trajectorySynthDefs][idx] = selectedSynth;
                    ("Trajectory " ++ idx ++ " set to use " ++ selectedSynth).postln;
                    // Refresh spatial editor if open
                    ("DEBUG Controls3: refresh func exists? " ++ ~nUPIC[\ui][\refreshSpatializationEditor].notNil).postln;
                    if(~nUPIC[\ui][\refreshSpatializationEditor].notNil) {
                        ("DEBUG Controls3: calling refresh(" ++ idx ++ ")").postln;
                        ~nUPIC[\ui][\refreshSpatializationEditor].value(idx);
                    } {
                        "DEBUG Controls3: refresh func is nil!".postln;
                    };
                };
            } {
                // Always use fresh reference to ~nUPIC[\defaults]
                if(~nUPIC[\defaults].notNil) {
                    ~nUPIC[\defaults][\defaultSynthDef] = selectedSynth;
                };
                ("Default SynthDef set to " ++ selectedSynth ++ " for new trajectories").postln;
            };
        });

    // Amplitude Editing Controls Group - positioned after tuning group with same design principles
    // Only contains _edit amps button
    
    ampEditContentWidth = 80; // Just the button width
    ampEditGroupWidth = ampEditContentWidth + 10; // Add 5px left + 5px right margins
    ampEditGroupHeight = modeActionGroupHeight; // Match height of other groups
    ampEditGroupX = tuningGroupX + tuningGroupWidth + 5; // To the right of tuning group with 5px gap
    
    ampEditBorderView = UserView(window, Rect(ampEditGroupX, yStart, ampEditGroupWidth, ampEditGroupHeight));
    ampEditBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(255/255, 245/255, 220/255) // Light orange tint for amplitude editing
        );
        
        // Use light orange background for amplitude editing controls
        var ampEditColor = colors[\controlBackground] ? Color.new(255/255, 245/255, 220/255);
        var bgColor = ampEditColor.alpha_(0.4);  // Light appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, ampEditGroupWidth, ampEditGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, ampEditGroupWidth, ampEditGroupHeight));
    };
    
    ampEditGroupView = CompositeView(ampEditBorderView, Rect(5, 5, ampEditContentWidth, 20));
    
    // Edit Amplitudes button
    editAmpsButton = Button(ampEditGroupView, Rect(0, 0, 80, 20))
        .states_([["_edit amps", Color.white, Color.blue]])
        .font_(Font("Arial", 9, true))
        .action_({
            if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
                // Try to load AmplitudeEditor if not loaded
                if(~nUPIC[\ui][\openAmplitudeEditorForSelected].isNil) {
                    "Loading AmplitudeEditor module...".postln;
                    try {
                        (~nUPIC_basePath +/+ "UI/AmplitudeEditor.scd").load;
                        "AmplitudeEditor module loaded".postln;
                    } { |error|
                        ("ERROR loading AmplitudeEditor: " ++ error.errorString).postln;
                    };
                };
                
                // Call the amplitude editor function
                if(~nUPIC[\ui][\openAmplitudeEditorForSelected].notNil) {
                    "Opening amplitude editor for selected trajectories...".postln;
                    try {
                        ~nUPIC[\ui][\openAmplitudeEditorForSelected].value;
                    } { |error|
                        ("ERROR calling amplitude editor: " ++ error.errorString).postln;
                    };
                } {
                    "Select trajectories first (G key, then click on them)".postln;
                };
            } {
                "Select trajectories first (G key, then click on them)".postln;
            };
        });
    
    // Store reference (only the edit button now)
    state[\controls][\editAmpsButton] = editAmpsButton;
    
    // Initialize zoom system if needed
    if(state[\zoomLevels].isNil) {
        ~nUPIC[\ui][\initializeZoomSystem].value;
    };
    
    // Spatialization Editor Controls Group - positioned after amplitude editing group
    spatialEditContentWidth = 100; // Button width
    spatialEditGroupWidth = spatialEditContentWidth + 10; // Add margins
    spatialEditGroupHeight = modeActionGroupHeight; // Match height of other groups
    spatialEditGroupX = ampEditGroupX + ampEditGroupWidth + 5; // To the right of amplitude editing group
    
    spatialEditBorderView = UserView(window, Rect(spatialEditGroupX, yStart, spatialEditGroupWidth, spatialEditGroupHeight));
    spatialEditBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(255/255, 220/255, 255/255) // Light magenta tint for spatial
        );
        
        // Use light magenta background for spatial controls
        var spatialColor = colors[\controlBackground] ? Color.new(255/255, 220/255, 255/255);
        var bgColor = spatialColor.alpha_(0.4);  // Light appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, spatialEditGroupWidth, spatialEditGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, spatialEditGroupWidth, spatialEditGroupHeight));
    };
    
    spatialEditGroupView = CompositeView(spatialEditBorderView, Rect(5, 5, spatialEditContentWidth, 20));
    
    // Edit Spatialization button
    editSpatialButton = Button(spatialEditGroupView, Rect(0, 0, 100, 20))
        .states_([["_edit spatial", Color.white, Color.magenta.blend(Color.gray, 0.3)]])
        .font_(Font("Arial", 9, true))
        .action_({
            if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
                // Try to load SpatializationEditor if not loaded
                if(~nUPIC[\ui][\openSpatializationEditorForSelected].isNil) {
                    "Loading SpatializationEditor module...".postln;
                    try {
                        (~nUPIC_basePath +/+ "UI/SpatializationEditor.scd").load;
                        "SpatializationEditor module loaded".postln;
                    } { |error|
                        ("ERROR loading SpatializationEditor: " ++ error.errorString).postln;
                    };
                };
                
                // Call the spatialization editor function
                if(~nUPIC[\ui][\openSpatializationEditorForSelected].notNil) {
                    "Opening spatialization editor for selected trajectories...".postln;
                    try {
                        ~nUPIC[\ui][\openSpatializationEditorForSelected].value;
                    } { |error|
                        ("ERROR calling spatialization editor: " ++ error.errorString).postln;
                    };
                } {
                    "Select trajectories first (G key, then click on them)".postln;
                };
            } {
                "Select trajectories first (G key, then click on them)".postln;
            };
        });
    
    // Store reference
    state[\controls][\editSpatialButton] = editSpatialButton;
    
    // Wavetable Editor Controls Group - positioned after spatialization editing group
    wavetableContentWidth = 100; // Button width
    wavetableGroupWidth = wavetableContentWidth + 10; // Add margins
    wavetableGroupHeight = modeActionGroupHeight; // Match height of other groups
    wavetableGroupX = spatialEditGroupX + spatialEditGroupWidth + 5; // To the right of spatial editing group
    
    wavetableBorderView = UserView(window, Rect(wavetableGroupX, yStart, wavetableGroupWidth, wavetableGroupHeight));
    wavetableBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(220/255, 255/255, 220/255) // Light green tint for wavetable
        );
        
        // Use light green background for wavetable controls
        var wavetableColor = colors[\controlBackground] ? Color.new(220/255, 255/255, 220/255);
        var bgColor = wavetableColor.alpha_(0.4);  // Light appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, wavetableGroupWidth, wavetableGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, wavetableGroupWidth, wavetableGroupHeight));
    };
    
    wavetableGroupView = CompositeView(wavetableBorderView, Rect(5, 5, wavetableContentWidth, 20));
    
    // Edit Wavetable button
    editWavetableButton = Button(wavetableGroupView, Rect(0, 0, 100, 20))
        .states_([["_edit wavetable", Color.white, Color.green.alpha_(0.8)]])
        .font_(Font("Arial", 9, true))
        .action_({
            // Check if wavetable editor is loaded
            if(~nUPIC[\wavetableEditor].isNil or: { ~nUPIC[\wavetableEditor][\open].isNil }) {
                // Try to load the wavetable editor
                try {
                    (~nUPIC_basePath +/+ "UI/WavetableEditor.scd").load;
                    "Wavetable Editor loaded".postln;
                    0.1.wait; // Small delay to ensure it's loaded
                } { |error|
                    ("ERROR loading Wavetable Editor: " ++ error.errorString).postln;
                };
            };
            
            // Open the wavetable editor
            if(~nUPIC[\wavetableEditor].notNil and: { ~nUPIC[\wavetableEditor][\open].notNil }) {
                ~nUPIC[\wavetableEditor][\open].value;
            } {
                "Wavetable Editor not available".postln;
            };
        });
    
    // Store reference
    state[\controls][\editWavetableButton] = editWavetableButton;
    
    // Help Controls Group - positioned after wavetable editor group with same design principles
    // Only contains _help button
    
    helpContentWidth = 50; // Just the button width
    helpGroupWidth = helpContentWidth + 10; // Add 5px left + 5px right margins
    helpGroupHeight = modeActionGroupHeight; // Match height of other groups
    helpGroupX = wavetableGroupX + wavetableGroupWidth + 5; // To the right of wavetable editor group with 5px gap
    
    helpBorderView = UserView(window, Rect(helpGroupX, yStart, helpGroupWidth, helpGroupHeight));
    helpBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(220/255, 220/255, 255/255) // Light purple tint for help
        );
        
        // Use light purple background for help controls
        var helpColor = colors[\controlBackground] ? Color.new(220/255, 220/255, 255/255);
        var bgColor = helpColor.alpha_(0.4);  // Light appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, helpGroupWidth, helpGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, helpGroupWidth, helpGroupHeight));
    };
    
    helpGroupView = CompositeView(helpBorderView, Rect(5, 5, helpContentWidth, 20));
    
    // Help button
    helpButton = Button(helpGroupView, Rect(0, 0, 50, 20))
        .states_([["_help", Color.white, Color.gray(0.7)]])
        .font_(Font("Arial", 9, true))
        .action_({
            ~nUPIC[\ui][\showHelp].value;
        });
    
    // Store reference
    state[\controls][\helpButton] = helpButton;
    
    // Analysis Tools Group - positioned after help group with same design principles
    // Contains SC meter and frequency scope buttons
    
    analysisContentWidth = 70 + 3 + 70; // Two buttons: 70 + gap + 70 = 143px content
    analysisGroupWidth = analysisContentWidth + 10; // Add 5px left + 5px right margins
    analysisGroupHeight = modeActionGroupHeight; // Match height of other groups
    analysisGroupX = helpGroupX + helpGroupWidth + 5; // To the right of help group with 5px gap
    
    analysisBorderView = UserView(window, Rect(analysisGroupX, yStart, analysisGroupWidth, analysisGroupHeight));
    analysisBorderView.drawFunc = {
        var colors = ~nUPIC[\colors] ? (
            background: Color.white,
            systemBackground: Color.gray(0.9),
            controlBackground: Color.new(255/255, 255/255, 220/255) // Light yellow tint for analysis
        );
        
        // Use light yellow background for analysis tools controls
        var analysisColor = colors[\controlBackground] ? Color.new(255/255, 255/255, 220/255);
        var bgColor = analysisColor.alpha_(0.4);  // Light appearance
        Pen.fillColor = bgColor;
        Pen.fillRect(Rect(0, 0, analysisGroupWidth, analysisGroupHeight));
        
        // Draw white border
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, analysisGroupWidth, analysisGroupHeight));
    };
    
    analysisGroupView = CompositeView(analysisBorderView, Rect(5, 5, analysisContentWidth, 20));
    
    // SC Meter button
    scMeterButton = Button(analysisGroupView, Rect(0, 0, 70, 20))
        .states_([["_sc meter", Color.white, Color.green.alpha_(0.8)]])
        .font_(Font("Arial", 9, true))
        .action_({
            "Opening SuperCollider server meter...".postln;
            try {
                // Open the SC server meter
                if(s.meter.isNil or: { s.meter.window.isClosed }) {
                    s.meter;
                    "SC Meter opened".postln;
                } {
                    "SC Meter already open".postln;
                };
            } { |error|
                ("Error opening SC Meter: " ++ error.errorString).postln;
            };
        });
    
    // Frequency Scope button
    freqScopeButton = Button(analysisGroupView, Rect(73, 0, 70, 20))
        .states_([["_freqscope", Color.white, Color.cyan.alpha_(0.8)]])
        .font_(Font("Arial", 9, true))
        .action_({
            "Opening SuperCollider frequency scope...".postln;
            try {
                // Open the SC frequency scope
                if(s.freqscope.isNil or: { s.freqscope.window.isClosed }) {
                    s.freqscope;
                    "FreqScope opened".postln;
                } {
                    "FreqScope already open".postln;
                };
            } { |error|
                ("Error opening FreqScope: " ++ error.errorString).postln;
            };
        });
    
    // Store references
    state[\controls][\scMeterButton] = scMeterButton;
    state[\controls][\freqScopeButton] = freqScopeButton;
    
    // Store references
    state[\controls][\playButton] = playButton;
    state[\controls][\durationNumberBox] = durationNumberBox;
    state[\controls][\zoomInButton] = zoomInButton;
    state[\controls][\zoomOutButton] = zoomOutButton;
    state[\controls][\freqZoomInButton] = freqZoomInButton;
    state[\controls][\freqZoomOutButton] = freqZoomOutButton;
    state[\controls][\gridTypeMenu] = gridTypeMenu;
    state[\controls][\synthDefMenu] = synthDefMenu;
    state[\controls][\eraseModeButton] = eraseModeButton;
    state[\controls][\gridButton] = gridButton;
};

"nUPIC UI Controls module loaded".postln;
)
