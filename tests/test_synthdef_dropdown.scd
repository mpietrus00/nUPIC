// Test that Xenakis and Brün synthdefs appear in dropdown menu

(
s.waitForBoot {
    // Load the SynthDefs
    ("Audio/SynthDefs.scd").loadRelative;
    
    s.sync;
    
    "Testing SynthDef dropdown menu...".postln;
    "=================================".postln;
    "".postln;
    
    // Check if synthdefs are loaded
    if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
        "Available synthdefs in dropdown menu:".postln;
        "".postln;
        
        ~nUPIC_SynthDefs[\available].do { |synthName, i|
            var description = case
                { synthName == \simpleGravObject } { "Gravitational object synth" }
                { synthName == \simpleGravObj2 } { "Gravitational object with Doppler" }
                { synthName == \richTexture } { "Rich layered texture" }
                { synthName == \percNoise } { "Percussive noise" }
                { synthName == \auditoryDistortion } { "Auditory distortion (QDT)" }
                { synthName == \testSinOsc } { "Test sine oscillator" }
                { synthName == \testSinOscVibrato } { "Test sine with vibrato" }
                { synthName == \simpleSine } { "Simple sine wave" }
                { synthName == \simpleVarSaw } { "Simple variable saw" }
                { synthName == \efficientDefault } { "Efficient default synth" }
                { synthName == \ultraLightVarSaw } { "Ultra light VarSaw" }
                { synthName == \optimizedSimple } { "Optimized simple synth" }
                // Xenakis inspired
                { synthName == \stochasticXenakis } { "XENAKIS: GENDYN-inspired stochastic" }
                { synthName == \sieveHarmonics } { "XENAKIS: Sieve theory harmonics" }
                { synthName == \achorripsis } { "XENAKIS: Stochastic distributions" }
                { synthName == \metastaseis } { "XENAKIS: Mass glissandi" }
                // Brün inspired
                { synthName == \sawdustBrun } { "BRÜN: SAWDUST micro-temporal" }
                { synthName == \infraudibles } { "BRÜN: Inaudible components" }
                { "Unknown synthdef" };
            
            ("  " ++ (i+1).asString.padLeft(2) ++ ". \\" ++ synthName.asString.padRight(20) ++ " - " ++ description).postln;
        };
        
        "".postln;
        ("Total synthdefs available: " ++ ~nUPIC_SynthDefs[\available].size).postln;
        "".postln;
        
        // Check for Xenakis/Brün synthdefs specifically
        var xenakisBrunSynths = [\stochasticXenakis, \sieveHarmonics, \achorripsis, 
                                  \metastaseis, \sawdustBrun, \infraudibles];
        var foundXB = xenakisBrunSynths.select { |synth|
            ~nUPIC_SynthDefs[\available].includes(synth)
        };
        
        if(foundXB.size > 0) {
            "✓ Xenakis and Brün synthdefs found in menu:".postln;
            foundXB.do { |synth| ("    - \\" ++ synth).postln };
        } {
            "✗ WARNING: Xenakis and Brün synthdefs NOT found in menu!".postln;
            "  Check that XenakisBrun_SynthDefs.scd is in the Audio folder".postln;
        };
        
    } {
        "ERROR: ~nUPIC_SynthDefs not loaded properly".postln;
    };
    
    "".postln;
    "Creating test window with synthdef dropdown...".postln;
    
    // Create a test window with the dropdown menu
    {
        var win, menu, label, playButton, testSynth;
        
        win = Window("SynthDef Dropdown Test", Rect(100, 100, 400, 150));
        
        label = StaticText(win, Rect(10, 10, 380, 30))
            .string_("Select a SynthDef from the dropdown menu:")
            .font_(Font("Arial", 12));
        
        menu = PopUpMenu(win, Rect(10, 50, 250, 25))
            .items_(if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
                ~nUPIC_SynthDefs[\available].collect(_.asString)
            } { ["No synthdefs available"] })
            .value_(0)
            .action_({ |m|
                var selected = ~nUPIC_SynthDefs[\available][m.value];
                ("Selected: \\" ++ selected).postln;
            });
        
        playButton = Button(win, Rect(270, 50, 120, 25))
            .states_([["Test Selected", Color.black, Color.green],
                      ["Stop", Color.white, Color.red]])
            .action_({ |btn|
                if(btn.value == 1) {
                    var synthName = ~nUPIC_SynthDefs[\available][menu.value];
                    ("Testing synthdef: \\" ++ synthName).postln;
                    testSynth = Synth(synthName, [
                        \freq, 440,
                        \amp, 0.2,
                        \pan, 0,
                        \mass, 2,
                        \velocity, 5,
                        \distance, 100,
                        \width, 0.5
                    ]);
                } {
                    if(testSynth.notNil) {
                        testSynth.set(\gate, 0);
                        testSynth = nil;
                    };
                };
            });
        
        StaticText(win, Rect(10, 90, 380, 50))
            .string_("The dropdown should include:\n• Original synthdefs (simpleGravObject, etc.)\n• Xenakis synthdefs (stochasticXenakis, metastaseis, etc.)\n• Brün synthdefs (sawdustBrun, infraudibles)")
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
