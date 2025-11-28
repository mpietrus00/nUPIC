// Use only the working SynthDefs
// This removes additiveOS from the list to prevent errors

(
"Configuring nUPIC to use only working SynthDefs...".postln;
"".postln;

// List of SynthDefs that are confirmed working
~workingSynthDefs = [
    \pulsarTrain,
    \grainBank,
    \fmCascade,
    \simpleOS,
    \simpleGravObject,
    \testOrbit
];

// Update the registry
~nUPIC_SynthDefs = IdentityDictionary.new;
~nUPIC_SynthDefs[\available] = ~workingSynthDefs;
~nUPIC_SynthDefs[\default] = \pulsarTrain;  // Or use \simpleGravObject for simpler sound

"Working SynthDefs configured:".postln;
~workingSynthDefs.do { |name|
    ("  • " ++ name).postln;
};

"".postln;
("Default: " ++ ~nUPIC_SynthDefs[\default]).postln;
"".postln;

"You can now use nUPIC without additiveOS errors.".postln;
"Run: \"nUPIC_Main.scd\".load".postln;
)
