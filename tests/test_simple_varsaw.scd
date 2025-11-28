// Test script for the new simpleVarSaw SynthDef
// This verifies that the synth is loaded and appears in menus

(
"=== Testing simpleVarSaw SynthDef ===".postln;
"".postln;

// 1. Check if SynthDef is loaded
"1. Checking if simpleVarSaw is in the available list...".postln;
if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
    var available = ~nUPIC_SynthDefs[\available];
    if(available.includes(\simpleVarSaw)) {
        "✓ simpleVarSaw found in available SynthDefs list".postln;
        ("Available SynthDefs: " ++ available).postln;
    } {
        "✗ simpleVarSaw NOT found in available list".postln;
        ("Available SynthDefs: " ++ available).postln;
        "Reloading SynthDefs...".postln;
        (~nUPIC_basePath +/+ "Audio/SynthDefs.scd").load;
    };
} {
    "✗ SynthDef list not initialized".postln;
    "Loading SynthDefs...".postln;
    (~nUPIC_basePath +/+ "Audio/SynthDefs.scd").load;
};

"".postln;

// 2. Test the synth directly
"2. Testing simpleVarSaw synth directly...".postln;
~testSimpleVarSaw = {
    var synth;
    
    "Creating test synth...".postln;
    synth = Synth(\simpleVarSaw, [
        \freq, 440,
        \amp, 0.1,
        \pan, 0,
        \width, 0.5
    ]);
    
    if(synth.notNil) {
        "✓ Synth created successfully".postln;
        "Playing A440 for 2 seconds...".postln;
        
        // Test parameter changes
        fork {
            0.5.wait;
            "Changing frequency to 880Hz...".postln;
            synth.set(\freq, 880);
            
            0.5.wait;
            "Changing width to 0.1 (narrow pulse)...".postln;
            synth.set(\width, 0.1);
            
            0.5.wait;
            "Changing width to 0.9 (wide pulse)...".postln;
            synth.set(\width, 0.9);
            
            0.5.wait;
            "Stopping synth...".postln;
            synth.set(\gate, 0);
            
            1.wait;
            "Test complete".postln;
        };
    } {
        "✗ Failed to create synth".postln;
    };
};

"".postln;

// 3. Check UI menus
"3. Checking UI menus...".postln;
if(~nUPIC[\ui][\state].notNil and: { ~nUPIC[\ui][\state][\controls].notNil }) {
    var controls = ~nUPIC[\ui][\state][\controls];
    
    // Check synthDefMenu in main controls
    if(controls[\synthDefMenu].notNil) {
        var items = controls[\synthDefMenu].items;
        "Main synthDefMenu items: ".post; items.postln;
        if(items.includesEqual("simpleVarSaw")) {
            "✓ simpleVarSaw appears in main menu".postln;
        } {
            "✗ simpleVarSaw NOT in main menu - updating...".postln;
            // Update the menu
            controls[\synthDefMenu].items = ~nUPIC_SynthDefs[\available].collect(_.asString);
        };
    } {
        "Main synthDefMenu not found (UI might not be open)".postln;
    };
} {
    "UI not initialized - open the main window to see menus".postln;
};

"".postln;

// 4. Instructions
"=== INSTRUCTIONS ===".postln;
"To test the simpleVarSaw synth:".postln;
"1. Execute: ~testSimpleVarSaw.value;".postln;
"   This will play a test tone with parameter changes".postln;
"".postln;
"2. In the UI:".postln;
"   - Draw a trajectory".postln;
"   - Press G to enter select mode".postln;
"   - Click on the trajectory to select it".postln;
"   - Choose 'simpleVarSaw' from the SynthDef menu at the bottom".postln;
"   - Press SPACE to play - you'll hear the simple VarSaw sound".postln;
"".postln;
"The simpleVarSaw is a minimal synth with:".postln;
"• Single VarSawOS oscillator (oversampled for quality)".postln;
"• Basic frequency, amplitude, pan, and width controls".postln;
"• No gravity/physics parameters".postln;
"• Clean, simple sound".postln;
)
