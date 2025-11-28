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
    window.background = Color.gray(0.95);
    
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
                    if(i == 0) { Color.white } { Color.gray(0.85) }
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
                            if(i == j) { Color.white } { Color.gray(0.85) }
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
    var spatialView, overlayView, controlView;
    var winWidth = container.bounds.width, winHeight = container.bounds.height;
    var viewHeight = winHeight - 100;  // Leave space for controls
    var data = ~nUPIC[\data];
    var colors = ~nUPIC[\colors];
    var defaults = ~nUPIC[\defaults];
    var currentEnvelope, isDrawing = false;
    var trajectory = data[\trajectories][trajIndex];
    var trajectoryLength;
    var channelLabels;
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
        var lastX = trajectory.last.x;
        trajectoryLength = lastX - firstX;
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

    // Channel labels on the left
    channelLabels = UserView(container, Rect(0, 30, 50, viewHeight - 30));
    channelLabels.drawFunc = {
        numChannels.do { |i|
            var y = ((maxChannel - i) / maxChannel.max(1)) * (viewHeight - 30);
            var label = "Ch " ++ (i + 1);

            Pen.fillColor = Color.black;
            Pen.stringAtPoint(label, Point(10, y - 5), Font("Arial", 10));

            // Draw horizontal guide line
            Pen.strokeColor = Color.gray(0.8);
            Pen.width = 0.5;
            Pen.line(Point(45, y), Point(winWidth, y));
            Pen.stroke;
        };
    };
    
    // Main spatialization drawing view
    spatialView = UserView(container, Rect(50, 30, winWidth - 60, viewHeight - 30));
    spatialView.background = Color.white;
    
    // Overlay for interactive elements
    overlayView = UserView(container, Rect(50, 30, winWidth - 60, viewHeight - 30));
    overlayView.background = Color.clear;
    
    // Drawing function
    spatialView.drawFunc = {
        var width = spatialView.bounds.width;
        var height = spatialView.bounds.height;

        // Draw grid
        Pen.strokeColor = Color.gray(0.9);
        Pen.width = 0.5;

        // Vertical grid lines (time)
        10.do { |i|
            var x = (i + 1) / 11 * width;
            Pen.line(Point(x, 0), Point(x, height));
            Pen.stroke;
        };

        // Horizontal grid lines (channels)
        numChannels.do { |i|
            var y = (i / maxChannel.max(1)) * height;
            Pen.strokeColor = if(i == 0 or: { i == maxChannel }) { Color.gray(0.6) } { Color.gray(0.85) };
            Pen.width = if(i == 0 or: { i == maxChannel }) { 1 } { 0.5 };
            Pen.line(Point(0, y), Point(width, y));
            Pen.stroke;
        };

        // Draw current spatialization envelope
        if(currentEnvelope.notNil and: { currentEnvelope.size > 1 }) {
            Pen.strokeColor = Color.blue;
            Pen.width = 2;

            // Draw the curve as a solid line
            currentEnvelope.do { |point, i|
                var x = (point.x / trajectoryLength) * width;
                var y = ((maxChannel - point.channel) / maxChannel.max(1)) * height;

                if(i == 0) {
                    Pen.moveTo(Point(x, y));
                } {
                    Pen.lineTo(Point(x, y));
                };
            };
            Pen.stroke;
        };

        // Draw instructions
        Pen.fillColor = Color.black;
        Pen.font = Font("Arial", 11);
        Pen.stringAtPoint("Draw spatialization curve: Vertical = Channels 1-" ++ numChannels ++ ", Horizontal = Trajectory length",
            Point(10, 5));
    };
    
    // Mouse interaction for drawing
    overlayView.mouseDownAction = { |view, x, y, modifiers, buttonNumber, clickCount|
        var width = view.bounds.width;
        var height = view.bounds.height;
        var timePos, channel;

        isDrawing = true;

        // Calculate position
        timePos = (x / width) * trajectoryLength;
        channel = maxChannel - ((y / height) * maxChannel);  // Invert Y axis
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
        var timePos, channel;

        if(isDrawing) {
            timePos = (x / width) * trajectoryLength;
            channel = maxChannel - ((y / height) * maxChannel);
            channel = channel.clip(0, maxChannel);
            
            // Add point if moved enough
            if((x - lastX).abs > 5 or: { (channel - lastChannel).abs > 0.2 }) {
                currentEnvelope.add((x: timePos, channel: channel));
                lastX = x;
                lastChannel = channel;
                view.refresh;
                spatialView.refresh;
            };
        };
    };
    
    overlayView.mouseUpAction = { |view, x, y, modifiers, buttonNumber|
        if(isDrawing) {
            isDrawing = false;
            
            // Ensure envelope spans full trajectory
            if(currentEnvelope.size > 0) {
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
                
                // Store the envelope
                data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
                
                ("Spatialization envelope saved for trajectory " ++ trajIndex).postln;
                ("Points: " ++ currentEnvelope.size).postln;
            };
            
            view.refresh;
            spatialView.refresh;
        };
    };
    
    // Control area
    controlView = CompositeView(container, Rect(0, viewHeight, winWidth, 100));
    controlView.background = Color.gray(0.9);
    
    // Preset buttons
    Button(controlView, Rect(10, 10, 80, 25))
        .states_([["Center", Color.black, Color.gray(0.8)]])
        .action_({
            var center = maxChannel / 2;
            currentEnvelope = List[
                (x: 0, channel: center),
                (x: trajectoryLength, channel: center)
            ];
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(100, 10, 80, 25))
        .states_([["Circle", Color.black, Color.cyan]])
        .action_({
            var numPts = 32;
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

    Button(controlView, Rect(190, 10, 80, 25))
        .states_([["Spiral", Color.black, Color.green]])
        .action_({
            var numPts = 64;
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

    Button(controlView, Rect(280, 10, 80, 25))
        .states_([["Random", Color.black, Color.red]])
        .action_({
            var numPts = 20;
            currentEnvelope = List.new;
            numPts.do { |i|
                var xPos = i / (numPts - 1) * trajectoryLength;
                var channel = (numChannels.asFloat).rand;
                currentEnvelope.add((x: xPos, channel: channel.clip(0, maxChannel)));
            };
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(370, 10, 80, 25))
        .states_([["Ch1→Last", Color.black, Color.blue]])
        .action_({
            currentEnvelope = List[
                (x: 0, channel: 0),
                (x: trajectoryLength, channel: maxChannel)
            ];
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });

    Button(controlView, Rect(460, 10, 80, 25))
        .states_([["Last→Ch1", Color.black, Color.blue]])
        .action_({
            currentEnvelope = List[
                (x: 0, channel: maxChannel),
                (x: trajectoryLength, channel: 0)
            ];
            data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
            spatialView.refresh;
        });
    
    // Smoothing button
    Button(controlView, Rect(550, 10, 80, 25))
        .states_([["Smooth", Color.white, Color.gray(0.5)]])
        .action_({
            if(currentEnvelope.size > 2) {
                var smoothed = List.new;
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
                data[\spatializationEnvelopes][trajIndex] = currentEnvelope;
                spatialView.refresh;
            };
        });
    
    // Info display
    StaticText(controlView, Rect(10, 45, 500, 20))
        .string_("Trajectory " ++ trajIndex ++ " - SynthDef: " ++ trajSynthDef ++ " (" ++ numChannels ++ " channels)")
        .font_(Font("Arial", 11));

    StaticText(controlView, Rect(10, 65, 600, 20))
        .string_("Click and drag to draw. Channels 1-" ++ numChannels ++ " map to speaker positions.")
        .font_(Font("Arial", 10))
        .stringColor_(Color.gray(0.5));
    
    // Apply button
    Button(controlView, Rect(winWidth - 100, 10, 80, 30))
        .states_([["Apply", Color.white, Color.green]])
        .font_(Font("Arial", 12, true))
        .action_({
            "Spatialization envelope applied to trajectory".postln;
            ~nUPIC[\ui][\refreshDisplay].value;
        });
};

"✓ Spatialization Envelope Editor loaded".postln;
"Use ~nUPIC[\ui][\openSpatializationEditorForSelected].value to edit selected trajectories".postln;
)