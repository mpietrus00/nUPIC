// nUPIC Core Constants and Configuration
// Central configuration for the nUPIC trajectory synthesis system

(
// Initialize nUPIC namespace
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };

// Core constants
~nUPIC[\constants] = (
    // System limits
    maxSynths: 200,
    maxTrajectories: 200,
    maxUndoSteps: 50,
    
    // UI dimensions
    defaultWidth: 1200,
    defaultHeight: 670,  // Increased by 20px for better proportions
    controlPanelHeight: 32,  // Reduced from 240 for compact controls
    
    // Timing and performance
    frameRate: 60,  // Increased to 60 Hz for smoother parameter updates
    audioFrameRate: 120, // Even higher rate for audio parameter updates
    defaultDuration: 10, // seconds
    maxDuration: 600, // 10 minutes
    
    // Smoothness settings
    useHighResAudio: true, // Enable high resolution audio updates
    lagTimeFreq: 0.1,     // Lag time for frequency changes (seconds)
    lagTimeAmp: 0.05,     // Lag time for amplitude changes (seconds)
    lagTimePan: 0.08,     // Lag time for panning changes (seconds)
    
    // Audio parameters
    defaultSampleRate: 44100,
    freqMin: 20,   // Set back to 20 Hz as requested
    freqMax: 7500,
    
    // Interaction
    dragThreshold: 10,
    eraseRadius: 20,
    clickThreshold: 10,
    moveStep: 10,
    
    // Drawing
    trajectoryWidth: 2,
    selectedWidth: 4,
    gridOpacity: 0.5,
    
    // File system
    presetExtension: ".nupic",
    presetDirectory: "nUPIC_Projects",
    
    // Version
    version: "2.0.0",
    fileFormatVersion: "2.0"
);

// Color palette - Clean Professional theme
~nUPIC[\colors] = (
    // Main UI colors with clean light gray theme
    background: Color.white,  // Keep drawing areas white for clarity
    systemBackground: Color.gray(0.9),  // Light gray for system areas
    controlBackground: Color.new(205/255, 250/255, 205/255),  // Light green for control areas (rgb 205, 250, 205)
    grid: Color.gray(0.3, 0.5),
    gridText: Color.gray(0.4),
    trajectory: { |index, maxIndex = 200| 
        Color.hsv((index / maxIndex) * 0.8, 0.7, 0.9) 
    },
    selected: Color.blue,
    eraseMode: Color.red,
    selectMode: Color.blue,
    drawMode: Color.gray,
    playback: Color.green,
    playbackLine: Color.red,
    
    // Amplitude editor colors
    amplitudeEnvelope: Color.red.alpha_(0.6),
    amplitudeStroke: Color.red,
    amplitudeBackground: Color.white,
    amplitudeGrid: Color.gray(0.8, 0.5),
    
    // Button colors
    buttonNormal: Color.gray(0.9),
    buttonPressed: Color.gray(0.7),
    buttonActive: Color.blue.alpha_(0.8),
    buttonDanger: Color.red.alpha_(0.8),
    buttonSuccess: Color.green.alpha_(0.8)
);

// Default settings
~nUPIC[\defaults] = (
    // Playback
    playDuration: 10,
    
    // Zoom
    zoomFreqMin: 20,   // Set back to 20 Hz as requested
    zoomFreqMax: 7500,
    zoomTimeMin: 0,
    zoomTimeMax: 1,
    
    // Grid
    showGrid: true,
    gridType: \equalTemperament,
    
    // Audio
    synthDefNames: [\upicWavetable, \simpleGravObject, \trajectoryVarSaw, \testOrbit],
    defaultSynthDef: \upicWavetable,
    
    // UI modes
    drawMode: \frequency, // \frequency or \amplitude
    eraseMode: false,
    selectMode: false,
    
    // Server configuration
    serverMemSize: 65536 * 2,
    serverWireBufs: 128,
    serverMaxNodes: 2048,
    serverAudioBusChannels: 512
);

// Defaults - reactive settings that notify UI when changed
// Values stored directly for backwards compatibility: defaults[\playDuration]
// Use defaults.setValue(\key, value) to update and auto-refresh UI
~nUPIC[\defaults] = (
    // Actual values (backwards compatible - direct access works)
    defaultSynthDef: \upicWavetable,
    playDuration: 10,
    showGrid: true,
    gridType: \equalTemperament,

    // Dependants storage
    _dependants: IdentitySet.new,

    // Set value and notify dependants (named setValue to avoid Event:set conflict)
    setValue: { |self, key, value|
        var oldValue = self[key];
        self[key] = value;
        if(oldValue != value) {
            ("defaults[" ++ key ++ "] changed: " ++ oldValue ++ " -> " ++ value).postln;
            self.notifyChanged(key, value, oldValue);
        };
        value
    },

    // Add dependant (UI element or other listener)
    addDependant: { |self, dep|
        self['_dependants'].add(dep);
    },

    // Remove dependant
    removeDependant: { |self, dep|
        self['_dependants'].remove(dep);
    },

    // Notify all dependants of change
    notifyChanged: { |self, what, value, oldValue|
        self['_dependants'].do { |dep|
            {
                if(dep.respondsTo(\update)) {
                    dep.update(self, what, value, oldValue);
                } {
                    if(dep.isKindOf(Function)) {
                        dep.value(what, value, oldValue);
                    };
                };
            }.defer;
        };
    }
);

// Grid system definitions
~nUPIC[\gridSystems] = (
    equalTemperament: (
        name: "Equal Temperament (12-TET)",
        baseFreq: 440,
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            // Generate actual semitones, not arbitrary subdivisions
            var semitone = 2.pow(1/12);
            var startNote = (minFreq / baseFreq).log2 * 12;
            var endNote = (maxFreq / baseFreq).log2 * 12;
            var freqs = [];
            
            // Generate every semitone in the range
            (startNote.floor..(endNote.ceil)).do { |noteNum|
                var freq = baseFreq * semitone.pow(noteNum);
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    fokker31: (
        name: "31-tone Equal Temperament (Fokker)",
        baseFreq: 440,
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            // Generate ALL 31 steps per octave, not arbitrary subdivisions
            var step31 = 2.pow(1/31);
            var startStep = (minFreq / baseFreq).log2 * 31;
            var endStep = (maxFreq / baseFreq).log2 * 31;
            var freqs = [];
            
            // Generate every 31-TET step in the range
            (startStep.floor..(endStep.ceil)).do { |stepNum|
                var freq = baseFreq * step31.pow(stepNum);
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    harmonicSeries: (
        name: "Harmonic Series",
        baseFreq: 110, // A2
        calculation: { |baseFreq = 110, minFreq, maxFreq, numLines|
            // Generate ALL harmonics in range, not arbitrary subdivisions
            var fundamental = baseFreq;
            var startHarm = (minFreq / fundamental).ceil.max(1);
            var endHarm = (maxFreq / fundamental).floor;
            var freqs = [];
            
            // Generate every harmonic in the range
            (startHarm..endHarm).do { |harm|
                var freq = fundamental * harm;
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    just: (
        name: "Just Intonation",
        baseFreq: 440,
        ratios: [1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2/1],
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            var justRatios = [1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2/1];
            var octave = (minFreq / baseFreq).log2.floor;
            var freqs = [];
            
            while { baseFreq * (2.pow(octave)) < maxFreq } {
                justRatios.do { |ratio|
                    var freq = baseFreq * (2.pow(octave)) * ratio;
                    if(freq >= minFreq and: { freq <= maxFreq }) {
                        freqs = freqs.add(freq);
                    };
                };
                octave = octave + 1;
            };
            freqs;
        }
    ),
    
    quarterTone: (
        name: "Quarter-tone (24-TET)",
        baseFreq: 440,
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            // Generate ALL 24 quarter-tone steps per octave
            var quarterStep = 2.pow(1/24);
            var startQuarter = (minFreq / baseFreq).log2 * 24;
            var endQuarter = (maxFreq / baseFreq).log2 * 24;
            var freqs = [];
            
            // Generate every quarter-tone step in the range
            (startQuarter.floor..(endQuarter.ceil)).do { |quarterNum|
                var freq = baseFreq * quarterStep.pow(quarterNum);
                if(freq >= minFreq and: { freq <= maxFreq }) {
                    freqs = freqs.add(freq);
                };
            };
            freqs;
        }
    ),
    
    pythagorean: (
        name: "Pythagorean Tuning",
        baseFreq: 440,
        ratios: [1/1, 256/243, 9/8, 32/27, 81/64, 4/3, 729/512, 3/2, 128/81, 27/16, 16/9, 243/128, 2/1],
        calculation: { |baseFreq, minFreq, maxFreq, numLines|
            var pythRatios = [1/1, 256/243, 9/8, 32/27, 81/64, 4/3, 729/512, 3/2, 128/81, 27/16, 16/9, 243/128, 2/1];
            var octave = (minFreq / baseFreq).log2.floor;
            var freqs = [];
            
            while { baseFreq * (2.pow(octave)) < maxFreq } {
                pythRatios.do { |ratio|
                    var freq = baseFreq * (2.pow(octave)) * ratio;
                    if(freq >= minFreq and: { freq <= maxFreq }) {
                        freqs = freqs.add(freq);
                    };
                };
                octave = octave + 1;
            };
            freqs;
        }
    )
);

// Amplitude envelope presets
~nUPIC[\amplitudePresets] = (
    fadeIn: { |width|
        var env = List.new;
        10.do { |i|
            env.add((x: i * width / 10, amp: i / 10));
        };
        env.add((x: width, amp: 1.0));
        env
    },
    
    fadeOut: { |width|
        var env = List.new;
        env.add((x: 0, amp: 1.0));
        10.do { |i|
            env.add((x: (i + 1) * width / 10, amp: 1.0 - ((i + 1) / 10)));
        };
        env
    },
    
    fadeInOut: { |width|
        var env = List.new;
        5.do { |i|
            env.add((x: i * width / 10, amp: i / 5));
        };
        5.do { |i|
            env.add((x: (i + 5) * width / 10, amp: 1.0 - (i / 5)));
        };
        env
    },
    
    constant: { |width|
        List[(x: 0, amp: 0.7), (x: width, amp: 0.7)]
    },
    
    pulse: { |width|
        var env = List.new;
        20.do { |i|
            var amp = if(i.even) { 0.9 } { 0.1 };
            env.add((x: i * width / 20, amp: amp));
        };
        env.add((x: width, amp: 0.1));
        env
    },
    
    swell: { |width|
        var env = List.new;
        var numSwells = 3;
        (numSwells * 20).do { |i|
            var phase = (i / 20 * 2pi);
            var amp = phase.sin.linlin(-1, 1, 0.1, 0.9);
            env.add((x: i * width / (numSwells * 20), amp: amp));
        };
        env
    },
    
    percussive: { |width|
        List[
            (x: 0, amp: 0.0),
            (x: width * 0.02, amp: 1.0),
            (x: width * 0.1, amp: 0.3),
            (x: width * 0.5, amp: 0.1),
            (x: width, amp: 0.0)
        ]
    },
    
    reverse: { |width|
        List[
            (x: 0, amp: 0.0),
            (x: width * 0.7, amp: 0.1),
            (x: width * 0.95, amp: 1.0),
            (x: width, amp: 0.0)
        ]
    }
);

"nUPIC constants and configuration loaded".postln;
)
