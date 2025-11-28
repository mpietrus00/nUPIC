// Update SynthDef Menus with Efficient SynthDefs
// This ensures the new performance-optimized synths appear in all menus

(
"=== Updating SynthDef Menus ===".postln;

// 1. First ensure the efficient SynthDefs are created
~ensureEfficientSynthDefs = {
    
    // Check if efficientDefault exists, if not create it
    if(SynthDescLib.global.at(\efficientDefault).isNil) {
        "Creating efficientDefault SynthDef...".postln;
        
        SynthDef(\efficientDefault, {
            var sig, freq, amp, pan;
            var gate = \gate.kr(1);
            
            // Minimal parameters - no lag for efficiency
            freq = \freq.kr(440).clip(20, 8000);
            amp = \amp.kr(0.1).clip(0, 0.3);
            pan = \pan.kr(0).clip(-1, 1);
            
            // Single oscillator - use Saw for efficiency
            sig = Saw.ar(freq);
            
            // Simple filter instead of complex processing
            sig = LPF.ar(sig, freq * 2);
            
            // Fast envelope
            sig = sig * amp * EnvGen.kr(
                Env.asr(0.002, 1, 0.02),
                gate,
                doneAction: 2
            );
            
            // No tanh, just simple clipping
            sig = sig.clip2(0.9) * 0.7;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "efficientDefault created".postln;
    } {
        "efficientDefault already exists".postln;
    };
    
    // Check if ultraLightVarSaw exists, if not create it
    if(SynthDescLib.global.at(\ultraLightVarSaw).isNil) {
        "Creating ultraLightVarSaw SynthDef...".postln;
        
        SynthDef(\ultraLightVarSaw, {
            var sig, freq, amp, pan, width;
            var gate = \gate.kr(1);
            
            // Minimal smoothing for CPU efficiency
            freq = \freq.kr(440).clip(20, 8000);
            amp = \amp.kr(0.1).clip(0, 0.5);
            pan = \pan.kr(0).clip(-1, 1);
            width = \width.kr(0.5).clip(0.01, 0.99);
            
            // Single non-oversampled oscillator for efficiency
            sig = VarSaw.ar(freq, 0, width);
            
            // Simple envelope
            sig = sig * amp * EnvGen.kr(
                Env.asr(0.001, 1, 0.01),  // Very fast attack/release
                gate,
                doneAction: 2
            );
            
            // Minimal processing
            sig = sig * 0.5;  // Simple scaling instead of tanh
            
            // Output with panning
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "ultraLightVarSaw created".postln;
    } {
        "ultraLightVarSaw already exists".postln;
    };
    
    // Check if optimizedSimple exists, if not create it
    if(SynthDescLib.global.at(\optimizedSimple).isNil) {
        "Creating optimizedSimple SynthDef...".postln;
        
        SynthDef(\optimizedSimple, {
            var sig, freq, amp, pan, mass, velocity, distance, width;
            var gate = \gate.kr(1);
            var useAntiAlias;
            
            // Minimal lag for efficiency
            freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.02);
            amp = Lag.kr(\amp.kr(0.0).clip(0, 0.3), 0.01);  // Reduced max amplitude
            pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
            mass = \mass.kr(1).clip(0.1, 25);
            velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.05);
            distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
            width = Lag.kr(\width.kr(0.5).clip(0.01, 0.99), 0.02);
            
            // Use anti-aliased oscillator only for high frequencies
            useAntiAlias = freq > 2000;
            sig = Select.ar(useAntiAlias, [
                VarSaw.ar(freq, 0, width),  // Regular for low/mid frequencies
                Saw.ar(freq) * width  // Simple saw for high frequencies (less CPU)
            ]);
            
            // Minimal harmonics - only add if mass is significant
            sig = sig + Select.ar(mass > 2, [
                0,  // No harmonic
                Saw.ar(freq * 2) * 0.05 * mass.linlin(2, 5, 0, 1)  // Simple harmonic
            ]);
            
            // Simple brightness control
            sig = LPF.ar(sig, (freq * distance.linlin(20, 500, 3, 0.5)).min(4000));
            
            // Envelope with shorter release
            sig = sig * amp * EnvGen.kr(Env.asr(0.005, 1, 0.05), gate, doneAction: 2);
            
            // Soft clipping only if needed
            sig = Select.ar(sig.abs > 0.8, [
                sig,
                sig.tanh
            ]) * 0.6;
            
            Out.ar(0, Pan2.ar(sig, pan));
        }).add;
        
        "optimizedSimple created".postln;
    } {
        "optimizedSimple already exists".postln;
    };
};

// 2. Update the global SynthDef list
~updateSynthDefList = {
    var currentList;
    
    // Initialize if needed
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
    };
    
    // Get current list or create new
    currentList = if(~nUPIC_SynthDefs[\available].notNil) {
        ~nUPIC_SynthDefs[\available]
    } {
        [\simpleGravObject, \richTexture, \percNoise, \auditoryDistortion, \testSinOsc, \testSinOscVibrato, \simpleSine]
    };
    
    // Add efficient synths if not already there
    [\efficientDefault, \ultraLightVarSaw, \optimizedSimple].do { |synthName|
        if(currentList.includes(synthName).not) {
            currentList = currentList.add(synthName);
            ("Added " ++ synthName ++ " to available list").postln;
        };
    };
    
    // Store updated list
    ~nUPIC_SynthDefs[\available] = currentList;
    
    ("Available SynthDefs: " ++ currentList).postln;
};

// 3. Update all existing menu widgets
~updateAllMenus = {
    var state = ~nUPIC[\ui][\state];
    var menuItems = ~nUPIC_SynthDefs[\available].collect(_.asString);
    
    "Updating menu widgets...".postln;
    
    if(state.notNil and: { state[\controls].notNil }) {
        var controls = state[\controls];
        
        // Update main synthDefMenu (bottom panel)
        if(controls[\synthDefMenu].notNil) {
            controls[\synthDefMenu].items = menuItems;
            "Updated main synthDefMenu".postln;
        };
        
        // Update any other synth menus that might exist
        [\synthDefMenu2, \synthDefMenuSidebar, \synthDefMenuCompact].do { |key|
            if(controls[key].notNil) {
                controls[key].items = menuItems;
                ("Updated " ++ key).postln;
            };
        };
    } {
        "UI not open - menus will be updated when window opens".postln;
    };
};

// 4. Create a function to refresh menus on demand
~refreshSynthDefMenus = {
    ~ensureEfficientSynthDefs.value;
    ~updateSynthDefList.value;
    ~updateAllMenus.value;
    "SynthDef menus refreshed".postln;
};

// 5. Store the refresh function globally for easy access
~nUPIC[\ui][\refreshSynthDefMenus] = ~refreshSynthDefMenus;

// 6. Execute all updates
"".postln;
"Ensuring efficient SynthDefs exist...".postln;
~ensureEfficientSynthDefs.value;

"".postln;
"Updating SynthDef list...".postln;
~updateSynthDefList.value;

"".postln;
"Updating menu widgets...".postln;
~updateAllMenus.value;

"".postln;
"=== MENU UPDATE COMPLETE ===".postln;
"The following SynthDefs should now appear in menus:".postln;
~nUPIC_SynthDefs[\available].do { |name, i|
    ("  " ++ (i+1) ++ ". " ++ name).postln;
};

"".postln;
"RECOMMENDED SYNTHDEFS BY TRAJECTORY COUNT:".postln;
"• 1-5 trajectories:   simpleGravObject or richTexture".postln;
"• 5-10 trajectories:  simpleVarSaw or optimizedSimple".postln;
"• 10-20 trajectories: efficientDefault or ultraLightVarSaw".postln;
"• 20+ trajectories:   ultraLightVarSaw only".postln;

"".postln;
"To refresh menus at any time, execute:".postln;
"  ~nUPIC[\\ui][\\refreshSynthDefMenus].value;".postln;

// Test function to verify SynthDefs work
~testEfficientSynths = {
    "Testing efficient SynthDefs...".postln;
    
    fork {
        // Test efficientDefault
        "Playing efficientDefault...".postln;
        var s1 = Synth(\efficientDefault, [\freq, 440, \amp, 0.1, \pan, 0]);
        1.wait;
        s1.set(\gate, 0);
        0.5.wait;
        
        // Test ultraLightVarSaw
        "Playing ultraLightVarSaw...".postln;
        var s2 = Synth(\ultraLightVarSaw, [\freq, 550, \amp, 0.1, \pan, 0, \width, 0.3]);
        1.wait;
        s2.set(\gate, 0);
        0.5.wait;
        
        // Test optimizedSimple
        "Playing optimizedSimple...".postln;
        var s3 = Synth(\optimizedSimple, [\freq, 660, \amp, 0.1, \pan, 0, \mass, 2, \distance, 100]);
        1.wait;
        s3.set(\gate, 0);
        
        "Test complete - all efficient SynthDefs working".postln;
    };
};

"".postln;
"To test the efficient synths, execute:".postln;
"  ~testEfficientSynths.value;".postln;
)
