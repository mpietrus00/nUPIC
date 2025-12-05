// Wavetable Editor UI for nUPIC
// Visual editor for creating and modifying wavetables
// Each trajectory has its own wavetable

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetableEditor] = ~nUPIC[\wavetableEditor] ?? ();

~nUPIC[\wavetableEditor][\open] = { |trajectoryIndex = nil|
    var win, drawView, controlView, wavetableData, isDrawing = false;
    var width = 700, height = 400;
    var controlHeight = 140;  // Increased for preset menu
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

    // Row 1: Basic waveforms (y=5)
    xPos = 10;
    buttons[\sine] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_sine", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = Array.fill(numSamples, { |i|
                (i / (numSamples - 1) * 2 * pi).sin
            });
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\saw] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_saw", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = Array.fill(numSamples, { |i|
                (2 * (i / numSamples)) - 1
            });
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\square] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_square", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = Array.fill(numSamples, { |i|
                if(i < (numSamples / 2), 1, -1)
            });
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\triangle] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_tri", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = Array.fill(numSamples, { |i|
                var phase = i / numSamples;
                if(phase < 0.5,
                    { 4 * phase - 1 },
                    { 3 - (4 * phase) }
                )
            });
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\random] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_random", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var maxVal;
            wavetableData = Array.fill(numSamples, { rrand(-1.0, 1.0) });
            maxVal = wavetableData.abs.maxItem;
            if(maxVal > 0) {
                wavetableData = wavetableData / maxVal;
            };
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\smooth] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_smooth", Color.black, Color.gray(0.9)]])
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
    xPos = xPos + 65;

    buttons[\normalize] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_norm", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var maxVal = wavetableData.abs.maxItem;
            if(maxVal > 0) {
                wavetableData = wavetableData / maxVal;
                drawView.refresh;
                ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
            };
        });
    xPos = xPos + 65;

    buttons[\invert] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_invert", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = wavetableData.neg;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\reverse] = Button(controlView, Rect(xPos, 5, 60, 25))
        .states_([["_reverse", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = wavetableData.reverse;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });

    // Row 2: Advanced synthesis (y=35)
    xPos = 10;
    buttons[\harmonic] = Button(controlView, Rect(xPos, 35, 60, 25))
        .states_([["_harmonic", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            wavetableData = Signal.sineFill(numSamples, Array.fill(8, { |i| 1.0 / (i + 1) }));
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\chebyshev] = Button(controlView, Rect(xPos, 35, 60, 25))
        .states_([["_cheby", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var coeffs = [1, 0.5, 0.3, 0.2, 0.1];
            wavetableData = Signal.chebyFill(numSamples, coeffs);
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\formant] = Button(controlView, Rect(xPos, 35, 60, 25))
        .states_([["_formant", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            var signal = Signal.newClear(numSamples);
            var formants = [7, 12, 26];
            var amps = [1, 0.5, 0.3];

            formants.do { |harmonic, i|
                signal = signal + Signal.sineFill(numSamples,
                    Array.fill(harmonic - 1, 0) ++ [amps[i]]
                );
            };

            wavetableData = signal.normalize;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\fm] = Button(controlView, Rect(xPos, 35, 60, 25))
        .states_([["_fm", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = Signal.fill(numSamples, { |i|
                var phase = i / numSamples * 2pi;
                sin(phase + (4 * sin(3.7 * phase)))
            });
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\waveshape] = Button(controlView, Rect(xPos, 35, 60, 25))
        .states_([["_wshape", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            wavetableData = Signal.fill(numSamples, { |i|
                var x = i.linlin(0, numSamples - 1, -1, 1);
                (3 * x) - x.cubed
            });
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });
    xPos = xPos + 65;

    buttons[\additive] = Button(controlView, Rect(xPos, 35, 60, 25))
        .states_([["_additive", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 9))
        .action_({
            var numPartials = rrand(5, 15);
            var harmonics = Array.fill(numPartials, { |i|
                rrand(0.1, 1.0) / (i + 1).sqrt
            });
            var phases = Array.fill(numPartials, { rrand(0, 2pi) });

            wavetableData = Signal.sineFill(numSamples, harmonics, phases);
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
        });

    // Row 3: Test, Copy, and Close (y=70)
    buttons[\test] = Button(controlView, Rect(10, 65, 60, 25))
        .states_([["_test", Color.black, Color.gray(0.9)]])
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

    // Copy wavetable to other selected trajectories
    buttons[\copyToSelected] = Button(controlView, Rect(75, 65, 100, 25))
        .states_([["_copy to sel", Color.black, Color.gray(0.9)]])
        .font_(Font("Arial", 10))
        .action_({
            if(data.notNil and: { data[\selectedTrajectories].notNil }) {
                data[\selectedTrajectories].do { |idx|
                    if(idx != currentIndex) {
                        ~nUPIC[\trajectories][\setWavetable].value(idx, wavetableData.copy);
                    };
                };
                ("Wavetable copied to " ++ (data[\selectedTrajectories].size - 1) ++ " other trajectories").postln;
            };
        });

    buttons[\close] = Button(controlView, Rect(width - 70, 65, 60, 25))
        .states_([["_close", Color.white, Color.red.alpha_(0.8)]])
        .font_(Font("Arial", 10))
        .action_({ win.close });

    // Row 4: Preset dropdown menu (y=100)
    presetLabel = StaticText(controlView, Rect(10, 100, 50, 25))
        .string_("Preset:")
        .font_(Font("Arial", 10));

    // Get preset names if available
    presetNames = if(~nUPIC[\wavetablePresets].notNil and: { ~nUPIC[\wavetablePresets][\list].notNil }) {
        ["-- select preset --"] ++ ~nUPIC[\wavetablePresets][\list].value;
    } {
        ["-- no presets loaded --"]
    };

    presetMenu = PopUpMenu(controlView, Rect(65, 100, 180, 25))
        .items_(presetNames)
        .font_(Font("Arial", 10))
        .background_(Color.gray(0.95))
        .action_({ |menu|
            var selectedName;
            if(menu.value > 0) {
                selectedName = presetNames[menu.value].asSymbol;
                if(~nUPIC[\wavetablePresets].notNil and: { ~nUPIC[\wavetablePresets][\get].notNil }) {
                    wavetableData = ~nUPIC[\wavetablePresets][\get].value(selectedName);
                    if(wavetableData.notNil) {
                        drawView.refresh;
                        ~nUPIC[\trajectories][\setWavetable].value(currentIndex, wavetableData);
                        ("Loaded preset: " ++ selectedName).postln;
                    };
                };
            };
        });

    // Category filter buttons
    xPos = 255;
    [\basic, \organ, \acoustic, \vocal, \fm, \synth].do { |cat, i|
        Button(controlView, Rect(xPos + (i * 55), 100, 50, 25))
            .states_([[cat.asString, Color.black, Color.gray(0.85)]])
            .font_(Font("Arial", 9))
            .action_({
                var catPresets;
                if(~nUPIC[\wavetablePresets].notNil and: { ~nUPIC[\wavetablePresets][\categories].notNil }) {
                    catPresets = ~nUPIC[\wavetablePresets][\categories][cat];
                    if(catPresets.notNil) {
                        presetNames = ["-- " ++ cat ++ " --"] ++ catPresets.collect(_.asString);
                        presetMenu.items_(presetNames);
                    };
                };
            });
    };

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
