// Wavetable Editor UI for nUPIC
// Visual editor for creating and modifying wavetables

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetableEditor] = ~nUPIC[\wavetableEditor] ?? ();

~nUPIC[\wavetableEditor][\open] = {
    var win, drawView, wavetableData, isDrawing = false;
    var width = 600, height = 400;
    var numSamples = 512;
    var lastX, lastY;
    var buttons = ();
    
    // Initialize wavetable data (512 samples)
    wavetableData = Array.fill(numSamples, { |i| 
        sin(2pi * i / numSamples) 
    });
    
    // If buffer exists, get current wavetable
    if(~nUPIC_wavetableBuffer.notNil) {
        ~nUPIC_wavetableBuffer.getToFloatArray(action: { |array|
            {
                wavetableData = array;
                drawView.refresh;
            }.defer;
        });
    };
    
    // Create window - make it taller for more buttons
    win = Window("nUPIC Wavetable Editor", Rect(100, 100, width, height + 150));
    win.background = Color.gray(0.95);
    
    // Drawing area
    drawView = UserView(win, Rect(10, 10, width - 20, height - 20));
    drawView.background = Color.white;
    
    // Draw function
    drawView.drawFunc = {
        var step = (width - 20) / numSamples;
        var centerY = (height - 20) / 2;
        
        // Draw grid
        Pen.strokeColor = Color.gray(0.8);
        Pen.width = 1;
        
        // Horizontal center line
        Pen.line(Point(0, centerY), Point(width - 20, centerY));
        Pen.stroke;
        
        // Vertical lines at quarters
        4.do { |i|
            var x = (i + 1) * ((width - 20) / 4);
            Pen.line(Point(x, 0), Point(x, height - 20));
            Pen.stroke;
        };
        
    // Draw wavetable - all 2048 points connected
    Pen.strokeColor = Color.blue;
    Pen.width = 1;  // Thinner line for high resolution
    
    Pen.moveTo(Point(0, centerY - (wavetableData[0] * centerY * 0.9)));
    
    // Draw all points but only as connected lines (no individual dots)
    (numSamples - 1).do { |i|
        var x = (i + 1) * step;
        var y = centerY - (wavetableData[i + 1] * centerY * 0.9);
        Pen.lineTo(Point(x, y));
    };
    
    Pen.stroke;
    
    // Optional: Show a few reference points for visual feedback (not all 2048)
    // This doesn't affect drawing resolution, just visual markers
    if(false) {  // Set to true if you want to see some reference dots
        Pen.fillColor = Color.red.alpha_(0.3);
        (numSamples / 128).asInteger.do { |i|
            var index = i * 128;
            var x = index * step;
            var y = centerY - (wavetableData[index] * centerY * 0.9);
            Pen.fillOval(Rect(x - 1, y - 1, 2, 2));
        };
    };
    };
    
    // Mouse interaction for drawing
    drawView.mouseDownAction = { |view, x, y|
        var index, value;
        isDrawing = true;
        lastX = x;
        lastY = y;
        
        // Update wavetable at this position
        index = (x / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
        value = ((((height - 20) / 2) - y) / ((height - 20) / 2) / 0.9).clip(-1, 1);
        wavetableData[index] = value;
        
        drawView.refresh;
    };
    
    drawView.mouseMoveAction = { |view, x, y|
        if(isDrawing) {
            // Interpolate between last position and current
            var startIndex = (lastX / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
            var endIndex = (x / ((width - 20) / numSamples)).asInteger.clip(0, numSamples - 1);
            var startValue = ((((height - 20) / 2) - lastY) / ((height - 20) / 2) / 0.9).clip(-1, 1);
            var endValue = ((((height - 20) / 2) - y) / ((height - 20) / 2) / 0.9).clip(-1, 1);
            
            if(startIndex != endIndex) {
                var numSteps = (endIndex - startIndex).abs;
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
        // Update the buffer - NO wavetable conversion for OscOS
        if(~nUPIC_wavetableBuffer.notNil) {
            ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
        };
    };
    
    // Control buttons
    buttons[\sine] = Button(win, Rect(10, height, 80, 30))
        .states_([["Sine", Color.black, Color.gray(0.9)]])
        .action_({
            wavetableData = Array.fill(numSamples, { |i| 
                (i / (numSamples - 1) * 2 * pi).sin
            });
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    buttons[\saw] = Button(win, Rect(100, height, 80, 30))
        .states_([["Saw", Color.black, Color.gray(0.9)]])
        .action_({
            wavetableData = Array.fill(numSamples, { |i| 
                (2 * (i / numSamples)) - 1
            });
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    buttons[\square] = Button(win, Rect(190, height, 80, 30))
        .states_([["Square", Color.black, Color.gray(0.9)]])
        .action_({
            wavetableData = Array.fill(numSamples, { |i| 
                if(i < (numSamples / 2), 1, -1)
            });
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    buttons[\triangle] = Button(win, Rect(280, height, 80, 30))
        .states_([["Triangle", Color.black, Color.gray(0.9)]])
        .action_({
            wavetableData = Array.fill(numSamples, { |i|
                var phase = i / numSamples;
                if(phase < 0.5, 
                    { 4 * phase - 1 },
                    { 3 - (4 * phase) }
                )
            });
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    buttons[\random] = Button(win, Rect(370, height, 80, 30))
        .states_([["Random", Color.black, Color.gray(0.9)]])
        .action_({
            var maxVal;
            
            // Generate 2048 random values directly - raw noise
            wavetableData = Array.fill(numSamples, { 
                rrand(-1.0, 1.0) 
            });
            
            // NO smoothing - keep it raw and noisy!
            
            // Normalize to prevent clipping
            maxVal = wavetableData.abs.maxItem;
            if(maxVal > 0) {
                wavetableData = wavetableData / maxVal;
            };
            
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            "Generated raw random/noise wavetable with 2048 samples".postln;
        });
    
    buttons[\smooth] = Button(win, Rect(460, height, 80, 30))
        .states_([["Smooth", Color.black, Color.gray(0.9)]])
        .action_({
            // Apply smoothing filter
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
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    // Additional controls - Row 2
    buttons[\normalize] = Button(win, Rect(10, height + 40, 80, 30))
        .states_([["Normalize", Color.black, Color.gray(0.9)]])
        .action_({
            var maxVal = wavetableData.abs.maxItem;
            if(maxVal > 0) {
                wavetableData = wavetableData / maxVal;
                drawView.refresh;
                if(~nUPIC_wavetableBuffer.notNil) {
                    ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
                };
            };
        });
    
    buttons[\invert] = Button(win, Rect(100, height + 40, 80, 30))
        .states_([["Invert", Color.black, Color.gray(0.9)]])
        .action_({
            wavetableData = wavetableData.neg;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    buttons[\reverse] = Button(win, Rect(190, height + 40, 80, 30))
        .states_([["Reverse", Color.black, Color.gray(0.9)]])
        .action_({
            wavetableData = wavetableData.reverse;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
        });
    
    // Test button
    buttons[\test] = Button(win, Rect(470, height + 40, 80, 30))
        .states_([["Test", Color.black, Color.green.alpha_(0.3)]])
        .action_({
            fork {
                var synth = Synth(\upicWavetable, [
                    \freq, 440, 
                    \amp, 0.2, 
                    \gate, 1,
                    \bufnum, ~nUPIC_wavetableBuffer.bufnum
                ]);
                0.5.wait;
                synth.set(\freq, 550);
                0.5.wait;
                synth.set(\freq, 330);
                0.5.wait;
                synth.set(\gate, 0);
            };
        });
    
    buttons[\close] = Button(win, Rect(560, height + 40, 80, 30))
        .states_([["Close", Color.white, Color.red.alpha_(0.8)]])
        .action_({ win.close });
    
    // Advanced generation buttons - Row 3
    buttons[\harmonic] = Button(win, Rect(10, height + 80, 80, 30))
        .states_([["Harmonic", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            // Generate harmonic series with 8 harmonics
            wavetableData = Signal.sineFill(numSamples, Array.fill(8, { |i| 1.0 / (i + 1) }));
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            "Generated harmonic series wavetable".postln;
        });
    
    buttons[\chebyshev] = Button(win, Rect(100, height + 80, 80, 30))
        .states_([["Chebyshev", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            // Generate Chebyshev polynomial
            var coeffs = [1, 0.5, 0.3, 0.2, 0.1];
            wavetableData = Signal.chebyFill(numSamples, coeffs);
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            ("Generated Chebyshev wavetable with coeffs: " ++ coeffs).postln;
        });
    
    buttons[\formant] = Button(win, Rect(190, height + 80, 80, 30))
        .states_([["Formant", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            // Generate formant-like wavetable
            var signal = Signal.newClear(numSamples);
            var formants = [7, 12, 26];  // Harmonic numbers for formants
            var amps = [1, 0.5, 0.3];
            
            formants.do { |harmonic, i|
                signal = signal + Signal.sineFill(numSamples, 
                    Array.fill(harmonic - 1, 0) ++ [amps[i]]
                );
            };
            
            wavetableData = signal.normalize;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            "Generated formant wavetable".postln;
        });
    
    buttons[\fm] = Button(win, Rect(280, height + 80, 80, 30))
        .states_([["FM", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            // Generate FM synthesis wavetable
            wavetableData = Signal.fill(numSamples, { |i|
                var phase = i / numSamples * 2pi;
                sin(phase + (4 * sin(3.7 * phase)))  // carrier + (index * sin(modulator * phase))
            });
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            "Generated FM wavetable".postln;
        });
    
    buttons[\waveshape] = Button(win, Rect(370, height + 80, 80, 30))
        .states_([["Waveshape", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            // Generate waveshaping transfer function
            wavetableData = Signal.fill(numSamples, { |i|
                var x = i.linlin(0, numSamples - 1, -1, 1);
                (3 * x) - x.cubed  // Chebyshev T3 polynomial
            });
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            "Generated waveshaping transfer function".postln;
        });
    
    buttons[\additive] = Button(win, Rect(460, height + 80, 80, 30))
        .states_([["Additive", Color.black, Color.cyan.alpha_(0.3)]])
        .action_({
            // Generate additive synthesis with random harmonics
            var numPartials = rrand(5, 15);
            var harmonics = Array.fill(numPartials, { |i| 
                rrand(0.1, 1.0) / (i + 1).sqrt 
            });
            var phases = Array.fill(numPartials, { rrand(0, 2pi) });
            
            wavetableData = Signal.sineFill(numSamples, harmonics, phases);
            wavetableData = wavetableData.normalize;
            drawView.refresh;
            if(~nUPIC_wavetableBuffer.notNil) {
                ~nUPIC_wavetableBuffer.loadCollection(wavetableData);
            };
            ("Generated additive wavetable with " ++ numPartials ++ " partials").postln;
        });
    
    // Store window reference
    ~nUPIC[\wavetableEditor][\window] = win;
    
    win.onClose = {
        ~nUPIC[\wavetableEditor][\window] = nil;
    };
    
    win.front;
};

"✓ Wavetable Editor loaded".postln;
)