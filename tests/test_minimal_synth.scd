// Test the minimal VarSawOS trajectory synth

(
s.waitForBoot {
    var testSynth;
    
    // Load the minimal SynthDef
    ("Audio/SynthDefs.scd").loadRelative;
    
    s.sync;
    
    "Testing Minimal VarSawOS Trajectory Synth".postln;
    "=========================================".postln;
    "".postln;
    
    // Check what's loaded
    if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
        "Available synthdefs:".postln;
        ~nUPIC_SynthDefs[\available].do { |name|
            ("  • \\" ++ name).postln;
        };
        "".postln;
    };
    
    fork {
        // Test 1: Simple frequency sweep
        "Test 1: Frequency sweep (200 Hz to 2000 Hz)".postln;
        
        testSynth = Synth(\trajectoryVarSaw, [
            \freq, 200,
            \amp, 0.3,
            \pan, 0
        ]);
        
        // Sweep frequency
        100.do { |i|
            var freq = i.linexp(0, 99, 200, 2000);
            testSynth.set(\freq, freq);
            0.05.wait;
        };
        
        testSynth.set(\gate, 0);  // Release
        1.wait;
        
        // Test 2: Amplitude envelope simulation
        "".postln;
        "Test 2: Amplitude envelope (fade in and out)".postln;
        
        testSynth = Synth(\trajectoryVarSaw, [
            \freq, 440,
            \amp, 0,
            \pan, 0
        ]);
        
        // Fade in
        50.do { |i|
            testSynth.set(\amp, i / 50 * 0.3);
            0.02.wait;
        };
        
        // Sustain
        1.wait;
        
        // Fade out
        50.do { |i|
            testSynth.set(\amp, (1 - (i / 50)) * 0.3);
            0.02.wait;
        };
        
        testSynth.set(\gate, 0);
        1.wait;
        
        // Test 3: Panning test
        "".postln;
        "Test 3: Panning (left to right)".postln;
        
        testSynth = Synth(\trajectoryVarSaw, [
            \freq, 600,
            \amp, 0.2,
            \pan, -1
        ]);
        
        // Pan from left to right
        100.do { |i|
            testSynth.set(\pan, i.linlin(0, 99, -1, 1));
            0.03.wait;
        };
        
        testSynth.set(\gate, 0);
        1.wait;
        
        // Test 4: Multiple voices (simulating multiple trajectories)
        "".postln;
        "Test 4: Multiple trajectories (3 voices)".postln;
        
        var synths = [
            Synth(\trajectoryVarSaw, [\freq, 300, \amp, 0.15, \pan, -0.5]),
            Synth(\trajectoryVarSaw, [\freq, 450, \amp, 0.15, \pan, 0]),
            Synth(\trajectoryVarSaw, [\freq, 600, \amp, 0.15, \pan, 0.5])
        ];
        
        // Modulate all three
        100.do { |i|
            synths[0].set(\freq, 300 + (i * 2));
            synths[1].set(\freq, 450 - (i * 1.5));
            synths[2].set(\freq, 600 + (sin(i * 0.1) * 100));
            0.05.wait;
        };
        
        // Release all
        synths.do { |s| s.set(\gate, 0) };
        1.wait;
        
        "".postln;
        "Test complete!".postln;
        "".postln;
        "The minimal synth has:".postln;
        "  • Frequency control from trajectory Y-axis".postln;
        "  • Amplitude control from amplitude envelope".postln;
        "  • Pan control from trajectory X-axis (time)".postln;
        "  • Single VarSawOS oscillator with 4x oversampling".postln;
        "  • Fixed pulse width at 50%".postln;
    };
    
    // Create a simple GUI for manual testing
    {
        var win, freqSlider, ampSlider, panSlider, playButton;
        var manualSynth;
        
        win = Window("Minimal Synth Test", Rect(100, 100, 400, 250));
        
        StaticText(win, Rect(10, 10, 380, 20))
            .string_("Manual control for trajectoryVarSaw synth:")
            .font_(Font("Arial", 12, true));
        
        // Frequency control
        StaticText(win, Rect(10, 40, 100, 20)).string_("Frequency:");
        freqSlider = Slider(win, Rect(120, 40, 200, 20))
            .value_(0.3)
            .action_({ |sl|
                var freq = sl.value.linexp(0, 1, 20, 2000);
                if(manualSynth.notNil) {
                    manualSynth.set(\freq, freq);
                };
                StaticText(win, Rect(330, 40, 60, 20))
                    .string_(freq.round(0.1).asString ++ " Hz");
            });
        
        // Amplitude control
        StaticText(win, Rect(10, 70, 100, 20)).string_("Amplitude:");
        ampSlider = Slider(win, Rect(120, 70, 200, 20))
            .value_(0.3)
            .action_({ |sl|
                if(manualSynth.notNil) {
                    manualSynth.set(\amp, sl.value);
                };
                StaticText(win, Rect(330, 70, 60, 20))
                    .string_(sl.value.round(0.01).asString);
            });
        
        // Pan control
        StaticText(win, Rect(10, 100, 100, 20)).string_("Pan:");
        panSlider = Slider(win, Rect(120, 100, 200, 20))
            .value_(0.5)
            .action_({ |sl|
                var pan = sl.value.linlin(0, 1, -1, 1);
                if(manualSynth.notNil) {
                    manualSynth.set(\pan, pan);
                };
                StaticText(win, Rect(330, 100, 60, 20))
                    .string_(pan.round(0.01).asString);
            });
        
        // Play/Stop button
        playButton = Button(win, Rect(10, 140, 380, 40))
            .states_([
                ["▶ Play", Color.white, Color.green],
                ["◼ Stop", Color.white, Color.red]
            ])
            .action_({ |btn|
                if(btn.value == 1) {
                    manualSynth = Synth(\trajectoryVarSaw, [
                        \freq, freqSlider.value.linexp(0, 1, 20, 2000),
                        \amp, ampSlider.value,
                        \pan, panSlider.value.linlin(0, 1, -1, 1)
                    ]);
                } {
                    if(manualSynth.notNil) {
                        manualSynth.set(\gate, 0);
                        manualSynth = nil;
                    };
                };
            });
        
        StaticText(win, Rect(10, 190, 380, 50))
            .string_("This minimal synth is designed for nUPIC trajectories:\n• Y-axis → Frequency\n• Amplitude envelope → Volume\n• X-axis (time) → Pan")
            .font_(Font("Arial", 10))
            .stringColor_(Color.gray(0.4));
        
        win.onClose = {
            if(manualSynth.notNil) {
                manualSynth.set(\gate, 0);
            };
        };
        
        win.front;
    }.defer;
};
)
