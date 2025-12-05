// Wavetable Presets for nUPIC
// Collection of classic and advanced wavetable presets
// Each preset generates 2048 samples in range -1 to 1

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetablePresets] = ~nUPIC[\wavetablePresets] ?? ();

// Helper to normalize wavetable
~nUPIC[\wavetablePresets][\normalize] = { |data|
    var maxVal = data.abs.maxItem;
    if(maxVal > 0) { data / maxVal } { data };
};

// Number of samples
~nUPIC[\wavetablePresets][\numSamples] = 2048;

// ============================================================================
// PRESET DEFINITIONS
// ============================================================================
// Each preset is a function that generates the wavetable array

~nUPIC[\wavetablePresets][\presets] = (

    // === BASIC WAVEFORMS ===

    \sine: { |n = 2048|
        Array.fill(n, { |i| sin(2pi * i / n) });
    },

    \cosine: { |n = 2048|
        Array.fill(n, { |i| cos(2pi * i / n) });
    },

    \saw: { |n = 2048|
        Array.fill(n, { |i| (2 * i / n) - 1 });
    },

    \sawDown: { |n = 2048|
        Array.fill(n, { |i| 1 - (2 * i / n) });
    },

    \square: { |n = 2048|
        Array.fill(n, { |i| if(i < (n / 2), 1, -1) });
    },

    \triangle: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n;
            if(phase < 0.5,
                { 4 * phase - 1 },
                { 3 - (4 * phase) }
            )
        });
    },

    // === PULSE WIDTH VARIANTS ===

    \pulse10: { |n = 2048|
        Array.fill(n, { |i| if(i < (n * 0.1), 1, -1) });
    },

    \pulse25: { |n = 2048|
        Array.fill(n, { |i| if(i < (n * 0.25), 1, -1) });
    },

    \pulse75: { |n = 2048|
        Array.fill(n, { |i| if(i < (n * 0.75), 1, -1) });
    },

    // === HARMONIC COMBINATIONS ===

    \organFlute: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0, 0, 0.1, 0, 0, 0, 0.01]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \organReed: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0.8, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \organPipe: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0, 0.5, 0, 0.25, 0, 0.125, 0]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \organFull: { |n = 2048|
        var sig = Signal.sineFill(n, Array.fill(16, { |i| 1 / (i + 1) }));
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \brass: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0.7, 0.5, 0.6, 0.4, 0.3, 0.2, 0.15]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \strings: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0.5, 0.3, 0.4, 0.2, 0.15, 0.1, 0.08]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \clarinet: { |n = 2048|
        // Odd harmonics only (like clarinet)
        var sig = Signal.sineFill(n, [1, 0, 0.75, 0, 0.5, 0, 0.25, 0, 0.1]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \oboe: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0.8, 0.6, 0.7, 0.5, 0.4, 0.3, 0.35, 0.2, 0.15]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    // === VOCAL / FORMANT ===

    \vowelA: { |n = 2048|
        var sig = Signal.sineFill(n,
            Array.fill(32, { |i|
                var f = i + 1;
                // Formants at ~730, 1090, 2440 Hz (relative to fundamental)
                exp(-0.5 * ((f - 7).squared / 4)) * 0.8 +
                exp(-0.5 * ((f - 11).squared / 6)) * 0.5 +
                exp(-0.5 * ((f - 24).squared / 10)) * 0.3
            })
        );
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \vowelE: { |n = 2048|
        var sig = Signal.sineFill(n,
            Array.fill(32, { |i|
                var f = i + 1;
                // Formants at ~400, 2000, 2550 Hz
                exp(-0.5 * ((f - 4).squared / 3)) * 0.8 +
                exp(-0.5 * ((f - 20).squared / 8)) * 0.5 +
                exp(-0.5 * ((f - 25).squared / 6)) * 0.3
            })
        );
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \vowelI: { |n = 2048|
        var sig = Signal.sineFill(n,
            Array.fill(32, { |i|
                var f = i + 1;
                // Formants at ~290, 2300, 3100 Hz
                exp(-0.5 * ((f - 3).squared / 2)) * 0.8 +
                exp(-0.5 * ((f - 23).squared / 8)) * 0.6 +
                exp(-0.5 * ((f - 31).squared / 6)) * 0.3
            })
        );
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \vowelO: { |n = 2048|
        var sig = Signal.sineFill(n,
            Array.fill(32, { |i|
                var f = i + 1;
                // Formants at ~570, 840, 2410 Hz
                exp(-0.5 * ((f - 6).squared / 3)) * 0.8 +
                exp(-0.5 * ((f - 8).squared / 4)) * 0.6 +
                exp(-0.5 * ((f - 24).squared / 8)) * 0.3
            })
        );
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \vowelU: { |n = 2048|
        var sig = Signal.sineFill(n,
            Array.fill(32, { |i|
                var f = i + 1;
                // Formants at ~320, 920, 2200 Hz
                exp(-0.5 * ((f - 3).squared / 2)) * 0.8 +
                exp(-0.5 * ((f - 9).squared / 4)) * 0.5 +
                exp(-0.5 * ((f - 22).squared / 8)) * 0.3
            })
        );
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    // === FM SYNTHESIS ===

    \fmBell: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n * 2pi;
            sin(phase + (2.5 * sin(7 * phase)))
        }).normalize;
    },

    \fmMetallic: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n * 2pi;
            sin(phase + (5 * sin(11 * phase) * sin(3 * phase)))
        }).normalize;
    },

    \fmWarm: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n * 2pi;
            sin(phase + (2 * sin(2 * phase)))
        }).normalize;
    },

    \fmBright: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n * 2pi;
            sin(phase + (4 * sin(5 * phase)))
        }).normalize;
    },

    // === WAVESHAPING ===

    \softClip: { |n = 2048|
        Array.fill(n, { |i|
            var x = (2 * i / n) - 1;
            (1.5 * x) / (1 + (0.5 * x.abs))
        }).normalize;
    },

    \hardClip: { |n = 2048|
        Array.fill(n, { |i|
            var x = sin(2pi * i / n) * 1.5;
            x.clip(-0.8, 0.8)
        }).normalize;
    },

    \cubic: { |n = 2048|
        Array.fill(n, { |i|
            var x = (2 * i / n) - 1;
            (3 * x) - x.cubed
        }).normalize;
    },

    \foldback: { |n = 2048|
        Array.fill(n, { |i|
            var x = sin(2pi * i / n) * 2;
            x.fold(-1, 1)
        }).normalize;
    },

    \wrap: { |n = 2048|
        Array.fill(n, { |i|
            var x = sin(2pi * i / n) * 2;
            x.wrap(-1, 1)
        }).normalize;
    },

    // === COMPLEX / TEXTURAL ===

    \supersaw: { |n = 2048|
        var sig = Array.fill(n, 0);
        7.do { |j|
            var detune = (j - 3) * 0.008;
            sig = sig + Array.fill(n, { |i|
                var phase = (i / n * (1 + detune));
                (2 * phase.mod(1)) - 1
            });
        };
        sig.normalize;
    },

    \pwmSquare: { |n = 2048|
        var sig = Array.fill(n, 0);
        8.do { |j|
            var width = 0.3 + (j * 0.05);
            sig = sig + Array.fill(n, { |i|
                if((i / n).mod(1) < width, 0.5, -0.5)
            });
        };
        sig.normalize;
    },

    \bitcrush: { |n = 2048|
        Array.fill(n, { |i|
            var val = sin(2pi * i / n);
            (val * 8).round / 8
        });
    },

    \digital: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n;
            ((sin(2pi * phase) * 4).round / 4) +
            ((sin(4pi * phase) * 2).round / 2) * 0.3
        }).normalize;
    },

    // === XENAKIS / EXPERIMENTAL ===

    \gendy: { |n = 2048|
        var points = 12;
        var yVals = Array.fill(points, { rrand(-1.0, 1.0) });
        var xVals = (0..points-1) / (points - 1);
        Array.fill(n, { |i|
            var phase = i / n;
            var idx = (phase * (points - 1)).floor.asInteger;
            var nextIdx = (idx + 1).min(points - 1);
            var t = (phase * (points - 1)) - idx;
            yVals[idx].blend(yVals[nextIdx], t)
        });
    },

    \chaotic: { |n = 2048|
        var x = 0.1, r = 3.9;
        Array.fill(n, { |i|
            x = r * x * (1 - x);  // Logistic map
            (x * 2) - 1
        });
    },

    \noise: { |n = 2048|
        Array.fill(n, { rrand(-1.0, 1.0) });
    },

    \smoothNoise: { |n = 2048|
        var raw = Array.fill(n, { rrand(-1.0, 1.0) });
        var smoothed = raw.copy;
        5.do {
            smoothed = smoothed.collect { |val, i|
                var prev = smoothed[(i - 1) % n];
                var next = smoothed[(i + 1) % n];
                (prev + (val * 2) + next) / 4
            }
        };
        smoothed.normalize;
    },

    // === CLASSIC SYNTH EMULATIONS ===

    \moog: { |n = 2048|
        // Moog-like thick saw
        var sig = Signal.sineFill(n, Array.fill(32, { |i|
            1 / (i + 1) * exp(-0.05 * i)
        }));
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },

    \prophet: { |n = 2048|
        // Prophet-like fat sound
        var sig = Array.fill(n, 0);
        3.do { |j|
            var detune = (j - 1) * 0.005;
            sig = sig + Array.fill(n, { |i|
                var phase = i / n * (1 + detune) * 2pi;
                sin(phase) * 0.5 + ((2 * (i / n * (1 + detune)).mod(1)) - 1) * 0.5
            });
        };
        sig.normalize;
    },

    \dx7: { |n = 2048|
        // DX7-like FM bell
        Array.fill(n, { |i|
            var phase = i / n * 2pi;
            sin(phase + (1.4 * sin(14 * phase)) + (0.7 * sin(7 * phase)))
        }).normalize;
    },

    \ppg: { |n = 2048|
        // PPG-like digital wavetable
        Array.fill(n, { |i|
            var phase = i / n;
            var saw = (2 * phase) - 1;
            var sq = if(phase < 0.5, 1, -1);
            (saw * 0.6) + (sq * 0.4)
        });
    },

    // === PERCUSSION ===

    \kick: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n;
            sin(2pi * phase * (1 + (20 * exp(-8 * phase))))
        }).normalize;
    },

    \hat: { |n = 2048|
        var sig = Array.fill(n, { rrand(-1.0, 1.0) });
        // High-pass character
        sig.differentiate.normalize;
    },

    \pluck: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n;
            sin(2pi * phase) * exp(-3 * phase) +
            sin(4pi * phase) * exp(-4 * phase) * 0.5 +
            sin(6pi * phase) * exp(-5 * phase) * 0.25
        }).normalize;
    }
);

// ============================================================================
// API FUNCTIONS
// ============================================================================

// Get list of all preset names (sorted)
~nUPIC[\wavetablePresets][\list] = {
    ~nUPIC[\wavetablePresets][\presets].keys.asArray.sort;
};

// Get preset data by name
~nUPIC[\wavetablePresets][\get] = { |name|
    var preset = ~nUPIC[\wavetablePresets][\presets][name];
    if(preset.notNil) {
        preset.value(~nUPIC[\wavetablePresets][\numSamples]);
    } {
        nil
    };
};

// Get organized categories
~nUPIC[\wavetablePresets][\categories] = (
    \basic: [\sine, \cosine, \saw, \sawDown, \square, \triangle],
    \pulse: [\pulse10, \pulse25, \pulse75],
    \organ: [\organFlute, \organReed, \organPipe, \organFull],
    \acoustic: [\brass, \strings, \clarinet, \oboe],
    \vocal: [\vowelA, \vowelE, \vowelI, \vowelO, \vowelU],
    \fm: [\fmBell, \fmMetallic, \fmWarm, \fmBright],
    \waveshape: [\softClip, \hardClip, \cubic, \foldback, \wrap],
    \complex: [\supersaw, \pwmSquare, \bitcrush, \digital],
    \experimental: [\gendy, \chaotic, \noise, \smoothNoise],
    \synth: [\moog, \prophet, \dx7, \ppg],
    \percussion: [\kick, \hat, \pluck]
);

// Load preset into a trajectory
~nUPIC[\wavetablePresets][\loadToTrajectory] = { |presetName, trajectoryIndex|
    var data = ~nUPIC[\wavetablePresets][\get].value(presetName);
    if(data.notNil) {
        ~nUPIC[\trajectories][\setWavetable].value(trajectoryIndex, data);
        ("Loaded wavetable preset '" ++ presetName ++ "' to trajectory " ++ trajectoryIndex).postln;
        true
    } {
        ("Preset '" ++ presetName ++ "' not found").warn;
        false
    };
};

"Wavetable Presets loaded (" ++ ~nUPIC[\wavetablePresets][\list].value.size ++ " presets)".postln;
)
