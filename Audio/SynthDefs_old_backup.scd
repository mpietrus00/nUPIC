// nUPIC Audio SynthDefs - Minimal Version
// Single VarSawOS synth with trajectory frequency and amplitude envelope
// Part of the nUPIC (nu-UPIC) system inspired by Xenakis' UPIC

(
// Initialize SynthDef collection
~nUPIC_SynthDefs = IdentityDictionary.new;

// Global amplitude scaling bus for anti-clipping
~nUPIC_globalAmpBus = Bus.control(s, 1);
~nUPIC_globalAmpBus.set(1.0);  // Initialize at full scale

// Load all SynthDefs for nUPIC
~loadnUPICSynthDefs = {

    // Optimized SynthDef for better performance with many instances (from XenakisTrajectory.scd)
    SynthDef(\simpleGravObject, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var gate = \gate.kr(1);  // Add gate for proper release

        // Get parameters with safe defaults and add smoothing via lag filters
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.1);  // Increased lag for smoother glides
        amp = Lag.kr(\amp.kr(0.0).clip(0, 0.5), 0.05);  // Faster lag for quicker response
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.1);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.2);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.1);
        width = Lag.kr(\width.kr(0.5).clip(0.01, 2.9), 0.1);

        // SOUND GENERATION - Optimized for CPU efficiency:
        // Use regular oscillators when many synths are playing
        sig = Select.ar(K2A.ar(mass > 2), [
            // Simple mode for lighter CPU load
            VarSawOS.ar(freq, 0, width, oversample: 2) * 0.4,
            // Full mode (using oversampled VarSaw)
            VarSawOS.ar(freq, 0, width, oversample: 4) * 0.4
        ]);

        // Simplified harmonics
        sig = sig + (VarSawOS.ar(freq * 2, 0, width, oversample: 2) * mass.linlin(0.1, 5, 0, 0.1));

        // Simplified modulation
        sig = sig * (1 + (SinOscOS.ar(velocity * 2 + 0.1, oversample: 2) * velocity.linlin(0, 20, 0, 0.03)));

        // Distance affects brightness - closer = brighter
        sig = LPF.ar(sig, freq * distance.linlin(20, 500, 3, 1));

        // Apply amplitude with envelope
        sig = sig * amp * EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);

        // Safety limiter to prevent clipping
        sig = sig.tanh * 0.7;  // Reduce overall level for many synths

        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Rich Texture SynthDef - Complex VarSawOS layering for trajectory sonification
    SynthDef(\richTexture, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var gate = \gate.kr(1);
        var layer1, layer2, layer3, layer4, layer5;
        var detune1, detune2, detune3, detune4, detune5;
        var ampMod, freqMod, filterMod;
        var crossfade, morphAmount;
        var leftSig, rightSig;

        // Get parameters with trajectory-optimized lag times
        freq = Lag.kr(\freq.kr(440).clip(20, 8000), 0.08);  // Smooth frequency tracking
        amp = Lag.kr(\amp.kr(0.15).clip(0, 0.8), 0.05);     // Responsive amplitude
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.1);
        mass = Lag.kr(\mass.kr(1).clip(0.1, 10), 0.2);      // Mass affects texture complexity
        velocity = Lag.kr(\velocity.kr(0).clip(0, 30), 0.15); // Velocity affects modulation
        distance = Lag.kr(\distance.kr(100).clip(10, 1000), 0.1); // Distance affects filtering
        width = Lag.kr(\width.kr(0.5).clip(0.01, 0.99), 0.1);

        // Calculate detuning amounts based on mass and velocity
        detune1 = 1.0;  // Fundamental
        detune2 = 1.0 + (mass.linlin(0.1, 10, 0.002, 0.015));  // Slight sharp detune
        detune3 = 1.0 - (mass.linlin(0.1, 10, 0.001, 0.008));  // Slight flat detune
        detune4 = 1.0 + (velocity.linlin(0, 30, 0.005, 0.025)); // Velocity-based detune
        detune5 = 1.0 - (velocity.linlin(0, 30, 0.003, 0.012)); // Counter velocity detune

        // Layer 1: Fundamental with trajectory frequency
        layer1 = VarSawOS.ar(
            freq * detune1,
            0,
            width,
            oversample: 4
        ) * 0.4;

        // Layer 2: Slightly detuned for richness
        layer2 = VarSawOS.ar(
            freq * detune2,
            0,
            (width * 0.8).clip(0.01, 0.99),
            oversample: 4
        ) * 0.25;

        // Layer 3: Counter-detuned for beating effects
        layer3 = VarSawOS.ar(
            freq * detune3,
            0,
            (1 - width * 0.6).clip(0.01, 0.99),
            oversample: 4
        ) * 0.2;

        // Layer 4: Velocity-modulated layer for dynamic texture
        layer4 = VarSawOS.ar(
            freq * detune4,
            0,
            (width + velocity.linlin(0, 30, 0, 0.3)).clip(0.01, 0.99),
            oversample: 4
        ) * velocity.linlin(0, 30, 0.05, 0.2);

        // Layer 5: Harmonic layer at octave with mass-dependent amplitude
        layer5 = VarSawOS.ar(
            freq * 2 * detune5,
            0,
            (width * 0.7).clip(0.01, 0.99),
            oversample: 4
        ) * mass.linlin(0.1, 10, 0.05, 0.15);

        // Combine layers with trajectory-responsive mixing
        sig = layer1 + layer2 + layer3 + layer4 + layer5;

        // Add subtle sub-harmonic for depth (mass-dependent)
        sig = sig + (VarSawOS.ar(
            freq * 0.5,
            0,
            width * 0.5,
            oversample: 4
        ) * mass.linlin(0.1, 10, 0, 0.08));

        // Trajectory-responsive amplitude modulation
        ampMod = 1 + (SinOscOS.ar(
            velocity.linlin(0, 30, 0.2, 4),
            oversample: 2
        ) * velocity.linlin(0, 30, 0, 0.04));
        sig = sig * ampMod;

        // Trajectory-responsive frequency modulation (subtle vibrato)
        freqMod = SinOscOS.ar(
            mass.linlin(0.1, 10, 3, 8),
            oversample: 2
        ) * freq * mass.linlin(0.1, 10, 0.001, 0.008);
        // Apply freq mod by slightly shifting all layers
        sig = sig * (1 + (freqMod / freq * 0.5));

        // Distance-based filtering - multi-stage for rich timbre shaping
        // High-frequency rolloff based on distance
        sig = LPF.ar(sig,
            (freq * distance.linlin(10, 1000, 8, 2)).clip(freq, 12000)
        );

        // Low-frequency emphasis when close
        sig = HPF.ar(sig,
            (freq * distance.linlin(10, 1000, 0.3, 0.8)).clip(20, freq * 0.7)
        );

        // Resonant peak for formant-like character (mass-controlled)
        sig = RLPF.ar(sig,
            freq * mass.linlin(0.1, 10, 1.5, 3),
            mass.linlin(0.1, 10, 0.3, 0.8).clip(0.1, 0.9)
        );

        // Trajectory width affects stereo width via subtle phase shifting
        leftSig = sig;
        rightSig = DelayL.ar(sig, 0.002, width.linlin(0.01, 0.99, 0, 0.002));
        sig = [leftSig, rightSig];

        // Apply main amplitude with trajectory envelope
        sig = sig * amp * EnvGen.kr(
            Env.asr(0.02, 1, 0.15),
            gate,
            doneAction: 2
        );

        // Soft limiting with character preservation
        sig = sig.tanh * 0.6;

        // Output with trajectory-based panning
        Out.ar(0, Balance2.ar(sig[0], sig[1], pan, 1));
    }).add;

    // Auditory Distortion Synthesis based on QDT (Quadratic Difference Tones)
    SynthDef(\auditoryDistortion, {
        var sig, freq, amp, pan, gate;
        var carrier, f1, f2, f3;
        var amp1, amp2, amp3;
        var mass, velocity, distance, width;

        // Get parameters with safe defaults
        freq = Lag.kr(\freq.kr(300).clip(20, 1000), 0.25);  // Much smoother frequency changes
        amp = Lag.kr(\amp.kr(0.0).clip(0, 0.5), 0.15);  // Smoother amplitude
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.2);  // Smoother panning
        gate = \gate.kr(1);

        // Trajectory parameters
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.3);  // Smoother velocity changes
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.2);  // Smoother distance changes
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.2);  // Smoother width changes

        // Carrier frequency (high frequency that won't be directly heard)
        // Should be well above audible difference tones
        carrier = 3000 + (mass * 100);  // 3000-5500 Hz range based on mass

        // Calculate frequencies for QDT generation
        // f2 - f1 = fundamental (freq)
        // f3 - f1 = 2 * fundamental
        // f3 - f2 = fundamental
        f1 = carrier;
        f2 = carrier + freq;
        f3 = carrier + (2 * freq);

        // Calculate amplitudes based on trajectory parameters
        // Width controls harmonic balance
        amp1 = 0.5 * distance.linlin(20, 500, 0.8, 0.3);
        amp2 = 0.5 * width.linlin(0.1, 0.9, 0.3, 0.8) * distance.linlin(20, 500, 0.8, 0.3);
        amp3 = 0.3 * (1 - width).linlin(0.1, 0.9, 0.2, 0.6) * distance.linlin(20, 500, 0.6, 0.2);

        // Add slight modulation based on velocity
        amp1 = amp1 * (1 + LFSaw.ar(velocity * 0.1).range(-0.1, 0.1));
        amp2 = amp2 * (1 + LFSaw.ar(velocity * 0.15).range(-0.1, 0.1));
        amp3 = amp3 * (1 + LFSaw.ar(velocity * 0.2).range(-0.1, 0.1));

        // Generate the three sine tones
        sig = SinOscOS.ar(f1, 0, amp1, oversample: 2) +
              SinOscOS.ar(f2, 0, amp2, oversample: 2) +
              SinOscOS.ar(f3, 0, amp3, oversample: 2);

        // The QDTs will be generated in the listener's ear:
        // f2 - f1 = fundamental
        // f3 - f2 = fundamental
        // f3 - f1 = 2nd harmonic
        // 2*f2 - f3 = fundamental (cubic difference tone)

        // Add subtle amplitude modulation for liveliness
        sig = sig * (1 + SinOscOS.ar(velocity * 0.5 + 0.1, 0, 0.05, oversample: 2));

        // High-pass filter to remove any low frequency artifacts
        sig = HPF.ar(sig, 2000);

        // Apply amplitude envelope
        sig = sig * amp * EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);

        // Soft limiting
        sig = sig.tanh * 0.5;

        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Percussive noise SynthDef - continuous texture version
    SynthDef(\percNoise, {
        var sig, env, freq, amp, pan, rq, gate;
        var modFreq, modDepth;

        // Parameters
        freq = Lag.kr(\freq.kr(440).clip(20, 8000), 0.25);  // Much smoother frequency changes
        amp = Lag.kr(\amp.kr(0.2).clip(0, 0.5), 0.15);  // Smoother amplitude
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.2);  // Smoother panning
        rq = \rq.kr(0.1).clip(0.01, 1);
        gate = \gate.kr(1);

        // Texture modulation parameters
        modFreq = \modFreq.kr(0.5).clip(0.1, 10);
        modDepth = \modDepth.kr(0.3).clip(0, 1);

        // Sound generation - continuous filtered noise
        sig = BPF.ar(GrayNoise.ar, freq, rq, 3);

        // Add subtle amplitude modulation for texture variation
        sig = sig * (1 + (SinOsc.kr(modFreq, Rand(0, 2pi)) * modDepth));

        // Main envelope for overall on/off control
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );

        // Apply envelope and output
        Out.ar(0, Pan2.ar(sig * env * amp, pan));
    }).add;

    // Test SinOsc SynthDefs for frequency testing
    SynthDef(\testSinOsc, {
        arg freq = 440, amp = 0.1, gate = 1, pan = 0,
            attack = 0.01, decay = 0.1, sustain = 0.7, release = 0.3;

        var sig, env;

        // Simple ADSR envelope
        env = EnvGen.kr(
            Env.adsr(attack, decay, sustain, release),
            gate,
            doneAction: 2
        );

        // Pure sine wave - most direct frequency representation
        sig = SinOscOS.ar(freq, 0, amp * env, oversample: 2);

        // Pan and output
        sig = Pan2.ar(sig, pan);
        Out.ar(0, sig);
    }).add;

    // Alternative with slight vibrato for more musical testing
    SynthDef(\testSinOscVibrato, {
        arg freq = 440, amp = 0.1, gate = 1, pan = 0,
            attack = 0.01, decay = 0.1, sustain = 0.7, release = 0.3,
            vibratoRate = 5, vibratoDepth = 0.02;

        var sig, env, vibrato;

        // Simple ADSR envelope
        env = EnvGen.kr(
            Env.adsr(attack, decay, sustain, release),
            gate,
            doneAction: 2
        );

        // Add subtle vibrato for more musical character
        vibrato = SinOsc.kr(vibratoRate, 0, vibratoDepth);

        // Sine wave with vibrato
        sig = SinOscOS.ar(freq * (1 + vibrato), 0, amp * env, oversample: 2);

        // Pan and output
        sig = Pan2.ar(sig, pan);
        Out.ar(0, sig);
    }).add;

    // Very simple version - minimal parameters
    SynthDef(\simpleSine, {
        arg freq = 440, amp = 0.1, gate = 1;

        var sig, env;

        // Simple envelope that follows gate
        env = EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );

        // Pure sine wave
        sig = SinOscOS.ar(freq, 0, amp * env, oversample: 2);

        Out.ar(0, sig ! 2); // Stereo output
    }).add;

    // Master limiter to prevent clipping at output
    SynthDef(\masterLimiter, {
        var sig, limited;

        // Read the main output
        sig = In.ar(0, 2);

        // Multi-stage limiting for clean sound
        // Stage 1: Soft compression
        sig = Compander.ar(sig, sig,
            thresh: -12.dbamp,     // Start compressing at -12dB
            slopeBelow: 1.0,       // No compression below threshold
            slopeAbove: 0.3,       // 3:1 compression above threshold
            clampTime: 0.003,      // Fast attack
            relaxTime: 0.1         // Medium release
        );

        // Stage 2: Hard limiting
        limited = Limiter.ar(sig, level: -1.dbamp, dur: 0.005);

        // Stage 3: Final safety clipper
        limited = limited.clip2(0.95);

        // Replace the main output
        ReplaceOut.ar(0, limited);
    }).add;

    // simpleGravObj2 - VarSaw gravitational object synth with Doppler effect (from MultiObjectBarycenterSonification.scd)
    SynthDef(\simpleGravObj2, {
        var sig, freq, amp, pan, mass, velocity, distance, width;
        var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;

        // Get parameters with safe defaults and add smoothing via lag filters
        freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.01);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.05);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.02);
        mass = \mass.kr(1).clip(0.1, 25);
        velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.1);
        distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.02);
        width = Lag.kr(\width.kr(0.5).clip(0.1, 0.9), 0.05);

        // DOPPLER EFFECT:
        // Radial velocity component (+ = moving away, - = moving towards barycenter)
        radialVelocity = Lag.kr(\radialVel.kr(0).clip(-20, 20), 0.2); // Increased lag for smoothing
        dopplerSensitivity = \dopplerSens.kr(1.0).clip(0, 3.0);

        // Anti-flicker: reduce Doppler effect when very close to barycenter
        dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1); // Fade out Doppler near barycenter

        // Doppler frequency shift: f' = f * (c + vr) / c
        // Simplified for audio: audible shifts based on radial velocity
        dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05); // Increased shift rate for audibility
        dopplerShift = dopplerShift.clip(0.5, 2.0); // Larger shift range ±100% for clear effect
        dopplerFreq = freq * dopplerShift;

        // SOUND GENERATION:
        // 1. Base oscillator - VarSaw with Doppler-shifted frequency
        sig = VarSawOS.ar(dopplerFreq, 0, width, oversample: 2) * 0.4;

        // 2. Mass affects harmonics - bigger mass = more harmonics (also Doppler-shifted)
        sig = sig + (VarSawOS.ar(dopplerFreq * 2, 0, width * 0.8, oversample: 2) * mass.linlin(0.1, 5, 0, 0.15));

        // 3. Velocity affects frequency modulation - faster = more wobble
        sig = sig * (1 + (SinOscOS.ar(velocity * 2 + 0.1, oversample: 2) * velocity.linlin(0, 20, 0, 0.05)));

        // 4. Distance affects brightness - closer = brighter
        sig = LPF.ar(sig, dopplerFreq * distance.linlin(20, 500, 3, 1));

        // Apply amplitude
        sig = sig * amp;

        // Safety limiter to prevent clipping
        sig = sig.tanh;

        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Simple VarSawOS - minimal synth with just the oscillator
    SynthDef(\simpleVarSaw, {
        var sig, freq, amp, pan, width;
        var gate = \gate.kr(1);

        // Basic parameters with smoothing
        freq = Lag.kr(\freq.kr(440).clip(20, 8000), 0.05);
        amp = Lag.kr(\amp.kr(0.1).clip(0, 0.5), 0.02);
        pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.05);
        width = Lag.kr(\width.kr(0.5).clip(0.01, 0.99), 0.05);

        // Single VarSawOS oscillator
        sig = VarSawOS.ar(freq, 0, width, oversample: 2);

        // Simple envelope
        sig = sig * amp * EnvGen.kr(
            Env.asr(0.01, 1, 0.1),
            gate,
            doneAction: 2
        );

        // Soft limiting
        sig = sig.tanh * 0.8;

        // Output with panning
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Efficient Default - Ultra-lightweight for many voices
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

    // Ultra Light VarSaw - Minimal VarSaw for 10+ voices
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

    // Optimized Simple - Balanced performance/quality
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
        sig = Select.ar(K2A.ar(useAntiAlias), [
            VarSaw.ar(freq, 0, width),  // Regular for low/mid frequencies
            Saw.ar(freq) * width  // Simple saw for high frequencies (less CPU)
        ]);
        
        // Minimal harmonics - only add if mass is significant
        sig = sig + Select.ar(K2A.ar(mass > 2), [
            DC.ar(0),  // No harmonic (use DC.ar for audio-rate zero)
            Saw.ar(freq * 2) * 0.05 * mass.linlin(2, 5, 0, 1)  // Simple harmonic
        ]);
        
        // Simple brightness control
        sig = LPF.ar(sig, (freq * distance.linlin(20, 500, 3, 0.5)).min(4000));
        
        // Envelope with shorter release
        sig = sig * amp * EnvGen.kr(Env.asr(0.005, 1, 0.05), gate, doneAction: 2);
        
        // Soft clipping only if needed
        sig = Select.ar(K2A.ar(sig.abs > 0.8), [
            sig,
            sig.tanh
        ]) * 0.6;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;

    // Load Xenakis and Brün inspired SynthDefs if file exists
    // Handle case where basePath might not be set
    {
        var xenakisPath;
        if(~nUPIC_basePath.notNil) {
            xenakisPath = ~nUPIC_basePath +/+ "Audio/XenakisBrun_SynthDefs.scd";
        } {
            // Try relative path
            xenakisPath = "Audio/XenakisBrun_SynthDefs.scd";
        };
        
        if(File.exists(xenakisPath)) {
            xenakisPath.load;
            "Xenakis and Brün SynthDefs loaded".postln;
        } {
            // Try loading directly from same directory
            if(File.exists("XenakisBrun_SynthDefs.scd")) {
                "XenakisBrun_SynthDefs.scd".load;
                "Xenakis and Brün SynthDefs loaded from local directory".postln;
            };
        };
    }.value;
    
    // Store available SynthDef names - INCLUDING THE NEW EFFICIENT ONES AND XENAKIS/BRÜN
    ~nUPIC_SynthDefs[\available] = [
        \simpleGravObject, 
        \simpleGravObj2, 
        \richTexture, 
        \percNoise, 
        \auditoryDistortion, 
        \testSinOsc, 
        \testSinOscVibrato, 
        \simpleSine, 
        \simpleVarSaw,
        \efficientDefault,    // NEW
        \ultraLightVarSaw,    // NEW 
        \optimizedSimple,     // NEW
        // Xenakis inspired
        \stochasticXenakis,   // GENDYN-inspired
        \sieveHarmonics,      // Sieve theory
        \achorripsis,         // Stochastic distributions
        \metastaseis,         // Mass glissandi
        // Herbert Brün inspired
        \sawdustBrun,         // Micro-temporal
        \infraudibles         // Inaudible components
    ];

    "nUPIC SynthDefs loaded successfully".postln;
};

// Voice management functions
~nUPIC_voiceManager = (
    activeSynths: 0,
    maxSynths: 50,  // Limit to prevent clipping
    masterLimiter: nil,

    // Start the master limiter
    startMasterLimiter: {
        if(~nUPIC_voiceManager.masterLimiter.isNil) {
            ~nUPIC_voiceManager.masterLimiter = Synth(\masterLimiter, target: RootNode(), addAction: \addToTail);
            "Master limiter started".postln;
        };
    },

    // Stop the master limiter
    stopMasterLimiter: {
        if(~nUPIC_voiceManager.masterLimiter.notNil) {
            ~nUPIC_voiceManager.masterLimiter.free;
            ~nUPIC_voiceManager.masterLimiter = nil;
            "Master limiter stopped".postln;
        };
    },

    // Update voice count and calculate scaling
    updateVoiceCount: { |numSynths|
        var safeNumSynths;

        // Robust conversion to integer - handle Event objects and other types
        if(numSynths.isNil) {
            safeNumSynths = 1;
        } {
            if(numSynths.isKindOf(Event)) {
                ("WARNING: updateVoiceCount received Event object instead of number: %").format(numSynths).postln;
                safeNumSynths = 1;
            } {
                if(numSynths.isKindOf(Number)) {
                    safeNumSynths = numSynths.asInteger.max(1).min(100);
                } {
                    ("WARNING: updateVoiceCount received non-numeric value: % (type: %)").format(numSynths, numSynths.class).postln;
                    safeNumSynths = 1;
                };
            };
        };

        ~nUPIC_voiceManager.activeSynths = safeNumSynths;

        // Update global amplitude scaling
        if(~nUPIC_globalAmpBus.notNil) {
            var scaling = safeNumSynths.pow(-0.5).clip(0.1, 1.0);  // Same as 1/sqrt but safer
            ~nUPIC_globalAmpBus.set(scaling);
            ("Voice scaling updated: % synths, scaling factor: %").format(safeNumSynths, scaling.round(0.3)).postln;
        };
    },

    // Check if we can add more synths
    canAddSynth: {
        ~nUPIC_voiceManager.activeSynths < ~nUPIC_voiceManager.maxSynths;
    }
);

// Auto-load when this file is executed
~loadnUPICSynthDefs.value;
)
