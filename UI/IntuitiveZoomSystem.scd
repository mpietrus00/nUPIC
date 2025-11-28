// nUPIC Intuitive Zoom-Based View System
// Addresses the issue of confusing panning beyond composition boundaries

(
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

/*
PROBLEM WITH CURRENT APPROACH:
- Can pan beyond total duration (makes no sense)
- No clear sense of "where you are" in the composition
- Panning feels unlimited and disconnected from actual composition length

INTUITIVE SOLUTION - ZOOM-BASED VIEW:

1. START ZOOMED IN (DEFAULT VIEW)
   - Initial view shows 1/10th of total duration (e.g., 6s out of 60s total)
   - Start at beginning of composition (time 0)
   - This gives detailed editing capability by default

2. ZOOM LEVELS
   - Zoom Level 1: Show 1/10th of duration (most zoomed in)
   - Zoom Level 2: Show 1/5th of duration
   - Zoom Level 3: Show 1/2 of duration  
   - Zoom Level 4: Show full duration (fully zoomed out)
   
3. CONSTRAINED PANNING
   - Can only pan within the actual composition boundaries
   - Cannot pan before 0 seconds or after total duration
   - Panning moves the "view window" within the composition

4. INTUITIVE CONTROLS
   - +/- buttons or scroll wheel for zooming
   - Alt+Arrow keys for panning within boundaries
   - Clear indicators showing current time range and zoom level

5. VISUAL FEEDBACK
   - Time range indicator: "Viewing: 12.0s - 18.0s (6s window)"
   - Position indicator: "Position: 15.0s / 60.0s total"
   - Zoom level: "Zoom: 10x (detailed view)"

BENEFITS:
- Always start with detailed view for precise editing
- Can zoom out to see full composition when needed
- Cannot get "lost" by panning beyond composition
- Clear visual feedback about where you are
- Zoom levels provide predictable view changes
*/

// Update zoom levels - now using pure spatial coordinates (0.0 to 1.0) independent of duration
~nUPIC[\ui][\updateZoomLevels] = {
    var state = ~nUPIC[\ui][\state];
    var minViewWidth, maxViewWidth;
    
    if(state.isNil) { ^nil };
    
    // Fixed spatial zoom levels - completely decoupled from duration
    // These represent normalized spatial width from 0.0 to 1.0 (full canvas)
    minViewWidth = 0.01; // Minimum view is 1% of canvas for maximum detailed editing
    maxViewWidth = 1.0;  // Maximum view is 100% of canvas (full view)
    
    // Create fixed spatial zoom levels that DO NOT change with duration
    state[\zoomLevels] = [
        (width: minViewWidth, name: "Maximum (1%)"),
        (width: 0.02, name: "Very Close (2%)"),
        (width: 0.05, name: "Close (5%)"),
        (width: 0.1, name: "Medium (10%)"),
        (width: 0.25, name: "Wide (25%)"),
        (width: 0.5, name: "Half (50%)"),
        (width: maxViewWidth, name: "Full (100%)")
    ];
    
    // Adjust current zoom level if it's now invalid
    if(state[\currentZoomLevel].isNil or: { state[\currentZoomLevel] >= state[\zoomLevels].size }) {
        state[\currentZoomLevel] = state[\zoomLevels].size - 1; // Default to full view
    };
};

// Zoom system state structure
~nUPIC[\ui][\initializeZoomSystem] = {
    var state = ~nUPIC[\ui][\state];
    var constants, baseFreqMin, baseFreqMax, freqLevel;
    
    "[ZOOM] Initializing zoom system...".postln;
    "[ZOOM] State object: %".format(state.class).postln;
    "[ZOOM] Play duration: %".format(state[\playDuration]).postln;
    
    if(state.isNil) {
        "ERROR: State is nil in zoom initialization!".postln;
        ^nil;
    };
    
    if(state[\playDuration].isNil) {
        "WARNING: playDuration is nil, using default of 10".postln;
        state[\playDuration] = 10;
    };
    
    // Initialize zoom levels based on current duration
    ~nUPIC[\ui][\updateZoomLevels].value;
    
    // Initialize frequency zoom system
    constants = ~nUPIC[\constants];
    baseFreqMin = constants[\freqMin] ? 20;
    baseFreqMax = constants[\freqMax] ? 7500;
    
    // Frequency zoom levels (frequency range in Hz)
    state[\freqZoomLevels] = [
        (min: 20, max: 500, name: "Bass (20-500Hz)"),             // Bass focus
        (min: 20, max: 2000, name: "Low-Mid (20-2000Hz)"),    // Extended bass and mids
        (min: baseFreqMin, max: baseFreqMax, name: "Full (" ++ baseFreqMin ++ "-" ++ baseFreqMax ++ "Hz)")  // Full range
    ];
    
    // Current zoom state
    state[\currentZoomLevel] = 0;  // Start at most detailed time view
    state[\currentFreqZoomLevel] = 2;  // Start at full frequency range
    state[\viewStartTime] = 0.0;   // Start at beginning of composition
    
    // Set initial frequency zoom range
    freqLevel = state[\freqZoomLevels][state[\currentFreqZoomLevel]];
    state[\zoomFreqMin] = freqLevel.min;
    state[\zoomFreqMax] = freqLevel.max;
    
    "[ZOOM] Zoom levels set: %".format(state[\zoomLevels].size).postln;
    "[ZOOM] Current zoom level: %".format(state[\currentZoomLevel]).postln;
    "[ZOOM] View start time: %".format(state[\viewStartTime]).postln;
    
    // Calculate initial view window
    "[ZOOM] Calling updateZoomView...".postln;
    ~nUPIC[\ui][\updateZoomView].value;
    
    "[ZOOM] Zoom system initialized - starting with detailed view".postln;
    "[ZOOM] Final viewDuration: %".format(state[\viewDuration]).postln;
};

// Function to update zoom system when duration changes
~nUPIC[\ui][\onDurationChange] = {
    var state = ~nUPIC[\ui][\state];
    var oldSpatialPos, oldSpatialWidth;
    
    if(state.notNil and: { state[\zoomLevels].notNil }) {
        "[ZOOM] Duration changed, preserving spatial zoom state...".postln;
        
        // PRESERVE current spatial zoom state (this is the fix!)
        oldSpatialPos = state[\viewSpatialPos];
        oldSpatialWidth = state[\viewSpatialWidth];
        
        // Update zoom levels (spatial levels don't change with duration)
        ~nUPIC[\ui][\updateZoomLevels].value;
        
        // RESTORE preserved spatial zoom state
        if(oldSpatialPos.notNil) {
            state[\viewSpatialPos] = oldSpatialPos;
        };
        if(oldSpatialWidth.notNil) {
            state[\viewSpatialWidth] = oldSpatialWidth;
            state[\viewSpatialEnd] = (oldSpatialPos + oldSpatialWidth).min(1.0);
        };
        
        // Only update time-based display values (not spatial zoom state)
        if(state[\playDuration].notNil) {
            state[\viewStartTime] = state[\viewSpatialPos] * state[\playDuration];
            state[\viewEndTime] = state[\viewSpatialEnd] * state[\playDuration];
            state[\viewDuration] = state[\viewEndTime] - state[\viewStartTime];
        };
        
        // Refresh display with preserved zoom
        if(~nUPIC[\ui][\refreshDisplay].notNil) {
            ~nUPIC[\ui][\refreshDisplay].value;
        };
        
        // Update zoom control labels if they exist
        if(state[\controls].notNil and: { state[\controls][\zoomStatusLabel].notNil }) {
            {
                var currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
                if(currentLevel.notNil) {
                    state[\controls][\zoomStatusLabel].string = currentLevel.name;
                };
            }.defer;
        };
        
        "[ZOOM] Duration updated, spatial zoom state preserved".postln;
    };
};

// Update view window based on current zoom level and position  
~nUPIC[\ui][\updateZoomView] = {
    var state = ~nUPIC[\ui][\state];
    var currentLevel, viewWidth, maxStartPos;
    
    // Safety check for zoom levels
    if(state.isNil or: { state[\zoomLevels].isNil } or: { state[\currentZoomLevel].isNil }) {
        "Error: Zoom system not properly initialized".postln;
        ^nil;
    };
    
    currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
    if(currentLevel.isNil) {
        "Error: Invalid zoom level".postln;
        ^nil;
    };
    
    // Get the view width from zoom level (spatial, not time-based)
    viewWidth = currentLevel.width;
    
    // Initialize or keep track of spatial position (0.0 to 1.0 space)
    if(state[\viewSpatialPos].isNil) {
        state[\viewSpatialPos] = 0.0;  // Default to beginning
    };
    
    // Constrain view spatial position to valid boundaries
    maxStartPos = 1.0 - viewWidth;
    state[\viewSpatialPos] = state[\viewSpatialPos].clip(0, maxStartPos.max(0));
    
    // Store spatial view parameters for drawing and coordinate conversion
    state[\viewSpatialWidth] = viewWidth;
    state[\viewSpatialEnd] = (state[\viewSpatialPos] + viewWidth).min(1.0);
    
    // For time display purposes only, calculate time coordinates
    if(state[\playDuration].notNil) {
        state[\viewStartTime] = state[\viewSpatialPos] * state[\playDuration];
        state[\viewEndTime] = state[\viewSpatialEnd] * state[\playDuration];
        state[\viewDuration] = state[\viewEndTime] - state[\viewStartTime];
    };
    
    // Update display
    if(~nUPIC[\ui][\refreshDisplay].notNil) {
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    // Log current view in both spatial and time units
    ("View: " ++ (state[\viewSpatialPos] * 100).round(0.1) ++ "% - " ++ 
     (state[\viewSpatialEnd] * 100).round(0.1) ++ "% (" ++ 
     currentLevel.name ++ ")").postln;
    
    if(state[\playDuration].notNil) {
        ("Time: " ++ state[\viewStartTime].round(0.1) ++ "s - " ++ 
         state[\viewEndTime].round(0.1) ++ "s of " ++ 
         state[\playDuration].round(0.1) ++ "s total").postln;
    };
};

// Zoom in (more detailed view)
~nUPIC[\ui][\zoomIn] = {
    var state = ~nUPIC[\ui][\state];
    if(state[\currentZoomLevel] > 0) {
        state[\currentZoomLevel] = state[\currentZoomLevel] - 1;
        ~nUPIC[\ui][\updateZoomView].value;
        "Zoomed in".postln;
    } {
        "Already at maximum zoom level".postln;
    };
};

// Zoom out (less detailed view)
~nUPIC[\ui][\zoomOut] = {
    var state = ~nUPIC[\ui][\state];
    if(state[\currentZoomLevel] < (state[\zoomLevels].size - 1)) {
        state[\currentZoomLevel] = state[\currentZoomLevel] + 1;
        ~nUPIC[\ui][\updateZoomView].value;
        "Zoomed out".postln;
    } {
        "Already at minimum zoom level (full view)".postln;
    };
};

// Pan within composition boundaries - using spatial coordinates
~nUPIC[\ui][\panView] = { |direction|
    var state = ~nUPIC[\ui][\state];
    var panStep = state[\viewSpatialWidth] * 0.2;  // Pan by 20% of current view width
    var oldSpatialPos = state[\viewSpatialPos];
    
    case
    { direction == \left } {
        state[\viewSpatialPos] = state[\viewSpatialPos] - panStep;
    }
    { direction == \right } {
        state[\viewSpatialPos] = state[\viewSpatialPos] + panStep;
    };
    
    // Update and constrain the view
    ~nUPIC[\ui][\updateZoomView].value;
    
    // Check if we actually moved
    if(state[\viewSpatialPos] == oldSpatialPos) {
        ("Cannot pan further " ++ direction).postln;
    };
};

// Get current time range as string for display
~nUPIC[\ui][\getCurrentTimeRange] = {
    var state = ~nUPIC[\ui][\state];
    var currentLevel;
    
    // Safety check for zoom levels
    if(state.isNil or: { state[\zoomLevels].isNil } or: { state[\currentZoomLevel].isNil }) {
        ^"Zoom system not initialized";
    };
    
    currentLevel = state[\zoomLevels][state[\currentZoomLevel]];
    if(currentLevel.isNil) {
        ^"Invalid zoom level";
    };
    
    "Viewing: " ++ state[\viewStartTime].round(0.1) ++ "s - " ++ 
    state[\viewEndTime].round(0.1) ++ "s (" ++ currentLevel.name ++ ")"
};

// Convert screen coordinates to normalized spatial position using zoom view
~nUPIC[\ui][\screenToSpatial] = { |x, width|
    var state = ~nUPIC[\ui][\state];
    var normalizedX;
    
    if(state.isNil or: { state[\viewSpatialPos].isNil } or: { state[\viewSpatialWidth].isNil }) {
        ^nil;
    };
    
    normalizedX = x / width;
    state[\viewSpatialPos] + (normalizedX * state[\viewSpatialWidth]);
};

// Convert screen coordinates to time (for playback display purposes)
~nUPIC[\ui][\screenToTime] = { |x, width|
    var state = ~nUPIC[\ui][\state];
    var spatialPos;
    
    if(state.isNil or: { state[\playDuration].isNil }) {
        ^nil;
    };
    
    // First convert to spatial coordinate
    spatialPos = ~nUPIC[\ui][\screenToSpatial].value(x, width);
    
    // Then convert spatial to time based on current duration
    spatialPos * state[\playDuration];
};

// Convert spatial position to screen coordinates using zoom view
~nUPIC[\ui][\spatialToScreen] = { |spatialPos, width|
    var state = ~nUPIC[\ui][\state];
    var normalizedPos;
    
    if(state.isNil or: { state[\viewSpatialPos].isNil } or: { state[\viewSpatialWidth].isNil }) {
        ^nil;
    };
    
    normalizedPos = (spatialPos - state[\viewSpatialPos]) / state[\viewSpatialWidth];
    normalizedPos * width;
};

// Convert time to screen coordinates using zoom view  
~nUPIC[\ui][\timeToScreen] = { |time, width|
    var state = ~nUPIC[\ui][\state];
    var spatialPos;
    
    if(state.isNil or: { state[\playDuration].isNil }) {
        ^nil;
    };
    
    // Convert time to spatial coordinate
    spatialPos = time / state[\playDuration];
    
    // Then convert spatial to screen position
    ~nUPIC[\ui][\spatialToScreen].value(spatialPos, width);
};

// Frequency zoom in (more detailed frequency view)
~nUPIC[\ui][\freqZoomIn] = {
    var state = ~nUPIC[\ui][\state];
    var freqLevel;
    if(state[\currentFreqZoomLevel] > 0) {
        state[\currentFreqZoomLevel] = state[\currentFreqZoomLevel] - 1;
        freqLevel = state[\freqZoomLevels][state[\currentFreqZoomLevel]];
        state[\zoomFreqMin] = freqLevel.min;
        state[\zoomFreqMax] = freqLevel.max;
        
        // Update display to show trajectories in new positions
        if(~nUPIC[\ui][\refreshDisplay].notNil) {
            ~nUPIC[\ui][\refreshDisplay].value;
        };
        
        ("Frequency zoomed in: " ++ freqLevel.name).postln;
    } {
        "Already at maximum frequency zoom level".postln;
    };
};

// Frequency zoom out (less detailed frequency view)
~nUPIC[\ui][\freqZoomOut] = {
    var state = ~nUPIC[\ui][\state];
    var freqLevel;
    if(state[\currentFreqZoomLevel] < (state[\freqZoomLevels].size - 1)) {
        state[\currentFreqZoomLevel] = state[\currentFreqZoomLevel] + 1;
        freqLevel = state[\freqZoomLevels][state[\currentFreqZoomLevel]];
        state[\zoomFreqMin] = freqLevel.min;
        state[\zoomFreqMax] = freqLevel.max;
        
        // Update display to show trajectories in new positions
        if(~nUPIC[\ui][\refreshDisplay].notNil) {
            ~nUPIC[\ui][\refreshDisplay].value;
        };
        
        ("Frequency zoomed out: " ++ freqLevel.name).postln;
    } {
        "Already at minimum frequency zoom level".postln;
    };
};

// Pan frequency view up/down within current zoom level
~nUPIC[\ui][\panFrequency] = { |direction|
    var state = ~nUPIC[\ui][\state];
    var freqRange = state[\zoomFreqMax] - state[\zoomFreqMin];
    var panStep = freqRange * 0.2;  // Pan by 20% of current frequency view
    var oldFreqMin = state[\zoomFreqMin];
    var oldFreqMax = state[\zoomFreqMax];
    var constants = ~nUPIC[\constants];
    var absFreqMin = constants[\freqMin] ? 20;
    var absFreqMax = constants[\freqMax] ? 7500;
    
    case
    { direction == \up } {
        // Pan up (higher frequencies)
        state[\zoomFreqMin] = state[\zoomFreqMin] + panStep;
        state[\zoomFreqMax] = state[\zoomFreqMax] + panStep;
    }
    { direction == \down } {
        // Pan down (lower frequencies)
        state[\zoomFreqMin] = state[\zoomFreqMin] - panStep;
        state[\zoomFreqMax] = state[\zoomFreqMax] - panStep;
    };
    
    // Constrain frequency view to absolute bounds
    if(state[\zoomFreqMin] < absFreqMin) {
        var offset = absFreqMin - state[\zoomFreqMin];
        state[\zoomFreqMin] = absFreqMin;
        state[\zoomFreqMax] = (state[\zoomFreqMax] + offset).min(absFreqMax);
    };
    
    if(state[\zoomFreqMax] > absFreqMax) {
        var offset = state[\zoomFreqMax] - absFreqMax;
        state[\zoomFreqMax] = absFreqMax;
        state[\zoomFreqMin] = (state[\zoomFreqMin] - offset).max(absFreqMin);
    };
    
    // Update display to show new frequency view
    if(~nUPIC[\ui][\refreshDisplay].notNil) {
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    // Check if we actually moved and provide feedback
    if(state[\zoomFreqMin] == oldFreqMin and: { state[\zoomFreqMax] == oldFreqMax }) {
        ("Cannot pan frequency further " ++ direction).postln;
    } {
        ("Frequency view: " ++ state[\zoomFreqMin].round(1) ++ "-" ++ state[\zoomFreqMax].round(1) ++ " Hz").postln;
    };
};

// RangeSlider integration functions
~nUPIC[\ui][\updateTimeZoomFromSlider] = { |startNorm, endNorm|
    var state = ~nUPIC[\ui][\state];
    var minGrabArea = 0.025;  // Minimum 2.5% of slider range for grab area
    var range, center, newStartNorm, newEndNorm;
    
    if(state.isNil) { ^nil };
    
    // Calculate requested range
    range = endNorm - startNorm;
    
    // If range is too small, expand it to minimum grab area
    if(range < minGrabArea) {
        center = (startNorm + endNorm) * 0.5;
        newStartNorm = (center - (minGrabArea * 0.5)).clip(0, 1 - minGrabArea);
        newEndNorm = newStartNorm + minGrabArea;
        
        // Update the actual slider values to reflect minimum grab area
        if(state[\horizontalRangeSlider].notNil) {
            {
                state[\horizontalRangeSlider].lo_(newStartNorm);
                state[\horizontalRangeSlider].hi_(newEndNorm);
            }.defer;
        };
        
        startNorm = newStartNorm;
        endNorm = newEndNorm;
    };
    
    // Update spatial view position based on constrained RangeSlider values
    state[\viewSpatialPos] = startNorm.clip(0, 1);
    state[\viewSpatialWidth] = (endNorm - startNorm).clip(minGrabArea, 1);
    state[\viewSpatialEnd] = (state[\viewSpatialPos] + state[\viewSpatialWidth]).clip(0, 1);
    
    // Update time-based values for display purposes
    if(state[\playDuration].notNil) {
        state[\viewStartTime] = state[\viewSpatialPos] * state[\playDuration];
        state[\viewEndTime] = state[\viewSpatialEnd] * state[\playDuration];
        state[\viewDuration] = state[\viewEndTime] - state[\viewStartTime];
    };
    
    // Refresh display
    ~nUPIC[\ui][\refreshDisplay].value;
    
    // Update zoom status labels if they exist
    ~nUPIC[\ui][\updateZoomStatusLabels].value;
};

~nUPIC[\ui][\updateFrequencyZoomFromSlider] = { |minNorm, maxNorm|
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var fullFreqMin, fullFreqMax, minGrabAreaNorm = 0.025, range, center, newMinNorm, newMaxNorm;
    
    if(state.isNil) { ^nil };
    
    // Get full frequency range
    fullFreqMin = constants[\freqMin] ? 20;
    fullFreqMax = constants[\freqMax] ? 7500;
    
    // Calculate requested normalized range
    range = maxNorm - minNorm;
    
    // If range is too small, expand it to minimum grab area
    if(range < minGrabAreaNorm) {
        center = (minNorm + maxNorm) * 0.5;
        newMinNorm = (center - (minGrabAreaNorm * 0.5)).clip(0, 1 - minGrabAreaNorm);
        newMaxNorm = newMinNorm + minGrabAreaNorm;
        
        // Update the actual slider values to reflect minimum grab area
        if(state[\verticalRangeSlider].notNil) {
            {
                state[\verticalRangeSlider].lo_(newMinNorm);
                state[\verticalRangeSlider].hi_(newMaxNorm);
            }.defer;
        };
        
        minNorm = newMinNorm;
        maxNorm = newMaxNorm;
    };
    
    // INTUITIVE MAPPING: Direct linear mapping from slider to frequency range
    // Bottom of slider (minNorm = 0) = 20 Hz (lowest frequency)
    // Top of slider (maxNorm = 1) = 7500 Hz (highest frequency)
    // This makes the slider behavior predictable and intuitive:
    // - Move bottom handle up: show less low frequencies (zoom into higher frequencies)
    // - Move top handle down: show less high frequencies (zoom into lower frequencies)
    
    state[\zoomFreqMin] = minNorm.linlin(0, 1, fullFreqMin, fullFreqMax);
    state[\zoomFreqMax] = maxNorm.linlin(0, 1, fullFreqMin, fullFreqMax);
    
    // Final bounds checking
    state[\zoomFreqMin] = state[\zoomFreqMin].clip(fullFreqMin, fullFreqMax);
    state[\zoomFreqMax] = state[\zoomFreqMax].clip(fullFreqMin, fullFreqMax);
    
    // Refresh display
    ~nUPIC[\ui][\refreshDisplay].value;
    
    // Update frequency status labels if they exist
    ~nUPIC[\ui][\updateZoomStatusLabels].value;
};

~nUPIC[\ui][\updateZoomStatusLabels] = {
    var state = ~nUPIC[\ui][\state];
    
    if(state.isNil or: { state[\controls].isNil }) { ^nil };
    
    // Update time range label
    if(state[\controls][\timeRangeLabel].notNil and: { state[\viewStartTime].notNil }) {
        {
            var timeStr = "%.1f-%.1fs".format(state[\viewStartTime], state[\viewEndTime] ? state[\viewStartTime]);
            state[\controls][\timeRangeLabel].string = timeStr;
        }.defer;
    };
    
    // Update frequency status label
    if(state[\controls][\freqStatusLabel].notNil and: { state[\zoomFreqMin].notNil }) {
        {
            var freqStr = "%.0f-%.0f Hz".format(state[\zoomFreqMin], state[\zoomFreqMax]);
            state[\controls][\freqStatusLabel].string = freqStr;
        }.defer;
    };
};

// Function to sync RangeSliders with current zoom state
~nUPIC[\ui][\syncRangeSliders] = {
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var fullFreqMin, fullFreqMax;
    var minGrabArea = 0.025;  // Minimum 2.5% grab area for both sliders
    
    if(state.isNil) { ^nil };
    
    // Sync horizontal (time) RangeSlider
    if(state[\horizontalRangeSlider].notNil and: { state[\viewSpatialPos].notNil }) {
        var startNorm = state[\viewSpatialPos];
        var endNorm = state[\viewSpatialEnd] ? (state[\viewSpatialPos] + 0.1);
        var range = endNorm - startNorm;
        
        // Ensure minimum grab area is respected during initialization
        if(range < minGrabArea) {
            var center = (startNorm + endNorm) * 0.5;
            startNorm = (center - (minGrabArea * 0.5)).clip(0, 1 - minGrabArea);
            endNorm = startNorm + minGrabArea;
            
            // Update the spatial view state to match the enforced minimum
            state[\viewSpatialPos] = startNorm;
            state[\viewSpatialEnd] = endNorm;
            state[\viewSpatialWidth] = endNorm - startNorm;
            
            // Update time-based values for display purposes
            if(state[\playDuration].notNil) {
                state[\viewStartTime] = state[\viewSpatialPos] * state[\playDuration];
                state[\viewEndTime] = state[\viewSpatialEnd] * state[\playDuration];
                state[\viewDuration] = state[\viewEndTime] - state[\viewStartTime];
            };
        };
        
        {
            state[\horizontalRangeSlider].lo_(startNorm);
            state[\horizontalRangeSlider].hi_(endNorm);
        }.defer;
    };
    
    // Sync vertical (frequency) RangeSlider
    if(state[\verticalRangeSlider].notNil and: { state[\zoomFreqMin].notNil }) {
        fullFreqMin = constants[\freqMin] ? 20;
        fullFreqMax = constants[\freqMax] ? 7500;
        
        {
            // Convert frequency values back to normalized coordinates (correct mapping)
            var minNorm = state[\zoomFreqMin].linlin(fullFreqMin, fullFreqMax, 0, 1);
            var maxNorm = state[\zoomFreqMax].linlin(fullFreqMin, fullFreqMax, 0, 1);
            
            state[\verticalRangeSlider].lo_(minNorm);
            state[\verticalRangeSlider].hi_(maxNorm);
        }.defer;
    };
};

"Intuitive zoom system design loaded".postln;
)
