// Wavetable Editor UI for nUPIC
// Visual editor for creating and modifying wavetables
// Each trajectory has its own wavetable

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetableEditor] = ~nUPIC[\wavetableEditor] ?? ();

~nUPIC[\wavetableEditor][\open] = { |trajectoryIndex = nil|
    var win, drawView, controlView, wavetableData, isDrawing = false;
    var width = 700, height = 400;
    var controlHeight = 45;  // Single row for controls
    var numSamples = 2048;
    var lastX, lastY;
    var buttons = ();
    var xPos;
    var currentIndex;
    var titleText;
    var data = ~nUPIC[\data];
    var trajCount = ~nUPIC[\trajectories][\count].value;
    var presetMenu, presetLabel, presetNames;

    // Determine which trajectory to edit
    if(trajectoryIndex.notNil) {
        currentIndex = trajectoryIndex;
    } {
        // Use first selected trajectory, or nil if none
        if(data.notNil and: { data[\selectedTrajectories].notNil } and: { data[\selectedTrajectories].size > 0 }) {
            currentIndex = data[\selectedTrajectories].asArray.sort[0];
        } {
            currentIndex = nil;
        };
    };

    // Check if we have a valid trajectory
    if(currentIndex.isNil or: { trajCount == 0 } or: { currentIndex >= trajCount }) {
        "No trajectory selected. Draw a trajectory first, select it, then open the wavetable editor.".warn;
        ^nil;
    };

    // Get wavetable data for this trajectory
    wavetableData = ~nUPIC[\trajectories][\getWavetable].value(currentIndex);
    if(wavetableData.isNil) {
        // Create default sine wavetable and store it
        wavetableData = Array.fill(2048, { |i|
            sin(2pi * i / 2048)
        });
        // Ensure storage exists
        if(data[\wavetables].isNil) { data[\wavetables] = List.new };
        if(data[\wavetableBuffers].isNil) { data[\wavetableBuffers] = List.new };
        // Pad with nil if needed
        while { data[\wavetables].size <= currentIndex } {
            data[\wavetables].add(nil);
            data[\wavetableBuffers].add(nil);
        };
        data[\wavetables][currentIndex] = wavetableData;
        if(Server.default.serverRunning) {
            data[\wavetableBuffers][currentIndex] = Buffer.loadCollection(Server.default, wavetableData);
        };
    };

    // Create title
    titleText = "nUPIC Wavetable Editor - Trajectory " ++ currentIndex;

    // Create window with B&K green
    win = Window(titleText, Rect(100, 100, width, height + controlHeight));
    win.background = Color.new(205/255, 250/255, 205/255); // B&K green

    // Drawing area
    drawView = UserView(win, Rect(10, 10, width - 20, height - 20));
    drawView.background = Color.white;

    // Draw function
    drawView.drawFunc = {
        var step = (width - 20) / numSamples;
        var centerY = (height - 20) / 2;
        var dashLen = 4, gapLen = 4;
        var x = 0;

        // Draw grid - dotted lines
        Pen.strokeColor = Color.gray(0.8);
        Pen.width = 1;

        // Horizontal center line (dotted)
        x = 0;
        while { x < (width - 20) } {
            Pen.line(Point(x, centerY), Point((x + dashLen).min(width - 20), centerY));
            Pen.stroke;
            x = x + dashLen + gapLen;
        };

        // Vertical lines at quarters (dotted)
        4.do { |i|
            var lineX = (i + 1) * ((width - 20) / 4);
            var y = 0;
            while { y < (height - 20) } {
                Pen.line(Point(lineX, y), Point(lineX, (y + dashLen).min(height - 20)));
                Pen.stroke;
                y = y + dashLen + gapLen;
            };
        };

        // Draw wavetable - all points connected
        Pen.strokeColor = Color.blue;
        Pen.width = 1.5;

        Pen.moveTo(Point(0, centerY - (wavetableData[0] * centerY * 0.9)));

        (numSamples - 1).do { |i|
            var ptX = (i + 1) * step;
            var y = centerY - (wavetableData[i + 1] * centerY * 0.9);
            Pen.lineTo(Point(ptX, y));
        };

        Pen.stroke;
    };

    // Helper function to update wavetable in manager
    ~nUPIC[\wavetableEditor][\updateWavetable] = {
        ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
    };

    // Mouse interaction for drawing
    drawView.mouseDownAction = { |view, x, y|
        var index, value;
        isDrawing = true;
        lastX = x;
        lastY = y;

        index = (x / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
        value = ((((height - 20) / 2) - y) / ((height - 20) / 2) / 0.9).clip(-1, 1);
        wavetableData[index] = value;

        drawView.refresh;
    };

    drawView.mouseMoveAction = { |view, x, y|
        var startIndex, endIndex, startValue, endValue, numSteps;
        if(isDrawing) {
            startIndex = (lastX / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
            endIndex = (x / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
            startValue = ((((height - 20) / 2) - lastY) / ((height - 20) / 2) / 0.9).clip(-1, 1);
            endValue = ((((height - 20) / 2) - y) / ((height - 20) / 2) / 0.9).clip(-1, 1);

            if(startIndex != endIndex) {
                numSteps = (endIndex - startIndex).abs;
                (numSteps + 1).do { |i|
                    var index = if(startIndex < endIndex,
                        { startIndex + i },
                        { startIndex - i }
                    ).clip(0, numSamples - 1);
                    var t = i / numSteps;
                    wavetableData[index] = startValue.blend(endValue, t);
                };
            } {
                wavetableData[startIndex] = endValue;
            };

            lastX = x;
            lastY = y;
            drawView.refresh;
        };
    };

    drawView.mouseUpAction = { |view, x, y|
        isDrawing = false;
        // Update the trajectory's wavetable
        ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
    };

    // Control area with light B&K green
    controlView = CompositeView(win, Rect(0, height, width, controlHeight));
    controlView.background = Color.new(190/255, 240/255, 190/255);

    // Single row: Dropdown menu + utility buttons
    xPos = 10;

    // Wavetable dropdown label
    presetLabel = StaticText(controlView, Rect(xPos, 10, 70, 25))
        .string_("Wavetable:")
        .font_(Font("Arial", 10));
    xPos = xPos + 75;

    // Get wav file names from TABLES directory
    presetNames = if(~nUPIC[\wavetablePresets].notNil and: { ~nUPIC[\wavetablePresets][\list].notNil }) {
        ["-- select --"] ++ ~nUPIC[\wavetablePresets][\list].value;
    } {
        ["-- no files --"]
    };

    presetMenu = PopUpMenu(controlView, Rect(xPos, 10, 200, 25))
        .items_(presetNames)
        .font_(Font("Arial", 10))
        .background_(Color.gray(0.95))
        .action_({ |menu|
            var selectedName;
            if(menu.value > 0) {
                selectedName = presetNames[menu.value];

                // Check if it's a wav file or programmatic preset
                if(~nUPIC[\wavetablePresets][\wavFiles].includes(selectedName)) {
                    // Load .wav file asynchronously
                    ~nUPIC[\wavetablePresets][\getWavData].value(selectedName, { |loadedData|
                        if(loadedData.notNil) {
                            wavetableData = loadedData;
                            { drawView.refresh }.defer;
                            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
                            ("Loaded: " ++ selectedName).postln;
                        };
                    });
                } {
                    // Programmatic preset (sync)
                    var presetData = ~nUPIC[\wavetablePresets][\get].value(selectedName.asSymbol);
                    if(presetData.notNil) {
                        wavetableData = presetData;
                        drawView.refresh;
                        ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
                        ("Loaded preset: " ++ selectedName).postln;
                    };
                };
            };
        });
    xPos = xPos + 205;

    // Refresh button
    buttons[\refresh] = Button(controlView, Rect(xPos, 10, 50, 25))
        .states_([["scan", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 10))
        .action_({
            ~nUPIC[\wavetablePresets][\scanWavFiles].value;
            presetNames = ["-- select --"] ++ ~nUPIC[\wavetablePresets][\list].value;
            presetMenu.items_(presetNames);
            ("Found " ++ (~nUPIC[\wavetablePresets][\wavFiles].size) ++ " wav files").postln;
        });
    xPos = xPos + 55;

    // Utility buttons
    buttons[\reverse] = Button(controlView, Rect(xPos, 10, 55, 25))
        .states_([["reverse", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = wavetableData.reverse;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 60;

    buttons[\invert] = Button(controlView, Rect(xPos, 10, 50, 25))
        .states_([["invert", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = wavetableData.neg;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 55;

    buttons[\smooth] = Button(controlView, Rect(xPos, 10, 55, 25))
        .states_([["smooth", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var smoothed = wavetableData.copy;
            3.do {
                smoothed = smoothed.collect { |val, i|
                    var prev = smoothed[(i - 1) % numSamples];
                    var next = smoothed[(i + 1) % numSamples];
                    (prev + (val * 2) + next) / 4;
                };
            };
            wavetableData = smoothed;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 60;

    buttons[\normalize] = Button(controlView, Rect(xPos, 10, 50, 25))
        .states_([["norm", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var maxVal = wavetableData.abs.maxItem;
            if(maxVal > 0) {
                wavetableData = wavetableData / maxVal;
                drawView.refresh;
                ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
            };
        });
    xPos = xPos + 55;

    buttons[\test] = Button(controlView, Rect(xPos, 10, 40, 25))
        .states_([["test", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var buffer = ~nUPIC[\trajectories][\getWavetableBuffer].value(currentIndex);
            if(buffer.notNil) {
                fork {
                    var synth = Synth(\upicWavetable, [
                        \freq, 440,
                        \amp, 0.2,
                        \gate, 1,
                        \bufnum, buffer.bufnum
                    ]);
                    0.5.wait;
                    synth.set(\freq, 550);
                    0.5.wait;
                    synth.set(\freq, 330);
                    0.5.wait;
                    synth.set(\gate, 0);
                };
            } {
                "No wavetable buffer available".warn;
            };
        });

    // Store window reference
    ~nUPIC[\wavetableEditor][\window] = win;
    ~nUPIC[\wavetableEditor][\currentIndex] = currentIndex;

    win.onClose = {
        ~nUPIC[\wavetableEditor][\window] = nil;
        ~nUPIC[\wavetableEditor][\currentIndex] = nil;
    };

    win.front;
};

"Wavetable Editor loaded (per-trajectory)".postln;
)
