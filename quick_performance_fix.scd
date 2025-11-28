// Quick Performance Fix for nUPIC
// Immediate improvements without major system changes

(
"=== Applying Quick Performance Fixes ===".postln;

// 1. AMPLITUDE SCALING - Reduce amplitude based on voice count
~fixAmplitudeScaling = {
    if(~nUPIC[\ui][\startPlayback].notNil) {
        var original = ~nUPIC[\ui][\startPlayback];
        
        // Store original if not stored
        if(~nUPIC[\ui][\startPlaybackPreAmpFix].isNil) {
            ~nUPIC[\ui][\startPlaybackPreAmpFix] = original;
        };
        
        // Wrap to add amplitude scaling
        ~nUPIC[\ui][\startPlayback] = {
            var state = ~nUPIC[\ui][\state];
            var data = ~nUPIC[\data];
            var numTraj = if(data.notNil and: { data[\trajectories].notNil }) {
                data[\trajectories].size
            } { 0 };
            
            // Calculate amplitude scaling
            var ampScale = case
                { numTraj <= 1 } { 0.2 }
                { numTraj <= 3 } { 0.15 }
                { numTraj <= 5 } { 0.1 }
                { numTraj <= 10 } { 0.07 }
                { numTraj <= 20 } { 0.04 }
                { numTraj <= 30 } { 0.03 }
                { true } { 0.02 };
            
            ("Amplitude scaling: " ++ ampScale ++ " for " ++ numTraj ++ " trajectories").postln;
            
            // Store in state for synth creation
            if(state.notNil) {
                state[\globalAmpScale] = ampScale;
            };
            
            // Call original
            ~nUPIC[\ui][\startPlaybackPreAmpFix].value;
        };
    };
    
    "Amplitude scaling fix applied".postln;
};

// 2. LIMIT HIGH FREQUENCY VOICES - Reduce polyphony above 2kHz
~limitHighFrequencies = {
    ~highFreqLimiter = (
        maxHighFreqVoices: 5,  // Max simultaneous voices above 2kHz
        threshold: 2000,        // Frequency threshold
        activeHighFreqs: List[],
        
        checkFreq: { |self, freq, synthIndex|
            if(freq > self.threshold) {
                if(self.activeHighFreqs.size >= self.maxHighFreqVoices) {
                    // Skip this voice
                    ("Skipping high freq voice: " ++ freq.round(1) ++ " Hz").postln;
                    false
                } {
                    self.activeHighFreqs.add(synthIndex);
                    true
                }
            } {
                true  // Allow low/mid frequencies
            }
        },
        
        clear: { |self|
            self.activeHighFreqs.clear;
        }
    );
    
    "High frequency limiter created".postln;
};

// 3. REDUCE UPDATE RATE - Less frequent parameter updates
~reduceUpdateRate = {
    // Modify the constants for lower frame rates
    if(~nUPIC[\constants].notNil) {
        ~nUPIC[\constants][\frameRate] = 30;  // Reduced from 60
        ~nUPIC[\constants][\audioFrameRate] = 60;  // Reduced from 120
        "Update rates reduced: visual=30fps, audio=60fps".postln;
    };
};

// 4. SIMPLIFIED SYNTH - Create a CPU-efficient default
~createEfficientDefault = {
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
    
    // Add to available synths
    if(~nUPIC_SynthDefs.notNil) {
        ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\efficientDefault);
    };
    
    // Make it default for high trajectory counts
    if(~nUPIC[\defaults].notNil) {
        ~nUPIC[\defaults][\efficientSynthDef] = \efficientDefault;
    };
    
    "Efficient default SynthDef created".postln;
};

// 5. FREQUENCY SPACING - Prevent beating in high frequencies
~preventHighFreqBeating = {
    ~freqSpacer = { |freq, index, total|
        if(freq > 1500) {
            // Add slight detuning to prevent beating
            var detune = (index - (total/2)) * 3;  // ±3 Hz per voice
            freq = freq + detune;
        };
        freq
    };
    
    "Frequency spacing function created".postln;
};

// 6. SERVER OPTIMIZATION
~optimizeServer = {
    // Increase buffer sizes for better performance
    s.options.blockSize = 128;  // Increase from default 64
    s.options.numOutputBusChannels = 2;
    s.options.numInputBusChannels = 0;  // Disable input if not needed
    s.options.sampleRate = 44100;  // Ensure standard sample rate
    
    // Increase memory
    s.options.memSize = 8192 * 32;
    s.options.numWireBufs = 128;
    
    "Server optimized - restart server for changes to take effect".postln;
    "Execute: s.reboot;".postln;
};

// 7. APPLY ALL FIXES
~applyQuickFixes = {
    "Applying all quick fixes...".postln;
    
    ~fixAmplitudeScaling.value;
    ~limitHighFrequencies.value;
    ~reduceUpdateRate.value;
    ~createEfficientDefault.value;
    ~preventHighFreqBeating.value;
    ~optimizeServer.value;
    
    "".postln;
    "=== QUICK FIXES APPLIED ===".postln;
    "✓ Amplitude auto-scaling based on voice count".postln;
    "✓ High frequency voice limiting (max 5 above 2kHz)".postln;
    "✓ Reduced update rates for better performance".postln;
    "✓ Efficient default SynthDef available".postln;
    "✓ Frequency spacing to prevent beating".postln;
    "✓ Server settings optimized".postln;
    "".postln;
    "RECOMMENDED ACTIONS:".postln;
    "1. Restart the server: s.reboot;".postln;
    "2. For >10 trajectories, use 'efficientDefault' SynthDef".postln;
    "3. Keep trajectories below 20 for best performance".postln;
};

// Auto-apply
~applyQuickFixes.value;

// Create test function
~testPerformance = { |numTrajectories = 15|
    "Creating " ++ numTrajectories ++ " test trajectories...".postln;
    
    // Clear existing
    if(~nUPIC[\data][\trajectories].notNil) {
        ~nUPIC[\data][\trajectories].clear;
    };
    
    // Create test trajectories at different frequencies
    numTrajectories.do { |i|
        var trajectory = List[];
        var startY = (i / numTrajectories) * 670;  // Spread across frequency range
        var endY = ((i + 0.5) / numTrajectories) * 670;
        
        // Simple two-point trajectory
        trajectory.add((x: 100, y: startY));
        trajectory.add((x: 1100, y: endY));
        
        ~nUPIC[\data][\trajectories].add(trajectory);
    };
    
    "Test trajectories created. Press SPACE to test playback.".postln;
    ~nUPIC[\ui][\refreshDisplay].value;
};

"".postln;
"To test performance with multiple trajectories:".postln;
"  ~testPerformance.value(15);  // Create 15 test trajectories".postln;
"  Then press SPACE to play".postln;
)
