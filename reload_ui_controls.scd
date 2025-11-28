// Reload UI Controls to show all SynthDefs in menus
(
"Reloading UI Controls with updated SynthDef menus...".postln;

// First ensure SynthDefs are loaded
if(~nUPIC_SynthDefs.isNil or: { ~nUPIC_SynthDefs[\available].isNil }) {
    "Loading SynthDefs first...".postln;
    (~nUPIC_basePath +/+ "Audio/SynthDefs.scd").load;
};

// Wait a bit for SynthDefs to load
fork {
    0.5.wait;
    
    // Reload the UI Controls module
    {
        "Loading updated UI Controls...".postln;
        (~nUPIC_basePath +/+ "UI/Controls.scd").load;
        "UI Controls reloaded".postln;
    }.defer;
    
    0.5.wait;
    
    // Display available SynthDefs
    {
        "\nAvailable SynthDefs (all should appear in menus):".postln;
        if(~nUPIC_SynthDefs.notNil and: { ~nUPIC_SynthDefs[\available].notNil }) {
            ~nUPIC_SynthDefs[\available].do { |name, i|
                var displayName = case
                    { name == \simpleGravObject } { "GravObject" }
                    { name == \simpleGravObj2 } { "GravObj2" }
                    { name == \richTexture } { "RichTexture" }
                    { name == \percNoise } { "PercNoise" }
                    { name == \auditoryDistortion } { "Distortion" }
                    { name == \testSinOsc } { "TestSine" }
                    { name == \testSinOscVibrato } { "TestVibrato" }
                    { name == \simpleSine } { "SimpleSine" }
                    { name == \simpleVarSaw } { "SimpleVarSaw" }
                    { name == \efficientDefault } { "Efficient" }
                    { name == \ultraLightVarSaw } { "UltraLight" }
                    { name == \optimizedSimple } { "Optimized" }
                    { name.asString };
                ("  " ++ (i+1) ++ ". " ++ name ++ " (" ++ displayName ++ ")").postln;
            };
            ("\nTotal: " ++ ~nUPIC_SynthDefs[\available].size ++ " SynthDefs available").postln;
        } {
            "WARNING: SynthDefs not loaded properly".postln;
        };
        
        "\n✓ UI Controls reloaded!".postln;
        "Close and reopen the nUPIC window to see all SynthDefs in the menus.".postln;
        "Both the sidebar menu and bottom panel menu should now show all 12 SynthDefs.".postln;
    }.defer;
};
)
