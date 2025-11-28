// nUPIC 8-Channel SynthDefs with Envelope-based Spatialization
// Uses drawn spatialization curves instead of random oscillators
// Each trajectory has its own spatial movement path

(
// Initialize 8-channel envelope-based SynthDef collection
~nUPIC_8ch_env_SynthDefs = IdentityDictionary.new;

// Load 8-channel envelope-based SynthDefs
~loadnUPIC8chEnvelopeSynthDefs = {
    
    // 8-channel UPIC Wavetable with envelope-based spatialization
    SynthDef(\upicWavetable8chEnv, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            // Envelope buffer for spatialization
            spatialEnvBuf = -1,  // Buffer containing the spatialization envelope
            playbackRate = 1;    // Rate of trajectory playback
        
        var sig, env, phase;
        var modulator, filter;
        var effectiveFreq, modFreq, filtCutoff;
        var morphPos, modIndex;
        var spatialPos, sigArray;
        var playbackPos, channelValue;
        
        // Use default wavetable if bufnum is 0 or not provided
        if(bufnum == 0) {
            if(~nUPIC_DefaultWaveTable.notNil) {
                bufnum = ~nUPIC_DefaultWaveTable.bufnum;
            };
        };
        
        // Map compatibility parameters
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
        
        // SPATIAL POSITIONING FROM ENVELOPE
        // If no envelope buffer provided, use center position
        if(spatialEnvBuf < 0) {
            spatialPos = 0.5 + (pan * 0.125);  // Center with slight pan offset
        } {
            // Read position from envelope buffer based on playback progress
            playbackPos = EnvGen.kr(
                Env([0, 1], [1/playbackRate], \lin),
                gate
            );
            
            // Read channel value from buffer (0-7 range)
            channelValue = BufRd.kr(
                1,  // 1 channel
                spatialEnvBuf,
                playbackPos * BufFrames.kr(spatialEnvBuf),
                interpolation: 1  // Linear interpolation
            );
            
            // Convert to 0-1 range for PanAz
            spatialPos = channelValue / 7;
        };
        
        // Create 8-channel panning
        sigArray = PanAz.ar(
            8,              // 8 channels
            sig,            // input signal
            spatialPos * 2, // position (0-2 for full circle)
            1,              // level
            2.5,            // width
            0               // orientation
        );
        
        // Output to 8 channels
        Out.ar(0, sigArray);
    }).add;
    
    // Precise 8-channel version with envelope-based spatialization
    SynthDef(\upicWavetablePrecise8chEnv, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            bufnum = 0,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            spatialEnvBuf = -1,
            playbackRate = 1;
        
        var sig, dopplerShift, finalFreq, distAmp;
        var phase;
        var spatialPos, sigArray;
        var playbackPos, channelValue;
        
        // Use default wavetable if bufnum is 0
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
        
        // SPATIAL POSITIONING FROM ENVELOPE
        if(spatialEnvBuf < 0) {
            spatialPos = 0.5 + (pan * 0.125);
        } {
            playbackPos = EnvGen.kr(
                Env([0, 1], [1/playbackRate], \lin),
                gate
            );
            
            channelValue = BufRd.kr(
                1,
                spatialEnvBuf,
                playbackPos * BufFrames.kr(spatialEnvBuf),
                interpolation: 1
            );
            
            spatialPos = channelValue / 7;
        };
        
        // Create 8-channel panning
        sigArray = PanAz.ar(
            8,
            sig,
            spatialPos * 2,
            1,
            2.5,
            0
        );
        
        Out.ar(0, sigArray);
    }).add;
    
    // Simple 8-channel gravity object with envelope-based spatialization
    SynthDef(\simpleGravObject8chEnv, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            spatialEnvBuf = -1,
            playbackRate = 1;
        
        var sig, env, dopplerShift, finalFreq, distAmp;
        var spatialPos, sigArray;
        var playbackPos, channelValue;
        
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
        
        // SPATIAL POSITIONING FROM ENVELOPE
        if(spatialEnvBuf < 0) {
            spatialPos = 0.5 + (pan * 0.125);
        } {
            playbackPos = EnvGen.kr(
                Env([0, 1], [1/playbackRate], \lin),
                gate
            );
            
            channelValue = BufRd.kr(
                1,
                spatialEnvBuf,
                playbackPos * BufFrames.kr(spatialEnvBuf),
                interpolation: 1
            );
            
            spatialPos = channelValue / 7;
        };
        
        // 8-channel output
        sigArray = PanAz.ar(8, sig, spatialPos * 2, 1, 2.5, 0);
        Out.ar(0, sigArray);
    }).add;
    
    // Store available 8-channel envelope-based SynthDef names
    ~nUPIC_8ch_env_SynthDefs[\available] = [
        \upicWavetable8chEnv,
        \upicWavetablePrecise8chEnv,
        \simpleGravObject8chEnv
    ];
    
    // Set default
    ~nUPIC_8ch_env_SynthDefs[\default] = \upicWavetablePrecise8chEnv;
    
    "✓ nUPIC 8-channel envelope-based spatialized SynthDefs loaded".postln;
    "Available 8ch envelope SynthDefs:".postln;
    ~nUPIC_8ch_env_SynthDefs[\available].do { |name|
        ("  • " ++ name).postln;
    };
    "8-channel envelope-based spatialization ready!".postln;
};

// Function to create buffer from spatialization envelope
~nUPIC[\createSpatialEnvelopeBuffer] = { |trajIdx|
    var data = ~nUPIC[\data];
    var envelope = data[\spatializationEnvelopes][trajIdx];
    var buffer;
    var bufferSize = 512;  // Resolution of envelope buffer
    var array;
    
    if(envelope.notNil and: { envelope.size > 1 }) {
        array = Array.fill(bufferSize, { |i|
            var pos = i / (bufferSize - 1);
            var x = pos * envelope.last.x;
            var channel;
            
            // Find surrounding points for interpolation
            var prevPoint = envelope[0];
            var nextPoint = envelope[1];
            var j = 0;
            
            while { j < (envelope.size - 1) and: { envelope[j + 1].x <= x } } {
                j = j + 1;
                prevPoint = envelope[j];
                if(j < (envelope.size - 1)) {
                    nextPoint = envelope[j + 1];
                };
            };
            
            // Interpolate channel value
            if(prevPoint.x == nextPoint.x) {
                channel = prevPoint.channel;
            } {
                var alpha = (x - prevPoint.x) / (nextPoint.x - prevPoint.x);
                channel = prevPoint.channel + (alpha * (nextPoint.channel - prevPoint.channel));
            };
            
            channel.clip(0, 7);
        });
        
        // Create buffer
        buffer = Buffer.loadCollection(s, array);
    } {
        // Default: center position
        array = Array.fill(bufferSize, 3.5);
        buffer = Buffer.loadCollection(s, array);
    };
    
    buffer;
};

// Auto-load when this file is executed
~loadnUPIC8chEnvelopeSynthDefs.value;

// Add to global SynthDef registry
if(~nUPIC_SynthDefs.notNil) {
    ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available] ++ ~nUPIC_8ch_env_SynthDefs[\available];
    ("✓ Added 8ch envelope SynthDefs to global registry").postln;
};

"".postln;
"To use envelope-based spatialization:".postln;
"1. Select trajectories with 'G' key".postln;
"2. Run: ~nUPIC[\ui][\openSpatializationEditorForSelected].value".postln;
"3. Draw spatialization curves (vertical = channels, horizontal = time)".postln;
"4. Trajectories will follow your drawn spatial paths!".postln;
)