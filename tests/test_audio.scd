// Test the quick audio example
// This creates a simple synth using the \simpleGravObject SynthDef
// It will play a 440 Hz tone at 0.1 amplitude for 1 second

(
var s = Synth(\simpleGravObject, [\freq, 440, \amp, 0.1, \gate, 1, \numSynths, 1]);
fork { 1.wait; s.set(\gate, 0); };
"Test completed: played 440 Hz tone for 1 second".postln;
)
