// nUPIC Spatialization Controls
// UI controls for 8-channel spatial parameters
// Allows control of spatial movement patterns, speed, and depth

(
// Add spatialization controls to nUPIC UI
~nUPIC[\ui][\createSpatializationControls] = { |parent, x, y, width|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var spatialGroup, spatialBorder;
    var spatialSpeedKnob, spatialDepthSlider, spatialPatternMenu;
    var spatialPhaseKnob, spatialRandomButton;
    var groupHeight = 100;
    
    // Initialize spatial parameters in defaults if not present
    if(defaults[\spatialSpeed].isNil) { defaults[\spatialSpeed] = 0.5 };
    if(defaults[\spatialDepth].isNil) { defaults[\spatialDepth] = 1.0 };
    if(defaults[\spatialPattern].isNil) { defaults[\spatialPattern] = 0 };
    if(defaults[\spatialPhase].isNil) { defaults[\spatialPhase] = 0 };
    
    // Create border view
    spatialBorder = UserView(parent, Rect(x, y, width, groupHeight));
    spatialBorder.drawFunc = {
        Pen.fillColor = Color.new(230/255, 230/255, 255/255, 0.3); // Light blue tint
        Pen.fillRect(Rect(0, 0, width, groupHeight));
        Pen.strokeColor = Color.white;
        Pen.width = 2;
        Pen.strokeRect(Rect(0, 0, width, groupHeight));
    };
    
    // Create group inside border
    spatialGroup = CompositeView(spatialBorder, Rect(5, 5, width - 10, groupHeight - 10));
    
    // Title
    StaticText(spatialGroup, Rect(0, 0, width - 10, 15))
        .string_("8-Channel Spatialization")
        .font_(Font("Arial", 10, true))
        .align_(\center);
    
    // Spatial Speed Knob
    StaticText(spatialGroup, Rect(5, 20, 60, 15))
        .string_("Speed")
        .font_(Font("Arial", 9));
    
    spatialSpeedKnob = Knob(spatialGroup, Rect(5, 35, 35, 35))
        .value_(defaults[\spatialSpeed])
        .action_({ |knob|
            defaults[\spatialSpeed] = knob.value.linexp(0, 1, 0.01, 5);
            ("Spatial speed: " ++ defaults[\spatialSpeed].round(0.01) ++ " Hz").postln;
            
            // Update playing synths if any
            ~nUPIC[\ui][\updatePlayingSpatialParams].value;
        });
    
    // Speed display
    StaticText(spatialGroup, Rect(5, 70, 60, 15))
        .string_((defaults[\spatialSpeed] * 100).round(1).asString ++ "%")
        .font_(Font("Arial", 8))
        .stringColor_(Color.gray);
    
    // Spatial Depth Slider
    StaticText(spatialGroup, Rect(70, 20, 60, 15))
        .string_("Depth")
        .font_(Font("Arial", 9));
    
    spatialDepthSlider = Slider(spatialGroup, Rect(70, 35, 100, 20))
        .value_(defaults[\spatialDepth])
        .orientation_(\horizontal)
        .action_({ |slider|
            defaults[\spatialDepth] = slider.value;
            ("Spatial depth: " ++ (defaults[\spatialDepth] * 100).round(1) ++ "%").postln;
            ~nUPIC[\ui][\updatePlayingSpatialParams].value;
        });
    
    // Depth display
    StaticText(spatialGroup, Rect(70, 55, 60, 15))
        .string_((defaults[\spatialDepth] * 100).round.asString ++ "%")
        .font_(Font("Arial", 8))
        .stringColor_(Color.gray);
    
    // Pattern selector
    StaticText(spatialGroup, Rect(180, 20, 60, 15))
        .string_("Pattern")
        .font_(Font("Arial", 9));
    
    spatialPatternMenu = PopUpMenu(spatialGroup, Rect(180, 35, 100, 20))
        .items_([
            "Random Walk",
            "Circular",
            "Figure-8",
            "Complex"
        ])
        .value_(defaults[\spatialPattern])
        .font_(Font("Arial", 9))
        .action_({ |menu|
            defaults[\spatialPattern] = menu.value;
            ("Spatial pattern: " ++ menu.item).postln;
            ~nUPIC[\ui][\updatePlayingSpatialParams].value;
        });
    
    // Phase knob (starting position)
    StaticText(spatialGroup, Rect(290, 20, 60, 15))
        .string_("Phase")
        .font_(Font("Arial", 9));
    
    spatialPhaseKnob = Knob(spatialGroup, Rect(290, 35, 30, 30))
        .value_(defaults[\spatialPhase] / (2*pi))
        .action_({ |knob|
            defaults[\spatialPhase] = knob.value * 2 * pi;
            ("Spatial phase: " ++ (knob.value * 360).round ++ "°").postln;
        });
    
    // Randomize button
    spatialRandomButton = Button(spatialGroup, Rect(330, 35, 60, 25))
        .states_([["Random", Color.white, Color.blue]])
        .font_(Font("Arial", 9))
        .action_({
            // Randomize spatial parameters for each trajectory
            if(data[\selectedTrajectories].notNil and: { data[\selectedTrajectories].size > 0 }) {
                data[\selectedTrajectories].do { |idx|
                    // Store random parameters per trajectory
                    if(data[\trajectorySpatialParams].isNil) {
                        data[\trajectorySpatialParams] = List.new;
                    };
                    
                    // Ensure list is long enough
                    while { data[\trajectorySpatialParams].size <= idx } {
                        data[\trajectorySpatialParams].add(nil);
                    };
                    
                    // Set random parameters
                    data[\trajectorySpatialParams][idx] = (
                        spatialSpeed: rrand(0.1, 2.0),
                        spatialDepth: rrand(0.3, 1.0),
                        spatialPattern: [0, 1, 2, 3].choose,
                        spatialPhase: rrand(0, 2*pi)
                    );
                    
                    ("Randomized spatial params for trajectory " ++ idx).postln;
                };
            } {
                // Randomize defaults if no selection
                defaults[\spatialSpeed] = rrand(0.1, 2.0);
                defaults[\spatialDepth] = rrand(0.3, 1.0);
                defaults[\spatialPattern] = [0, 1, 2, 3].choose;
                defaults[\spatialPhase] = rrand(0, 2*pi);
                
                // Update UI
                spatialSpeedKnob.value = defaults[\spatialSpeed].explin(0.01, 5, 0, 1);
                spatialDepthSlider.value = defaults[\spatialDepth];
                spatialPatternMenu.value = defaults[\spatialPattern];
                spatialPhaseKnob.value = defaults[\spatialPhase] / (2*pi);
                
                "Randomized default spatial parameters".postln;
            };
        });
    
    // Store control references
    state[\controls][\spatialSpeedKnob] = spatialSpeedKnob;
    state[\controls][\spatialDepthSlider] = spatialDepthSlider;
    state[\controls][\spatialPatternMenu] = spatialPatternMenu;
    state[\controls][\spatialPhaseKnob] = spatialPhaseKnob;
    
    // Return the border view
    spatialBorder;
};

// Function to update playing synths with new spatial parameters
~nUPIC[\ui][\updatePlayingSpatialParams] = {
    var state = ~nUPIC[\ui][\state];
    var defaults = ~nUPIC[\defaults];
    
    // Update any playing synths
    if(state[\synths].notNil) {
        state[\synths].do { |synth|
            if(synth.notNil) {
                try {
                    synth.set(
                        \spatialSpeed, defaults[\spatialSpeed] ? 0.5,
                        \spatialDepth, defaults[\spatialDepth] ? 1.0,
                        \spatialPattern, defaults[\spatialPattern] ? 0
                    );
                } { |error|
                    // Synth might not support spatial params
                };
            };
        };
    };
};

// Function to get spatial parameters for a trajectory
~nUPIC[\ui][\getSpatialParamsForTrajectory] = { |trajIdx|
    var data = ~nUPIC[\data];
    var defaults = ~nUPIC[\defaults];
    var params;
    
    // Check if trajectory has custom spatial params
    if(data[\trajectorySpatialParams].notNil and: {
        trajIdx < data[\trajectorySpatialParams].size and: {
            data[\trajectorySpatialParams][trajIdx].notNil
        }
    }) {
        params = data[\trajectorySpatialParams][trajIdx];
    } {
        // Use defaults
        params = (
            spatialSpeed: defaults[\spatialSpeed] ? 0.5,
            spatialDepth: defaults[\spatialDepth] ? 1.0,
            spatialPattern: defaults[\spatialPattern] ? 0,
            spatialPhase: defaults[\spatialPhase] ? 0
        );
    };
    
    params;
};

"✓ Spatialization Controls loaded".postln;
"Use ~nUPIC[\ui][\createSpatializationControls].value(parent, x, y, width) to add controls".postln;
)