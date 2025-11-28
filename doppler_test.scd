// Doppler Effect Test for nUPIC System
// This file demonstrates how to enable and test the Doppler effect

(
"=== DOPPLER EFFECT TEST ===".postln;

// Load the nUPIC system
"/Users/marcinpietruszewski/ParPhy_Son/HEPData-ins2666805-v1/nUPIC/nUPIC.scd".loadPaths;

// Wait for initialization
2.wait;

// Enable Doppler effect with moderate sensitivity
"Enabling Doppler effect...".postln;
~nUPIC[\ui][\enableDoppler].value(1.0);

"".postln;
"=== DOPPLER EFFECT ENABLED ===".postln;
"".postln;
"Instructions:".postln;
"1. Draw some trajectories that move in circular or curved patterns".postln;
"2. Make sure trajectories pass near the center of the screen".postln;
"3. Press SPACE to play and listen for pitch shifts".postln;
"4. Trajectories moving toward center = higher pitch".postln;
"5. Trajectories moving away from center = lower pitch".postln;
"".postln;
"Available Doppler controls:".postln;
"~nUPIC[\\ui][\\enableDoppler].value(1.0);     // Enable with normal sensitivity".postln;
"~nUPIC[\\ui][\\enableDoppler].value(2.0);     // Enable with strong sensitivity".postln;
"~nUPIC[\\ui][\\disableDoppler].value;          // Disable Doppler effect".postln;
"~nUPIC[\\ui][\\getDopplerSensitivity].value;  // Check current setting".postln;
"".postln;
"Current Doppler sensitivity: " ++ ~nUPIC[\ui][\getDopplerSensitivity].value.postln;
"".postln;
"=== TEST READY ===".postln;
"Draw some curved trajectories and press SPACE to hear the Doppler effect!".postln;
)
