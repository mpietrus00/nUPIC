// Test UPIC-inspired Wavetable SynthDef
// Tests drawable waveform synthesis capabilities

(
s.waitForBoot {
    var testBuffer, drawPoints, synth;
    
    // Load the SynthDef
    ("Audio/SynthDefs.scd").loadRelative;
    
    s.sync;
    
    "Testing UPIC Wavetable SynthDef".postln;
    "================================".postln;
    "".postln;
    
    // Check what's loaded
    if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
        "Available synthdefs:".postln;
        ~nUPIC_SynthDefs[\available].do { |name, i|
            ("  " ++ (i+1) ++ ". \\" ++ name).postln;
        };
        "".postln;
    };
    
    fork {
        // Test 1: Default sine wave wavetable
        "Test 1: Default sine wave wavetable".postln;
        "------------------------------------".postln;
        
        if(~nUPIC_DefaultWaveTable.isNil) {
            ~initDefaultWavetable.value;
            s.sync;
        };
        
        synth = Synth(\upicWavetable, [
            \bufnum, ~nUPIC_DefaultWaveTable.bufnum,
            \freq, 440,
            \amp, 0.2,
            \pan, 0,
            \timeScale, 1,
            \modIndex, 0,
            \oversample, 1
        ]);
        
        "Playing default sine wavetable at 440Hz".postln;
        2.wait;
        synth.set(\gate, 0);
        1.wait;
        
        // Test 2: Create custom wavetable from drawn points (sawtooth-like)
        "".postln;
        "Test 2: Custom drawn wavetable (sawtooth shape)".postln;
        "------------------------------------------------".postln;
        
        // Simulate drawn points for a sawtooth wave
        drawPoints = 32.collect { |i|
            (x: i, y: i.linlin(0, 31, -1, 1))
        };
        
        testBuffer = ~createWavetableFromTrajectory.value(drawPoints, 2048);
        s.sync;
        
        if(testBuffer.notNil) {
            synth = Synth(\upicWavetable, [
                \bufnum, testBuffer.bufnum,
                \freq, 220,
                \amp, 0.2,
                \pan, 0,
                \timeScale, 1,
                \modIndex, 0,
                \oversample, 1
            ]);
            
            "Playing custom sawtooth wavetable at 220Hz".postln;
            2.wait;
            synth.set(\gate, 0);
            1.wait;
            testBuffer.free;
        };
        
        // Test 3: Complex drawn waveform with modulation
        "".postln;
        "Test 3: Complex drawn wavetable with modulation".postln;
        "------------------------------------------------".postln;
        
        // Create a more complex waveform shape
        drawPoints = 64.collect { |i|
            var phase = i / 63 * 2pi;
            (x: i, y: (sin(phase) * 0.7 + (sin(phase * 3) * 0.3)))
        };
        
        testBuffer = ~createWavetableFromTrajectory.value(drawPoints, 2048);
        s.sync;
        
        if(testBuffer.notNil) {
            synth = Synth(\upicWavetable, [
                \bufnum, testBuffer.bufnum,
                \freq, 330,
                \amp, 0.2,
                \pan, 0,
                \timeScale, 1,
                \modIndex, 0.5,  // Add modulation
                \modFreq, 3,
                \oversample, 2    // 4x oversampling
            ]);
            
            "Playing complex wavetable at 330Hz with modulation".postln;
            3.wait;
            synth.set(\gate, 0);
            1.wait;
            testBuffer.free;
        };
        
        // Test 4: Time scaling (micro/macro time interpretation)
        "".postln;
        "Test 4: Time scaling demo (UPIC micro/macro time)".postln;
        "---------------------------------------------------".postln;
        
        // Create a pulse-like waveform
        drawPoints = 32.collect { |i|
            (x: i, y: if(i < 8) { 1 } { -0.5 })
        };
        
        testBuffer = ~createWavetableFromTrajectory.value(drawPoints, 2048);
        s.sync;
        
        if(testBuffer.notNil) {
            synth = Synth(\upicWavetable, [
                \bufnum, testBuffer.bufnum,
                \freq, 100,
                \amp, 0.2,
                \pan, 0,
                \timeScale, 1,
                \modIndex, 0,
                \oversample, 1
            ]);
            
            "Playing pulse wave at 100Hz (normal time scale)".postln;
            2.wait;
            
            // Change time scale
            synth.set(\timeScale, 0.25); // Slower (macro time)
            "Time scale = 0.25 (macro time - lower frequency)".postln;
            2.wait;
            
            synth.set(\timeScale, 4); // Faster (micro time)
            "Time scale = 4 (micro time - higher frequency)".postln;
            2.wait;
            
            synth.set(\gate, 0);
            1.wait;
            testBuffer.free;
        };
        
        // Test 5: Filter and resonance
        "".postln;
        "Test 5: Filter modulation test".postln;
        "-------------------------------".postln;
        
        // Create a harmonically rich waveform
        drawPoints = 64.collect { |i|
            var phase = i / 63 * 4pi;
            (x: i, y: sin(phase) + (sin(phase * 2) * 0.5) + (sin(phase * 4) * 0.25))
        };
        
        testBuffer = ~createWavetableFromTrajectory.value(drawPoints, 2048);
        s.sync;
        
        if(testBuffer.notNil) {
            synth = Synth(\upicWavetable, [
                \bufnum, testBuffer.bufnum,
                \freq, 110,
                \amp, 0.2,
                \pan, 0,
                \filtCutoff, 2000,
                \resonance, 0.5,
                \modIndex, 0.7,  // Mix filtered and direct
                \oversample, 1
            ]);
            
            "Playing with filter sweeps".postln;
            
            // Sweep filter cutoff
            100.do { |i|
                var cutoff = i.linexp(0, 99, 200, 5000);
                synth.set(\filtCutoff, cutoff);
                0.03.wait;
            };
            
            synth.set(\gate, 0);
            1.wait;
            testBuffer.free;
        };
        
        "".postln;
        "============================================".postln;
        "UPIC Wavetable SynthDef test complete!".postln;
        "".postln;
        "Features tested:".postln;
        "• Drawable wavetable synthesis".postln;
        "• Time scaling (micro/macro time)".postln;
        "• Frequency/amplitude modulation".postln;
        "• Filter control".postln;
        "• Oversampling for anti-aliasing".postln;
        "============================================".postln;
    };
    
    // Create interactive test GUI
    {
        var win, drawView, testButton, clearButton;
        var drawnPoints = List.new;
        var currentBuffer = nil, currentSynth = nil;
        var isDrawing = false;
        var timeScaleSlider, modIndexSlider, freqSlider;
        
        win = Window("UPIC Wavetable Drawing Test", Rect(100, 100, 800, 400));
        
        // Drawing area for waveform
        drawView = UserView(win, Rect(10, 10, 780, 200));
        drawView.background = Color.white;
        
        drawView.drawFunc = {
            // Draw axes
            Pen.strokeColor = Color.gray(0.7);
            Pen.line(Point(0, 100), Point(780, 100));
            Pen.stroke;
            
            // Draw waveform
            if(drawnPoints.size > 1) {
                Pen.strokeColor = Color.blue;
                Pen.width = 2;
                Pen.moveTo(drawnPoints[0]);
                drawnPoints.do { |point|
                    Pen.lineTo(point);
                };
                Pen.stroke;
            };
        };
        
        drawView.mouseDownAction = { |view, x, y|
            drawnPoints.clear;
            drawnPoints.add(Point(x, y));
            isDrawing = true;
            drawView.refresh;
        };
        
        drawView.mouseMoveAction = { |view, x, y|
            if(isDrawing) {
                drawnPoints.add(Point(x, y));
                drawView.refresh;
            };
        };
        
        drawView.mouseUpAction = { |view, x, y|
            isDrawing = false;
            
            // Convert drawn points to wavetable
            if(drawnPoints.size > 2) {
                var trajPoints = drawnPoints.collect { |p|
                    (x: p.x, y: p.y.linlin(0, 200, 1, -1))
                };
                
                // Free old buffer
                if(currentBuffer.notNil) { currentBuffer.free };
                
                // Create new wavetable
                currentBuffer = ~createWavetableFromTrajectory.value(trajPoints, 2048);
                
                // Update synth if playing
                if(currentSynth.notNil and: { currentBuffer.notNil }) {
                    currentSynth.set(\bufnum, currentBuffer.bufnum);
                };
                
                "Wavetable updated from drawing".postln;
            };
        };
        
        // Test button
        testButton = Button(win, Rect(10, 220, 100, 30))
            .states_([
                ["Play", Color.white, Color.green],
                ["Stop", Color.white, Color.red]
            ])
            .action_({ |btn|
                if(btn.value == 1) {
                    if(currentBuffer.notNil) {
                        currentSynth = Synth(\upicWavetable, [
                            \bufnum, currentBuffer.bufnum,
                            \freq, freqSlider.value.linexp(0, 1, 100, 1000),
                            \amp, 0.2,
                            \timeScale, timeScaleSlider.value.linexp(0, 1, 0.125, 8),
                            \modIndex, modIndexSlider.value,
                            \oversample, 2
                        ]);
                        "Playing drawn wavetable".postln;
                    } {
                        "Draw a waveform first!".postln;
                        btn.value = 0;
                    };
                } {
                    if(currentSynth.notNil) {
                        currentSynth.set(\gate, 0);
                        currentSynth = nil;
                    };
                };
            });
        
        // Clear button
        clearButton = Button(win, Rect(120, 220, 100, 30))
            .states_([["Clear", Color.black, Color.gray(0.9)]])
            .action_({
                drawnPoints.clear;
                drawView.refresh;
                if(currentSynth.notNil) {
                    currentSynth.set(\gate, 0);
                    currentSynth = nil;
                    testButton.value = 0;
                };
            });
        
        // Frequency control
        StaticText(win, Rect(10, 260, 100, 20)).string_("Frequency:");
        freqSlider = Slider(win, Rect(110, 260, 200, 20))
            .value_(0.3)
            .action_({ |sl|
                var freq = sl.value.linexp(0, 1, 100, 1000);
                if(currentSynth.notNil) {
                    currentSynth.set(\freq, freq);
                };
            });
        
        // Time scale control
        StaticText(win, Rect(10, 290, 100, 20)).string_("Time Scale:");
        timeScaleSlider = Slider(win, Rect(110, 290, 200, 20))
            .value_(0.5)
            .action_({ |sl|
                var scale = sl.value.linexp(0, 1, 0.125, 8);
                if(currentSynth.notNil) {
                    currentSynth.set(\timeScale, scale);
                };
            });
        
        // Modulation control
        StaticText(win, Rect(10, 320, 100, 20)).string_("Mod Index:");
        modIndexSlider = Slider(win, Rect(110, 320, 200, 20))
            .value_(0)
            .action_({ |sl|
                if(currentSynth.notNil) {
                    currentSynth.set(\modIndex, sl.value);
                };
            });
        
        // Instructions
        StaticText(win, Rect(350, 220, 440, 150))
            .string_("INSTRUCTIONS:\n\n1. Draw a waveform in the white area above\n2. Press 'Play' to hear your drawn wavetable\n3. Adjust sliders while playing to hear changes\n\nThis demonstrates the core UPIC principle:\nDrawing becomes sound through wavetable synthesis!\n\nTime Scale: <1 = slower/lower, >1 = faster/higher\nMod Index: Controls filter/modulation depth")
            .font_(Font("Arial", 11));
        
        win.onClose = {
            if(currentSynth.notNil) { currentSynth.set(\gate, 0) };
            if(currentBuffer.notNil) { currentBuffer.free };
        };
        
        win.front;
    }.value;
};
)