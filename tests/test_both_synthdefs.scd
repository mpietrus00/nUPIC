// Test both synthdefs: simpleGravObject and trajectoryVarSaw

(
s.waitForBoot {
    // Load the SynthDefs
    ("Audio/SynthDefs.scd").loadRelative;
    
    s.sync;
    
    "Testing Both SynthDefs".postln;
    "======================".postln;
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
        var synth;
        
        // Test 1: simpleGravObject
        "Test 1: simpleGravObject (gravitational object with Doppler)".postln;
        "This has mass, velocity, distance, and width parameters".postln;
        
        synth = Synth(\simpleGravObject, [
            \freq, 440,
            \amp, 0.25,
            \pan, 0,
            \mass, 2,
            \velocity, 5,
            \distance, 100,
            \width, 0.5,
            \radialVel, 0,
            \dopplerSens, 1.0
        ]);
        
        // Modulate parameters
        100.do { |i|
            var progress = i / 99;
            synth.set(
                \freq, progress.linexp(0, 1, 200, 800),
                \mass, progress.linlin(0, 1, 0.5, 5),
                \velocity, (sin(i * 0.1) * 10).abs,
                \distance, progress.linlin(0, 1, 200, 50),
                \radialVel, sin(i * 0.05) * 10
            );
            0.05.wait;
        };
        
        synth.set(\gate, 0);
        1.wait;
        
        // Test 2: trajectoryVarSaw
        "".postln;
        "Test 2: trajectoryVarSaw (simple trajectory synth)".postln;
        "This only has freq, amp, and pan parameters".postln;
        
        synth = Synth(\trajectoryVarSaw, [
            \freq, 440,
            \amp, 0.25,
            \pan, 0
        ]);
        
        // Modulate parameters
        100.do { |i|
            var progress = i / 99;
            synth.set(
                \freq, progress.linexp(0, 1, 200, 800),
                \amp, (sin(i * 0.05) * 0.2 + 0.2).abs,
                \pan, sin(i * 0.03)
            );
            0.05.wait;
        };
        
        synth.set(\gate, 0);
        1.wait;
        
        "".postln;
        "Test complete!".postln;
        "".postln;
        "Both synthdefs are available in the dropdown menu:".postln;
        "• simpleGravObject - Complex synth with physics parameters".postln;
        "• trajectoryVarSaw - Simple synth for basic trajectories".postln;
    };
    
    // Create test GUI
    {
        var win, menu, playButton, testSynth;
        var freqSlider, ampSlider, massSlider, velocitySlider, distanceSlider;
        
        win = Window("SynthDef Test", Rect(100, 100, 500, 350));
        
        StaticText(win, Rect(10, 10, 480, 20))
            .string_("Select and test synthdefs:")
            .font_(Font("Arial", 12, true));
        
        // SynthDef selection
        StaticText(win, Rect(10, 40, 80, 20)).string_("SynthDef:");
        menu = PopUpMenu(win, Rect(100, 40, 200, 25))
            .items_(~nUPIC_SynthDefs[\available].collect(_.asString))
            .value_(0);
        
        // Play button
        playButton = Button(win, Rect(310, 40, 180, 25))
            .states_([
                ["▶ Play Selected", Color.white, Color.green],
                ["◼ Stop", Color.white, Color.red]
            ])
            .action_({ |btn|
                if(btn.value == 1) {
                    var synthName = ~nUPIC_SynthDefs[\available][menu.value];
                    ("Playing: \\" ++ synthName).postln;
                    
                    testSynth = Synth(synthName, [
                        \freq, freqSlider.value.linexp(0, 1, 100, 2000),
                        \amp, ampSlider.value * 0.3,
                        \pan, 0,
                        \mass, massSlider.value.linlin(0, 1, 0.1, 5),
                        \velocity, velocitySlider.value.linlin(0, 1, 0, 20),
                        \distance, distanceSlider.value.linlin(0, 1, 20, 500),
                        \width, 0.5,
                        \radialVel, 0,
                        \dopplerSens, 1.0
                    ]);
                } {
                    if(testSynth.notNil) {
                        testSynth.set(\gate, 0);
                        testSynth = nil;
                    };
                };
            });
        
        // Control sliders
        StaticText(win, Rect(10, 80, 480, 20))
            .string_("Parameters (simpleGravObject uses all, trajectoryVarSaw uses only freq/amp):")
            .font_(Font("Arial", 10));
        
        // Frequency
        StaticText(win, Rect(10, 110, 80, 20)).string_("Frequency:");
        freqSlider = Slider(win, Rect(100, 110, 300, 20))
            .value_(0.3)
            .action_({ |sl|
                var freq = sl.value.linexp(0, 1, 100, 2000);
                if(testSynth.notNil) { testSynth.set(\freq, freq) };
                StaticText(win, Rect(410, 110, 80, 20))
                    .string_(freq.round(0.1).asString ++ " Hz");
            });
        
        // Amplitude
        StaticText(win, Rect(10, 140, 80, 20)).string_("Amplitude:");
        ampSlider = Slider(win, Rect(100, 140, 300, 20))
            .value_(0.5)
            .action_({ |sl|
                if(testSynth.notNil) { testSynth.set(\amp, sl.value * 0.3) };
                StaticText(win, Rect(410, 140, 80, 20))
                    .string_(sl.value.round(0.01).asString);
            });
        
        // Mass (simpleGravObject only)
        StaticText(win, Rect(10, 170, 80, 20)).string_("Mass:");
        massSlider = Slider(win, Rect(100, 170, 300, 20))
            .value_(0.3)
            .action_({ |sl|
                var mass = sl.value.linlin(0, 1, 0.1, 5);
                if(testSynth.notNil) { testSynth.set(\mass, mass) };
                StaticText(win, Rect(410, 170, 80, 20))
                    .string_(mass.round(0.1).asString);
            });
        
        // Velocity (simpleGravObject only)
        StaticText(win, Rect(10, 200, 80, 20)).string_("Velocity:");
        velocitySlider = Slider(win, Rect(100, 200, 300, 20))
            .value_(0.25)
            .action_({ |sl|
                var vel = sl.value.linlin(0, 1, 0, 20);
                if(testSynth.notNil) { testSynth.set(\velocity, vel) };
                StaticText(win, Rect(410, 200, 80, 20))
                    .string_(vel.round(0.1).asString);
            });
        
        // Distance (simpleGravObject only)
        StaticText(win, Rect(10, 230, 80, 20)).string_("Distance:");
        distanceSlider = Slider(win, Rect(100, 230, 300, 20))
            .value_(0.5)
            .action_({ |sl|
                var dist = sl.value.linlin(0, 1, 20, 500);
                if(testSynth.notNil) { testSynth.set(\distance, dist) };
                StaticText(win, Rect(410, 230, 80, 20))
                    .string_(dist.round(1).asString);
            });
        
        StaticText(win, Rect(10, 270, 480, 70))
            .string_("Notes:\n• simpleGravObject: Full physics-based synth with Doppler effect\n• trajectoryVarSaw: Simple synth, ignores physics parameters\n• Both synthdefs will appear in nUPIC's dropdown menu")
            .font_(Font("Arial", 10))
            .stringColor_(Color.gray(0.4));
        
        win.onClose = {
            if(testSynth.notNil) {
                testSynth.set(\gate, 0);
            };
        };
        
        win.front;
    }.defer;
};
)
