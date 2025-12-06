// Wavetable Editor UI for nUPIC
// Visual editor for creating and modifying wavetables
// Supports tabbed interface for editing multiple arcs simultaneously

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetableEditor] = ~nUPIC[\wavetableEditor] ?? ();

~nUPIC[\wavetableEditor][\open] = { |arcIndex = nil|
    var win, tabView, drawView, controlView;
    var width = 480, height = 200;
    var tabHeight = 25;
    var controlHeight = 35;
    var numSamples = 2048;
    var isDrawing = false;
    var lastX, lastY;
    var buttons = ();
    var xPos;
    var data = ~nUPIC[\data];
    var trajCount = ~nUPIC[\arcs][\count].value;
    var presetMenu, presetNames;

    // Tab management
    var arcIndices = List.new;
    var tabButtons = List.new;
    var wavetableCache = IdentityDictionary.new;
    var activeTabIndex = 0;

    // Helper to get current arc index
    var getCurrentArcIndex = { arcIndices[activeTabIndex] };

    // Helper to get current wavetable data
    var getCurrentWavetable = {
        var idx = getCurrentArcIndex.value;
        if(wavetableCache[idx].isNil) {
            wavetableCache[idx] = ~nUPIC[\arcs][\getWavetable].value(idx) ?? {
                Array.fill(2048, { |i| sin(2pi * i / 2048) })
            };
        };
        wavetableCache[idx];
    };

    // Helper to set current wavetable data
    var setCurrentWavetable = { |newData|
        var idx = getCurrentArcIndex.value;
        wavetableCache[idx] = newData;
        ~nUPIC[\arcs][\setWavetable].value(idx, newData);
    };

    // Determine which arcs to edit
    if(arcIndex.notNil) {
        // Single arc specified
        arcIndices.add(arcIndex);
    } {
        // Use all selected arcs
        if(data.notNil and: { data[\selectedArcs].notNil } and: { data[\selectedArcs].size > 0 }) {
            arcIndices = data[\selectedArcs].asArray.sort.asList;
        };
    };

    // Check if we have valid arcs
    if(arcIndices.size == 0 or: { trajCount == 0 }) {
        "No arc selected. Draw an arc first, select it, then open the wavetable editor.".warn;
        ^nil;
    };

    // Filter out invalid indices
    arcIndices = arcIndices.select { |idx| idx < trajCount };
    if(arcIndices.size == 0) {
        "Selected arcs are invalid.".warn;
        ^nil;
    };

    // Pre-load wavetable data for all arcs
    arcIndices.do { |idx|
        var wt = ~nUPIC[\arcs][\getWavetable].value(idx);
        if(wt.isNil) {
            wt = Array.fill(2048, { |i| sin(2pi * i / 2048) });
            // Ensure storage exists
            if(data[\wavetables].isNil) { data[\wavetables] = List.new };
            if(data[\wavetableBuffers].isNil) { data[\wavetableBuffers] = List.new };
            while { data[\wavetables].size <= idx } {
                data[\wavetables].add(nil);
                data[\wavetableBuffers].add(nil);
            };
            data[\wavetables][idx] = wt;
            if(Server.default.serverRunning) {
                data[\wavetableBuffers][idx] = Buffer.loadCollection(Server.default, wt);
            };
        };
        wavetableCache[idx] = wt;
    };

    // Calculate window dimensions
    if(arcIndices.size > 1) {
        // Add space for tabs
        height = height + tabHeight;
    };

    // Create window
    win = Window("nUPIC Wavetable Editor", Rect(100, 100, width, height + controlHeight));
    win.background = Color.new(205/255, 250/255, 205/255); // B&K green

    // Tab bar (only if multiple arcs)
    if(arcIndices.size > 1) {
        var tabWidth, tabStartY;
        tabView = CompositeView(win, Rect(0, 0, width, tabHeight));
        tabView.background = Color.new(180/255, 230/255, 180/255);

        tabWidth = (width / arcIndices.size).min(80);
        tabStartY = 2;

        // Create tab buttons
        arcIndices.do { |arcIdx, i|
            var btn = Button(tabView, Rect(i * tabWidth + 2, tabStartY, tabWidth - 4, tabHeight - 4))
                .states_([
                    ["Arc " ++ arcIdx, Color.black, Color.gray(0.85)],
                    ["Arc " ++ arcIdx, Color.white, Color.blue(0.7)]
                ])
                .font_(Font("Arial", 10, true))
                .value_(if(i == 0, 1, 0))
                .action_({ |btn|
                    // Switch to this tab
                    activeTabIndex = i;
                    // Update all tab button states
                    tabButtons.do { |tb, j|
                        tb.value = if(j == i, 1, 0);
                    };
                    // Refresh drawing
                    drawView.refresh;
                });
            tabButtons.add(btn);
        };
    };

    // Drawing area
    drawView = UserView(win, Rect(10, if(arcIndices.size > 1, tabHeight + 10, 10), width - 20, 200 - 20));
    drawView.background = Color.white;

    // Draw function
    drawView.drawFunc = {
        var wavetableData = getCurrentWavetable.value;
        var step = (width - 20) / numSamples;
        var centerY = (200 - 20) / 2;
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
            while { y < (200 - 20) } {
                Pen.line(Point(lineX, y), Point(lineX, (y + dashLen).min(200 - 20)));
                Pen.stroke;
                y = y + dashLen + gapLen;
            };
        };

        // Draw wavetable
        Pen.strokeColor = Color.blue;
        Pen.width = 1.5;

        Pen.moveTo(Point(0, centerY - (wavetableData[0] * centerY * 0.9)));

        (numSamples - 1).do { |i|
            var ptX = (i + 1) * step;
            var y = centerY - (wavetableData[i + 1] * centerY * 0.9);
            Pen.lineTo(Point(ptX, y));
        };

        Pen.stroke;

        // Show current arc label in corner
        Pen.stringAtPoint(
            "Arc " ++ getCurrentArcIndex.value,
            Point(5, 5),
            Font("Arial", 10, true),
            Color.gray(0.4)
        );
    };

    // Mouse interaction for drawing
    drawView.mouseDownAction = { |view, x, y|
        var index, value;
        var wavetableData = getCurrentWavetable.value;
        isDrawing = true;
        lastX = x;
        lastY = y;

        index = (x / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
        value = ((((200 - 20) / 2) - y) / ((200 - 20) / 2) / 0.9).clip(-1, 1);
        wavetableData[index] = value;

        drawView.refresh;
    };

    drawView.mouseMoveAction = { |view, x, y|
        var startIndex, endIndex, startValue, endValue, numSteps;
        var wavetableData = getCurrentWavetable.value;
        if(isDrawing) {
            startIndex = (lastX / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
            endIndex = (x / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
            startValue = ((((200 - 20) / 2) - lastY) / ((200 - 20) / 2) / 0.9).clip(-1, 1);
            endValue = ((((200 - 20) / 2) - y) / ((200 - 20) / 2) / 0.9).clip(-1, 1);

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
        setCurrentWavetable.value(getCurrentWavetable.value);
    };

    // Control area
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
                            setCurrentWavetable.value(loadedData);
                            wavetableCache[getCurrentArcIndex.value] = loadedData;
                            { drawView.refresh }.defer;
                        };
                    });
                } {
                    var presetData = ~nUPIC[\wavetablePresets][\get].value(selectedName.asSymbol);
                    if(presetData.notNil) {
                        setCurrentWavetable.value(presetData);
                        wavetableCache[getCurrentArcIndex.value] = presetData;
                        drawView.refresh;
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
            var wt = getCurrentWavetable.value.reverse;
            setCurrentWavetable.value(wt);
            wavetableCache[getCurrentArcIndex.value] = wt;
            drawView.refresh;
        });

    buttons[\invert] = Button(controlView, Rect(xPos + 35, 5, 32, 22))
        .states_([["inv", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var wt = getCurrentWavetable.value.neg;
            setCurrentWavetable.value(wt);
            wavetableCache[getCurrentArcIndex.value] = wt;
            drawView.refresh;
        });

    buttons[\smooth] = Button(controlView, Rect(xPos + 70, 5, 32, 22))
        .states_([["smo", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var smoothed = getCurrentWavetable.value.copy;
            3.do {
                smoothed = smoothed.collect { |val, i|
                    var prev = smoothed[(i - 1) % numSamples];
                    var next = smoothed[(i + 1) % numSamples];
                    (prev + (val * 2) + next) / 4;
                };
            };
            setCurrentWavetable.value(smoothed);
            wavetableCache[getCurrentArcIndex.value] = smoothed;
            drawView.refresh;
        });

    buttons[\normalize] = Button(controlView, Rect(xPos + 105, 5, 32, 22))
        .states_([["nrm", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var wt = getCurrentWavetable.value;
            var maxVal = wt.abs.maxItem;
            if(maxVal > 0) {
                wt = wt / maxVal;
                setCurrentWavetable.value(wt);
                wavetableCache[getCurrentArcIndex.value] = wt;
                drawView.refresh;
            };
        });

    buttons[\test] = Button(controlView, Rect(xPos + 140, 5, 32, 22))
        .states_([["test", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var buffer = ~nUPIC[\arcs][\getWavetableBuffer].value(getCurrentArcIndex.value);
            if(buffer.notNil) {
                fork {
                    var synth = Synth(\upicWavetable, [\freq, 440, \amp, 0.2, \gate, 1, \bufnum, buffer.bufnum]);
                    0.5.wait; synth.set(\freq, 550);
                    0.5.wait; synth.set(\freq, 330);
                    0.5.wait; synth.set(\gate, 0);
                };
            };
        });

    // Arc-to-Wavetable conversion: use arc shape as wavetable
    buttons[\fromArc] = Button(controlView, Rect(xPos + 180, 5, 38, 22))
        .states_([["arc→", Color.white, Color.new(0.5, 0.3, 0.6)]])
        .font_(Font("Arial", 9, true))
        .action_({
            var arcIdx = getCurrentArcIndex.value;
            var wt = ~nUPIC[\arcs][\convertToWavetable].value(arcIdx);
            if(wt.notNil) {
                setCurrentWavetable.value(wt);
                wavetableCache[arcIdx] = wt;
                drawView.refresh;
                "Arc % shape applied as wavetable".format(arcIdx).postln;
            } {
                "Could not convert arc % to wavetable".format(arcIdx).warn;
            };
        });

    // Wavetable-to-Arc conversion: create new arc from wavetable shape
    buttons[\toArc] = Button(controlView, Rect(xPos + 222, 5, 38, 22))
        .states_([["→arc", Color.white, Color.new(0.3, 0.5, 0.6)]])
        .font_(Font("Arial", 9, true))
        .action_({
            var wt = getCurrentWavetable.value;
            var newIdx = ~nUPIC[\arcs][\createFromWavetable].value(wt, 100, 600);
            if(newIdx.notNil) {
                "Created arc % from wavetable".format(newIdx).postln;
            } {
                "Could not create arc from wavetable".warn;
            };
        });

    // Apply to All button (only if multiple arcs)
    if(arcIndices.size > 1) {
        buttons[\applyAll] = Button(controlView, Rect(xPos + 268, 5, 32, 22))
            .states_([["all", Color.white, Color.new(0.2, 0.5, 0.2)]])
            .font_(Font("Arial", 9, true))
            .action_({
                var currentWt = getCurrentWavetable.value;
                arcIndices.do { |idx|
                    wavetableCache[idx] = currentWt.copy;
                    ~nUPIC[\arcs][\setWavetable].value(idx, currentWt.copy);
                };
                "Applied wavetable to all % arcs".format(arcIndices.size).postln;
            });
    };

    // Store window reference
    ~nUPIC[\wavetableEditor][\window] = win;
    ~nUPIC[\wavetableEditor][\arcIndices] = arcIndices;
    ~nUPIC[\wavetableEditor][\activeTabIndex] = activeTabIndex;

    win.onClose = {
        ~nUPIC[\wavetableEditor][\window] = nil;
        ~nUPIC[\wavetableEditor][\arcIndices] = nil;
        ~nUPIC[\wavetableEditor][\activeTabIndex] = nil;
    };

    win.front;
};

"Wavetable Editor loaded (tabbed multi-arc support)".postln;
)
