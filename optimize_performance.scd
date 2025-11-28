// Performance Optimization for nUPIC
// Fixes glitching with >10 trajectories and high-frequency interference

(
"=== Loading Performance Optimizations ===".postln;

// 1. OPTIMIZE SYNTHDEFS - Create lightweight versions
~createOptimizedSynthDefs = {
    
    // Ultra-light VarSaw for many voices
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
    
    // Optimized simple synth with anti-aliasing for high frequencies
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
        sig = Select.ar(useAntiAlias, [
            VarSaw.ar(freq, 0, width),  // Regular for low/mid frequencies
            Saw.ar(freq) * width  // Simple saw for high frequencies (less CPU)
        ]);
        
        // Minimal harmonics - only add if mass is significant
        sig = sig + Select.ar(mass > 2, [
            0,  // No harmonic
            Saw.ar(freq * 2) * 0.05 * mass.linlin(2, 5, 0, 1)  // Simple harmonic
        ]);
        
        // Simple brightness control
        sig = LPF.ar(sig, (freq * distance.linlin(20, 500, 3, 0.5)).min(4000));
        
        // Envelope with shorter release
        sig = sig * amp * EnvGen.kr(Env.asr(0.005, 1, 0.05), gate, doneAction: 2);
        
        // Soft clipping only if needed
        sig = Select.ar(sig.abs > 0.8, [
            sig,
            sig.tanh
        ]) * 0.6;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "Optimized SynthDefs loaded".postln;
};

// 2. VOICE ALLOCATION SYSTEM - Limit voices based on CPU
~createVoiceAllocator = {
    ~voiceAllocator = (
        maxVoices: 20,  // Maximum simultaneous voices
        activeVoices: List[],
        cpuThreshold: 50,  // CPU percentage threshold
        
        // Check if we can add a new voice
        canAddVoice: { |self|
            var canAdd = self.activeVoices.size < self.maxVoices;
            var cpuOK = s.avgCPU < self.cpuThreshold;
            canAdd and: cpuOK
        },
        
        // Add voice with priority (lower frequencies get priority)
        addVoice: { |self, synth, freq, trajIndex|
            if(self.canAddVoice) {
                self.activeVoices.add((
                    synth: synth,
                    freq: freq,
                    trajIndex: trajIndex,
                    startTime: Main.elapsedTime
                ));
                true
            } {
                // Voice stealing - remove highest frequency voice
                if(self.activeVoices.size > 0) {
                    var sorted = self.activeVoices.sortBy({ |v| v.freq });
                    var toRemove = sorted.last;  // Remove highest freq
                    if(freq < toRemove.freq) {  // Only if new is lower
                        toRemove.synth.set(\gate, 0);
                        self.activeVoices.remove(toRemove);
                        self.activeVoices.add((
                            synth: synth,
                            freq: freq,
                            trajIndex: trajIndex,
                            startTime: Main.elapsedTime
                        ));
                        ("Voice stolen from traj " ++ toRemove.trajIndex).postln;
                    };
                };
                false
            }
        },
        
        // Remove voice
        removeVoice: { |self, synth|
            self.activeVoices.removeAllSuchThat({ |v| v.synth == synth });
        },
        
        // Clear all voices
        clear: { |self|
            self.activeVoices.do({ |v| v.synth.set(\gate, 0) });
            self.activeVoices.clear;
        }
    );
    
    "Voice allocator created".postln;
};

// 3. FREQUENCY DECONFLICTION - Prevent beating in high frequencies
~createFrequencyManager = {
    ~freqManager = (
        minSeparation: 50,  // Minimum Hz separation for high frequencies
        highFreqThreshold: 1000,  // Above this, apply deconfliction
        
        // Adjust frequency to avoid conflicts
        deconflictFreq: { |self, freq, existingFreqs|
            if(freq > self.highFreqThreshold) {
                var conflicts = existingFreqs.select({ |f| 
                    (f - freq).abs < self.minSeparation and: { f > self.highFreqThreshold }
                });
                
                if(conflicts.size > 0) {
                    // Shift frequency slightly to avoid beating
                    var shift = self.minSeparation * (existingFreqs.size.rand2 / existingFreqs.size);
                    freq = freq + shift;
                    ("Deconflicted freq: shifted by " ++ shift.round(0.1) ++ " Hz").postln;
                };
            };
            freq
        }
    );
    
    "Frequency manager created".postln;
};

// 4. OPTIMIZED PLAYBACK FUNCTION
~optimizedStartPlayback = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var numTrajectories, lightweightThreshold;
    
    if(data[\trajectories].isNil or: { data[\trajectories].size == 0 }) {
        "No trajectories to play".postln;
        ^nil;
    };
    
    numTrajectories = data[\trajectories].size;
    lightweightThreshold = 10;  // Use lightweight synths above this count
    
    ("Starting optimized playback with " ++ numTrajectories ++ " trajectories").postln;
    
    // Initialize voice allocator
    if(~voiceAllocator.isNil) { ~createVoiceAllocator.value };
    if(~freqManager.isNil) { ~createFrequencyManager.value };
    
    // Clear previous voices
    ~voiceAllocator.clear;
    
    // Choose SynthDef based on trajectory count
    var synthDefToUse = if(numTrajectories > lightweightThreshold) {
        "Using ultra-light synthesis for " ++ numTrajectories ++ " trajectories".postln;
        \ultraLightVarSaw
    } {
        "Using optimized synthesis".postln;
        \optimizedSimple
    };
    
    // Store original startPlayback if not already stored
    if(~originalStartPlayback.isNil) {
        ~originalStartPlayback = ~nUPIC[\ui][\startPlayback];
    };
    
    // Modify the synth creation in startPlayback
    ~nUPIC[\ui][\startPlayback] = {
        var state = ~nUPIC[\ui][\state];
        var data = ~nUPIC[\data];
        var existingFreqs = List[];
        
        // Call original but intercept synth creation
        state[\isPlaying] = true;
        
        // Create modified playback task
        state[\playbackTask] = Task {
            var playDuration = state[\playDuration] ? 10;
            var frameRate = 30;  // Reduced frame rate for better performance
            var frameTime = 1 / frameRate;
            
            // Create synths with optimization
            fork {
                data[\trajectories].do { |traj, i|
                    var synth, freq, amp;
                    
                    if(traj.size > 0) {
                        freq = traj[0].y.linlin(0, 670, 7500, 20);
                        
                        // Deconflict high frequencies
                        if(freq > 1000) {
                            freq = ~freqManager.deconflictFreq(freq, existingFreqs);
                        };
                        existingFreqs.add(freq);
                        
                        // Check voice allocation
                        if(~voiceAllocator.canAddVoice) {
                            // Reduce amplitude based on voice count
                            amp = 0.1 / (numTrajectories.sqrt);
                            
                            synth = Synth(synthDefToUse, [
                                \freq, freq,
                                \amp, amp,
                                \pan, (i - (numTrajectories/2)) / (numTrajectories/2).max(1),
                                \mass, 1,
                                \velocity, 0,
                                \distance, 100,
                                \width, 0.5
                            ], state[\synthGroup]);
                            
                            if(synth.notNil) {
                                ~voiceAllocator.addVoice(synth, freq, i);
                                state[\synths] = state[\synths].add(synth);
                            };
                        } {
                            ("Skipping trajectory " ++ i ++ " - voice limit reached").postln;
                        };
                    };
                    
                    // Small delay between synth creation
                    if(i % 5 == 0) { 0.01.wait };
                };
                
                ("Created " ++ state[\synths].size ++ " synths").postln;
                ("CPU usage: " ++ s.avgCPU.round(0.1) ++ "%").postln;
                
                // Simplified playback loop
                while { state[\playbackPosition] < playDuration and: { state[\isPlaying] } } {
                    var currentTime = state[\playbackPosition];
                    
                    // Update trajectories (simplified)
                    data[\trajectories].do { |traj, i|
                        if(state[\synths][i].notNil and: { traj.size > 1 }) {
                            // Find interpolation points (simplified)
                            var point1, point2;
                            var freq, amp, pan;
                            
                            // Basic interpolation
                            block { |break|
                                (traj.size - 1).do { |j|
                                    var t1 = traj[j].x.linlin(0, 1200, 0, playDuration);
                                    var t2 = traj[j + 1].x.linlin(0, 1200, 0, playDuration);
                                    
                                    if(currentTime >= t1 and: { currentTime <= t2 }) {
                                        point1 = traj[j];
                                        point2 = traj[j + 1];
                                        
                                        var factor = (currentTime - t1) / (t2 - t1);
                                        freq = point1.y.blend(point2.y, factor).linlin(0, 670, 7500, 20);
                                        pan = point1.x.blend(point2.x, factor).linlin(0, 1200, -1, 1);
                                        amp = 0.1 / (numTrajectories.sqrt);
                                        
                                        state[\synths][i].set(
                                            \freq, freq,
                                            \amp, amp,
                                            \pan, pan
                                        );
                                        
                                        break.value;
                                    };
                                };
                            };
                        };
                    };
                    
                    state[\playbackPosition] = state[\playbackPosition] + frameTime;
                    
                    // Update display less frequently
                    if((state[\playbackPosition] * frameRate).asInteger % 5 == 0) {
                        { state[\drawView].refresh }.defer;
                    };
                    
                    frameTime.wait;
                };
                
                // Cleanup
                state[\isPlaying] = false;
                ~voiceAllocator.clear;
                state[\synths].do { |synth| if(synth.notNil) { synth.set(\gate, 0) } };
                state[\synths].clear;
                state[\playbackPosition] = 0;
                
                "Optimized playback complete".postln;
            };
        }.play;
    };
    
    // Execute the optimized playback
    ~nUPIC[\ui][\startPlayback].value;
};

// 5. CPU MONITOR
~startCPUMonitor = {
    if(~cpuMonitor.notNil) { ~cpuMonitor.stop };
    
    ~cpuMonitor = Task {
        loop {
            var cpu = s.avgCPU;
            var voices = if(~voiceAllocator.notNil) { 
                ~voiceAllocator.activeVoices.size 
            } { 0 };
            
            if(cpu > 60) {
                ("WARNING: High CPU usage: " ++ cpu.round(0.1) ++ "% with " ++ voices ++ " voices").postln;
                
                // Emergency reduction
                if(cpu > 80 and: { ~voiceAllocator.notNil }) {
                    "EMERGENCY: Reducing voices".postln;
                    ~voiceAllocator.maxVoices = (~voiceAllocator.maxVoices - 5).max(5);
                };
            };
            
            2.wait;  // Check every 2 seconds
        };
    }.play;
    
    "CPU monitor started".postln;
};

// 6. APPLY ALL OPTIMIZATIONS
~applyOptimizations = {
    "Applying all performance optimizations...".postln;
    
    // Load optimized SynthDefs
    ~createOptimizedSynthDefs.value;
    
    // Create voice allocator
    ~createVoiceAllocator.value;
    
    // Create frequency manager
    ~createFrequencyManager.value;
    
    // Start CPU monitor
    ~startCPUMonitor.value;
    
    // Add to available SynthDefs
    if(~nUPIC_SynthDefs.notNil) {
        ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\ultraLightVarSaw);
        ~nUPIC_SynthDefs[\available] = ~nUPIC_SynthDefs[\available].add(\optimizedSimple);
    };
    
    // Set server options for better performance
    s.options.memSize = 8192 * 32;  // Increase memory
    s.options.numWireBufs = 128;    // Increase wire buffers
    s.options.maxNodes = 2048;      // Increase max nodes
    
    "".postln;
    "=== OPTIMIZATIONS APPLIED ===".postln;
    "• Lightweight SynthDefs created".postln;
    "• Voice allocation system active (max " ++ ~voiceAllocator.maxVoices ++ " voices)".postln;
    "• Frequency deconfliction active for frequencies > 1000 Hz".postln;
    "• CPU monitor running".postln;
    "• Server settings optimized".postln;
    "".postln;
    "To use optimized playback:".postln;
    "  ~optimizedStartPlayback.value;".postln;
    "".postln;
    "Or it will automatically engage when >10 trajectories are detected".postln;
};

// Auto-apply optimizations
~applyOptimizations.value;

// Override the standard playback if many trajectories
if(~nUPIC[\ui][\startPlaybackOriginal].isNil) {
    ~nUPIC[\ui][\startPlaybackOriginal] = ~nUPIC[\ui][\startPlayback];
};

~nUPIC[\ui][\startPlayback] = {
    var data = ~nUPIC[\data];
    var numTraj = if(data.notNil and: { data[\trajectories].notNil }) { 
        data[\trajectories].size 
    } { 0 };
    
    if(numTraj > 10) {
        "Engaging optimized playback for " ++ numTraj ++ " trajectories".postln;
        ~optimizedStartPlayback.value;
    } {
        // Use original for small numbers
        ~nUPIC[\ui][\startPlaybackOriginal].value;
    };
};

"Performance optimizations loaded and active!".postln;
)
