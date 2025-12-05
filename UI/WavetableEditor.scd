// Wavetable Editor UI for nUPIC
// Visual editor for creating and modifying wavetables
// Each arc has its own wavetable

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetableEditor] = ~nUPIC[\wavetableEditor] ?? ();

~nUPIC[\wavetableEditor][\open] = { |arcIndex = nil|
    var win, drawView, controlView, wavetableData, isDrawing = false;
    var width = 350, height = 200;
    var controlHeight = 35;  // Single row for controls
    var numSamples = 2048;
    var lastX, lastY;
    var buttons = ();
    var xPos;
    var currentIndex;
    var titleText;
    var data = ~nUPIC[\data];
    var trajCount = ~nUPIC[\arcs][\count].value;
    var presetMenu, presetLabel, presetNames;

    // Determine which arc to edit
    if(arcIndex.notNil) {
        currentIndex = arcIndex;
    } {
        // Use first selected arc, or nil if none
        if(data.notNil and: { data[\selectedArcs].notNil } and: { data[\selectedArcs].size > 0 }) {
            currentIndex = data[\selectedArcs].asArray.sort[0];
        } {
            currentIndex = nil;
        };
    };

    // Check if we have a valid arc
    if(currentIndex.isNil or: { trajCount == 0 } or: { currentIndex >= trajCount }) {
        "No arc selected. Draw a arc first, select it, then open the wavetable editor.".warn;
        ^nil;
    };

    // Get wavetable data for this arc
    wavetableData = ~nUPIC[\arcs][\getWavetable].value(currentIndex);
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
    titleText = "nUPIC Wavetable Editor - Arc " ++ currentIndex;

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
        ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
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
        // Update the arc's wavetable
        ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
    };

    // Control area with light B&K green
    controlView = CompositeView(win, Rect(0, height, width, controlHeight));
    controlView.background = Color.new(190/255, 240/255, 190/255);

    // Get wav file names from TABLES directory
    presetNames = if(~nUPIC[\wavetablePresets].notNil and: { ~nUPIC[\wavetablePresets][\list].notNil }) {
        ["-- select --"] ++ ~nUPIC[\wavetablePresets][\list].value;
    } {
        ["-- no files --"]
    };

    // Dropdown menu
    presetMenu = PopUpMenu(controlView, Rect(5, 5, 120, 22))
        .items_(presetNames)
        .font_(Font("Arial", 9))
        .background_(Color.gray(0.95))
        .action_({ |menu|
            var selectedName;
            if(menu.value > 0) {
                selectedName = presetNames[menu.value];
                if(~nUPIC[\wavetablePresets][\wavFiles].includes(selectedName)) {
                    ~nUPIC[\wavetablePresets][\getWavData].value(selectedName, { |loadedData|
                        if(loadedData.notNil) {
                            wavetableData = loadedData;
                            { drawView.refresh }.defer;
                            ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
                        };
                    });
                } {
                    var presetData = ~nUPIC[\wavetablePresets][\get].value(selectedName.asSymbol);
                    if(presetData.notNil) {
                        wavetableData = presetData;
                        drawView.refresh;
                        ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
                    };
                };
            };
        });

    // Utility buttons - compact layout
    xPos = 130;
    buttons[\reverse] = Button(controlView, Rect(xPos, 5, 32, 22))
        .states_([["rev", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            wavetableData = wavetableData.reverse;
            drawView.refresh;
            ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
        });

    buttons[\invert] = Button(controlView, Rect(xPos + 35, 5, 32, 22))
        .states_([["inv", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            wavetableData = wavetableData.neg;
            drawView.refresh;
            ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
        });

    buttons[\smooth] = Button(controlView, Rect(xPos + 70, 5, 32, 22))
        .states_([["smo", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
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
            ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
        });

    buttons[\normalize] = Button(controlView, Rect(xPos + 105, 5, 32, 22))
        .states_([["nrm", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var maxVal = wavetableData.abs.maxItem;
            if(maxVal > 0) {
                wavetableData = wavetableData / maxVal;
                drawView.refresh;
                ~nUPIC[\arcs][\setWavetable].value(currentIndex, wavetableData);
            };
        });

    buttons[\test] = Button(controlView, Rect(xPos + 140, 5, 32, 22))
        .states_([["test", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var buffer = ~nUPIC[\arcs][\getWavetableBuffer].value(currentIndex);
            if(buffer.notNil) {
                fork {
                    var synth = Synth(\upicWavetable, [\freq, 440, \amp, 0.2, \gate, 1, \bufnum, buffer.bufnum]);
                    0.5.wait; synth.set(\freq, 550);
                    0.5.wait; synth.set(\freq, 330);
                    0.5.wait; synth.set(\gate, 0);
                };
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

"Wavetable Editor loaded (per-arc)".postln;
)
