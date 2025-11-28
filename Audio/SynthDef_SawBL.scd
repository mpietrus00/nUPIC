// SawBL-based SynthDef for nUPIC
// Band-limited sawtooth synth with rich harmonics and smooth sound

(
// Add SawBL Synth to nUPIC SynthDef collection
SynthDef(\sawBLSynth, {
    arg freq = 440, amp = 0.1, pan = 0, gate = 1,
        mass = 1, velocity = 0, distance = 100, width = 0.5,
        radialVel = 0, dopplerSens = 0, numSynths = 1,
        detune = 0.01, filterCutoff = 4, resonance = 0.5;
    
    var sig, env, dopplerShift, finalFreq, distAmp;
    var saw1, saw2, saw3, subOsc, filter;
    var massNorm = (mass / 10).clip(0, 1);
    var velNorm = velocity.clip(0, 1000) / 1000;
    
    // Calculate Doppler-shifted frequency
    dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
    finalFreq = freq * dopplerShift.clip(0.5, 2.0);
    
    // Multi-stage envelope with velocity sensitivity
    env = EnvGen.kr(
        Env.adsr(
            0.002 + (massNorm * 0.008),  // Slower attack for heavier objects
            0.05,
            0.7 - (velNorm * 0.2),        // Lower sustain for faster objects
            0.3 + (massNorm * 0.7)        // Longer release for heavier objects
        ),
        gate,
        doneAction: 2
    );
    
    // Main sawtooth oscillators with detuning for richness
    // Using SawOS (oversampled) for high quality
    saw1 = SawOS.ar(finalFreq, 0, 1, 4);
    saw2 = SawOS.ar(finalFreq * (1 + detune), 0, 1, 4);
    saw3 = SawOS.ar(finalFreq * (1 - detune), 0, 1, 4);
    
    // Sub oscillator for bass presence (one octave down)
    subOsc = SawOS.ar(finalFreq * 0.5, 0, 0.3 * massNorm, 4);
    
    // Mix oscillators with slight phase differences
    sig = (saw1 + saw2 + saw3) / 3;
    sig = sig + subOsc;
    
    // Add harmonics based on mass
    sig = sig + (SawOS.ar(finalFreq * 2, 0, 0.15 * massNorm, 4));
    sig = sig + (SawOS.ar(finalFreq * 3, 0, 0.08 * massNorm, 4));
    
    // Dynamic filter based on velocity and distance
    filter = RLPF.ar(
        sig,
        (finalFreq * filterCutoff * (1 + velNorm)).min(15000) * (distAmp = (100 / distance.max(10)).sqrt.clip(0, 2)),
        resonance + (massNorm * 0.3)
    );
    
    sig = SelectX.ar(width, [sig, filter]);
    
    // Waveshaping for character
    sig = (sig * (1 + massNorm)).tanh;
    
    // Apply envelopes and amplitude scaling
    sig = sig * amp * env * distAmp * (0.6 / numSynths.sqrt.max(1));
    
    // Soft limiting
    sig = sig.softclip * 0.9;
    
    // Output with panning
    Out.ar(0, Pan2.ar(sig, pan));
}).add;

// Add to the synth list if it exists
if(~nUPIC_SynthDefs.notNil) {
    ~nUPIC_SynthDefs.put(\sawBLSynth, \sawBLSynth);
};
);