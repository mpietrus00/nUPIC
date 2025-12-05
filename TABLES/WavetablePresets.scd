// Wavetable Presets for nUPIC
// Loads .wav files from TABLES directory and converts to wavetables
// Also includes programmatic presets as fallback

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\wavetablePresets] = ~nUPIC[\wavetablePresets] ?? ();

// Number of samples for wavetable
~nUPIC[\wavetablePresets][\numSamples] = 2048;

// Store the TABLES directory path
~nUPIC[\wavetablePresets][\tablesPath] = nil;

// Storage for loaded .wav files
~nUPIC[\wavetablePresets][\wavFiles] = List.new;
~nUPIC[\wavetablePresets][\wavData] = IdentityDictionary.new;

// Helper to normalize wavetable
~nUPIC[\wavetablePresets][\normalize] = { |data|
    var maxVal = data.abs.maxItem;
    if(maxVal > 0) { data / maxVal } { data };
};

// ============================================================================
// WAV FILE SCANNING AND LOADING
// ============================================================================

// Find TABLES directory
~nUPIC[\wavetablePresets][\findTablesPath] = {
    var candidates, found = nil;

    // Try multiple locations
    candidates = [
        // Relative to executing path
        if(thisProcess.nowExecutingPath.notNil) {
            PathName(thisProcess.nowExecutingPath).pathOnly +/+ "TABLES"
        } { nil },
        // Relative to nUPIC base path
        if(~nUPIC_basePath.notNil) {
            ~nUPIC_basePath +/+ "TABLES"
        } { nil },
        // Common locations
        Platform.userExtensionDir +/+ "nUPIC/TABLES",
        "~/nUPIC/TABLES".standardizePath
    ];

    candidates.do { |path|
        if(path.notNil and: { File.exists(path) }) {
            found = path;
        };
    };

    ~nUPIC[\wavetablePresets][\tablesPath] = found;
    found;
};

// Scan TABLES directory for .wav files
~nUPIC[\wavetablePresets][\scanWavFiles] = {
    var path = ~nUPIC[\wavetablePresets][\tablesPath];
    var files = List.new;

    if(path.isNil) {
        path = ~nUPIC[\wavetablePresets][\findTablesPath].value;
    };

    if(path.notNil and: { File.exists(path) }) {
        PathName(path).files.do { |file|
            var ext = file.extension.toLower;
            if(ext == "wav" or: { ext == "aif" } or: { ext == "aiff" }) {
                files.add(file.fileName);
            };
        };
        ("Found " ++ files.size ++ " audio files in TABLES directory").postln;
    } {
        "TABLES directory not found - using programmatic presets only".postln;
    };

    ~nUPIC[\wavetablePresets][\wavFiles] = files;
    files;
};

// Load a .wav file and resample to wavetable size
~nUPIC[\wavetablePresets][\loadWavFile] = { |filename, action|
    var path = ~nUPIC[\wavetablePresets][\tablesPath];
    var fullPath, numSamples;

    numSamples = ~nUPIC[\wavetablePresets][\numSamples];

    if(path.notNil) {
        fullPath = path +/+ filename;

        if(File.exists(fullPath)) {
            // Load into a temporary buffer
            Buffer.read(Server.default, fullPath, action: { |buf|
                var data, resampled, step, i, idx, frac, v0, v1;

                // Get the buffer data
                buf.loadToFloatArray(action: { |floatArray|
                    var numChannels = buf.numChannels;
                    var sourceLen = floatArray.size / numChannels;

                    // If stereo, mix to mono
                    if(numChannels > 1) {
                        data = Array.fill(sourceLen.asInteger, { |i|
                            var sum = 0;
                            numChannels.do { |ch|
                                sum = sum + floatArray[i * numChannels + ch];
                            };
                            sum / numChannels
                        });
                    } {
                        data = floatArray.asArray;
                    };

                    // Resample to 2048 samples using linear interpolation
                    step = data.size / numSamples;
                    resampled = Array.fill(numSamples, { |i|
                        idx = (i * step).floor.asInteger;
                        frac = (i * step) - idx;
                        v0 = data[idx.clip(0, data.size - 1)];
                        v1 = data[(idx + 1).clip(0, data.size - 1)];
                        v0 + (frac * (v1 - v0))
                    });

                    // Normalize
                    resampled = ~nUPIC[\wavetablePresets][\normalize].value(resampled);

                    // Store in cache
                    ~nUPIC[\wavetablePresets][\wavData][filename.asSymbol] = resampled;

                    // Free the temp buffer
                    buf.free;

                    // Call the action with the data
                    if(action.notNil) {
                        action.value(resampled);
                    };

                    ("Loaded wavetable from: " ++ filename).postln;
                });
            });
        } {
            ("File not found: " ++ fullPath).warn;
            nil
        };
    } {
        "TABLES directory not set".warn;
        nil
    };
};

// Get cached wav data or load it
~nUPIC[\wavetablePresets][\getWavData] = { |filename, action|
    var cached = ~nUPIC[\wavetablePresets][\wavData][filename.asSymbol];

    if(cached.notNil) {
        if(action.notNil) { action.value(cached) };
        cached
    } {
        ~nUPIC[\wavetablePresets][\loadWavFile].value(filename, action);
        nil  // Data will be provided via action callback
    };
};

// List all .wav files
~nUPIC[\wavetablePresets][\listWavFiles] = {
    if(~nUPIC[\wavetablePresets][\wavFiles].size == 0) {
        ~nUPIC[\wavetablePresets][\scanWavFiles].value;
    };
    ~nUPIC[\wavetablePresets][\wavFiles];
};

// Load wav to arc (async)
~nUPIC[\wavetablePresets][\loadWavToTrajectory] = { |filename, arcIndex|
    ~nUPIC[\wavetablePresets][\getWavData].value(filename, { |data|
        if(data.notNil) {
            ~nUPIC[\arcs][\setWavetable].value(arcIndex, data);
            ("Loaded " ++ filename ++ " to arc " ++ arcIndex).postln;
        };
    });
};

// ============================================================================
// PROGRAMMATIC PRESETS (fallback)
// ============================================================================

~nUPIC[\wavetablePresets][\presets] = (
    \sine: { |n = 2048| Array.fill(n, { |i| sin(2pi * i / n) }) },
    \saw: { |n = 2048| Array.fill(n, { |i| (2 * i / n) - 1 }) },
    \square: { |n = 2048| Array.fill(n, { |i| if(i < (n / 2), 1, -1) }) },
    \triangle: { |n = 2048|
        Array.fill(n, { |i|
            var phase = i / n;
            if(phase < 0.5, { 4 * phase - 1 }, { 3 - (4 * phase) })
        })
    },
    \organFull: { |n = 2048|
        var sig = Signal.sineFill(n, Array.fill(16, { |i| 1 / (i + 1) }));
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    },
    \brass: { |n = 2048|
        var sig = Signal.sineFill(n, [1, 0.7, 0.5, 0.6, 0.4, 0.3, 0.2, 0.15]);
        ~nUPIC[\wavetablePresets][\normalize].value(sig.asArray);
    }
);

// Get programmatic preset data
~nUPIC[\wavetablePresets][\get] = { |name|
    var preset = ~nUPIC[\wavetablePresets][\presets][name];
    if(preset.notNil) {
        preset.value(~nUPIC[\wavetablePresets][\numSamples]);
    } { nil };
};

// ============================================================================
// COMBINED API
// ============================================================================

// List all available wavetables (wav files + programmatic)
~nUPIC[\wavetablePresets][\list] = {
    var wavFiles = ~nUPIC[\wavetablePresets][\listWavFiles].value;
    var presets = ~nUPIC[\wavetablePresets][\presets].keys.asArray;

    // Return wav files first, then programmatic presets
    wavFiles ++ presets.collect(_.asString);
};

// Load any wavetable to arc (handles both wav and programmatic)
~nUPIC[\wavetablePresets][\loadToTrajectory] = { |name, arcIndex|
    var nameStr = name.asString;
    var wavFiles = ~nUPIC[\wavetablePresets][\wavFiles];

    if(wavFiles.includes(nameStr)) {
        // It's a wav file
        ~nUPIC[\wavetablePresets][\loadWavToTrajectory].value(nameStr, arcIndex);
    } {
        // Try programmatic preset
        var data = ~nUPIC[\wavetablePresets][\get].value(name.asSymbol);
        if(data.notNil) {
            ~nUPIC[\arcs][\setWavetable].value(arcIndex, data);
            ("Loaded preset " ++ name ++ " to arc " ++ arcIndex).postln;
        } {
            ("Wavetable not found: " ++ name).warn;
        };
    };
};

// Categories for programmatic presets
~nUPIC[\wavetablePresets][\categories] = (
    \basic: [\sine, \saw, \square, \triangle],
    \synth: [\organFull, \brass]
);

// ============================================================================
// INITIALIZATION
// ============================================================================

// Auto-scan for wav files on load
~nUPIC[\wavetablePresets][\findTablesPath].value;
~nUPIC[\wavetablePresets][\scanWavFiles].value;

"Wavetable Presets loaded".postln;
)
