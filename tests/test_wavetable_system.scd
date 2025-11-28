// Test script to ensure wavetable system loads correctly
// Run this after START_NUPIC.scd

(
"Testing wavetable system...".postln;

// Check if buffer exists
if(~nUPIC_wavetableBuffer.notNil) {
    ("✓ Wavetable buffer exists: bufnum = " ++ ~nUPIC_wavetableBuffer.bufnum).postln;
} {
    "✗ Wavetable buffer not found - creating one...".postln;
    ~nUPIC_wavetableBuffer = Buffer.alloc(s, 512, 1);
    0.5.wait;
};

// Generate a test wavetable
if(~nUPIC_generateRandomWavetable.notNil) {
    ~nUPIC_generateRandomWavetable.value;
    "✓ Random wavetable generated".postln;
} {
    "✗ Wavetable generator not found".postln;
};

// Test the SynthDef
fork {
    var synth;
    
    "Testing upicWavetable SynthDef...".postln;
    
    // Check if it exists
    if(SynthDescLib.global.synthDescs[\upicWavetable].notNil) {
        "✓ upicWavetable SynthDef found in library".postln;
        
        // Try to create a synth
        try {
            synth = Synth(\upicWavetable, [
                \freq, 440,
                \amp, 0.2,
                \gate, 1,
                \bufnum, ~nUPIC_wavetableBuffer.bufnum,
                \numSynths, 1
            ]);
            
            "✓ Synth created successfully - playing 440Hz".postln;
            1.wait;
            
            synth.set(\freq, 550);
            "  Changed to 550Hz".postln;
            0.5.wait;
            
            synth.set(\freq, 330);
            "  Changed to 330Hz".postln;
            0.5.wait;
            
            synth.set(\gate, 0);
            "✓ Test complete - synth released".postln;
            
        } { |error|
            ("✗ Error creating synth: " ++ error.errorString).postln;
        };
    } {
        "✗ upicWavetable SynthDef not found in library".postln;
        "  Attempting to load it...".postln;
        
        // Try to load it
        (~nUPIC_basePath +/+ "Audio/upicWavetable.scd").load;
        1.wait;
        
        if(SynthDescLib.global.synthDescs[\upicWavetable].notNil) {
            "✓ upicWavetable loaded successfully".postln;
        } {
            "✗ Failed to load upicWavetable".postln;
        };
    };
};

// Test opening the editor
"".postln;
"To open the wavetable editor, run:".postln;
"  ~nUPIC[\wavetableEditor][\open].value".postln;
"".postln;
"Or click the 'Edit Wavetable' button in the main UI".postln;
)