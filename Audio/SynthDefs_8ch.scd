// nUPIC 8-Channel Spatialized SynthDefs
// Automated spatialization using random oscillators for immersive sound field
// Each trajectory can move through the 8-channel space automatically

(
// Initialize 8-channel SynthDef collection
~nUPIC_8ch_SynthDefs = IdentityDictionary.new;

// Load 8-channel spatialized SynthDefs
~loadnUPIC8chSynthDefs = {
    
    // 8-channel UPIC Wavetable with automated spatialization
    SynthDef(\upicWavetable8ch, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            // Spatialization parameters
            spatialSpeed = 0.5,     // Speed of spatial movement (Hz)
            spatialDepth = 1.0,     // Depth of spatialization (0-1)
            spatialPattern = 0,     // 0=random, 1=circular, 2=figure-8, 3=spiral
            spatialPhase = 0;       // Starting phase for spatial movement
        
        var sig, env, phase;
        var modulator, filter;
        var effectiveFreq, modFreq, filtCutoff;
        var morphPos, modIndex;
        var spatialPos, panArray, sigArray;
        var randSpeed1, randSpeed2, randSpeed3;
        
        // Use default wavetable if bufnum is 0 or not provided
        if(bufnum == 0) {
            if(~nUPIC_DefaultWaveTable.notNil) {
                bufnum = ~nUPIC_DefaultWaveTable.bufnum;
            };
        };
        
        // Map compatibility parameters to UPIC parameters
        modFreq = velocity.linlin(0, 20, 0.5, 10);
        modIndex = 0.1;
        morphPos = width.clip(0, 1);
        filtCutoff = distance.linexp(20, 500, 8000, 500);
        
        // Envelope
        env = EnvGen.kr(
            Env.adsr(
                0.01 * mass.linlin(1, 10, 1, 2),
                0.05,
                0.8,
                0.2 * mass.linlin(1, 10, 1, 3)
            ),
            gate,
            doneAction: 2
        );
        
        effectiveFreq = freq;
        
        // Phase generation with velocity-based modulation
        modulator = SinOsc.ar(modFreq, 0, modIndex * velocity.linlin(0, 20, 0, 1));
        phase = LFSaw.ar(effectiveFreq * (1 + modulator)).range(0, 1);
        
        // Main oscillator
        sig = OscOS.ar(
            bufnum,
            phase,
            1,
            0,
            2,  // 4x oversampling
            1,
            0
        );
        
        // Add harmonics based on mass
        sig = sig + (SinOsc.ar(effectiveFreq * 2, 0, mass.linlin(1, 10, 0, 0.2)) * 0.3);
        sig = sig + (SinOsc.ar(effectiveFreq * 3, 0, mass.linlin(1, 10, 0, 0.1)) * 0.2);
        
        // Filter
        filter = RLPF.ar(
            sig,
            filtCutoff.clip(20, 20000),
            2
        );
        
        sig = XFade2.ar(sig, filter, distance.linlin(20, 500, -1, 1));
        
        // Apply envelope and amplitude
        sig = sig * env * amp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.95;
        
        // SPATIAL POSITIONING WITH RANDOM OSCILLATORS
        // Create different random oscillator speeds for complex movement
        randSpeed1 = LFNoise1.kr(spatialSpeed * 0.7).range(0.3, 1.5);
        randSpeed2 = LFNoise1.kr(spatialSpeed * 0.5).range(0.5, 2);
        randSpeed3 = LFNoise1.kr(spatialSpeed * 0.3).range(0.2, 1);
        
        // Generate spatial position based on pattern
        spatialPos = Select.kr(spatialPattern, [
            // 0: Random wandering
            LFNoise1.kr(spatialSpeed * randSpeed1, spatialDepth).range(0, 1),
            // 1: Circular motion
            SinOsc.kr(spatialSpeed, spatialPhase).range(0, 1),
            // 2: Figure-8 motion
            SinOsc.kr(spatialSpeed, spatialPhase) * SinOsc.kr(spatialSpeed * 2, spatialPhase + (pi/2)),
            // 3: Spiral motion
            (SinOsc.kr(spatialSpeed * randSpeed2, spatialPhase) * 
             LFSaw.kr(spatialSpeed * 0.1, spatialPhase).range(0.2, 1))
        ]);
        
        // Add pan offset from the original pan parameter
        spatialPos = (spatialPos + pan).wrap(0, 1);
        
        // Create 8-channel panning array using PanAz
        sigArray = PanAz.ar(
            8,              // 8 channels
            sig,            // input signal
            spatialPos * 2, // position (0-2 for full circle)
            1,              // level (keep at 1)
            2.5,            // width (2.5 for good spread)
            0               // orientation
        );
        
        // Output to 8 channels
        Out.ar(0, sigArray);
    }).add;
    
    // Precise 8-channel version for accurate amplitude control
    SynthDef(\upicWavetablePrecise8ch, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            // Spatialization parameters
            spatialSpeed = 0.5,
            spatialDepth = 1.0,
            spatialPattern = 0,
            spatialPhase = 0;
        
        var sig, dopplerShift, finalFreq, distAmp;
        var phase;
        var spatialPos, panArray, sigArray;
        var randSpeed1, randSpeed2;
        
        // Use default wavetable if bufnum is 0 or not provided
        if(bufnum == 0) {
            if(~nUPIC_DefaultWaveTable.notNil) {
                bufnum = ~nUPIC_DefaultWaveTable.bufnum;
            };
        };
        
        // Calculate frequency with optional Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Phase generation
        phase = LFSaw.ar(finalFreq).range(0, 1);
        
        // Main oscillator
        sig = OscOS.ar(
            bufnum,
            phase,
            1,
            0,
            2,  // 4x oversampling
            1.0,
            0
        );
        
        // Add harmonics based on mass
        sig = sig + (SinOsc.ar(finalFreq * 2, 0, mass.linlin(1, 10, 0, 0.3)) * 0.3);
        sig = sig + (SinOsc.ar(finalFreq * 3, 0, mass.linlin(1, 10, 0, 0.1)) * 0.2);
        
        // Distance amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Direct amplitude control with minimal lag
        sig = sig * Lag.kr(amp * distAmp * (1 / numSynths.sqrt.max(1)), 0.001);
        
        // Gate for note off
        sig = sig * EnvGen.kr(Env.cutoff(0.002), gate, doneAction: 2);
        
        // Soft limiting
        sig = sig.clip(-0.9, 0.9);
        
        // SPATIAL POSITIONING
        // Random oscillators for movement
        randSpeed1 = LFNoise1.kr(spatialSpeed * 0.7).range(0.3, 1.5);
        randSpeed2 = LFNoise1.kr(spatialSpeed * 0.5).range(0.5, 2);
        
        // Generate spatial position based on pattern
        spatialPos = Select.kr(spatialPattern, [
            // 0: Random wandering with smooth interpolation
            LFNoise2.kr(spatialSpeed * randSpeed1, spatialDepth).range(0, 1),
            // 1: Circular motion
            SinOsc.kr(spatialSpeed, spatialPhase).range(0, 1),
            // 2: Figure-8 motion
            SinOsc.kr(spatialSpeed, spatialPhase) * SinOsc.kr(spatialSpeed * 2, spatialPhase + (pi/2)),
            // 3: Complex random motion
            (LFNoise1.kr(spatialSpeed * randSpeed1) * 
             LFNoise2.kr(spatialSpeed * randSpeed2 * 0.5)).range(0, 1)
        ]);
        
        // Add pan offset
        spatialPos = (spatialPos + pan).wrap(0, 1);
        
        // Create 8-channel panning
        sigArray = PanAz.ar(
            8,              // 8 channels
            sig,            // input signal
            spatialPos * 2, // position
            1,              // level
            2.5,            // width
            0               // orientation
        );
        
        // Output to 8 channels
        Out.ar(0, sigArray);
    }).add;
    
    // Simple 8-channel gravity object with spatialization
    SynthDef(\simpleGravObject8ch, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            spatialSpeed = 0.5,
            spatialDepth = 1.0,
            spatialPattern = 0,
            spatialPhase = 0;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var spatialPos, sigArray;
        
        // Calculate frequency
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Envelope
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );
        
        // Oscillators
        sig = Mix.ar([
            SinOsc.ar(finalFreq) * 0.5,
            SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),
            SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)
        ]);
        
        // Vibrato
        sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));
        
        // Distance amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Apply amplitude
        sig = sig * amp * env * distAmp * (1 / numSynths.sqrt.max(1));
        sig = sig.tanh * 0.9;
        
        // Spatial positioning - smooth random movement
        spatialPos = Select.kr(spatialPattern, [
            LFNoise2.kr(spatialSpeed, spatialDepth).range(0, 1),
            SinOsc.kr(spatialSpeed, spatialPhase).range(0, 1),
            LFTri.kr(spatialSpeed, spatialPhase).range(0, 1),
            LFNoise0.kr(spatialSpeed * 2).range(0, 1) // Jumpy random
        ]);
        
        spatialPos = (spatialPos + pan).wrap(0, 1);
        
        // 8-channel output
        sigArray = PanAz.ar(8, sig, spatialPos * 2, 1, 2.5, 0);
        Out.ar(0, sigArray);
    }).add;
    
    // Store available 8-channel SynthDef names
    ~nUPIC_8ch_SynthDefs[\available] = [
        \upicWavetable8ch,
        \upicWavetablePrecise8ch,
        \simpleGravObject8ch
    ];
    
    // Set default
    ~nUPIC_8ch_SynthDefs[\default] = \upicWavetablePrecise8ch;
    
    "✓ nUPIC 8-channel spatialized SynthDefs loaded".postln;
    "Available 8ch SynthDefs:".postln;
    ~nUPIC_8ch_SynthDefs[\available].do { |name|
        ("  • " ++ name).postln;
    };
    "8-channel automated spatialization ready!".postln;
};

// Auto-load when this file is executed
~loadnUPIC8chSynthDefs.value;

// Add to global SynthDef registry
if(~nUPIC_SynthDefs.notNil) {
    ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available] ++ ~nUPIC_8ch_SynthDefs[\available];
    ("✓ Added 8ch SynthDefs to global registry").postln;
};
)