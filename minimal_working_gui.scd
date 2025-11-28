// Minimal Working nUPIC GUI
// This file creates a complete working nUPIC interface with all controls visible
// Load this to test the full system

(
"Loading minimal working nUPIC GUI...".postln;

// Initialize nUPIC namespace
~nUPIC = IdentityDictionary.new;

// Basic constants
~nUPIC[\constants] = (
    defaultWidth: 1200,
    defaultHeight: 800,
    controlPanelHeight: 250,
    freqMin: 20,
    freqMax: 7500,
    frameRate: 30
);

// Colors
~nUPIC[\colors] = (
    background: Color.white,
    grid: Color.gray(0.3, 0.5),
    trajectory: { |index, maxIndex = 200| 
        Color.hsv((index / maxIndex) * 0.8, 0.7, 0.9) 
    },
    selected: Color.blue,
    eraseMode: Color.red,
    drawMode: Color.gray
);

// Basic data structures
~nUPIC[\data] = (
    trajectories: List.new,
    amplitudeEnvelopes: List.new,
    selectedTrajectories: Set.new,
    trajectorySynthDefs: List.new
);

// UI namespace
~nUPIC[\ui] = IdentityDictionary.new;

// Create main window function
~nUPIC[\ui][\createMainWindow] = {
    var window, drawView, controlsHeight;
    var width, height, constants;
    var yStart, state;
    var isDrawing = false, currentTrajectory;
    
    constants = ~nUPIC[\constants];
    width = constants[\defaultWidth];
    height = constants[\defaultHeight]; 
    controlsHeight = constants[\controlPanelHeight];
    
    // Initialize UI state
    state = (
        window: nil,
        drawView: nil,
        isPlaying: false,
        playDuration: 10,
        zoomFreqMin: 20,
        zoomFreqMax: 7500,
        zoomTimeMin: 0,
        zoomTimeMax: 1,
        showGrid: true,
        gridType: \equalTemperament,
        eraseMode: false,
        selectMode: false,
        controls: IdentityDictionary.new
    );
    
    ~nUPIC[\ui][\state] = state;
    
    // Create main window
    window = Window("nUPIC - Trajectory Synthesis System", 
        Rect(100, 100, width, height + controlsHeight));
    window.background = Color.white;
    
    state[\window] = window;
    
    // Create main drawing view
    drawView = UserView(window, Rect(0, 0, width, height));
    drawView.background = Color.white;
    state[\drawView] = drawView;
    
    // Drawing function for the main view
    drawView.drawFunc = {
        var data = ~nUPIC[\data];
        
        // Clear background
        Pen.fillColor = Color.white;
        Pen.fillRect(Rect(0, 0, width, height));
        
        // Draw grid if enabled
        if(state[\showGrid]) {
            Pen.strokeColor = Color.gray(0.8);
            Pen.width = 1;
            
            // Horizontal lines (frequency)
            10.do { |i|
                var y = i * (height / 10);
                Pen.line(Point(0, y), Point(width, y));
                Pen.stroke;
            };
            
            // Vertical lines (time)
            12.do { |i|
                var x = i * (width / 12);
                Pen.line(Point(x, 0), Point(x, height));
                Pen.stroke;
            };
        };
        
        // Draw trajectories
        if(data[\trajectories].notNil) {
            data[\trajectories].do { |traj, trajIndex|
                if(traj.notNil and: { traj.size > 0 }) {
                    var isSelected = data[\selectedTrajectories].includes(trajIndex);
                    var color = ~nUPIC[\colors][\trajectory].value(trajIndex);
                    
                    if(isSelected) {
                        Pen.strokeColor = Color.red;
                        Pen.width = 4;
                    } {
                        Pen.strokeColor = color;
                        Pen.width = 2;
                    };
                    
                    // Draw trajectory line
                    traj.do { |point, i|
                        var x = if(point.isKindOf(Event)) { point.x } { point.x };
                        var y = if(point.isKindOf(Event)) { point.y } { point.y };
                        
                        if(i == 0) {
                            Pen.moveTo(Point(x, y));
                        } {
                            Pen.lineTo(Point(x, y));
                        };
                    };
                    Pen.stroke;
                };
            };
        };
        
        // Draw playback cursor if playing
        if(state[\isPlaying]) {
            var playX = state[\playbackPosition] / state[\playDuration] * width;
            Pen.strokeColor = Color.red;
            Pen.width = 2;
            Pen.line(Point(playX, 0), Point(playX, height));
            Pen.stroke;
        };
    };
    
    // === CREATE ALL CONTROLS ===
    yStart = height + 10;
    
    // Row 1: Duration controls
    StaticText(window, Rect(10, yStart, 100, 20))
        .string_("Duration (sec):")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    StaticText(window, Rect(width - 60, yStart, 50, 20))
        .string_(state[\playDuration].asString ++ "s")
        .stringColor_(Color.black)
        .font_(Font("Arial", 14));
    
    Slider(window, Rect(120, yStart, width - 190, 20))
        .value_(state[\playDuration] / 60)
        .action_({ |sl|
            state[\playDuration] = (sl.value * 60).max(1);
        });
    
    // Row 2: Frequency zoom controls (yStart + 30)
    StaticText(window, Rect(10, yStart + 30, 100, 20))
        .string_("Freq Zoom:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    StaticText(window, Rect(width - 150, yStart + 30, 140, 20))
        .string_("20-7500 Hz")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    Slider(window, Rect(120, yStart + 30, 200, 20))
        .value_(0.0)
        .action_({ |sl|
            // Zoom logic would go here
            state[\drawView].refresh;
        });
    
    StaticText(window, Rect(340, yStart + 30, 100, 20))
        .string_("Center Freq:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    Slider(window, Rect(450, yStart + 30, 200, 20))
        .value_(0.5);
    
    // Row 3: Time zoom controls (yStart + 60)
    StaticText(window, Rect(10, yStart + 60, 100, 20))
        .string_("Time Zoom:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    Slider(window, Rect(120, yStart + 60, 200, 20))
        .value_(0.0)
        .action_({ |sl|
            state[\drawView].refresh;
        });
    
    StaticText(window, Rect(340, yStart + 60, 100, 20))
        .string_("Time Center:")
        .stringColor_(Color.black)
        .font_(Font("Arial", 12));
    
    Slider(window, Rect(450, yStart + 60, 200, 20))
        .value_(0.5);
    
    // Row 4: Mode controls (yStart + 90)
    Button(window, Rect(10, yStart + 90, 60, 25))
        .states_([
            ["Play", Color.white, Color.green],
            ["Stop", Color.white, Color.red]
        ])
        .action_({ |btn|
            if(btn.value == 1) {
                "Starting playback...".postln;
                state[\isPlaying] = true;
            } {
                "Stopping playback...".postln;
                state[\isPlaying] = false;
            };
        });
    
    Button(window, Rect(80, yStart + 90, 80, 25))
        .states_([
            ["Erase", Color.black, Color.gray(0.9)],
            ["ERASING", Color.white, Color.red]
        ])
        .action_({ |btn|
            state[\eraseMode] = btn.value == 1;
        });
    
    Button(window, Rect(170, yStart + 90, 80, 25))
        .states_([
            ["Select", Color.black, Color.gray(0.9)],
            ["SELECTING", Color.white, Color.blue]
        ])
        .action_({ |btn|
            state[\selectMode] = btn.value == 1;
        });
    
    Button(window, Rect(260, yStart + 90, 80, 25))
        .states_([
            ["Grid ON", Color.black, Color.gray(0.9)],
            ["Grid OFF", Color.white, Color.gray(0.6)]
        ])
        .action_({ |btn|
            state[\showGrid] = btn.value == 0;
            state[\drawView].refresh;
        });
    
    PopUpMenu(window, Rect(350, yStart + 90, 150, 25))
        .items_(["Equal Temperament", "31-tone Fokker", "Harmonic Series", "Just Intonation"])
        .value_(0);
    
    // Row 5: Action buttons (yStart + 120)
    Button(window, Rect(10, yStart + 120, 60, 25))
        .states_([["Clear All", Color.white, Color.red.alpha_(0.8)]])
        .action_({
            ~nUPIC[\data][\trajectories].clear;
            ~nUPIC[\data][\selectedTrajectories].clear;
            state[\drawView].refresh;
            "All trajectories cleared".postln;
        });
    
    Button(window, Rect(80, yStart + 120, 120, 25))
        .states_([["Edit Amplitudes", Color.white, Color.blue]])
        .action_({
            "Edit Amplitudes button clicked!".postln;
            "Selected trajectories: ".post;
            ~nUPIC[\data][\selectedTrajectories].postln;
        });
    
    Button(window, Rect(210, yStart + 120, 80, 25))
        .states_([["Reset Zoom", Color.black, Color.gray(0.9)]])
        .action_({
            "Zoom reset".postln;
        });
    
    StaticText(window, Rect(300, yStart + 120, 80, 20))
        .string_("SynthDef:")
        .font_(Font("Arial", 12));
    
    PopUpMenu(window, Rect(380, yStart + 120, 150, 25))
        .items_(["simpleGravObject", "percNoise", "auditoryDistortion"])
        .value_(0);
    
    // Row 6: Status and help (yStart + 150)
    StaticText(window, Rect(10, yStart + 150, 400, 40))
        .string_("Status: Ready\nPress G for select mode, E for erase mode, SPACE to play")
        .font_(Font("Arial", 10))
        .stringColor_(Color.gray(0.5));
    
    Button(window, Rect(width - 100, yStart + 150, 80, 25))
        .states_([["Help", Color.black, Color.gray(0.9)]])
        .action_({
            "=== nUPIC Help ===".postln;
            "G: Toggle select mode".postln;
            "E: Toggle erase mode".postln;
            "SPACE: Play/Stop".postln;
            "Click and drag to draw trajectories".postln;
            "==================".postln;
        });
    
    // === MOUSE HANDLING ===
    
    drawView.mouseDownAction = { |view, x, y, modifiers, buttonNumber, clickCount|
        if(state[\selectMode]) {
            "Select mode - checking for trajectory at %@%".format(x, y).postln;
        } {
            if(state[\eraseMode]) {
                "Erase mode - erasing at %@%".format(x, y).postln;
            } {
                // Start drawing new trajectory
                isDrawing = true;
                currentTrajectory = List.new;
                currentTrajectory.add(Point(x, y));
                "Started drawing trajectory at %@%".format(x, y).postln;
            };
        };
    };
    
    drawView.mouseMoveAction = { |view, x, y, modifiers|
        if(isDrawing) {
            currentTrajectory.add(Point(x, y));
            view.refresh;
        };
    };
    
    drawView.mouseUpAction = { |view, x, y, modifiers, buttonNumber|
        if(isDrawing) {
            isDrawing = false;
            if(currentTrajectory.size > 1) {
                ~nUPIC[\data][\trajectories].add(currentTrajectory);
                "Added trajectory with % points".format(currentTrajectory.size).postln;
            };
            currentTrajectory = nil;
            view.refresh;
        };
    };
    
    // === KEYBOARD HANDLING ===
    window.view.keyDownAction = { |view, char, mod, unicode, keycode|
        case
        { char == $g } {
            state[\selectMode] = state[\selectMode].not;
            ("Select mode: " ++ state[\selectMode]).postln;
        }
        { char == $e } {
            state[\eraseMode] = state[\eraseMode].not;
            ("Erase mode: " ++ state[\eraseMode]).postln;
        }
        { keycode == 49 } {  // Spacebar
            state[\isPlaying] = state[\isPlaying].not;
            ("Playing: " ++ state[\isPlaying]).postln;
        }
        { char == $c } {
            ~nUPIC[\data][\trajectories].clear;
            ~nUPIC[\data][\selectedTrajectories].clear;
            state[\drawView].refresh;
            "Cleared all trajectories".postln;
        };
    };
    
    window.view.canFocus = true;
    window.view.focus;
    
    // Cleanup on close
    window.onClose = {
        "nUPIC window closed".postln;
        ~nUPIC[\ui][\state][\window] = nil;
    };
    
    window.front;
    
    "nUPIC GUI created with all controls visible!".postln;
    "Window size: %x% (% control height)".format(width, height + controlsHeight, controlsHeight).postln;
    window;
};

// Launch the GUI
~nUPIC[\ui][\createMainWindow].value;

)
