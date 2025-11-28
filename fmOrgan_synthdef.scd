// FM Organ SynthDef - Based on fmCascade but with organ characteristics
// Features drawbar-like harmonics, steady tone, and optional vibrato/chorus

(
"Loading FM Organ SynthDef...".postln;
"".postln;

s.waitForBoot {
    
    // FM Organ synthesis - Hammond-inspired using FM
    SynthDef(\fmOrgan, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            // Organ-specific parameters (drawbar positions 0-1)
            draw16 = 0.8,    // 16' sub-fundamental
            draw8 = 1.0,     // 8' fundamental  
            draw513 = 0.7,   // 5 1/3' fifth
            draw4 = 0.6,     // 4' octave
            draw223 = 0.4,   // 2 2/3' twelfth
            draw2 = 0.3,     // 2' super octave
            draw135 = 0.2,   // 1 3/5' seventeenth
            draw113 = 0.2,   // 1 1/3' nineteenth
            draw1 = 0.1,     // 1' twenty-second
            vibrato = 0.3,   // Vibrato depth (0-1)
            rotary = 0.5;    // Rotary speaker effect amount
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var drawbarSignals, carrier, modulator;
        var massNorm = (mass / 10).clip(0, 1);
        var vibratoLFO, rotaryLFO;
        
        // Doppler calculation
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Organ envelope - quick attack, full sustain, medium release
        env = EnvGen.kr(
            Env.adsr(
                0.002,  // Very quick attack (organ key click)
                0.01,   // Minimal decay
                1.0,    // Full sustain
                0.3     // Medium release
            ),
            gate,
            doneAction: 2
        );
        
        // Vibrato/Chorus LFO (classic organ vibrato)
        vibratoLFO = SinOsc.kr(6.5 + (velocity * 0.5)) * vibrato * 0.01;
        
        // Rotary speaker simulation (slow/fast)
        rotaryLFO = SinOsc.kr(
            Select.kr(velocity > 10, [0.7, 5.5])  // Slow or fast rotation
        ) * rotary;
        
        // Generate drawbar harmonics using FM synthesis
        drawbarSignals = [
            // 16' - Sub-fundamental (one octave down)
            SinOsc.ar(finalFreq * 0.5 * (1 + vibratoLFO)) * draw16,
            
            // 8' - Fundamental
            SinOsc.ar(finalFreq * (1 + vibratoLFO)) * draw8,
            
            // 5 1/3' - Fifth above fundamental (3rd harmonic)
            SinOsc.ar(finalFreq * 1.5 * (1 + vibratoLFO)) * draw513,
            
            // 4' - Octave (2nd harmonic)
            SinOsc.ar(finalFreq * 2 * (1 + vibratoLFO)) * draw4,
            
            // 2 2/3' - Octave + fifth (3rd harmonic of octave)
            SinOsc.ar(finalFreq * 3 * (1 + vibratoLFO)) * draw223,
            
            // 2' - Two octaves (4th harmonic)
            SinOsc.ar(finalFreq * 4 * (1 + vibratoLFO)) * draw2,
            
            // 1 3/5' - Two octaves + major third (5th harmonic)
            SinOsc.ar(finalFreq * 5 * (1 + vibratoLFO)) * draw135,
            
            // 1 1/3' - Two octaves + fifth (6th harmonic)
            SinOsc.ar(finalFreq * 6 * (1 + vibratoLFO)) * draw113,
            
            // 1' - Three octaves (8th harmonic)
            SinOsc.ar(finalFreq * 8 * (1 + vibratoLFO)) * draw1
        ];
        
        // Mix drawbar signals
        sig = Mix.ar(drawbarSignals);
        
        // Add some FM modulation for extra harmonics (subtle)
        modulator = SinOsc.ar(finalFreq * 2.01, 0, finalFreq * 0.5 * massNorm);
        carrier = SinOsc.ar(finalFreq + modulator);
        sig = sig + (carrier * 0.2);
        
        // Add "key click" - a brief percussive attack
        sig = sig + (
            WhiteNoise.ar(0.01) * 
            EnvGen.kr(Env.perc(0.0001, 0.005), gate)
        );
        
        // Normalize and apply mass parameter to brightness
        sig = sig * 0.3;
        sig = LPF.ar(sig, 4000 + (mass * 2000));  // Mass controls brightness
        
        // Apply rotary speaker effect (simple amplitude modulation + panning)
        sig = sig * (1 + (rotaryLFO * 0.3));
        
        // Width parameter controls stereo spread
        sig = Pan2.ar(sig, pan + (rotaryLFO * width * 0.5));
        
        // Distance effects
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Final amplitude scaling
        sig = sig * amp * env * distAmp * (0.7 / numSynths.sqrt.max(1));
        
        // Soft saturation (tube-like)
        sig = (sig * 1.5).tanh * 0.8;
        
        Out.ar(0, sig);
    }).add;
    
    "✓ fmOrgan loaded".postln;
    
    // Also create a simpler organ preset
    SynthDef(\simpleOrgan, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var vibrato;
        
        // Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Organ envelope
        env = EnvGen.kr(
            Env.adsr(0.002, 0.01, 1.0, 0.3),
            gate,
            doneAction: 2
        );
        
        // Simple vibrato
        vibrato = SinOsc.kr(5.5) * 0.005 * velocity.linlin(0, 20, 0, 1);
        
        // Classic organ sound with just a few drawbars
        sig = Mix.ar([
            SinOsc.ar(finalFreq * 0.5 * (1 + vibrato)) * 0.3,   // Sub
            SinOsc.ar(finalFreq * (1 + vibrato)) * 1.0,         // Fundamental
            SinOsc.ar(finalFreq * 2 * (1 + vibrato)) * 0.5,     // Octave
            SinOsc.ar(finalFreq * 3 * (1 + vibrato)) * 0.3,     // Twelfth
            SinOsc.ar(finalFreq * 4 * (1 + vibrato)) * 0.2,     // 2nd octave
            SinOsc.ar(finalFreq * 6 * (1 + vibrato)) * 0.1      // 2nd fifth
        ]);
        
        // Normalize
        sig = sig * 0.3;
        
        // Mass controls tone (filter)
        sig = LPF.ar(sig, 2000 + (mass * 3000));
        
        // Distance
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Output
        sig = sig * amp * env * distAmp * (0.8 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ simpleOrgan loaded".postln;
    
    // Wait for compilation
    s.sync;
    
    "".postln;
    "Testing organ synthdefs...".postln;
    
    fork {
        // Test fmOrgan
        var synth = Synth(\fmOrgan, [
            \freq, 220,  // A below middle C
            \amp, 0.1,
            \gate, 1,
            // Classic jazz organ settings
            \draw16, 0.8,
            \draw8, 1.0,
            \draw4, 0.6,
            \draw2, 0.3,
            \vibrato, 0.4,
            \rotary, 0.3
        ]);
        
        "Playing fmOrgan (A220, jazz preset)...".postln;
        1.wait;
        
        synth.set(\freq, 330);  // E
        "Changed to E330...".postln;
        0.5.wait;
        
        synth.set(\freq, 440);  // A
        "Changed to A440...".postln;
        0.5.wait;
        
        synth.set(\gate, 0);
        "Released.".postln;
        
        1.wait;
        
        // Test simpleOrgan
        synth = Synth(\simpleOrgan, [
            \freq, 261.63,  // Middle C
            \amp, 0.1,
            \gate, 1,
            \mass, 5,
            \velocity, 10
        ]);
        
        "Playing simpleOrgan (Middle C)...".postln;
        1.wait;
        
        synth.set(\gate, 0);
        "Released.".postln;
        
        0.5.wait;
        
        "".postln;
        "=== Organ SynthDefs Ready ===".postln;
        "".postln;
        "Available organ synthdefs:".postln;
        "  • fmOrgan    - Full drawbar organ with rotary effect".postln;
        "  • simpleOrgan - Simple organ sound".postln;
        "".postln;
        
        // Update registry if it exists
        if(~nUPIC_SynthDefs.notNil) {
            ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\fmOrgan);
            ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\simpleOrgan);
            "Added to nUPIC synthdef registry.".postln;
        };
        
        "".postln;
        "Try this for a classic organ chord:".postln;
        "(".postln;
        "var chord = [261.63, 329.63, 392.00]; // C major".postln;
        "chord.do { |freq|".postln;
        "    Synth(\\fmOrgan, [\\freq, freq, \\amp, 0.05, \\draw8, 1, \\draw4, 0.5]);".postln;
        "};".postln;
        ")".postln;
    };
};
)
