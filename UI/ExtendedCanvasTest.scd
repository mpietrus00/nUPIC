// Extended Canvas and Panning Test for nUPIC
// This file demonstrates the extended virtual canvas and panning functionality
// Part of the nUPIC (nu-UPIC) modular system

(
"=== Testing Extended Canvas and Panning Features ===".postln;

// Test function to create test trajectories across the extended canvas
~nUPIC[\ui][\createExtendedCanvasTest] = {
    var data = ~nUPIC[\data];
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var width, height, virtualWidth, virtualHeight;
    var testTrajectories;

    if(data.isNil or: { state.isNil }) {
        "Please initialize nUPIC first".postln;
        ^nil;
    };

    width = constants[\defaultWidth] ? 1200;
    height = constants[\defaultHeight] ? 800;
    virtualWidth = width * 4;  // 4800
    virtualHeight = height * 3;  // 2400

    "Creating test trajectories for extended canvas...".postln;
    ("Canvas size: " ++ width ++ "x" ++ height).postln;
    ("Virtual canvas size: " ++ virtualWidth ++ "x" ++ virtualHeight).postln;

    // Clear existing trajectories
    if(data[\clearAll].notNil) {
        data[\clearAll].value;
    };

    // Create test trajectories in different regions of the virtual canvas
    testTrajectories = [
        // Top-left quadrant (visible on startup)
        {
            var traj = [];
            10.do { |i|
                var x = i * (width * 0.08) + 50;
                var y = 50 + (i * 10);
                var freq = y.linlin(0, height, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Top-right quadrant (need to pan right to see)
        {
            var traj = [];
            10.do { |i|
                var x = width * 2.5 + (i * 30);  // Far right
                var y = 100 + (i * 8);
                var freq = y.linlin(0, height, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Bottom-left quadrant (need to pan down to see)
        {
            var traj = [];
            8.do { |i|
                var x = 200 + (i * 50);
                var y = height * 2.2 + (i * 15);  // Far down
                var freq = y.linlin(0, virtualHeight, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Bottom-right quadrant (need to pan right and down to see)
        {
            var traj = [];
            6.do { |i|
                var x = width * 3.2 + (i * 40);  // Far right
                var y = height * 2.5 + (i * -20);  // Far down
                var freq = y.linlin(0, virtualHeight, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Diagonal trajectory across the entire virtual canvas
        {
            var traj = [];
            20.do { |i|
                var x = i * (virtualWidth / 20);
                var y = i * (virtualHeight / 20);
                var freq = y.linlin(0, virtualHeight, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Horizontal trajectory across the middle
        {
            var traj = [];
            30.do { |i|
                var x = i * (virtualWidth / 30);
                var y = virtualHeight * 0.5;
                var freq = y.linlin(0, virtualHeight, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Vertical trajectory on the right edge
        {
            var traj = [];
            15.do { |i|
                var x = virtualWidth * 0.9;  // Near right edge
                var y = i * (virtualHeight / 15);
                var freq = y.linlin(0, virtualHeight, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value,

        // Spiral pattern in the center-right area
        {
            var traj = [];
            var centerX = virtualWidth * 0.75;
            var centerY = virtualHeight * 0.6;
            var radius = 200;
            40.do { |i|
                var angle = i * (2 * pi / 40) * 3;  // 3 full rotations
                var currentRadius = radius * (1 - (i / 40)) + 50;  // Spiral inward
                var x = centerX + (currentRadius * cos(angle));
                var y = centerY + (currentRadius * sin(angle));
                var freq = y.linlin(0, virtualHeight, 7500, 20);
                traj = traj.add((x: x, y: y, freq: freq));
            };
            traj;
        }.value
    ];

    // Add trajectories to data
    testTrajectories.do { |traj, i|
        if(data[\addTrajectory].notNil) {
            data[\addTrajectory].value(traj);
            ("Added test trajectory " ++ (i + 1) ++ " with " ++ traj.size ++ " points").postln;
        };
    };

    // Refresh the display
    if(state[\drawView].notNil) {
        state[\drawView].refresh;
    };

    "Test trajectories created!".postln;
    "".postln;
    "=== Pan Control Instructions ===".postln;
    "Alt + Arrow Keys: Pan around the extended canvas".postln;
    "Shift + Alt + Arrow Keys: Pan with larger steps".postln;
    "".postln;
    "Try panning to discover trajectories in different areas:".postln;
    "- Current view: Top-left quadrant (trajectory 1 visible)".postln;
    "- Pan RIGHT: See trajectory in top-right area".postln;
    "- Pan DOWN: See trajectory in bottom-left area".postln;
    "- Pan RIGHT + DOWN: See trajectory in bottom-right area".postln;
    "- The diagonal trajectory spans the entire virtual canvas".postln;
    "- The spiral is in the center-right area".postln;
    "".postln;
    "Total virtual canvas size: " ++ virtualWidth ++ " x " ++ virtualHeight ++ " pixels".postln;
    "Current viewport: " ++ state[\viewportX] ++ ", " ++ state[\viewportY] ++
    " (showing " ++ width ++ " x " ++ height ++ " area)".postln;
};

// Test viewport position reporting
~nUPIC[\ui][\reportViewportPosition] = {
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var width, height, virtualWidth, virtualHeight, viewportX, viewportY;
    var centerX, centerY, quadrantX, quadrantY;

    if(state.isNil) {
        "nUPIC not initialized".postln;
        ^nil;
    };

    width = constants[\defaultWidth] ? 1200;
    height = constants[\defaultHeight] ? 800;
    virtualWidth = state[\virtualCanvasWidth] ? (width * 4);
    virtualHeight = state[\virtualCanvasHeight] ? (height * 3);
    viewportX = state[\viewportX] ? 0;
    viewportY = state[\viewportY] ? 0;

    "=== Current Viewport Position ===".postln;
    ("Viewport X: " ++ viewportX ++ " (max: " ++ (virtualWidth - width) ++ ")").postln;
    ("Viewport Y: " ++ viewportY ++ " (max: " ++ (virtualHeight - height) ++ ")").postln;
    ("Showing area: " ++ viewportX ++ "," ++ viewportY ++ " to " ++
     (viewportX + width) ++ "," ++ (viewportY + height)).postln;

    // Calculate which quadrant we're mostly in
    centerX = viewportX + (width / 2);
    centerY = viewportY + (height / 2);
    quadrantX = if(centerX < (virtualWidth / 2)) { "Left" } { "Right" };
    quadrantY = if(centerY < (virtualHeight / 2)) { "Top" } { "Bottom" };

    ("Current quadrant: " ++ quadrantY ++ "-" ++ quadrantX).postln;
    "".postln;
};

// Function to demonstrate panning programmatically
~nUPIC[\ui][\demoPanning] = {
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var width, height, maxX, maxY;

    if(state.isNil) {
        "nUPIC not initialized".postln;
        ^nil;
    };

    width = constants[\defaultWidth] ? 1200;
    height = constants[\defaultHeight] ? 800;
    maxX = state[\virtualCanvasWidth] - width;
    maxY = state[\virtualCanvasHeight] - height;

    "Starting pan demonstration...".postln;

    Task {
        // Show each corner of the virtual canvas
        var positions = [
            [0, 0, "Top-Left corner"],
            [maxX, 0, "Top-Right corner"],
            [0, maxY, "Bottom-Left corner"],
            [maxX, maxY, "Bottom-Right corner"],
            [maxX / 2, maxY / 2, "Center of virtual canvas"],
            [0, 0, "Back to start"]
        ];

        positions.do { |pos|
            var x = pos[0];
            var y = pos[1];
            var desc = pos[2];

            ("Moving to: " ++ desc ++ " (" ++ x ++ ", " ++ y ++ ")").postln;
            state[\viewportX] = x;
            state[\viewportY] = y;

            // Refresh display
            { state[\drawView].refresh }.defer;

            2.0.wait;  // Wait 2 seconds at each position
        };

        "Pan demonstration complete!".postln;
        ~nUPIC[\ui][\reportViewportPosition].value;
    }.play;
};

// Function to test canvas boundary limits
~nUPIC[\ui][\testCanvasBounds] = {
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var width, height, maxX, maxY;
    var testX, testY;

    if(state.isNil) {
        "nUPIC not initialized".postln;
        ^nil;
    };

    width = constants[\defaultWidth] ? 1200;
    height = constants[\defaultHeight] ? 800;
    maxX = state[\virtualCanvasWidth] - width;
    maxY = state[\virtualCanvasHeight] - height;

    "=== Testing Canvas Boundary Limits ===".postln;
    ("Virtual canvas: " ++ state[\virtualCanvasWidth] ++ " x " ++ state[\virtualCanvasHeight]).postln;
    ("Viewport size: " ++ width ++ " x " ++ height).postln;
    ("Maximum pan X: " ++ maxX).postln;
    ("Maximum pan Y: " ++ maxY).postln;

    // Test extreme values
    "Testing extreme pan values...".postln;

    // Try to pan beyond limits (should be clipped)
    testX = maxX + 1000;  // Way beyond limit
    testY = maxY + 1000;  // Way beyond limit

    state[\viewportX] = testX;
    state[\viewportY] = testY;

    ("Attempted to set viewport to: " ++ testX ++ ", " ++ testY).postln;
    ("Actually clipped to: " ++ state[\viewportX] ++ ", " ++ state[\viewportY]).postln;

    // Test negative values (should be clipped to 0)
    state[\viewportX] = -500;
    state[\viewportY] = -300;

    ("Attempted to set viewport to: -500, -300").postln;
    ("Actually clipped to: " ++ state[\viewportX] ++ ", " ++ state[\viewportY]).postln;

    { state[\drawView].refresh }.defer;
    "Boundary test complete.".postln;
};

// Helper function to show current trajectory visibility
~nUPIC[\ui][\checkTrajectoryVisibility] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var width, height, viewportX, viewportY, visibleCount;

    if(state.isNil or: { data.isNil }) {
        "nUPIC not properly initialized".postln;
        ^nil;
    };

    if(data[\trajectories].isNil or: { data[\trajectories].size == 0 }) {
        "No trajectories to check".postln;
        ^nil;
    };

    width = constants[\defaultWidth] ? 1200;
    height = constants[\defaultHeight] ? 800;
    viewportX = state[\viewportX] ? 0;
    viewportY = state[\viewportY] ? 0;
    visibleCount = 0;

    "=== Trajectory Visibility Check ===".postln;
    ("Current viewport: " ++ viewportX ++ ", " ++ viewportY ++
     " to " ++ (viewportX + width) ++ ", " ++ (viewportY + height)).postln;

    data[\trajectories].do { |traj, i|
        var isVisible = false;

        // Check if any point of the trajectory is in the current viewport
        traj.do { |point|
            var px = if(point.isKindOf(Event)) { point.x } { point.x };
            var py = if(point.isKindOf(Event)) { point.y } { point.y };

            if((px >= viewportX) and: { px <= (viewportX + width) } and:
               { py >= viewportY } and: { py <= (viewportY + height) }) {
                isVisible = true;
            };
        };

        if(isVisible) {
            ("Trajectory " ++ (i + 1) ++ ": VISIBLE (" ++ traj.size ++ " points)").postln;
            visibleCount = visibleCount + 1;
        } {
            ("Trajectory " ++ (i + 1) ++ ": not visible (" ++ traj.size ++ " points)").postln;
        };
    };

    ("Total trajectories: " ++ data[\trajectories].size).postln;
    ("Visible trajectories: " ++ visibleCount).postln;
    "".postln;
};

"Extended Canvas Test functions loaded:".postln;
"~nUPIC[\\ui][\\createExtendedCanvasTest].value  - Create test trajectories".postln;
"~nUPIC[\\ui][\\reportViewportPosition].value   - Show current viewport position".postln;
"~nUPIC[\\ui][\\demoPanning].value              - Automated pan demonstration".postln;
"~nUPIC[\\ui][\\testCanvasBounds].value         - Test boundary limit clipping".postln;
"~nUPIC[\\ui][\\checkTrajectoryVisibility].value - Check which trajectories are visible".postln;
"".postln;
"To start the test:".postln;
"1. Make sure nUPIC is loaded and the main window is open".postln;
"2. Run: ~nUPIC[\\ui][\\createExtendedCanvasTest].value".postln;
"3. Use Alt+Arrow keys to pan around and discover trajectories".postln;
"4. Use ~nUPIC[\\ui][\\reportViewportPosition].value to see where you are".postln;
)

~nUPIC[\ui][\createExtendedCanvasTest].value
