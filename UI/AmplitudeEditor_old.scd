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
    var ampWin, ampView, tabContainer, presetContainer;
    var winWidth = 700, winHeight = 450;
    var viewHeight = 280;
    var data = ~nUPIC[\data];
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var amplitudePresets = ~nUPIC[\amplitudePresets];
    var tabs = List.new;
    var tabButtons = List.new;
    var currentTab = 0;
    
    if(data.isNil or: { state.isNil }) {
        "nUPIC data or state not initialized".postln;
        ^nil;
    };
    
    // Use selected trajectories or create tabs for all trajectories with data
    if(selectedIndices.isNil) {
        if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
            tabs = data[\selectedTrajectories].asArray.sort;
        } {
            // Show all trajectories that have amplitude data or create default for all
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
    
    // Close existing window if open
    if(~nUPIC[\ui][\ampEditorWindow].notNil and: { 
        ~nUPIC[\ui][\ampEditorWindow].isClosed.not 
    }) {
        ~nUPIC[\ui][\ampEditorWindow].close;
    };
    
    // Create new window
    ampWin = Window("nUPIC Amplitude Editor", 
        Rect(200, 100, winWidth, winHeight));
    ampWin.background = Color.gray(0.95);
    ~nUPIC[\ui][\ampEditorWindow] = ampWin;
    ~nUPIC[\ui][\ampEditorCurrentTabs] = tabs;
    
    // Initialize amplitude envelopes for all tabs
    if(data[\amplitudeEnvelopes].isNil) {
        data[\amplitudeEnvelopes] = List.new;
    };
    
    tabs.do { |trajIndex|
        var traj;
        // Ensure amplitude envelopes list is large enough
        while(data[\amplitudeEnvelopes].size <= trajIndex) {
            data[\amplitudeEnvelopes].add(nil);
        };
        
        // Initialize zoom settings for this trajectory
        if(~nUPIC[\ui][\ampEditorZooms][trajIndex].isNil) {
            ~nUPIC[\ui][\ampEditorZooms][trajIndex] = (ampZoomMin: 0, ampZoomMax: 1);
        };
        
        // Create default envelope if needed
        if(data[\amplitudeEnvelopes][trajIndex].isNil and: {
            trajIndex < data[\trajectories].size
        }) {
            var trajLength;
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
    
    // Create tab buttons
    if(tabs.size > 1) {
        tabContainer = CompositeView(ampWin, Rect(0, 0, winWidth, 30));
        tabContainer.background = Color.gray(0.8);
        
        tabs.do { |trajIndex, i|
            var tabBtn = Button(tabContainer, 
                Rect(i * (winWidth / tabs.size), 0, winWidth / tabs.size, 30));
            var trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
                colors[\trajectory].value(trajIndex, constants[\maxTrajectories] ? 200)
            } { Color.hsv((trajIndex / 200) * 0.8, 0.7, 0.9) };
            
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
                ~nUPIC[\ui][\ampEditorActiveTab] = i;
                ~nUPIC[\ui][\updateAmplitudeEditor].value;
            };
            
            if(i == 0) { tabBtn.value = 1 };  // Select first tab by default
            tabButtons.add(tabBtn);
        };
    };
    
    // Create amplitude editing area (starts at y=30 if tabs, y=0 if single trajectory)
    var editorY = if(tabs.size > 1) { 30 } { 0 };
    var editorHeight = winHeight - editorY;
    
    ~nUPIC[\ui][\createAmplitudeEditorContent].value(ampWin, 
        Rect(0, editorY, winWidth, editorHeight), tabs[0]);
    
    // Window cleanup
    ampWin.onClose = {
        ~nUPIC[\ui][\ampEditorWindow] = nil;
        ~nUPIC[\ui][\ampEditorCurrentTabs].clear;
        "Amplitude editor closed".postln;
    };
    
    ampWin.front;
    "Amplitude editor opened with " ++ tabs.size ++ " trajectory tabs".postln;
    ampWin;
};

// Legacy compatibility - redirect old function to new system
~nUPIC[\ui][\createAmplitudeWindow] = { |trajIndex|
    ~nUPIC[\ui][\createAmplitudeEditor].value([trajIndex]);
};

// Create amplitude editor content for current tab
~nUPIC[\ui][\createAmplitudeEditorContent] = { |parent, bounds, trajIndex|
    var container, ampView, overlayView, presetContainer;
    var winWidth = bounds.width, winHeight = bounds.height;
    var viewHeight = winHeight - 140;  // Height for amplitude view
    var data = ~nUPIC[\data];
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var amplitudePresets = ~nUPIC[\amplitudePresets];
    var ampZoomMin, ampZoomMax;
    var traj;
    
    // Clear existing content from parent
    parent.children.do({ |child| child.remove });
    
    // Get zoom values for current trajectory
    ampZoomMin = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMin] ? 0;
    ampZoomMax = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMax] ? 1;
    
    // Create container for all elements
    container = CompositeView(parent, bounds);
    
    // Create amplitude editing view
    ampView = MultiSliderView(container, Rect(0, 0, winWidth, viewHeight));
    ampView.background = colors[\amplitudeBackground] ? Color.white;
    ampView.fillColor = colors[\amplitudeEnvelope] ? Color.red.alpha_(0.6);
    ampView.strokeColor = colors[\amplitudeStroke] ? Color.red;
    ampView.drawRects = false;
    ampView.drawLines = true;
    ampView.thumbSize = 4;
    ampView.gap = 0;
    ampView.isFilled = true;
    ampView.elasticMode = true;
    
    // Update amplitude envelope when multislider changes
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
        
        // Keep existing envelope points before zoom range
        if(existingEnv.notNil) {
            existingEnv.do { |point|
                if(point.x < zoomStartX) {
                    newEnv.add(point);
                };
            };
        };
        
        // Add points from multislider values (zoomed portion)
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
        
        data[\amplitudeEnvelopes][trajIndex] = cleanEnv;
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    // Add overlay view for drawing grid and labels
    overlayView = UserView(container, Rect(0, 0, winWidth, viewHeight));
    overlayView.acceptsMouse = false;
    
    overlayView.drawFunc = {
        var traj = data[\trajectories][trajIndex];
        var trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
            colors[\trajectory].value(trajIndex, constants[\maxTrajectories] ? 200)
        } { Color.hsv((trajIndex / 200) * 0.8, 0.7, 0.9) };
        
        // Draw trajectory shape as light background
        if(traj.notNil and: { traj.size > 1 }) {
            var trajFirstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
            var trajLastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
            var freqMax = constants[\freqMax] ? 7500;
            var freqMin = constants[\freqMin] ? 20;
            
            Pen.strokeColor = trajColor.alpha_(0.3);
            Pen.width = 2;
            
            traj.do { |point, i|
                var freq = if(point.isKindOf(Event)) { point.freq } {
                    point.y.linlin(0, constants[\defaultHeight] ? 800, freqMax, freqMin)
                };
                var xPos = if(point.isKindOf(Event)) { point.x } { point.x };
                var normalizedX = (xPos - trajFirstX) / (trajLastX - trajFirstX);
                
                if(normalizedX >= ampZoomMin and: { normalizedX <= ampZoomMax }) {
                    var zoomedX = normalizedX.linlin(ampZoomMin, ampZoomMax, 0, 1);
                    var screenX = zoomedX * winWidth;
                    var screenY = freq.linlin(freqMin, freqMax, viewHeight, 0);
                    
                    if(i == 0 or: { normalizedX < ampZoomMin }) {
                        Pen.moveTo(Point(screenX, screenY));
                    } {
                        Pen.lineTo(Point(screenX, screenY));
                    };
                };
            };
            Pen.stroke;
        };
        
        // Draw grid lines and labels
        ~nUPIC[\ui][\drawAmplitudeGrid].value(winWidth, viewHeight, ampZoomMin, ampZoomMax);
    };
    
    // Create preset and control container
    presetContainer = CompositeView(container, Rect(0, viewHeight, winWidth, winHeight - viewHeight));
    presetContainer.background = Color.gray(0.9);
    
    // Add controls to preset container
    ~nUPIC[\ui][\createAmplitudeControls].value(presetContainer, 
        Rect(0, 0, winWidth, winHeight - viewHeight), trajIndex);
    
    // Store references in a dictionary for updating
    parent.setProperty(\views, (
        container: container,
        ampView: ampView,
        overlayView: overlayView,
        presetContainer: presetContainer
    ));
};
    var ampWin, ampView, ampEnv;
    var winWidth = 600, winHeight = 370;  // Height for three rows of controls
    var viewHeight = 250;  // Height for amplitude view
    var isDrawing = false, lastX = 0;
    var trajColor;
    var traj, avgX, avgY, windowX, windowY;
    var presetButtons;
    var trajLength, trajFirstX, trajLastX;
    var ampZoomMin = 0, ampZoomMax = 1;     // Amplitude zoom range (0-1)
    var ampZoomSlider, ampZoomLabel, ampPanSlider, ampPanLabel;
    var overlayView;
    var data = ~nUPIC[\data];
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var amplitudePresets = ~nUPIC[\amplitudePresets];
    var defaultWidth, defaultHeight;
    
    if(data.isNil or: { state.isNil }) {
        "nUPIC data or state not initialized".postln;
        ^nil;
    };
    
    if(data[\trajectories].isNil or: { trajIndex >= data[\trajectories].size }) {
        "Invalid trajectory index".postln;
        ^nil;
    };
    
    // Don't create duplicate windows
    if(~nUPIC[\ui][\ampWindows][trajIndex].notNil and: { 
        ~nUPIC[\ui][\ampWindows][trajIndex].isClosed.not 
    }) {
        ~nUPIC[\ui][\ampWindows][trajIndex].front;
        ^nil;
    };
    
    // Calculate position near trajectory
    traj = data[\trajectories][trajIndex];
    if(traj.size > 0) {
        avgX = 0;
        avgY = 0;
        traj.do { |point|
            if(point.isKindOf(Event)) {
                avgX = avgX + point.x;
                avgY = avgY + point.y;
            };
        };
        avgX = avgX / traj.size;
        avgY = avgY / traj.size;
        
        // Position window near the trajectory center
        defaultWidth = constants[\defaultWidth] ? 1200;
        defaultHeight = constants[\defaultHeight] ? 800;
        windowX = 100 + avgX.linlin(0, defaultWidth, 0, defaultWidth).clip(100, defaultWidth - winWidth);
        windowY = 50 + avgY.linlin(0, defaultHeight, 0, defaultHeight).clip(50, defaultHeight - winHeight);
    } {
        // Default position if trajectory is empty
        windowX = 400 + (trajIndex * 30);
        windowY = 200 + (trajIndex * 30);
    };
    
    trajColor = if(colors.notNil and: { colors[\trajectory].notNil }) {
        colors[\trajectory].value(trajIndex, constants[\maxTrajectories] ? 200)
    } { Color.hsv((trajIndex / 200) * 0.8, 0.7, 0.9) };
    
    ampWin = Window("Amplitude - Trajectory " ++ trajIndex,
        Rect(windowX, windowY, winWidth, winHeight));
    ampWin.background = Color.gray(0.95);
    
    // Initialize zoom values in dictionary
    ~nUPIC[\ui][\ampWindowZooms][trajIndex] = (ampZoomMin: ampZoomMin, ampZoomMax: ampZoomMax);
    
    // Initialize amplitude envelope if needed
    if(data[\amplitudeEnvelopes].isNil) {
        data[\amplitudeEnvelopes] = List.new;
    };
    
    // Ensure amplitude envelopes list is large enough
    while(data[\amplitudeEnvelopes].size <= trajIndex) {
        data[\amplitudeEnvelopes].add(nil);
    };
    
    if(data[\amplitudeEnvelopes][trajIndex].isNil) {
        data[\amplitudeEnvelopes][trajIndex] = List.new;
        // Create default envelope matching trajectory length
        trajLength = if(traj.size > 0) {
            trajFirstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
            trajLastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
            trajLastX - trajFirstX;
        } { winWidth };
        data[\amplitudeEnvelopes][trajIndex].add((x: 0, amp: 0.3));
        data[\amplitudeEnvelopes][trajIndex].add((x: trajLength, amp: 0.3));
    };
    
    // Create preset buttons
    presetButtons = [
        \fadeIn, \fadeOut, \fadeInOut, \constant,
        \pulse, \swell, \percussive, \reverse
    ];
    
    presetButtons.do { |preset, i|
        var row = (i / 4).floor;  // 4 buttons per row
        var col = i % 4;
        var btn = Button(ampWin, Rect(5 + (col * 74), viewHeight + 5 + (row * 25), 70, 20));
        btn.states = [[preset.asString, Color.black, Color.gray(0.9)]];
        btn.font = Font("Arial", 9);
        btn.action = {
            var trajLen, trajStart, trajEnd, zoomedStart, zoomedEnd, zoomedLen, presetEnv, existingEnv, newEnv;
            // Get actual trajectory length
            trajLen = if(traj.size > 0) {
                trajStart = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
                trajEnd = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
                trajEnd - trajStart;
            } { winWidth };
            
            // Calculate zoomed region
            zoomedStart = trajLen * ampZoomMin;
            zoomedEnd = trajLen * ampZoomMax;
            zoomedLen = zoomedEnd - zoomedStart;
            
            // Apply preset to zoomed region
            if(amplitudePresets.notNil and: { amplitudePresets[preset].notNil }) {
                presetEnv = amplitudePresets[preset].value(zoomedLen);
            } {
                // Fallback preset creation
                presetEnv = case 
                { preset == \fadeIn } { 
                    List[(x: 0, amp: 0), (x: zoomedLen, amp: 1)] 
                }
                { preset == \fadeOut } { 
                    List[(x: 0, amp: 1), (x: zoomedLen, amp: 0)] 
                }
                { preset == \constant } { 
                    List[(x: 0, amp: 0.7), (x: zoomedLen, amp: 0.7)] 
                }
                { 
                    List[(x: 0, amp: 0.3), (x: zoomedLen, amp: 0.3)] 
                };
            };
            
            existingEnv = data[\amplitudeEnvelopes][trajIndex];
            newEnv = List.new;
            
            // Keep existing envelope points before zoom range
            if(existingEnv.notNil) {
                existingEnv.do { |point|
                    if(point.x < zoomedStart) {
                        newEnv.add(point);
                    };
                };
            };
            
            // Add preset points (offset to zoomed region)
            presetEnv.do { |point|
                newEnv.add((x: point.x + zoomedStart, amp: point.amp));
            };
            
            // Keep existing envelope points after zoom range
            if(existingEnv.notNil) {
                existingEnv.do { |point|
                    if(point.x > zoomedEnd) {
                        newEnv.add(point);
                    };
                };
            };
            
            // Sort by x position
            newEnv = newEnv.sort({ |a, b| a.x < b.x });
            
            data[\amplitudeEnvelopes][trajIndex] = newEnv;
            ~nUPIC[\ui][\updateAmplitudeDisplay].value(trajIndex);
            ("Applied " ++ preset ++ " envelope to trajectory " ++ trajIndex ++ " (zoomed region)").postln;
        };
    };
    
    // Add clear button
    Button(ampWin, Rect(300, viewHeight + 30, 45, 20))
        .states_([["Clear", Color.white, Color.red.alpha_(0.7)]])
        .font_(Font("Arial", 9))
        .action_({
            var trajLen, trajStart, trajEnd, zoomedStart, zoomedEnd, existingEnv, newEnv;
            trajLen = if(traj.size > 0) {
                trajStart = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
                trajEnd = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
                trajEnd - trajStart;
            } { winWidth };
            
            // Calculate zoomed region
            zoomedStart = trajLen * ampZoomMin;
            zoomedEnd = trajLen * ampZoomMax;
            
            existingEnv = data[\amplitudeEnvelopes][trajIndex];
            newEnv = List.new;
            
            // Keep existing envelope points before zoom range
            if(existingEnv.notNil) {
                existingEnv.do { |point|
                    if(point.x < zoomedStart) {
                        newEnv.add(point);
                    };
                };
            };
            
            // Add flat envelope for zoomed region
            newEnv.add((x: zoomedStart, amp: 0.3));
            newEnv.add((x: zoomedEnd, amp: 0.3));
            
            // Keep existing envelope points after zoom range
            if(existingEnv.notNil) {
                existingEnv.do { |point|
                    if(point.x > zoomedEnd) {
                        newEnv.add(point);
                    };
                };
            };
            
            // Sort by x position
            newEnv = newEnv.sort({ |a, b| a.x < b.x });
            
            data[\amplitudeEnvelopes][trajIndex] = newEnv;
            ~nUPIC[\ui][\updateAmplitudeDisplay].value(trajIndex);
        });
    
    // Add "Apply to All Selected" button
    Button(ampWin, Rect(350, viewHeight + 30, 100, 20))
        .states_([["Apply to Selected", Color.black, Color.green.alpha_(0.7)]])
        .font_(Font("Arial", 9))
        .action_({
            if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 1 }) {
                var sourceEnv = data[\amplitudeEnvelopes][trajIndex];
                data[\selectedTrajectories].do { |i|
                    if(i != trajIndex and: { i < data[\trajectories].size }) {
                        // Ensure amplitude envelopes list is large enough
                        while(data[\amplitudeEnvelopes].size <= i) {
                            data[\amplitudeEnvelopes].add(nil);
                        };
                        data[\amplitudeEnvelopes][i] = sourceEnv.deepCopy;
                    };
                };
                ~nUPIC[\ui][\refreshDisplay].value;
                ("Applied amplitude envelope to " ++ data[\selectedTrajectories].size ++ " trajectories").postln;
            } {
                "Select multiple trajectories to apply envelope to all".postln;
            };
        });
    
    // Amplitude zoom controls - third row to avoid overlap
    StaticText(ampWin, Rect(5, viewHeight + 50, 40, 20))
        .string_("Zoom:")
        .font_(Font("Arial", 10));
    
    ampZoomSlider = Slider(ampWin, Rect(50, viewHeight + 50, 100, 20))
        .value_(0)  // 0 = full view
        .action_({ |slider|
            var zoomLevel = slider.value.linexp(0, 1, 1, 10);  // Exponential zoom up to 10x
            var center = (ampZoomMin + ampZoomMax) / 2;
            var span = 1 / zoomLevel;
            ampZoomMin = (center - (span / 2)).max(0);
            ampZoomMax = (center + (span / 2)).min(1);
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMin] = ampZoomMin;
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMax] = ampZoomMax;
            ampZoomLabel.string = zoomLevel.round(0.1).asString ++ "x";
            // Update the display with zoomed values
            ~nUPIC[\ui][\updateAmplitudeDisplay].value(trajIndex);
            if(overlayView.notNil) { overlayView.refresh };
        });
    
    ampZoomLabel = StaticText(ampWin, Rect(155, viewHeight + 50, 40, 20))
        .string_("1x")
        .font_(Font("Arial", 10));
    
    StaticText(ampWin, Rect(200, viewHeight + 50, 30, 20))
        .string_("Pan:")
        .font_(Font("Arial", 10));
    
    ampPanSlider = Slider(ampWin, Rect(235, viewHeight + 50, 100, 20))
        .value_(0.5)
        .action_({ |slider|
            var span = ampZoomMax - ampZoomMin;
            var center = slider.value;
            ampZoomMin = (center - (span / 2)).max(0);
            ampZoomMax = (center + (span / 2)).min(1);
            // Adjust if we hit bounds
            if(ampZoomMin == 0) { ampZoomMax = span.min(1) };
            if(ampZoomMax == 1) { ampZoomMin = (1 - span).max(0) };
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMin] = ampZoomMin;
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMax] = ampZoomMax;
            // Update the display with zoomed values
            ~nUPIC[\ui][\updateAmplitudeDisplay].value(trajIndex);
            if(overlayView.notNil) { overlayView.refresh };
        });
    
    // Reset zoom button
    Button(ampWin, Rect(340, viewHeight + 50, 50, 20))
        .states_([["Reset", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            ampZoomMin = 0; ampZoomMax = 1;
            ampZoomSlider.value = 0;
            ampPanSlider.value = 0.5;
            ampZoomLabel.string = "1x";
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMin] = 0;
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMax] = 1;
            ~nUPIC[\ui][\updateAmplitudeDisplay].value(trajIndex);
        });
    
    // Play this trajectory button
    Button(ampWin, Rect(400, viewHeight + 50, 55, 20))
        .states_([
            ["Play", Color.white, Color.green.alpha_(0.8)],
            ["Stop", Color.white, Color.red.alpha_(0.8)]
        ])
        .font_(Font("Arial", 10))
        .action_({ |btn|
            if(btn.value == 1) {
                // Start playback - placeholder for now
                "Play individual trajectory " ++ trajIndex ++ " (audio engine integration pending)".postln;
                // Will be implemented when audio engine is integrated
            } {
                // Stop playback
                "Stop trajectory " ++ trajIndex ++ " playback".postln;
            };
        });
    
    // Create MultiSliderView for amplitude editing
    ampView = MultiSliderView(ampWin, Rect(0, 0, winWidth, viewHeight));
    ampView.background = Color.white;
    ampView.fillColor = Color.red.alpha_(0.6);
    ampView.strokeColor = Color.red;
    ampView.drawRects = false;  // Draw as continuous line
    ampView.drawLines = true;
    ampView.thumbSize = 4;
    ampView.gap = 0;
    ampView.isFilled = true;
    ampView.elasticMode = true;  // Allows smooth drawing
    
    // Initialize with amplitude envelope data
    {
        ~nUPIC[\ui][\updateAmplitudeDisplay].value(trajIndex);
    }.defer(0.1);  // Wait for window to be fully created
    
    // Update amplitude envelope when multislider changes
    ampView.action = { |view|
        var values = view.value;
        var currentTraj = data[\trajectories][trajIndex];
        var trajLen = if(currentTraj.size > 0) {
            var firstX = if(currentTraj[0].isKindOf(Event)) { currentTraj[0].x } { currentTraj[0].x };
            var lastX = if(currentTraj.last.isKindOf(Event)) { currentTraj.last.x } { currentTraj.last.x };
            lastX - firstX;
        } { winWidth };
        var newEnv = List.new;
        var cleanEnv = List.new;
        var prevX = -1;
        var existingEnv = data[\amplitudeEnvelopes][trajIndex];
        var zoomStartX = ampZoomMin * trajLen;
        var zoomEndX = ampZoomMax * trajLen;
        
        // Keep existing envelope points before zoom range
        if(existingEnv.notNil) {
            existingEnv.do { |point|
                if(point.x < zoomStartX) {
                    newEnv.add(point);
                };
            };
        };
        
        // Add points from multislider values (zoomed portion)
        values.do { |amp, i|
            var normalizedPos = i / (values.size - 1);  // 0 to 1 across the view
            var zoomedPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);  // Map to zoomed range
            var x = zoomedPos * trajLen;  // Map to actual trajectory length
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
        
        // Sort by x position
        newEnv = newEnv.sort({ |a, b| a.x < b.x });
        
        // Remove duplicates (keep last)
        prevX = -1;
        newEnv.do { |point|
            if((point.x - prevX).abs > 0.1) {
                cleanEnv.add(point);
                prevX = point.x;
            };
        };
        
        data[\amplitudeEnvelopes][trajIndex] = cleanEnv;
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    // Add overlay view for drawing grid and labels
    overlayView = UserView(ampWin, Rect(0, 0, winWidth, viewHeight));
    overlayView.acceptsMouse = false;  // Pass mouse events through to MultiSliderView
    
    overlayView.drawFunc = {
        // Draw trajectory shape as light background
        if(traj.notNil and: { traj.size > 1 }) {
            var trajFirstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
            var trajLastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
            var freqMax = constants[\freqMax] ? 7500;
            var freqMin = constants[\freqMin] ? 20;
            
            // Draw trajectory line
            Pen.strokeColor = trajColor.alpha_(0.3);
            Pen.width = 2;
            
            traj.do { |point, i|
                var freq = if(point.isKindOf(Event)) { point.freq } {
                    point.y.linlin(0, constants[\defaultHeight] ? 800, freqMax, freqMin)
                };
                var xPos = if(point.isKindOf(Event)) { point.x } { point.x };
                var normalizedX = (xPos - trajFirstX) / (trajLastX - trajFirstX);  // 0 to 1
                
                // Only draw points within the zoomed range
                if(normalizedX >= ampZoomMin and: { normalizedX <= ampZoomMax }) {
                    var zoomedX = normalizedX.linlin(ampZoomMin, ampZoomMax, 0, 1);  // Remap to full view
                    var screenX = zoomedX * winWidth;
                    // Map frequency to vertical position (inverted - high freq at top)
                    var screenY = freq.linlin(freqMin, freqMax, viewHeight, 0);
                    
                    if(i == 0 or: { normalizedX < ampZoomMin }) {
                        Pen.moveTo(Point(screenX, screenY));
                    } {
                        Pen.lineTo(Point(screenX, screenY));
                    };
                };
            };
            Pen.stroke;
        };
        
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
            // Calculate actual position in the zoomed range
            var actualPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);
            // Show percentage of trajectory
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
            "Amplitude envelope spans full trajectory (0% = start, 100% = end)",
            Point(10, 5), Font("Arial", 10));
        
        // Trajectory label with color
        Pen.fillColor = trajColor;
        Pen.stringAtPoint(
            "Trajectory " ++ trajIndex,
            Point(winWidth - 80, 5), Font("Arial", 12, true));
    };
    
    ampWin.onClose = {
        ~nUPIC[\ui][\ampWindows][trajIndex] = nil;
        ~nUPIC[\ui][\ampWindowZooms][trajIndex] = nil;
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    ~nUPIC[\ui][\ampWindows][trajIndex] = ampWin;
    ampWin.front;
};

// Update amplitude display with zoom
~nUPIC[\ui][\updateAmplitudeDisplay] = { |trajIndex|
    {
        var ampWin = ~nUPIC[\ui][\ampWindows][trajIndex];
        var ampView, ampEnv, trajLen, currentTraj;
        var ampZoomMin, ampZoomMax;
        var data = ~nUPIC[\data];
        
        if(ampWin.isNil or: { ampWin.isClosed } or: { data.isNil }) { ^nil };
        
        // Get the MultiSliderView from the window
        ampView = ampWin.view.children.detect({ |child| child.isKindOf(MultiSliderView) });
        if(ampView.isNil) { ^nil };
        
        // Get current zoom values from the dictionary
        ampZoomMin = ~nUPIC[\ui][\ampWindowZooms][trajIndex] !? { 
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMin] 
        } ? 0;
        ampZoomMax = ~nUPIC[\ui][\ampWindowZooms][trajIndex] !? { 
            ~nUPIC[\ui][\ampWindowZooms][trajIndex][\ampZoomMax] 
        } ? 1;
        
        if(data[\amplitudeEnvelopes].notNil and: { trajIndex < data[\amplitudeEnvelopes].size }) {
            ampEnv = data[\amplitudeEnvelopes][trajIndex];
        };
        
        if(data[\trajectories].notNil and: { trajIndex < data[\trajectories].size }) {
            currentTraj = data[\trajectories][trajIndex];
        };
        
        trajLen = if(currentTraj.notNil and: { currentTraj.size > 0 }) {
            var firstX = if(currentTraj[0].isKindOf(Event)) { currentTraj[0].x } { currentTraj[0].x };
            var lastX = if(currentTraj.last.isKindOf(Event)) { currentTraj.last.x } { currentTraj.last.x };
            lastX - firstX
        } { 600 };
        
        if(ampEnv.notNil and: { ampEnv.size > 0 }) {
            var values = Array.fill(500, { |i|
                var normalizedPos = i / 499;  // 0 to 1 across the view
                var zoomedPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);  // Apply horizontal zoom
                var xPos = zoomedPos * trajLen;  // Position in trajectory coordinates
                var amp = 0.3;  // Default
                
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
            // Default flat envelope
            ampView.value = Array.fill(500, 0.3);
        };
    }.defer;
};

// Close all amplitude windows
~nUPIC[\ui][\closeAllAmplitudeWindows] = {
    ~nUPIC[\ui][\ampWindows].do { |win, index|
        if(win.notNil and: { win.isClosed.not }) {
            win.close;
        };
    };
    ~nUPIC[\ui][\ampWindows].clear;
    ~nUPIC[\ui][\ampWindowZooms].clear;
};

"nUPIC Amplitude Editor module loaded".postln;
)
