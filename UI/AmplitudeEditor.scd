// nUPIC Amplitude Editor Module
// Single tabbed amplitude envelope editing window that responds to trajectory selection
// Part of the nUPIC (nu-UPIC) modular system

(
// Ensure nUPIC UI namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

// Initialize single amplitude editing system
~nUPIC[\ui][\ampEditorWindow] = nil;
~nUPIC[\ui][\ampEditorCurrentTabs] = List.new;
~nUPIC[\ui][\ampEditorActiveTab] = 0;
~nUPIC[\ui][\ampEditorZooms] = IdentityDictionary.new;

// Create or update the single amplitude editor window
~nUPIC[\ui][\createAmplitudeEditor] = { |selectedIndices = nil|
    var ampWin, tabContainer, editorContainer;
    var winWidth = 700, winHeight = 450;
    var data = ~nUPIC[\data];
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var tabs = List.new;
    var tabButtons = List.new;
    var editorY, editorHeight;
    var existingWindow = false;
    
    if(data.isNil or: { state.isNil }) {
        "nUPIC data or state not initialized".postln;
        ^nil;
    };
    
    // Use selected trajectories or all trajectories with data
    if(selectedIndices.isNil) {
        if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
            tabs = data[\selectedTrajectories].asArray.sort;
        } {
            if(data[\trajectories].notNil) {
                tabs = (0..(data[\trajectories].size - 1)).asArray;
            } {
                "No trajectories available".postln;
                ^nil;
            };
        };
    } {
        tabs = selectedIndices.asArray.sort;
    };
    
    if(tabs.size == 0) {
        "No trajectories to edit".postln;
        ^nil;
    };
    
    // Check if window is already open and update it instead of closing
    if(~nUPIC[\ui][\ampEditorWindow].notNil and: { 
        ~nUPIC[\ui][\ampEditorWindow].isClosed.not 
    }) {
        existingWindow = true;
        ampWin = ~nUPIC[\ui][\ampEditorWindow];
        
        // Check if tabs are the same - if so, just bring window to front
        if(~nUPIC[\ui][\ampEditorCurrentTabs].asArray.sort == tabs) {
            ampWin.front;
            "Amplitude editor already open with same trajectories".postln;
            ^ampWin;
        };
        
        // Clear existing content but keep window
        ampWin.view.children.do({ |child| child.remove });
        ("Updated amplitude editor with " ++ tabs.size ++ " trajectory tabs").postln;
    } {
        // Create new window
        ampWin = Window("nUPIC Amplitude Editor", 
            Rect(200, 100, winWidth, winHeight));
        ampWin.background = Color.new(205/255, 250/255, 205/255); // B&K green
        // Window created with fixed size
        ("Amplitude editor opened with " ++ tabs.size ++ " trajectory tabs").postln;
    };
    
    // Update window references
    ~nUPIC[\ui][\ampEditorWindow] = ampWin;
    ~nUPIC[\ui][\ampEditorCurrentTabs] = tabs;
    ~nUPIC[\ui][\ampEditorActiveTab] = 0;
    
    // Initialize amplitude envelopes for all tabs
    if(data[\amplitudeEnvelopes].isNil) {
        data[\amplitudeEnvelopes] = List.new;
    };
    
    tabs.do { |trajIndex|
        var traj, trajLength;
        
        // Ensure amplitude envelopes list is large enough
        while({ data[\amplitudeEnvelopes].size <= trajIndex }) {
            data[\amplitudeEnvelopes].add(nil);
        };
        
        // Initialize zoom settings
        if(~nUPIC[\ui][\ampEditorZooms][trajIndex].isNil) {
            ~nUPIC[\ui][\ampEditorZooms][trajIndex] = (ampZoomMin: 0, ampZoomMax: 1);
        };
        
        // Create default envelope if needed
        if(data[\amplitudeEnvelopes][trajIndex].isNil and: {
            trajIndex < data[\trajectories].size
        }) {
            traj = data[\trajectories][trajIndex];
            trajLength = if(traj.size > 0) {
                var trajFirstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
                var trajLastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
                trajLastX - trajFirstX;
            } { 600 };
            
            data[\amplitudeEnvelopes][trajIndex] = List[
                (x: 0, amp: 0.3),
                (x: trajLength, amp: 0.3)
            ];
        };
    };
    
    // Create tab buttons (if multiple trajectories)
    if(tabs.size > 1) {
        tabContainer = CompositeView(ampWin, Rect(0, 0, winWidth, 30));
        tabContainer.background = Color.new(180/255, 230/255, 180/255); // Darker B&K green for tabs
        
        tabs.do { |trajIndex, i|
            var tabBtn = Button(tabContainer, 
                Rect(i * (winWidth / tabs.size), 0, winWidth / tabs.size, 30));
            var trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
                var maxTrajs = data[\trajectories].size.max(1);
                colors[\trajectory].value(trajIndex, constants[\maxTrajectories] ? maxTrajs)
            } { 
                var maxTrajs = data[\trajectories].size.max(1);
                Color.hsv((trajIndex / maxTrajs) * 0.8, 0.7, 0.9)
            };
            
            tabBtn.states = [
                ["Trajectory " ++ trajIndex, Color.black, Color.gray(0.9)],
                ["Trajectory " ++ trajIndex, Color.white, trajColor]
            ];
            tabBtn.font = Font("Arial", 10, true);
            tabBtn.action = { |btn|
                // Update all tab buttons
                tabButtons.do { |otherBtn, j|
                    otherBtn.value = if(j == i) { 1 } { 0 };
                };
                
                // Update active tab
                ~nUPIC[\ui][\ampEditorActiveTab] = i;
                
                // Update content immediately
                { 
                    ~nUPIC[\ui][\updateAmplitudeEditorContent].value;
                }.defer(0.01);
            };
            
            if(i == 0) { tabBtn.value = 1 };  // Select first tab by default
            tabButtons.add(tabBtn);
        };
        
        // Store tab buttons for later access
        ~nUPIC[\ui][\ampEditorTabButtons] = tabButtons;
    };
    
    // Create editor content area
    editorY = if(tabs.size > 1) { 30 } { 0 };
    editorHeight = winHeight - editorY;
    
    editorContainer = CompositeView(ampWin, Rect(0, editorY, winWidth, editorHeight));
    ~nUPIC[\ui][\ampEditorContainer] = editorContainer;
    
    // Create initial content for first tab
    ~nUPIC[\ui][\createAmplitudeEditorContent].value(editorContainer, tabs[0]);
    
    // Window cleanup
    ampWin.onClose = {
        ~nUPIC[\ui][\ampEditorWindow] = nil;
        ~nUPIC[\ui][\ampEditorCurrentTabs].clear;
        ~nUPIC[\ui][\ampEditorContainer] = nil;
        ~nUPIC[\ui][\ampEditorTabButtons] = nil;
        "Amplitude editor closed".postln;
    };
    
    ampWin.front;
    ampWin;
};

// Update editor content when switching tabs
~nUPIC[\ui][\updateAmplitudeEditorContent] = {
    var tabs = ~nUPIC[\ui][\ampEditorCurrentTabs];
    var activeTab = ~nUPIC[\ui][\ampEditorActiveTab];
    var container = ~nUPIC[\ui][\ampEditorContainer];
    
    if(container.notNil and: { activeTab < tabs.size }) {
        var trajIndex = tabs[activeTab];
        ~nUPIC[\ui][\createAmplitudeEditorContent].value(container, trajIndex);
    };
};

// Create amplitude editor content for current trajectory
~nUPIC[\ui][\createAmplitudeEditorContent] = { |container, trajIndex|
    var ampView, overlayView, presetContainer, toolbarContainer, levelMeterContainer;
    var winWidth = container.bounds.width, winHeight = container.bounds.height;
    var viewHeight = winHeight - 180;  // More space for enhanced controls
    var meterWidth = 30;  // Width for level meter
    var editorWidth = winWidth - meterWidth - 10;  // Editor width minus meter and spacing
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var ampZoomMin, ampZoomMax;
    var levelMeter, analysisText;
    
    // Clear existing content
    container.children.do({ |child| child.remove });
    
    // Get zoom values for current trajectory
    ampZoomMin = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMin] ? 0;
    ampZoomMax = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMax] ? 1;
    
    // Create amplitude editing view (reduced width to make room for meter)
    ampView = MultiSliderView(container, Rect(0, 0, editorWidth, viewHeight));
    ampView.background = colors[\amplitudeBackground] ? Color.white;
    ampView.fillColor = colors[\amplitudeEnvelope] ? Color.red.alpha_(0.6);
    ampView.strokeColor = colors[\amplitudeStroke] ? Color.red;
    ampView.drawRects = false;
    ampView.drawLines = true;
    ampView.thumbSize = 4;
    ampView.gap = 0;
    ampView.isFilled = true;
    ampView.elasticMode = true;
    
    // Update amplitude envelope when multislider changes - ONLY for current trajectory
    ampView.action = { |view|
        var values = view.value;
        var currentTraj = data[\trajectories][trajIndex];
        var trajLen = if(currentTraj.size > 0) {
            var firstX = if(currentTraj[0].isKindOf(Event)) { currentTraj[0].x } { currentTraj[0].x };
            var lastX = if(currentTraj.last.isKindOf(Event)) { currentTraj.last.x } { currentTraj.last.x };
            lastX - firstX;
        } { 600 };
        var newEnv = List.new;
        var cleanEnv = List.new;
        var prevX = -1;
        var existingEnv = data[\amplitudeEnvelopes][trajIndex];
        var zoomStartX = ampZoomMin * trajLen;
        var zoomEndX = ampZoomMax * trajLen;
        
        // Ensure we're only editing THIS trajectory's envelope
        if(trajIndex >= data[\amplitudeEnvelopes].size) {
            ("WARNING: Trajectory index " ++ trajIndex ++ " out of range, ignoring edit").postln;
            ^nil;
        };
        
        // Keep existing envelope points before zoom range
        if(existingEnv.notNil) {
            existingEnv.do { |point|
                if(point.x < zoomStartX) {
                    newEnv.add(point);
                };
            };
        };
        
        // Add points from multislider values (zoomed portion) - ONLY for this trajectory
        values.do { |amp, i|
            var normalizedPos = i / (values.size - 1);
            var zoomedPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);
            var x = zoomedPos * trajLen;
            newEnv.add((x: x, amp: amp));
        };
        
        // Keep existing envelope points after zoom range
        if(existingEnv.notNil) {
            existingEnv.do { |point|
                if(point.x > zoomEndX) {
                    newEnv.add(point);
                };
            };
        };
        
        // Sort by x position and remove duplicates
        newEnv = newEnv.sort({ |a, b| a.x < b.x });
        newEnv.do { |point|
            if((point.x - prevX).abs > 0.1) {
                cleanEnv.add(point);
                prevX = point.x;
            };
        };
        
        // Update ONLY this trajectory's envelope
        data[\amplitudeEnvelopes][trajIndex] = cleanEnv;
        
        ("Updated amplitude envelope for trajectory " ++ trajIndex ++ " with " ++ cleanEnv.size ++ " points").postln;
        
        // Don't update level meter during drawing - only during preview
        // The level meter will be updated only when preview is playing
        
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    // Add overlay view for drawing grid and labels (reduced width)
    overlayView = UserView(container, Rect(0, 0, editorWidth, viewHeight));
    overlayView.acceptsMouse = false;
    
    overlayView.drawFunc = {
        var traj = data[\trajectories][trajIndex];
        var trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
            var maxTrajs = data[\trajectories].size.max(1);
            colors[\trajectory].value(trajIndex, constants[\maxTrajectories] ? maxTrajs)
        } { 
            var maxTrajs = data[\trajectories].size.max(1);
            Color.hsv((trajIndex / maxTrajs) * 0.8, 0.7, 0.9)
        };
        
        // Draw trajectory shape as light background
        if(traj.notNil and: { traj.size > 1 }) {
            var trajFirstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
            var trajLastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
            var freqMax = constants[\freqMax] ? 7500;
            var freqMin = constants[\freqMin] ? 20;
            
            Pen.strokeColor = trajColor.alpha_(0.6);
            Pen.width = 4;
            
            traj.do { |point, i|
                var freq = if(point.isKindOf(Event)) { point.freq } {
                    var state = ~nUPIC[\ui][\state];
                    var zoomFreqMax = state[\zoomFreqMax] ? (constants[\freqMax] ? 7500);
                    var zoomFreqMin = state[\zoomFreqMin] ? (constants[\freqMin] ? 20);
                    point.y.linlin(0, constants[\defaultHeight] ? 800, zoomFreqMax, zoomFreqMin)
                };
                var xPos = if(point.isKindOf(Event)) { point.x } { point.x };
                var normalizedX = (xPos - trajFirstX) / (trajLastX - trajFirstX);
                
                if(normalizedX >= ampZoomMin and: { normalizedX <= ampZoomMax }) {
                    var zoomedX = normalizedX.linlin(ampZoomMin, ampZoomMax, 0, 1);
                    var screenX = zoomedX * editorWidth;  // Use editorWidth instead of winWidth
                    var screenY = freq.linlin(freqMin, freqMax, viewHeight * 0.8, viewHeight * 0.2);
                    
                    if(i == 0 or: { normalizedX < ampZoomMin }) {
                        Pen.moveTo(Point(screenX, screenY));
                    } {
                        Pen.lineTo(Point(screenX, screenY));
                    };
                };
            };
            Pen.stroke;
        };
        
        // Draw grid
        ~nUPIC[\ui][\drawAmplitudeGrid].value(editorWidth, viewHeight, ampZoomMin, ampZoomMax);
    };
    
    // Create level meter container on the right side (initially hidden)
    levelMeterContainer = CompositeView(container, Rect(editorWidth + 5, 0, meterWidth, viewHeight));
    levelMeterContainer.background = Color.new(190/255, 240/255, 190/255); // Light B&K green
    levelMeterContainer.visible = true;  // Always visible now
    
    // Create vertical level meter
    levelMeter = LevelIndicator(levelMeterContainer, Rect(5, 30, 20, viewHeight - 60))
        .warning_(0.8).critical_(0.95)
        .style_(0)  // Vertical style
        .numTicks_(20)
        .value_(0);  // Start at 0
    
    // Label for level meter
    StaticText(levelMeterContainer, Rect(0, 5, meterWidth, 20))
        .string_("Level")
        .font_(Font("Arial", 9, true))
        .align_(\center)
        .stringColor_(Color.gray(0.3));
    
    // Create toolbar area (above main editor)
    toolbarContainer = CompositeView(container, Rect(0, 0, winWidth, 30));
    toolbarContainer.background = Color.new(180/255, 230/255, 180/255); // Darker B&K green for toolbar
    ~nUPIC[\ui][\createAmplitudeToolbar].value(toolbarContainer, trajIndex);
    
    // Adjust editor position to account for toolbar
    ampView.bounds = Rect(0, 30, editorWidth, viewHeight - 30);
    overlayView.bounds = Rect(0, 30, editorWidth, viewHeight - 30);
    levelMeterContainer.bounds = Rect(editorWidth + 5, 30, meterWidth, viewHeight - 30);
    
    // Create control area
    presetContainer = CompositeView(container, Rect(0, viewHeight, winWidth, winHeight - viewHeight));
    presetContainer.background = Color.new(190/255, 240/255, 190/255); // Light B&K green
    
    // Add enhanced controls
    ~nUPIC[\ui][\createAmplitudeControls].value(presetContainer, trajIndex, ampZoomMin, ampZoomMax);
    
    // Initialize display
    {
        ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
    }.defer(0.1);
    
    // Store references for updates
    container.setProperty(\ampView, ampView);
    container.setProperty(\overlayView, overlayView);
    container.setProperty(\trajIndex, trajIndex);
    container.setProperty(\levelMeter, levelMeter);
    
    // Level meter starts empty - will only show activity during preview
};

// Draw amplitude grid
~nUPIC[\ui][\drawAmplitudeGrid] = { |winWidth, viewHeight, ampZoomMin, ampZoomMax|
    // Draw grid lines
    Pen.strokeColor = Color.gray(0.8, 0.5);
    Pen.width = 0.5;
    
    // Horizontal lines (amplitude levels)
    5.do { |i|
        var y = i * (viewHeight / 4);
        Pen.line(Point(0, y), Point(winWidth, y));
        Pen.stroke;
        
        // Labels
        Pen.fillColor = Color.gray(0.5);
        Pen.stringAtPoint(((4 - i) * 25).asString ++ "%",
            Point(5, y - 15), Font("Arial", 9));
    };
    
    // Vertical lines (time markers)
    10.do { |i|
        var x = (i + 1) * (winWidth / 11);
        var normalizedPos = (i + 1) / 11;
        var actualPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);
        var percentLabel = (actualPos * 100).round(1).asString ++ "%";
        
        Pen.strokeColor = Color.gray(0.8, 0.5);
        Pen.line(Point(x, 0), Point(x, viewHeight));
        Pen.stroke;
        
        // Position labels
        Pen.fillColor = Color.gray(0.5);
        Pen.stringAtPoint(percentLabel, Point(x - 15, viewHeight - 15), Font("Arial", 8));
    };
    
    // Instructions
    Pen.fillColor = Color.black;
    Pen.stringAtPoint(
        "Draw amplitude envelope - higher = louder",
        Point(10, 5), Font("Arial", 10));
};

// Create amplitude toolbar with playback and analysis tools
~nUPIC[\ui][\createAmplitudeToolbar] = { |container, trajIndex|
    var data = ~nUPIC[\data];
    var colors = ~nUPIC[\colors];
    var trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
        colors[\trajectory].value(trajIndex, ~nUPIC[\constants][\maxTrajectories] ? 200)
    } { Color.hsv((trajIndex / 200) * 0.8, 0.7, 0.9) };
    
    // Preview button
    Button(container, Rect(5, 5, 60, 20))
        .states_([["Preview", Color.black, Color.green.alpha_(0.3)]])
        .font_(Font("Arial", 8))
        .action_({ 
            ~nUPIC[\ui][\previewTrajectoryAmplitude].value(trajIndex);
        });
    
    // Analysis display
    StaticText(container, Rect(70, 5, 200, 20))
        .string_("Peak: -- dB | RMS: -- dB")
        .font_(Font("Arial", 8))
        .stringColor_(Color.gray(0.2))
        .background_(Color.white.alpha_(0.8));
    
    // Store reference for updates
    container.setProperty(\analysisText, container.children.last);
    
    // Undo/Redo buttons
    Button(container, Rect(container.bounds.width - 100, 5, 40, 20))
        .states_([["Undo", Color.black, Color.gray(0.8)]])
        .font_(Font("Arial", 8))
        .action_({ 
            ~nUPIC[\ui][\undoAmplitudeEdit].value(trajIndex);
        });
    
    Button(container, Rect(container.bounds.width - 55, 5, 40, 20))
        .states_([["Redo", Color.black, Color.gray(0.8)]])
        .font_(Font("Arial", 8))
        .action_({ 
            ~nUPIC[\ui][\redoAmplitudeEdit].value(trajIndex);
        });
};

// Create amplitude controls
~nUPIC[\ui][\createAmplitudeControls] = { |container, trajIndex, ampZoomMin, ampZoomMax|
    var containerBounds = container.bounds;
    var data = ~nUPIC[\data];
    var colors = ~nUPIC[\colors];
    var trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
        var maxTrajs = ~nUPIC[\data][\trajectories].size.max(1);
        colors[\trajectory].value(trajIndex, ~nUPIC[\constants][\maxTrajectories] ? maxTrajs)
    } { 
        var maxTrajs = ~nUPIC[\data][\trajectories].size.max(1);
        Color.hsv((trajIndex / maxTrajs) * 0.8, 0.7, 0.9)
    };
    var row1Y = 5, row2Y = 30, row3Y = 55, row4Y = 80;
    
    // Trajectory label
    StaticText(container, Rect(10, row1Y, 200, 20))
        .string_("Trajectory " ++ trajIndex)
        .font_(Font("Arial", 12, true))
        .stringColor_(trajColor);
    
    // Enhanced preset buttons with more shapes
    [\fadeIn, \fadeOut, \constant, \pulse, \exponential, \adsr].do { |preset, i|
        var btnWidth = 60;
        Button(container, Rect(10 + (i * (btnWidth + 5)), row2Y, btnWidth, 20))
            .states_([[preset.asString, Color.black, Color.gray(0.9)]])
            .font_(Font("Arial", 8))
            .action_({
                ~nUPIC[\ui][\saveAmplitudeState].value(trajIndex);  // Save for undo
                ~nUPIC[\ui][\applyAmplitudePreset].value(trajIndex, preset);
            });
    };
    
    // Advanced operations row
    Button(container, Rect(10, row3Y, 70, 20))
        .states_([["Normalize", Color.black, Color.blue.alpha_(0.3)]])
        .font_(Font("Arial", 8))
        .action_({
            ~nUPIC[\ui][\saveAmplitudeState].value(trajIndex);
            ~nUPIC[\ui][\normalizeAmplitude].value(trajIndex);
        });
    
    Button(container, Rect(85, row3Y, 70, 20))
        .states_([["Smooth", Color.black, Color.cyan.alpha_(0.3)]])
        .font_(Font("Arial", 8))
        .action_({
            ~nUPIC[\ui][\saveAmplitudeState].value(trajIndex);
            ~nUPIC[\ui][\smoothAmplitude].value(trajIndex);
        });
    
    Button(container, Rect(160, row3Y, 80, 20))
        .states_([["Apply to All", Color.black, Color.green.alpha_(0.5)]])
        .font_(Font("Arial", 8))
        .action_({
            ~nUPIC[\ui][\applyAmplitudeToSelected].value(trajIndex);
        });
    
    Button(container, Rect(245, row3Y, 50, 20))
        .states_([["Clear", Color.white, Color.red.alpha_(0.7)]])
        .font_(Font("Arial", 8))
        .action_({
            ~nUPIC[\ui][\saveAmplitudeState].value(trajIndex);
            ~nUPIC[\ui][\clearAmplitude].value(trajIndex);
        });
    
    // Enhanced zoom controls with pan
    StaticText(container, Rect(10, row4Y, 40, 20))
        .string_("Zoom:")
        .font_(Font("Arial", 9));
    
    Slider(container, Rect(50, row4Y, 80, 20))
        .value_(0)
        .action_({ |slider|
            ~nUPIC[\ui][\updateAmplitudeZoom].value(trajIndex, slider.value);
        });
    
    StaticText(container, Rect(135, row4Y, 50, 20))
        .string_("Position:")
        .font_(Font("Arial", 9));
    
    Slider(container, Rect(185, row4Y, 80, 20))
        .value_(0)
        .action_({ |slider|
            ~nUPIC[\ui][\updateAmplitudePan].value(trajIndex, slider.value);
        });
    
    // Scale display toggle
    Button(container, Rect(270, row4Y, 60, 20))
        .states_([["Linear", Color.black, Color.gray(0.9)], ["dB Scale", Color.white, Color.black]])
        .font_(Font("Arial", 8))
        .action_({ |btn|
            ~nUPIC[\ui][\toggleAmplitudeScale].value(trajIndex, btn.value == 1);
        });
    
    // Enhanced instructions
    StaticText(container, Rect(10, row4Y + 25, 600, 35))
        .string_("• Click and drag to shape amplitude envelope  • Use presets for common shapes  • Normalize to optimize levels\n• Preview to hear trajectory  • Undo/Redo available  • Zoom/Position to focus on sections  • Apply envelope to other selected trajectories")
        .font_(Font("Arial", 8))
        .stringColor_(Color.gray(0.4));
};

// Update amplitude display
~nUPIC[\ui][\updateAmplitudeDisplay] = { |ampView, trajIndex|
    var data = ~nUPIC[\data];
    var ampEnv = data[\amplitudeEnvelopes][trajIndex];
    var currentTraj = data[\trajectories][trajIndex];
    var trajLen, ampZoomMin, ampZoomMax;
    
    if(ampEnv.isNil) { ^nil };
    
    ampZoomMin = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMin] ? 0;
    ampZoomMax = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMax] ? 1;
    
    trajLen = if(currentTraj.notNil and: { currentTraj.size > 0 }) {
        var firstX = if(currentTraj[0].isKindOf(Event)) { currentTraj[0].x } { currentTraj[0].x };
        var lastX = if(currentTraj.last.isKindOf(Event)) { currentTraj.last.x } { currentTraj.last.x };
        lastX - firstX
    } { 600 };
    
    if(ampEnv.size > 0) {
        // Calculate dynamic resolution based on zoom level and trajectory length
        var zoomRange = ampZoomMax - ampZoomMin;
        var baseResolution = 200;  // Base resolution for full view
        var maxResolution = 800;   // Maximum resolution when zoomed in
        var minResolution = 50;    // Minimum resolution when zoomed out
        
        // Higher resolution when zoomed in (smaller zoom range)
        var dynamicResolution = (baseResolution / zoomRange.max(0.1)).clip(minResolution, maxResolution).asInteger;
        
        var values = Array.fill(dynamicResolution, { |i|
            var normalizedPos = i / (dynamicResolution - 1);
            var zoomedPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);
            var xPos = zoomedPos * trajLen;
            var amp = 0.3;
            
            // Find the amplitude at this position
            if(ampEnv.size > 1) {
                block { |break|
                    (ampEnv.size - 1).do { |j|
                        if((ampEnv[j].x <= xPos) and: { (ampEnv[j + 1].x >= xPos) }) {
                            var factor = (xPos - ampEnv[j].x) / (ampEnv[j + 1].x - ampEnv[j].x);
                            amp = ampEnv[j].amp.blend(ampEnv[j + 1].amp, factor);
                            break.value;
                        };
                    };
                };
                
                // Handle edge cases
                if(xPos <= ampEnv.first.x) { amp = ampEnv.first.amp };
                if(xPos >= ampEnv.last.x) { amp = ampEnv.last.amp };
            } {
                if(ampEnv.size > 0) { amp = ampEnv.first.amp };
            };
            
            amp
        });
        ampView.value = values;
    } {
        ampView.value = Array.fill(500, 0.3);
    };
};

// Helper functions for presets
~nUPIC[\ui][\applyAmplitudePreset] = { |trajIndex, preset|
    var data = ~nUPIC[\data];
    var traj = data[\trajectories][trajIndex];
    var trajLen = if(traj.size > 0) {
        var firstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
        var lastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
        lastX - firstX;
    } { 600 };
    var newEnv;
    
    newEnv = case 
    { preset == \fadeIn } { 
        List[(x: 0, amp: 0), (x: trajLen, amp: 1)] 
    }
    { preset == \fadeOut } { 
        List[(x: 0, amp: 1), (x: trajLen, amp: 0)] 
    }
    { preset == \constant } { 
        List[(x: 0, amp: 0.7), (x: trajLen, amp: 0.7)] 
    }
    { preset == \pulse } {
        List[
            (x: 0, amp: 0),
            (x: trajLen * 0.1, amp: 1),
            (x: trajLen * 0.2, amp: 0),
            (x: trajLen, amp: 0)
        ]
    }
    { 
        List[(x: 0, amp: 0.3), (x: trajLen, amp: 0.3)] 
    };
    
    data[\amplitudeEnvelopes][trajIndex] = newEnv;
    
    // Update the display immediately if editor is open
    if(~nUPIC[\ui][\ampEditorContainer].notNil) {
        var ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
        if(ampView.notNil) {
            { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
        };
    };
    
    ("Applied " ++ preset ++ " envelope to trajectory " ++ trajIndex).postln;
    
    // Level meter will only animate during preview playback
};

// Update amplitude zoom
~nUPIC[\ui][\updateAmplitudeZoom] = { |trajIndex, zoomValue|
    var zoomRange = 0.2 + (zoomValue * 0.6);  // Zoom range from 20% to 80% of trajectory
    var currentPan = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\currentPan] ? 0;
    var maxPan = 1 - zoomRange;
    var zoomStart = (currentPan * maxPan).max(0).min(maxPan);
    var zoomEnd = (zoomStart + zoomRange).min(1.0);
    
    // Update zoom settings
    ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMin] = zoomStart;
    ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMax] = zoomEnd;
    ~nUPIC[\ui][\ampEditorZooms][trajIndex][\zoomValue] = zoomValue;
    
    // Refresh the current editor content if this is the active trajectory
    if(~nUPIC[\ui][\ampEditorContainer].notNil) {
        var currentTrajIndex = ~nUPIC[\ui][\ampEditorContainer].getProperty(\trajIndex);
        if(currentTrajIndex == trajIndex) {
            var ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
            var overlayView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\overlayView);
            if(ampView.notNil) {
                { 
                    ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
                    if(overlayView.notNil) { overlayView.refresh };
                }.defer(0.05);
            };
        };
    };
    
    ("Zoom updated for trajectory " ++ trajIndex ++ ": " ++ (zoomRange * 100).round(1) ++ "% range at " ++ (zoomStart * 100).round(1) ++ "%").postln;
};

// Apply current trajectory's amplitude to all selected trajectories
~nUPIC[\ui][\applyAmplitudeToSelected] = { |sourceTrajIndex|
    var data = ~nUPIC[\data];
    var sourceEnv = data[\amplitudeEnvelopes][sourceTrajIndex];
    
    if(sourceEnv.isNil) {
        ("No amplitude envelope to copy from trajectory " ++ sourceTrajIndex).postln;
        ^nil;
    };
    
    if(data[\selectedTrajectories].isNil or: { data[\selectedTrajectories].size == 0 }) {
        "No trajectories selected. Use G key and click trajectories first.".postln;
        ^nil;
    };
    
    data[\selectedTrajectories].do { |trajIndex|
        if(trajIndex != sourceTrajIndex) {
            var targetTraj = data[\trajectories][trajIndex];
            var targetLen = if(targetTraj.size > 0) {
                var firstX = if(targetTraj[0].isKindOf(Event)) { targetTraj[0].x } { targetTraj[0].x };
                var lastX = if(targetTraj.last.isKindOf(Event)) { targetTraj.last.x } { targetTraj.last.x };
                lastX - firstX;
            } { 600 };
            
            var sourceLen = if(data[\trajectories][sourceTrajIndex].size > 0) {
                var firstX = if(data[\trajectories][sourceTrajIndex][0].isKindOf(Event)) {
                    data[\trajectories][sourceTrajIndex][0].x
                } { data[\trajectories][sourceTrajIndex][0].x };
                var lastX = if(data[\trajectories][sourceTrajIndex].last.isKindOf(Event)) {
                    data[\trajectories][sourceTrajIndex].last.x
                } { data[\trajectories][sourceTrajIndex].last.x };
                lastX - firstX;
            } { 600 };
            
            // Scale the envelope to fit the target trajectory
            var scaledEnv = sourceEnv.collect { |point|
                var scaledX = point.x * (targetLen / sourceLen);
                (x: scaledX, amp: point.amp)
            };
            
            // Ensure amplitude envelopes list is large enough
            while({ data[\amplitudeEnvelopes].size <= trajIndex }) {
                data[\amplitudeEnvelopes].add(nil);
            };
            
            data[\amplitudeEnvelopes][trajIndex] = scaledEnv;
        };
    };
    
    ("Applied amplitude envelope from trajectory " ++ sourceTrajIndex ++ 
     " to " ++ data[\selectedTrajectories].size ++ " selected trajectories").postln;
};

// Clear amplitude envelope for a trajectory
~nUPIC[\ui][\clearAmplitude] = { |trajIndex|
    var data = ~nUPIC[\data];
    var traj = data[\trajectories][trajIndex];
    var trajLen = if(traj.size > 0) {
        var firstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
        var lastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
        lastX - firstX;
    } { 600 };
    
    // Reset to flat envelope at 30%
    data[\amplitudeEnvelopes][trajIndex] = List[
        (x: 0, amp: 0.3),
        (x: trajLen, amp: 0.3)
    ];
    
    // Update display if editor is open
    if(~nUPIC[\ui][\ampEditorContainer].notNil) {
        var ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
        if(ampView.notNil) {
            { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
        };
    };
    
    ("Cleared amplitude envelope for trajectory " ++ trajIndex).postln;
};

// Legacy compatibility - redirect old function to new system
~nUPIC[\ui][\createAmplitudeWindow] = { |trajIndex|
    ~nUPIC[\ui][\createAmplitudeEditor].value([trajIndex]);
};

// Function to open amplitude editor for selected trajectories
~nUPIC[\ui][\openAmplitudeEditorForSelected] = {
    var data = ~nUPIC[\data];
    if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
        ~nUPIC[\ui][\createAmplitudeEditor].value(data[\selectedTrajectories].asArray);
        // Enable auto-update when opening amplitude editor
        ~nUPIC[\ui][\setupAmplitudeEditorAutoUpdate].value;
    } {
        "No trajectories selected. Select trajectories first with G key and click on them.".postln;
    };
};

// Close amplitude editor
~nUPIC[\ui][\closeAmplitudeEditor] = {
    if(~nUPIC[\ui][\ampEditorWindow].notNil and: { 
        ~nUPIC[\ui][\ampEditorWindow].isClosed.not 
    }) {
        ~nUPIC[\ui][\ampEditorWindow].close;
    };
};

// Automatic amplitude editor update on trajectory selection
~nUPIC[\ui][\setupAmplitudeEditorAutoUpdate] = {
    // Set up callback for when trajectories are selected
    ~nUPIC[\ui][\onTrajectorySelectionChanged] = {
        var data = ~nUPIC[\data];
        
        // Only update if amplitude editor is open
        if(~nUPIC[\ui][\ampEditorWindow].notNil and: {
            ~nUPIC[\ui][\ampEditorWindow].isClosed.not
        }) {
            // Check if we have selected trajectories
            if(data[\selectedTrajectories].notNil and: {
                data[\selectedTrajectories].size > 0
            }) {
                // Update amplitude editor with current selection
                var selectedArray = data[\selectedTrajectories].asArray.sort;
                
                // Only update if selection actually changed
                if(~nUPIC[\ui][\ampEditorCurrentTabs].asArray.sort != selectedArray) {
                    {
                        ~nUPIC[\ui][\createAmplitudeEditor].value(selectedArray);
                    }.defer(0.05);  // Small delay to ensure selection is fully processed
                };
            };
        };
    };
    
    "Amplitude editor auto-update enabled".postln;
};

// Remove auto-update callback
~nUPIC[\ui][\removeAmplitudeEditorAutoUpdate] = {
    ~nUPIC[\ui][\onTrajectorySelectionChanged] = nil;
    "Amplitude editor auto-update disabled".postln;
};

// Enhanced close function that also removes auto-update
~nUPIC[\ui][\closeAmplitudeEditor] = {
    if(~nUPIC[\ui][\ampEditorWindow].notNil and: { 
        ~nUPIC[\ui][\ampEditorWindow].isClosed.not 
    }) {
        ~nUPIC[\ui][\ampEditorWindow].close;
    };
    // Remove auto-update when closing
    ~nUPIC[\ui][\removeAmplitudeEditorAutoUpdate].value;
};

// ===================== ADVANCED AMPLITUDE EDITING FUNCTIONS =====================

// Initialize undo/redo system (moved inside main block for proper scoping)
// This will be set up after the main module loads

// Save current amplitude state for undo
~nUPIC[\ui][\saveAmplitudeState] = { |trajIndex|
    var data, currentEnv, envCopy;
    data = ~nUPIC[\data];
    currentEnv = data[\amplitudeEnvelopes][trajIndex];
    
    if(currentEnv.notNil) {
        // Initialize stacks if needed
        if(~nUPIC[\ui][\ampEditorUndoStacks][trajIndex].isNil) {
            ~nUPIC[\ui][\ampEditorUndoStacks][trajIndex] = List.new;
        };
        
        // Deep copy the envelope
        envCopy = currentEnv.collect({ |point| (x: point.x, amp: point.amp) });
        ~nUPIC[\ui][\ampEditorUndoStacks][trajIndex].add(envCopy);
        
        // Limit undo stack size
        if(~nUPIC[\ui][\ampEditorUndoStacks][trajIndex].size > 20) {
            ~nUPIC[\ui][\ampEditorUndoStacks][trajIndex].removeAt(0);
        };
        
        // Clear redo stack when new action is performed
        ~nUPIC[\ui][\ampEditorRedoStacks][trajIndex] = List.new;
    };
};

// Undo amplitude edit
~nUPIC[\ui][\undoAmplitudeEdit] = { |trajIndex|
    var data, undoStack;
    data = ~nUPIC[\data];
    undoStack = ~nUPIC[\ui][\ampEditorUndoStacks][trajIndex];
    
    if(undoStack.notNil and: { undoStack.size > 0 }) {
        // Save current state to redo stack
        var redoStack, currentEnv, envCopy, previousState, ampView, levelMeter;
        redoStack = ~nUPIC[\ui][\ampEditorRedoStacks][trajIndex] ?? List.new;
        currentEnv = data[\amplitudeEnvelopes][trajIndex];
        if(currentEnv.notNil) {
            envCopy = currentEnv.collect({ |point| (x: point.x, amp: point.amp) });
            redoStack.add(envCopy);
        };
        ~nUPIC[\ui][\ampEditorRedoStacks][trajIndex] = redoStack;
        
        // Restore from undo stack
        previousState = undoStack.pop;
        data[\amplitudeEnvelopes][trajIndex] = previousState;
        
        // Update display and level meter
        if(~nUPIC[\ui][\ampEditorContainer].notNil) {
            ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
            levelMeter = ~nUPIC[\ui][\ampEditorContainer].getProperty(\levelMeter);
            if(ampView.notNil) {
                { 
                    ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
                    if(levelMeter.notNil) {
                        ~nUPIC[\ui][\updateLevelMeter].value(levelMeter, trajIndex);
                    };
                }.defer(0.05);
            };
        };
        
        ("Undid amplitude edit for trajectory " ++ trajIndex).postln;
    } {
        "No undo history for trajectory " ++ trajIndex;
    };
};

// Redo amplitude edit
~nUPIC[\ui][\redoAmplitudeEdit] = { |trajIndex|
    var data, redoStack;
    data = ~nUPIC[\data];
    redoStack = ~nUPIC[\ui][\ampEditorRedoStacks][trajIndex];
    
    if(redoStack.notNil and: { redoStack.size > 0 }) {
        // Save current state to undo stack (but don't clear redo stack)
        var undoStack, currentEnv, envCopy, nextState, ampView;
        undoStack = ~nUPIC[\ui][\ampEditorUndoStacks][trajIndex] ?? List.new;
        currentEnv = data[\amplitudeEnvelopes][trajIndex];
        if(currentEnv.notNil) {
            envCopy = currentEnv.collect({ |point| (x: point.x, amp: point.amp) });
            undoStack.add(envCopy);
            if(undoStack.size > 20) {
                undoStack.removeAt(0);
            };
        };
        ~nUPIC[\ui][\ampEditorUndoStacks][trajIndex] = undoStack;
        
        // Restore from redo stack
        nextState = redoStack.pop;
        data[\amplitudeEnvelopes][trajIndex] = nextState;
        
        // Update display
        if(~nUPIC[\ui][\ampEditorContainer].notNil) {
            ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
            if(ampView.notNil) {
                { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
            };
        };
        
        ("Redid amplitude edit for trajectory " ++ trajIndex).postln;
    } {
        ("No redo history for trajectory " ++ trajIndex).postln;
    };
};

// Enhanced presets with more sophisticated envelopes
~nUPIC[\ui][\applyAmplitudePreset] = { |trajIndex, preset|
    var data = ~nUPIC[\data];
    var traj = data[\trajectories][trajIndex];
    var trajLen = if(traj.size > 0) {
        var firstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
        var lastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
        lastX - firstX;
    } { 600 };
    var newEnv;
    
    newEnv = case 
    { preset == \fadeIn } { 
        List[(x: 0, amp: 0), (x: trajLen, amp: 1)] 
    }
    { preset == \fadeOut } { 
        List[(x: 0, amp: 1), (x: trajLen, amp: 0)] 
    }
    { preset == \constant } { 
        List[(x: 0, amp: 0.7), (x: trajLen, amp: 0.7)] 
    }
    { preset == \pulse } {
        List[
            (x: 0, amp: 0),
            (x: trajLen * 0.1, amp: 1),
            (x: trajLen * 0.2, amp: 0),
            (x: trajLen, amp: 0)
        ]
    }
    { preset == \exponential } {
        // Exponential decay
        var points = List.new;
        50.do { |i|
            var pos = i / 49;
            var x = pos * trajLen;
            var amp = exp(pos * -3);  // Exponential decay
            points.add((x: x, amp: amp));
        };
        points
    }
    { preset == \adsr } {
        // Attack, Decay, Sustain, Release envelope
        List[
            (x: 0, amp: 0),                    // Start
            (x: trajLen * 0.1, amp: 1),         // Attack peak
            (x: trajLen * 0.3, amp: 0.6),       // Decay to sustain
            (x: trajLen * 0.8, amp: 0.6),       // Sustain
            (x: trajLen, amp: 0)                // Release
        ]
    }
    { 
        List[(x: 0, amp: 0.3), (x: trajLen, amp: 0.3)] 
    };
    
    data[\amplitudeEnvelopes][trajIndex] = newEnv;
    
    // Update the display immediately if editor is open
    if(~nUPIC[\ui][\ampEditorContainer].notNil) {
        var ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
        if(ampView.notNil) {
            { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
        };
    };
    
    ("Applied " ++ preset ++ " envelope to trajectory " ++ trajIndex).postln;
};

// Normalize amplitude envelope
~nUPIC[\ui][\normalizeAmplitude] = { |trajIndex|
    var data, ampEnv, maxAmp, normalizedEnv, ampView;
    data = ~nUPIC[\data];
    ampEnv = data[\amplitudeEnvelopes][trajIndex];
    
    if(ampEnv.notNil and: { ampEnv.size > 0 }) {
        maxAmp = ampEnv.collect(_.amp).maxItem;
        if(maxAmp > 0) {
            normalizedEnv = ampEnv.collect { |point|
                (x: point.x, amp: point.amp / maxAmp)
            };
            data[\amplitudeEnvelopes][trajIndex] = normalizedEnv;
            
            // Update display
            if(~nUPIC[\ui][\ampEditorContainer].notNil) {
                ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
                if(ampView.notNil) {
                    { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
                };
            };
            
            ("Normalized amplitude envelope for trajectory " ++ trajIndex).postln;
        };
    };
};

// Smooth amplitude envelope using moving average
~nUPIC[\ui][\smoothAmplitude] = { |trajIndex, windowSize = 5|
    var data, ampEnv, smoothedEnv, startIdx, endIdx, avgAmp, count, ampView;
    data = ~nUPIC[\data];
    ampEnv = data[\amplitudeEnvelopes][trajIndex];
    
    if(ampEnv.notNil and: { ampEnv.size > windowSize }) {
        smoothedEnv = List.new;
        
        ampEnv.do { |point, i|
            startIdx = (i - (windowSize.div(2))).max(0);
            endIdx = (i + (windowSize.div(2))).min(ampEnv.size - 1);
            avgAmp = 0;
            count = 0;
            
            (startIdx..endIdx).do { |j|
                avgAmp = avgAmp + ampEnv[j].amp;
                count = count + 1;
            };
            
            smoothedEnv.add((x: point.x, amp: avgAmp / count));
        };
        
        data[\amplitudeEnvelopes][trajIndex] = smoothedEnv;
        
        // Update display
        if(~nUPIC[\ui][\ampEditorContainer].notNil) {
            ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
            if(ampView.notNil) {
                { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
            };
        };
        
        ("Smoothed amplitude envelope for trajectory " ++ trajIndex).postln;
    };
};

// Position functionality for amplitude zoom (pan renamed to position)
~nUPIC[\ui][\updateAmplitudePan] = { |trajIndex, panValue|
    var zoomSettings, zoomRange, maxPan, newMin, newMax;
    zoomSettings = ~nUPIC[\ui][\ampEditorZooms][trajIndex];
    if(zoomSettings.notNil) {
        zoomRange = zoomSettings[\ampZoomMax] - zoomSettings[\ampZoomMin];
        maxPan = 1 - zoomRange;
        newMin = (panValue * maxPan).max(0).min(maxPan);
        newMax = (newMin + zoomRange).min(1.0);
        
        zoomSettings[\ampZoomMin] = newMin;
        zoomSettings[\ampZoomMax] = newMax;
        zoomSettings[\currentPan] = panValue;
        
        // Refresh display if this is the active trajectory
        if(~nUPIC[\ui][\ampEditorContainer].notNil) {
            var currentTrajIndex = ~nUPIC[\ui][\ampEditorContainer].getProperty(\trajIndex);
            if(currentTrajIndex == trajIndex) {
                var ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
                var overlayView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\overlayView);
                if(ampView.notNil) {
                    { 
                        ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
                        if(overlayView.notNil) { overlayView.refresh };
                    }.defer(0.05);
                };
            };
        };
        
        ("Position updated for trajectory " ++ trajIndex ++ ": " ++ (newMin * 100).round(1) ++ "% to " ++ (newMax * 100).round(1) ++ "%").postln;
    };
};

// Toggle between linear and dB scale display
~nUPIC[\ui][\toggleAmplitudeScale] = { |trajIndex, useDbScale|
    var currentTrajIndex, ampView, scaleType;
    // Store scale preference
    if(~nUPIC[\ui][\ampEditorScales].isNil) {
        ~nUPIC[\ui][\ampEditorScales] = IdentityDictionary.new;
    };
    
    ~nUPIC[\ui][\ampEditorScales][trajIndex] = useDbScale;
    
    // Update display immediately
    if(~nUPIC[\ui][\ampEditorContainer].notNil) {
        currentTrajIndex = ~nUPIC[\ui][\ampEditorContainer].getProperty(\trajIndex);
        if(currentTrajIndex == trajIndex) {
            ampView = ~nUPIC[\ui][\ampEditorContainer].getProperty(\ampView);
            if(ampView.notNil) {
                { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.05);
            };
        };
    };
    
    scaleType = if(useDbScale) { "dB" } { "linear" };
    ("Switched to " ++ scaleType ++ " scale for trajectory " ++ trajIndex).postln;
};

// Solo trajectory (mute all others during playback)
~nUPIC[\ui][\soloTrajectory] = { |trajIndex, solo|
    var data, action;
    data = ~nUPIC[\data];
    if(data[\soloedTrajectories].isNil) {
        data[\soloedTrajectories] = Set.new;
    };
    
    if(solo) {
        data[\soloedTrajectories].add(trajIndex);
    } {
        data[\soloedTrajectories].remove(trajIndex);
    };
    
    action = if(solo) { "Soloed" } { "Unsoloed" };
    (action ++ " trajectory " ++ trajIndex).postln;
};

// Mute trajectory
~nUPIC[\ui][\muteTrajectory] = { |trajIndex, mute|
    var data, action;
    data = ~nUPIC[\data];
    if(data[\mutedTrajectories].isNil) {
        data[\mutedTrajectories] = Set.new;
    };
    
    if(mute) {
        data[\mutedTrajectories].add(trajIndex);
    } {
        data[\mutedTrajectories].remove(trajIndex);
    };
    
    action = if(mute) { "Muted" } { "Unmuted" };
    (action ++ " trajectory " ++ trajIndex).postln;
};

// Preview single trajectory using the main playback system for consistent timing
~nUPIC[\ui][\previewTrajectoryAmplitude] = { |trajIndex|
    var data, traj, ampEnv, container, levelMeter;
    var constants, defaults, width, height, freqMin, freqMax;
    var trajFirstX, trajLastX, previewDuration, frameRate;
    var mainPlayDuration, timeScaling, trajectoryWidthInPixels;
    var synthDefName, firstPoint, startFreq, startPan, state, zoomFreqMax, zoomFreqMin;
    
    data = ~nUPIC[\data];
    traj = data[\trajectories][trajIndex];
    ampEnv = data[\amplitudeEnvelopes][trajIndex];
    container = ~nUPIC[\ui][\ampEditorContainer];
    constants = ~nUPIC[\constants];
    defaults = ~nUPIC[\defaults];
    
    if(traj.notNil and: { traj.size > 0 and: { container.notNil }}) {
        // Stop any existing preview
        if(~nUPIC[\ui][\previewTask].notNil) {
            ~nUPIC[\ui][\previewTask].stop;
            ~nUPIC[\ui][\previewTask] = nil;
        };
        if(~nUPIC[\ui][\previewSynth].notNil) {
            ~nUPIC[\ui][\previewSynth].set(\gate, 0);
            ~nUPIC[\ui][\previewSynth] = nil;
        };
        
        // Get level meter (always visible now)
        levelMeter = container.getProperty(\levelMeter);
        
        // Get system parameters - same as main playback
        width = constants[\defaultWidth] ? 1200;
        height = constants[\defaultHeight] ? 800;
        freqMin = constants[\freqMin] ? 20;
        freqMax = constants[\freqMax] ? 7500;
        frameRate = constants[\frameRate] ? 30;
        
        // Get trajectory time bounds
        trajFirstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
        trajLastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
        
        // Calculate preview duration using same time scaling as main system
        // Main system uses: timeScaling = playDuration / width
        // We want to play just this trajectory's portion
        mainPlayDuration = ~nUPIC[\ui][\state][\playDuration] ? defaults[\playDuration] ? 10;
        timeScaling = mainPlayDuration / width;
        trajectoryWidthInPixels = trajLastX - trajFirstX;
        previewDuration = (trajectoryWidthInPixels * timeScaling).min(4.0);
        
        ("Previewing trajectory " ++ trajIndex ++ " (" ++ previewDuration.round(2) ++ "s) using main playback timing").postln;
        
        // Create synth using same parameters as main system
        synthDefName = if(data[\trajectorySynthDefs].notNil and: { trajIndex < data[\trajectorySynthDefs].size }) {
            data[\trajectorySynthDefs][trajIndex]
        } {
            defaults[\defaultSynthDef] ? \upicWavetable8ch
        };
        
        firstPoint = if(traj[0].isKindOf(Event)) { traj[0] } { (x: traj[0].x, y: traj[0].y, freq: nil) };
        state = ~nUPIC[\ui][\state];
        zoomFreqMax = state[\zoomFreqMax] ? (constants[\freqMax] ? 7500);
        zoomFreqMin = state[\zoomFreqMin] ? (constants[\freqMin] ? 20);
        startFreq = firstPoint.freq ?? { firstPoint.y.linlin(0, height, zoomFreqMax, zoomFreqMin) };
        startPan = firstPoint.x.linlin(0, width, -1, 1);
        
        ~nUPIC[\ui][\previewSynth] = Synth(synthDefName, [
            \freq, startFreq,
            \amp, 0.0,
            \pan, startPan,
            \mass, 1.5 + (trajIndex * 0.3),
            \velocity, 5,
            \distance, 100,
            \width, 0.3 + (trajIndex * 0.1),
            \modFreq, 0.5 + (trajIndex * 0.2),
            \modDepth, 0.3,
            \rq, 0.1,
            \gate, 1
        ]);
        
        // Create preview playback task using same logic as main system
        ~nUPIC[\ui][\previewTask] = Task {
            var frameTime = 1 / frameRate;
            var playbackPosition = 0;
            var synthStarted = false;
            
            while { playbackPosition < previewDuration and: { ~nUPIC[\ui][\previewSynth].notNil } } {
                var x = trajFirstX + (playbackPosition / previewDuration * trajectoryWidthInPixels);
                var point1, point2, interpFactor, foundPoints = false;
                var freq, pan, velocity, amp;
                var lastPoint = if(traj.last.isKindOf(Event)) { traj.last } { (x: traj.last.x, y: traj.last.y, freq: nil) };
                
                // Start synth when trajectory begins (same logic as main system)
                if(synthStarted.not and: { x >= trajFirstX }) {
                    synthStarted = true;
                    ~nUPIC[\ui][\previewSynth].set(\amp, 0.1);
                };
                
                // Only process if within trajectory range
                if(x >= trajFirstX and: { x <= trajLastX }) {
                    // Find interpolation points (same logic as main system)
                    block { |break|
                        (traj.size - 1).do { |j|
                            var p1 = if(traj[j].isKindOf(Event)) { traj[j] } { (x: traj[j].x, y: traj[j].y, freq: nil) };
                            var p2 = if(traj[j + 1].isKindOf(Event)) { traj[j + 1] } { (x: traj[j + 1].x, y: traj[j + 1].y, freq: nil) };
                            
                            if((p1.x <= x) and: { (p2.x >= x) }) {
                                point1 = p1;
                                point2 = p2;
                                interpFactor = (x - point1.x) / (point2.x - point1.x);
                                foundPoints = true;
                                break.value;
                            };
                        };
                    };
                    
                    if(foundPoints) {
                        // Interpolate frequency (same as main system)
                        var state = ~nUPIC[\ui][\state];
                        var zoomFreqMax = state[\zoomFreqMax] ? (constants[\freqMax] ? 7500);
                        var zoomFreqMin = state[\zoomFreqMin] ? (constants[\freqMin] ? 20);
                        var freq1 = point1.freq ?? { point1.y.linlin(0, height, zoomFreqMax, zoomFreqMin) };
                        var freq2 = point2.freq ?? { point2.y.linlin(0, height, zoomFreqMax, zoomFreqMin) };
                        freq = freq1.blend(freq2, interpFactor);
                        pan = x.linlin(0, width, -1, 1);
                        velocity = ((freq2 - freq1).abs / (point2.x - point1.x).max(1)) * 0.1;
                        velocity = velocity.clip(0, 20);
                        
                        // Apply amplitude envelope using same logic as main system
                        if(ampEnv.notNil and: { ampEnv.size > 1 }) {
                            var ampPoint1, ampPoint2, ampFound = false;
                            var normalizedX = (x - trajFirstX) / (trajLastX - trajFirstX);
                            normalizedX = normalizedX.clip(0, 1) * 600;  // Same normalization as main system
                            
                            // Find amplitude interpolation points
                            block { |break|
                                (ampEnv.size - 1).do { |j|
                                    if((ampEnv[j].x <= normalizedX) and: { (ampEnv[j + 1].x >= normalizedX) }) {
                                        ampPoint1 = ampEnv[j];
                                        ampPoint2 = ampEnv[j + 1];
                                        ampFound = true;
                                        break.value;
                                    };
                                };
                            };
                            
                            if(ampFound) {
                                var ampInterpFactor = (normalizedX - ampPoint1.x) / (ampPoint2.x - ampPoint1.x);
                                amp = ampPoint1.amp.blend(ampPoint2.amp, ampInterpFactor) * 0.3;
                            } {
                                // Handle edges
                                if(normalizedX <= ampEnv.first.x) {
                                    amp = ampEnv.first.amp * 0.3;
                                } {
                                    if(normalizedX >= ampEnv.last.x) {
                                        amp = ampEnv.last.amp * 0.3;
                                    } {
                                        amp = 0.05;
                                    };
                                };
                            };
                        } {
                            amp = 0.1;  // Default amplitude
                        };
                        
                        // Update synth parameters
                        ~nUPIC[\ui][\previewSynth].set(
                            \freq, freq,
                            \pan, pan,
                            \velocity, velocity,
                            \amp, amp
                        );
                        
                        // Update level meter in real-time
                        if(levelMeter.notNil) {
                            { levelMeter.value = amp.clip(0, 1) }.defer;
                        };
                    };
                };
                
                playbackPosition = playbackPosition + frameTime;
                frameTime.wait;
            };
            
            // Clean up preview
            if(~nUPIC[\ui][\previewSynth].notNil) {
                ~nUPIC[\ui][\previewSynth].set(\gate, 0);
                ~nUPIC[\ui][\previewSynth] = nil;
            };
            if(levelMeter.notNil) {
                { levelMeter.value = 0 }.defer;  // Reset level meter but keep it visible
            };
            ~nUPIC[\ui][\previewTask] = nil;
            "Preview completed".postln;
        }.play;
    } {
        ("No trajectory data for trajectory " ++ trajIndex).postln;
    };
};

// Helper function to get amplitude at specific time
~nUPIC[\ui][\getAmplitudeAtTime] = { |ampEnv, time|
    var amp = 0.3;  // Default amplitude
    
    if(ampEnv.notNil and: { ampEnv.size > 0 }) {
        if(ampEnv.size == 1) {
            amp = ampEnv.first.amp;
        } {
            block { |break|
                (ampEnv.size - 1).do { |i|
                    if((ampEnv[i].x <= time) and: { (ampEnv[i + 1].x >= time) }) {
                        var factor = (time - ampEnv[i].x) / (ampEnv[i + 1].x - ampEnv[i].x);
                        amp = ampEnv[i].amp.blend(ampEnv[i + 1].amp, factor);
                        break.value;
                    };
                };
            };
            
            // Handle edge cases
            if(time <= ampEnv.first.x) { amp = ampEnv.first.amp };
            if(time >= ampEnv.last.x) { amp = ampEnv.last.amp };
        };
    };
    
    amp
};

// Update level meter based on current amplitude envelope
~nUPIC[\ui][\updateLevelMeter] = { |levelMeter, trajIndex|
    var data, ampEnv, maxAmp, avgAmp, rmsAmp;
    data = ~nUPIC[\data];
    ampEnv = data[\amplitudeEnvelopes][trajIndex];
    
    if(levelMeter.notNil and: { ampEnv.notNil and: { ampEnv.size > 0 }}) {
        // Calculate peak amplitude
        maxAmp = ampEnv.collect(_.amp).maxItem;
        
        // Calculate RMS (Root Mean Square) amplitude
        rmsAmp = sqrt(ampEnv.collect(_.amp).collect({ |amp| amp * amp }).mean);
        
        // Calculate average amplitude
        avgAmp = ampEnv.collect(_.amp).mean;
        
        // Set level meter to show peak amplitude
        levelMeter.value = maxAmp;
        
        // Update peak and RMS display in toolbar if available
        if(~nUPIC[\ui][\ampEditorContainer].notNil) {
            var toolbarContainer = ~nUPIC[\ui][\ampEditorContainer].children.detect({ |child|
                child.getProperty(\analysisText).notNil
            });
            if(toolbarContainer.notNil) {
                var analysisText = toolbarContainer.getProperty(\analysisText);
                if(analysisText.notNil) {
                    var peakDb = if(maxAmp > 0) { 20 * log10(maxAmp) } { -inf };
                    var rmsDb = if(rmsAmp > 0) { 20 * log10(rmsAmp) } { -inf };
                    analysisText.string = "Peak: " ++ peakDb.round(1) ++ " dB | RMS: " ++ rmsDb.round(1) ++ " dB";
                };
            };
        };
        
        ("Level meter updated for trajectory " ++ trajIndex ++ ": Peak = " ++ (maxAmp * 100).round(1) ++ "%").postln;
    };
};

// Update level meter when envelope changes
~nUPIC[\ui][\updateAmplitudeDisplayWithMeter] = { |ampView, trajIndex|
    ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
    
    // Also update level meter
    if(~nUPIC[\ui][\ampEditorContainer].notNil) {
        var levelMeter = ~nUPIC[\ui][\ampEditorContainer].getProperty(\levelMeter);
        if(levelMeter.notNil) {
            { ~nUPIC[\ui][\updateLevelMeter].value(levelMeter, trajIndex); }.defer(0.02);
        };
    };
};

// ===================== TRAJECTORY TRANSFORMATION SUPPORT =====================

// Transform amplitude envelope when trajectory is moved in time
~nUPIC[\ui][\transformAmplitudeEnvelopeTime] = { |trajIndex, deltaX|
    var data = ~nUPIC[\data];
    var ampEnv = data[\amplitudeEnvelopes][trajIndex];
    
    if(ampEnv.notNil and: { ampEnv.size > 0 }) {
        // Move all envelope points by deltaX
        var transformedEnv = ampEnv.collect { |point|
            (x: point.x + deltaX, amp: point.amp)
        };
        
        data[\amplitudeEnvelopes][trajIndex] = transformedEnv;
        
        // Update display if amplitude editor is open for this trajectory
        ~nUPIC[\ui][\refreshAmplitudeEditorIfOpen].value(trajIndex);
        
        ("Moved amplitude envelope for trajectory " ++ trajIndex ++ " by " ++ deltaX ++ " pixels").postln;
    };
};

// Scale amplitude envelope when trajectory length changes
~nUPIC[\ui][\scaleAmplitudeEnvelopeLength] = { |trajIndex, oldLength, newLength|
    var data = ~nUPIC[\data];
    var ampEnv = data[\amplitudeEnvelopes][trajIndex];
    
    if(ampEnv.notNil and: { ampEnv.size > 0 and: { oldLength > 0 }}) {
        var scaleFactor = newLength / oldLength;
        
        // Scale all envelope X positions by the scale factor
        var scaledEnv = ampEnv.collect { |point|
            (x: point.x * scaleFactor, amp: point.amp)
        };
        
        data[\amplitudeEnvelopes][trajIndex] = scaledEnv;
        
        // Update display if amplitude editor is open for this trajectory
        ~nUPIC[\ui][\refreshAmplitudeEditorIfOpen].value(trajIndex);
        
        ("Scaled amplitude envelope for trajectory " ++ trajIndex ++ " by factor " ++ scaleFactor.round(0.01)).postln;
    };
};

// Remove amplitude envelope when trajectory is deleted
~nUPIC[\ui][\removeAmplitudeEnvelope] = { |trajIndex|
    var data = ~nUPIC[\data];
    
    if(data[\amplitudeEnvelopes].notNil and: { trajIndex < data[\amplitudeEnvelopes].size }) {
        data[\amplitudeEnvelopes][trajIndex] = nil;
        ("Removed amplitude envelope for deleted trajectory " ++ trajIndex).postln;
    };
};

// Refresh amplitude editor if open for the given trajectory
~nUPIC[\ui][\refreshAmplitudeEditorIfOpen] = { |trajIndex|
    if(~nUPIC[\ui][\ampEditorWindow].notNil and: {
        ~nUPIC[\ui][\ampEditorWindow].isClosed.not
    }) {
        var currentTabs = ~nUPIC[\ui][\ampEditorCurrentTabs];
        if(currentTabs.includes(trajIndex)) {
            var container = ~nUPIC[\ui][\ampEditorContainer];
            if(container.notNil) {
                var currentTrajIndex = container.getProperty(\trajIndex);
                if(currentTrajIndex == trajIndex) {
                    var ampView = container.getProperty(\ampView);
                    var levelMeter = container.getProperty(\levelMeter);
                    if(ampView.notNil) {
                        { 
                            ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
                            if(levelMeter.notNil) {
                                ~nUPIC[\ui][\updateLevelMeter].value(levelMeter, trajIndex);
                            };
                        }.defer(0.05);
                    };
                };
            };
        };
    };
};

// Initialize undo/redo system after module loads
if(~nUPIC[\ui][\ampEditorUndoStacks].isNil) {
    ~nUPIC[\ui][\ampEditorUndoStacks] = IdentityDictionary.new;
    ~nUPIC[\ui][\ampEditorRedoStacks] = IdentityDictionary.new;
};

"nUPIC Amplitude Editor (Enhanced) module loaded".postln;
)
