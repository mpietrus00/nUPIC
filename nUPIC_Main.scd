// nUPIC Main Application
// Modular arc synthesis system inspired by Xenakis' UPIC
// Version 2.0.0

(
"Loading nUPIC (nu-UPIC) Arc Synthesis System...".postln;
"=================================================".postln;

// Initialize nUPIC namespace
~nUPIC = IdentityDictionary.new;

// Get the base path for nUPIC modules
// Handle case where nowExecutingPath might be nil
if(thisProcess.nowExecutingPath.notNil) {
    ~nUPIC_basePath = PathName(thisProcess.nowExecutingPath).pathOnly;
} {
    // Fallback: use current directory or prompt user
    "WARNING: thisProcess.nowExecutingPath is nil".postln;
    "Using current directory as base path".postln;
    ~nUPIC_basePath = File.getcwd +/+ "/";
};

// Load core modules
~loadnUPICModules = {
    var modules = [
        "Core/Constants.scd",
        "Audio/SynthDefs.scd",
        "Audio/SynthDefs_8ch_envelope.scd",  // Envelope-based 8ch synthdefs
        "Audio/upicWavetable.scd",
        "Core/ArcData.scd",
        "Core/PageData.scd",  // Multi-page composition support
        "UI/IntuitiveZoomSystem.scd",
        "UI/MainWindow.scd",
        "UI/Drawing.scd",
        "UI/MouseHandlers.scd",
        "UI/MouseHandlers_Spatial.scd",  // Spatial envelope support
        "UI/Controls.scd",
        "UI/AmplitudeEditor.scd",
        "UI/SpatializationEditor.scd",  // Spatialization editor
        "TABLES/WavetablePresets.scd",  // Wavetable preset library
        "UI/WavetableEditor.scd",
        "UI/PageSequencer.scd",  // Page sequence editor
        // "Utils/GridSystems.scd",
        // "Utils/FileIO.scd",
        // "Generators/BasicGenerators.scd",
        // "Generators/XenakisGenerators.scd",
        // "Generators/MathGenerators.scd",
        // "Audio/AudioEngine.scd"
    ];

    "Loading nUPIC modules:".postln;

    modules.do { |module|
        var path = ~nUPIC_basePath +/+ module;
        try {
            path.load;
            ("✓ " ++ module ++ " loaded").postln;
        } { |error|
            ("✗ Failed to load " ++ module ++ ": " ++ error.errorString).postln;
        };
    };
};

// Server configuration for optimal performance with audio sharing
~configurenUPICServer = {
    if(s.serverRunning.not) {
        // Use hard-coded values initially, will be updated when constants load
        s.options.memSize = 65536 * 2;
        s.options.numWireBufs = 128;
        s.options.maxNodes = 2048;
        s.options.numAudioBusChannels = 512;

        // Configure for audio sharing with other applications
        // This prevents SuperCollider from taking exclusive control of the audio interface
        s.options.device = nil; // Use default device

        // On macOS, try to use a sample rate that's compatible with system audio
        // Most apps use 44100 Hz, so this helps avoid conflicts
        s.options.sampleRate = 44100;

        // Set reasonable buffer sizes that don't conflict with system audio
        s.options.blockSize = 64;  // Smaller block size for better latency
        s.options.numBuffers = 1024; // Adequate buffering

        // Configure for 8-channel output
        s.options.numInputBusChannels = 2;
        s.options.numOutputBusChannels = 8;  // 8-channel surround output

        "Configured server options for nUPIC (audio sharing enabled)".postln;
        ("Memory: " ++ s.options.memSize ++ " samples").postln;
        ("Max nodes: " ++ s.options.maxNodes).postln;
        ("Sample rate: " ++ s.options.sampleRate ++ " Hz").postln;
        ("Block size: " ++ s.options.blockSize ++ " samples").postln;
        ("Output channels: " ++ s.options.numOutputBusChannels).postln;
    } {
        "Server already running with current settings".postln;
    };
};

// Initialize nUPIC system
~initnUPIC = {
    "Initializing nUPIC system...".postln;

    // Configure server
    ~configurenUPICServer.value;

    // Load modules
    ~loadnUPICModules.value;

    // Wait for server if needed
    s.waitForBoot {
        // Initialize arc data manager
        // Check if arcData was loaded properly
        if(~nUPIC.notNil and: { ~nUPIC.includesKey(\arcData) and: { ~nUPIC[\arcData].notNil } }) {
            if(~nUPIC[\arcData].includesKey(\manager) and: { ~nUPIC[\arcData][\manager].notNil }) {
                ~nUPIC[\data] = ~nUPIC[\arcData][\manager];
                "✓ ArcData manager loaded".postln;
            } {
                "ERROR: ArcData manager not found".postln;
                "~nUPIC.arcData keys: %".format(~nUPIC[\arcData].keys.asArray).postln;

                // Create an empty manager as fallback
                ~nUPIC[\data] = IdentityDictionary.new;
                "✓ Created empty data manager as fallback".postln;
            };
        } {
            "ERROR: arcData not loaded properly".postln;
            "Available nUPIC keys: %".format(~nUPIC.keys.asArray).postln;

            // Initialize empty structures as fallback
            ~nUPIC[\arcData] = IdentityDictionary.new;
            ~nUPIC[\data] = IdentityDictionary.new;
            "✓ Created empty data structures as fallback".postln;
        };

        // Ensure basic data arrays exist for GUI compatibility
        if(~nUPIC[\data][\arcs].isNil) {
            ~nUPIC[\data][\arcs] = List.new;
        };
        if(~nUPIC[\data][\amplitudeEnvelopes].isNil) {
            ~nUPIC[\data][\amplitudeEnvelopes] = List.new;
        };
        if(~nUPIC[\data][\arcSynthDefs].isNil) {
            ~nUPIC[\data][\arcSynthDefs] = List.new;
        };
        if(~nUPIC[\data][\selectedArcs].isNil) {
            ~nUPIC[\data][\selectedArcs] = Set.new;
        };

        // Initialize page system with first page
        if(~nUPIC[\pages].notNil and: { ~nUPIC[\pages][\manager].notNil }) {
            ~nUPIC[\pages][\manager].ensureInitialized.value;
            "✓ Page system initialized".postln;
        };

        "=================================================".postln;
        ~version = if(~nUPIC.notNil and: { ~nUPIC.includesKey(\constants) and: { ~nUPIC[\constants].notNil } }) {
            ~nUPIC[\constants][\version] ? "2.0.0"
        } { "2.0.0" };
        ("nUPIC " ++ ~version ++ " initialization complete!").postln;
        "Ready to create arc-based compositions.".postln;
        "=================================================".postln;

        // Launch the main interface
        if(~nUPIC.includesKey(\ui) and: { ~nUPIC[\ui].notNil } and: {
            ~nUPIC[\ui].includesKey(\createMainWindow) and: { ~nUPIC[\ui][\createMainWindow].notNil }
        }) {
            "Launching nUPIC GUI...".postln;
            ~nUPIC[\ui][\createMainWindow].value;
            
            // Auto-update SynthDef menu after window is created
            if(~nUPIC[\ui][\updateSynthDefMenusAfterLoad].notNil) {
                "Updating SynthDef menu with available synths...".postln;
                ~nUPIC[\ui][\updateSynthDefMenusAfterLoad].value;
            };

            // Auto-open Page Sequencer with Main UI
            if(~nUPIC[\pageSequencer].notNil and: { ~nUPIC[\pageSequencer][\open].notNil }) {
                "Launching Page Sequencer...".postln;
                { ~nUPIC[\pageSequencer][\open].value }.defer(0.5);
            };
        } {
            "GUI modules not loaded - using command-line mode".postln;
        };

        // Show available functions
        "Available nUPIC functions:".postln;
        "~nUPIC.data - Arc data manager".postln;
        "~nUPIC.constants - System constants".postln;
        "~nUPIC.colors - Color palette".postln;
        "~nUPIC.defaults - Default settings".postln;
        "~nUPIC.gridSystems - Tuning grid systems".postln;
        "~nUPIC.amplitudePresets - Amplitude envelope presets".postln;
        "".postln;
        "Data manager functions:".postln;
        "~nUPIC.data.addArc(arc, synthDef, ampEnv)".postln;
        "~nUPIC.data.selectArc(index)".postln;
        "~nUPIC.data.copy() / ~nUPIC.data.paste()".postln;
        "~nUPIC.data.undo() / ~nUPIC.data.redo()".postln;
        "~nUPIC.data.getStats()".postln;
        "".postln;
        "Example usage:".postln;
        "// Create a simple arc".postln;
        "~traj = List[".postln;
        "    (x: 100, y: 400, freq: 440),".postln;
        "    (x: 200, y: 300, freq: 880),".postln;
        "    (x: 300, y: 200, freq: 1320)".postln;
        "];".postln;
        "~nUPIC.data.addArc(~traj);".postln;
        "~nUPIC.data.getStats();".postln;
    };
};

// Launch nUPIC
~initnUPIC.value;

// Cleanup function
~cleannUPIC = {
    "Cleaning up nUPIC system...".postln;

    // Stop any running processes
    if(~nUPIC.includesKey(\audio) and: { ~nUPIC[\audio].notNil }) {
        try { ~nUPIC[\audio][\stopAll].value } { };
    };

    // Clear data
    if(~nUPIC.includesKey(\data) and: { ~nUPIC[\data].notNil }) {
        try { ~nUPIC[\data][\clearAll].value } { };
    };

    // Close UI windows
    if(~nUPIC.includesKey(\ui) and: { ~nUPIC[\ui].notNil }) {
        try { ~nUPIC[\ui][\closeAll].value } { };
    };

    "nUPIC cleanup complete".postln;
};

// Function to enable better audio sharing (call this if you have issues with other apps)
~enableAudioSharing = {
    "Configuring SuperCollider for better audio sharing...".postln;

    // Stop server if running
    if(s.serverRunning) {
        s.quit;
        "Server stopped. Reconfiguring...".postln;
        1.wait; // Give it time to fully stop
    };

    // Configure for maximum compatibility with other audio apps
    s.options.device = nil; // Use system default
    s.options.sampleRate = nil; // Use system sample rate
    s.options.blockSize = 128; // Larger block size for stability
    s.options.numBuffers = 2048; // More buffers

    // Reduce resource usage
    s.options.memSize = 32768; // Smaller memory footprint
    s.options.numInputBusChannels = 0; // No input if not needed
    s.options.numOutputBusChannels = 2; // Stereo output only
    s.options.maxNodes = 1024; // Fewer nodes

    "Audio sharing configuration applied. Restart nUPIC with ~initnUPIC.value".postln;
    "This should allow other apps to continue playing.".postln;
};

// Register cleanup on shutdown
ShutDown.add(~cleannUPIC);

"nUPIC main application loaded. Run ~initnUPIC.value to start.".postln;
"If other audio apps (Spotify, etc.) stop working, run ~enableAudioSharing.value".postln;
)
