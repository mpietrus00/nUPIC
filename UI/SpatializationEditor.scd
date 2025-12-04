// nUPIC Spatialization Envelope Editor
// Draw spatialization curves for each trajectory
// Vertical axis = 8 channels (0-7), Horizontal axis = trajectory length
// Similar to amplitude envelope but for spatial positioning

(
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

// Function to open spatialization editor for selected trajectories
~nUPIC[\ui][\openSpatializationEditorForSelected] = {
    var data = ~nUPIC[\data];
    var selectedIndices;
    
    if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
        selectedIndices = data[\selectedTrajectories].asArray.sort;
        ~nUPIC[\ui][\openSpatializationEditor].value(selectedIndices);
    } {
        "No trajectories selected. Use 'G' key to enter select mode, then click on trajectories.".postln;
    };
};

// Main spatialization editor window
~nUPIC[\ui][\openSpatializationEditor] = { |trajIndices|
    var window, container, tabButtons, contentViews, currentTab = 0;
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var winWidth = 800, winHeight = 500;
    var tabHeight = 30;
    
    if(trajIndices.isNil or: { trajIndices.size == 0 }) {
        "No trajectories to edit".postln;
        ^nil;
    };
    
    // Initialize spatialization envelopes storage if needed
    if(data[\spatializationEnvelopes].isNil) {
        data[\spatializationEnvelopes] = List.new;
    };
    
    // Ensure we have envelope for each trajectory
    data[\trajectories].size.do { |i|
        if(i >= data[\spatializationEnvelopes].size) {
            data[\spatializationEnvelopes].add(nil);
        };
    };
    
    // Create window
    window = Window("Spatialization Envelope Editor - " ++ trajIndices.size ++ " trajectories", 
        Rect(400, 200, winWidth, winHeight));
    window.background = Color.new(205/255, 250/255, 205/255); // B&K green
    
    // Create tab buttons if multiple trajectories
    if(trajIndices.size > 1) {
        tabButtons = List.new;
        contentViews = List.new;
        
        // Create tab button bar
        trajIndices.do { |trajIdx, i|
            var button = Button(window, Rect(5 + (i * 100), 5, 95, tabHeight - 5))
                .states_([[
                    "Traj " ++ trajIdx, 
                    Color.black, 
                    if(i == 0) { Color.white } { Color.new(180/255, 230/255, 180/255) }
                ]])
                .action_({ |btn|
                    // Hide all content views
                    contentViews.do { |view| view.visible = false };
                    // Show selected content view
                    contentViews[i].visible = true;
                    // Update button colors
                    tabButtons.do { |b, j|
                        b.states_([[
                            b.states[0][0],
                            Color.black,
                            if(i == j) { Color.white } { Color.new(180/255, 230/255, 180/255) }
                        ]]);
                    };
                    currentTab = i;
                });
            tabButtons.add(button);
        };
        
        // Create content containers for each trajectory
        trajIndices.do { |trajIdx, i|
            var contentView = CompositeView(window, Rect(5, tabHeight + 5, winWidth - 10, winHeight - tabHeight - 10));
            contentView.visible = (i == 0);  // Only first tab visible initially
            contentViews.add(contentView);
            
            // Create spatialization editor content for this trajectory
            ~nUPIC[\ui][\createSpatializationEditorContent].value(contentView, trajIdx);
        };
    } {
        // Single trajectory - no tabs needed
        container = CompositeView(window, Rect(5, 5, winWidth - 10, winHeight - 10));
        ~nUPIC[\ui][\createSpatializationEditorContent].value(container, trajIndices[0]);
    };
    
    window.front;
    
    // Store window reference
    ~nUPIC[\ui][\spatializationEditorWindow] = window;
};

// Helper function to get channel count from SynthDef name
~nUPIC[\ui][\getChannelCountFromSynthDef] = { |synthDefName|
    var name = synthDefName.asString;
    var numChannels = 1;  // Default mono

    if(name.contains("24ch")) { numChannels = 24 }
    { if(name.contains("15ch")) { numChannels = 15 }
    { if(name.contains("12ch")) { numChannels = 12 }
    { if(name.contains("8ch")) { numChannels = 8 }
    { if(name.contains("4ch")) { numChannels = 4 }
    { if(name.contains("3ch")) { numChannels = 3 }
    { if(name.contains("2ch")) { numChannels = 2 }
    }}}}}};

    numChannels;
};

// Create spatialization editor content for a single trajectory
~nUPIC[\ui][\createSpatializationEditorContent] = { |container, trajIndex|
    var spatialView, overlayView, controlView, channelLabelView;
    var winWidth = container.bounds.width, winHeight = container.bounds.height;
    var channelLabelWidth = 60;  // Width for channel labels (like freq labels in main UI)
    var channelLabelGap = 5;     // Gap between labels and drawing area
    var viewHeight = winHeight - 100;  // Leave space for controls
    var editorLeft = channelLabelWidth + channelLabelGap;
    var editorWidth = winWidth - editorLeft - 10;
    var data = ~nUPIC[\data];
    var colors = ~nUPIC[\colors];
    var defaults = ~nUPIC[\defaults];
    var currentEnvelope, isDrawing = false;
    var trajectory = data[\trajectories][trajIndex];
    var trajectoryLength;
    var numChannels, maxChannel;
    var trajSynthDef;
    var lastX = 0, lastChannel;

    // Get SynthDef for this trajectory
    trajSynthDef = if(data[\trajectorySynthDefs].notNil and: {
        trajIndex < data[\trajectorySynthDefs].size and: {
            data[\trajectorySynthDefs][trajIndex].notNil
        }
    }) {
        data[\trajectorySynthDefs][trajIndex]
    } {
        defaults[\defaultSynthDef] ? \upicWavetable8ch
    };

    // Get channel count from SynthDef
    numChannels = ~nUPIC[\ui][\getChannelCountFromSynthDef].value(trajSynthDef);
    maxChannel = numChannels - 1;
    lastChannel = maxChannel / 2;  // Start in middle

    // Calculate trajectory length
    if(trajectory.notNil and: { trajectory.size > 0 }) {
        var firstX = trajectory[0].x;
        var lastXVal = trajectory.last.x;
        trajectoryLength = lastXVal - firstX;
    } {
        trajectoryLength = 600;  // Default
    };

    // Get existing envelope or create default
    currentEnvelope = data[\spatializationEnvelopes][trajIndex];
    if(currentEnvelope.isNil) {
        // Create default envelope (center position)
        currentEnvelope = List[
            (x: 0, channel: maxChannel / 2),  // Start at center
            (x: trajectoryLength, channel: maxChannel / 2)  // End at center
        ];
        data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
    };

    // Clear container
    container.children.do({ |child| child.remove });

    // Vertical padding so top and bottom labels are visible
    ~nUPIC[\ui][\spatialVerticalPadding] = 15;

    // Channel labels view on the left (styled like frequency labels in main UI)
    channelLabelView = UserView(container, Rect(0, 0, channelLabelWidth, viewHeight));
    channelLabelView.background = Color.white;
    channelLabelView.drawFunc = {
        var labelHeight = viewHeight;
        var vPad = ~nUPIC[\ui][\spatialVerticalPadding];
        var drawableHeight = labelHeight - (2 * vPad);  // Area for drawing channels

        // Clear background
        Pen.fillColor = Color.white;
        Pen.fillRect(Rect(0, 0, channelLabelWidth, labelHeight));

        // Draw channel labels with padding
        numChannels.do { |i|
            var y = vPad + (((maxChannel - i) / maxChannel.max(1)) * drawableHeight);
            var label = "Ch" ++ i;

            // Draw label text
            Pen.fillColor = Color.gray(0.3);
            Pen.stringAtPoint(
                label,
                Point(8, y - 6),
                Font("Arial", 9, true),
                Color.gray(0.3)
            );

            // Draw tick mark extending to right edge
            Pen.strokeColor = Color.gray(0.4);
            Pen.width = 1.5;
            Pen.line(Point(channelLabelWidth - 12, y), Point(channelLabelWidth, y));
            Pen.stroke;
        };
    };

    // Main spatialization drawing view
    spatialView = UserView(container, Rect(editorLeft, 0, editorWidth, viewHeight));
    spatialView.background = Color.white;

    // Overlay for interactive elements
    overlayView = UserView(container, Rect(editorLeft, 0, editorWidth, viewHeight));
    overlayView.background = Color.clear;

    // Drawing function for spatial view
    spatialView.drawFunc = {
        var width = spatialView.bounds.width;
        var height = spatialView.bounds.height;
        var vPad = ~nUPIC[\ui][\spatialVerticalPadding];
        var drawableHeight = height - (2 * vPad);

        // Draw dotted horizontal grid lines for each channel (with padding)
        numChannels.do { |i|
            var y = vPad + (((maxChannel - i) / maxChannel.max(1)) * drawableHeight);
            var dashLength = 4;
            var gapLength = 4;
            var x = 0;

            // Thicker lines for first and last channels
            if(i == 0 or: { i == maxChannel }) {
                Pen.strokeColor = Color.gray(0.5);
                Pen.width = 1;
            } {
                Pen.strokeColor = Color.gray(0.7);
                Pen.width = 0.5;
            };

            // Draw dotted line
            while { x < width } {
                Pen.line(Point(x, y), Point((x + dashLength).min(width), y));
                Pen.stroke;
                x = x + dashLength + gapLength;
            };
        };

        // Draw vertical grid lines (time divisions) - lighter, also dotted
        10.do { |i|
            var x = (i + 1) / 11 * width;
            var y = 0;
            var dashLength = 3;
            var gapLength = 5;

            Pen.strokeColor = Color.gray(0.85);
            Pen.width = 0.5;

            while { y < height } {
                Pen.line(Point(x, y), Point(x, (y + dashLength).min(height)));
                Pen.stroke;
                y = y + dashLength + gapLength;
            };
        };

        // Draw current spatialization envelope (with padding)
        if(currentEnvelope.notNil and: { currentEnvelope.size > 1 }) {
            Pen.strokeColor = Color.blue;
            Pen.width = 2;

            // Draw the curve as a solid line
            currentEnvelope.do { |point, i|
                var ptX = (point.x / trajectoryLength) * width;
                var ptY = vPad + (((maxChannel - point.channel) / maxChannel.max(1)) * drawableHeight);

                if(i == 0) {
                    Pen.moveTo(Point(ptX, ptY));
                } {
                    Pen.lineTo(Point(ptX, ptY));
                };
            };
            Pen.stroke;
        };
    };

    // Mouse interaction for drawing
    overlayView.mouseDownAction = { |view, x, y, modifiers, buttonNumber, clickCount|
        var width = view.bounds.width;
        var height = view.bounds.height;
        var vPad = ~nUPIC[\ui][\spatialVerticalPadding];
        var drawableHeight = height - (2 * vPad);
        var timePos, channel;

        isDrawing = true;

        // Calculate position (accounting for vertical padding)
        timePos = (x / width) * trajectoryLength;
        channel = maxChannel - (((y - vPad) / drawableHeight) * maxChannel);  // Invert Y axis with padding
        channel = channel.clip(0, maxChannel);

        // Always start fresh - clear existing envelope
        currentEnvelope = List.new;

        // Add first point
        currentEnvelope.add((x: timePos, channel: channel));
        lastX = x;
        lastChannel = channel;

        view.refresh;
        spatialView.refresh;
    };

    overlayView.mouseMoveAction = { |view, x, y, modifiers|
        var width = view.bounds.width;
        var height = view.bounds.height;
        var vPad = ~nUPIC[\ui][\spatialVerticalPadding];
        var drawableHeight = height - (2 * vPad);
        var timePos, channel;

        if(isDrawing) {
            timePos = (x / width) * trajectoryLength;
            channel = maxChannel - (((y - vPad) / drawableHeight) * maxChannel);
            channel = channel.clip(0, maxChannel);

            // Add point if moved enough (very sensitive for detailed curves)
            if((x - lastX).abs > 2 or: { (channel - lastChannel).abs > 0.05 }) {
                currentEnvelope.add((x: timePos, channel: channel));
                lastX = x;
                lastChannel = channel;
                view.refresh;
                spatialView.refresh;
                channelLabelView.refresh;
            };
        };
    };

    overlayView.mouseUpAction = { |view, x, y, modifiers, buttonNumber|
        if(isDrawing) {
            isDrawing = false;

            // Ensure envelope spans full trajectory and interpolate to high resolution
            if(currentEnvelope.size > 0) {
                var interpolated;
                var numOutputPoints = 2048;  // High resolution spatial curve

                // Add start point if needed
                if(currentEnvelope[0].x > 0) {
                    currentEnvelope = List[(x: 0, channel: currentEnvelope[0].channel)] ++ currentEnvelope;
                };

                // Add end point if needed
                if(currentEnvelope.last.x < trajectoryLength) {
                    currentEnvelope.add((x: trajectoryLength, channel: currentEnvelope.last.channel));
                };
                
                // Sort by x position
                currentEnvelope = currentEnvelope.sort({ |a, b| a.x < b.x });

                // Remove duplicates at same x position (keep last)
                currentEnvelope = currentEnvelope.inject(List.new, { |result, point|
                    if(result.size == 0 or: { result.last.x != point.x }) {
                        result.add(point);
                    } {
                        result[result.size - 1] = point;  // Replace with newer point
                    };
                    result;
                });

                // Interpolate to 2048 points for super detailed curve
                if(currentEnvelope.size >= 2) {
                    interpolated = List.new;
                    numOutputPoints.do { |i|
                        var t = i / (numOutputPoints - 1);
                        var targetX = t * trajectoryLength;
                        var channel = 0;
                        var foundSegment = false;

                        // Find segment and interpolate
                        block { |break|
                            (currentEnvelope.size - 1).do { |j|
                                if(currentEnvelope[j].x <= targetX and: { currentEnvelope[j + 1].x >= targetX }) {
                                    var segmentT = (targetX - currentEnvelope[j].x) /
                                        (currentEnvelope[j + 1].x - currentEnvelope[j].x).max(0.001);
                                    channel = currentEnvelope[j].channel.blend(
                                        currentEnvelope[j + 1].channel, segmentT);
                                    foundSegment = true;
                                    break.value;
                                };
                            };
                        };

                        if(foundSegment.not) {
                            // Edge cases
                            if(targetX <= currentEnvelope.first.x) {
                                channel = currentEnvelope.first.channel;
                            } {
                                channel = currentEnvelope.last.channel;
                            };
                        };

                        interpolated.add((x: targetX, channel: channel.clip(0, maxChannel)));
                    };
                    currentEnvelope = interpolated;
                };

                // Store the envelope
                data[\spatializationEnvelopes][trajIndex] = currentEnvelope;

                ("Spatialization envelope saved for trajectory " ++ trajIndex).postln;
                ("Points: " ++ currentEnvelope.size ++ " (interpolated to 2048)").postln;
            };
            
            view.refresh;
            spatialView.refresh;
        };
    };
    
    // Control area
    controlView = CompositeView(container, Rect(0, viewHeight, winWidth, 100));
    controlView.background = Color.new(190/255, 240/255, 190/255); // Light B&K green
    
    // Preset buttons (60x25 to match main UI)
    Button(controlView, Rect(10, 10, 60, 25))
        .states_([["Center", Color.black, Color.gray(0.8)]])
        .font_(Font("Arial", 10))
        .action_({
            var center = maxChannel / 2;
            var numPts = 2048;
            currentEnvelope = List.new;
            numPts.do { |i|
                var xPos = i / (numPts - 1) * trajectoryLength;
                currentEnvelope.add((x: xPos, channel: center));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(80, 10, 60, 25))
        .states_([["Circle", Color.black, Color.cyan]])
        .font_(Font("Arial", 10))
        .action_({
            var numPts = 2048;
            var center = maxChannel / 2;
            var radius = maxChannel / 2;
            currentEnvelope = List.new;
            numPts.do { |i|
                var phase = i / (numPts - 1) * 2pi;
                var channel = center + (radius * sin(phase));
                var xPos = i / (numPts - 1) * trajectoryLength;
                currentEnvelope.add((x: xPos, channel: channel.clip(0, maxChannel)));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(150, 10, 60, 25))
        .states_([["Spiral", Color.black, Color.green]])
        .font_(Font("Arial", 10))
        .action_({
            var numPts = 2048;
            var center = maxChannel / 2;
            currentEnvelope = List.new;
            numPts.do { |i|
                var t = i / (numPts - 1);
                var phase = t * 4pi;  // Two full rotations
                var radius = t * center;  // Expanding radius
                var channel = center + (radius * sin(phase));
                var xPos = t * trajectoryLength;
                currentEnvelope.add((x: xPos, channel: channel.clip(0, maxChannel)));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(220, 10, 60, 25))
        .states_([["Random", Color.black, Color.red]])
        .font_(Font("Arial", 10))
        .action_({
            var numPts = 2048;
            var prevChannel = maxChannel / 2;
            currentEnvelope = List.new;
            numPts.do { |i|
                var xPos = i / (numPts - 1) * trajectoryLength;
                // Smooth random walk instead of pure random
                var delta = rrand(-0.1, 0.1) * maxChannel;
                prevChannel = (prevChannel + delta).clip(0, maxChannel);
                currentEnvelope.add((x: xPos, channel: prevChannel));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(290, 10, 60, 25))
        .states_([["0→Max", Color.black, Color.blue]])
        .font_(Font("Arial", 10))
        .action_({
            var numPts = 2048;
            currentEnvelope = List.new;
            numPts.do { |i|
                var t = i / (numPts - 1);
                var xPos = t * trajectoryLength;
                var channel = t * maxChannel;
                currentEnvelope.add((x: xPos, channel: channel));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(360, 10, 60, 25))
        .states_([["Max→0", Color.black, Color.blue]])
        .font_(Font("Arial", 10))
        .action_({
            var numPts = 2048;
            currentEnvelope = List.new;
            numPts.do { |i|
                var t = i / (numPts - 1);
                var xPos = t * trajectoryLength;
                var channel = maxChannel - (t * maxChannel);
                currentEnvelope.add((x: xPos, channel: channel));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });
    
    // Smoothing button
    Button(controlView, Rect(430, 10, 60, 25))
        .states_([["Smooth", Color.white, Color.gray(0.5)]])
        .font_(Font("Arial", 10))
        .action_({
            if(currentEnvelope.size > 2) {
                var smoothed = List.new;
                // Apply multiple passes for smoother result
                3.do {
                    smoothed = List.new;
                    currentEnvelope.do { |point, i|
                        if(i == 0 or: { i == (currentEnvelope.size - 1) }) {
                            smoothed.add(point);
                        } {
                            var prevChannel = currentEnvelope[i - 1].channel;
                            var nextChannel = currentEnvelope[i + 1].channel;
                            var smoothChannel = (prevChannel + point.channel + nextChannel) / 3;
                            smoothed.add((x: point.x, channel: smoothChannel));
                        };
                    };
                    currentEnvelope = smoothed;
                };
                data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
                spatialView.refresh;
            };
        });

    // Info display
    StaticText(controlView, Rect(10, 45, 500, 20))
        .string_("Trajectory " ++ trajIndex ++ " - SynthDef: " ++ trajSynthDef ++ " (" ++ numChannels ++ " ch) - 2048 point resolution")
        .font_(Font("Arial", 11));

    StaticText(controlView, Rect(10, 65, 600, 20))
        .string_("Click and drag to draw spatial curve. Ch0-Ch" ++ maxChannel ++ " map to speaker positions.")
        .font_(Font("Arial", 10))
        .stringColor_(Color.gray(0.5));
};

"✓ Spatialization Envelope Editor loaded".postln;
"Use ~nUPIC[\ui][\openSpatializationEditorForSelected].value to edit selected trajectories".postln;
)