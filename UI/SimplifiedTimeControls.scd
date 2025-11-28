// nUPIC Simplified Time Controls Design
// Removes the confusion between duration, zoom, center, and panning

/*
CURRENT PROBLEM:
- Duration slider (sets total time)
- Time zoom slider (zooms timeline view)
- Time center slider (centers zoom)
- Panning with Alt+Arrow (moves viewport)
- Grid time labels calculated with complex interactions

SIMPLIFIED APPROACH:

1. GLOBAL DURATION SETTING (unchanged)
   - Duration slider sets the total composition length
   - This is the "master timeline" - never changes during editing

2. REMOVE TIME ZOOM/CENTER SLIDERS
   - Eliminate the confusing time zoom and center sliders
   - The main view always shows the full duration
   - Simplifies grid time calculations significantly

3. PANNING FOR DETAILED WORK
   - Keep Alt+Arrow panning for detailed editing
   - Panning moves the viewport within the extended canvas
   - Grid time labels show actual time positions (not zoom-adjusted)
   - When panning, time labels simply shift to show current viewport time

4. VISUAL FEEDBACK
   - Grid shows actual time positions in the current viewport
   - Viewport position indicator shows where you are in the full composition
   - No more confusion between "zoom time" and "actual time"

BENEFITS:
- Much simpler mental model
- Grid time labels are always "real time" in composition
- Panning is purely for detailed editing, not time navigation
- Eliminates 2 complex sliders that interact confusingly
- Easier to understand what time position you're editing

IMPLEMENTATION:
- Remove time zoom controls from Controls.scd
- Simplify grid time calculation in Drawing.scd
- Make panning purely spatial (not temporal)
- Update time labels to show actual composition time
*/

// Simplified time calculation functions
~nUPIC[\\ui][\\simplifiedScreenToTime] = { |x, width|
    var state = ~nUPIC[\\ui][\\state];
    var viewportX = state[\\viewportX] ? 0;
    var virtualX = x + viewportX;  // Account for panning
    var normalizedX = virtualX / width;
    normalizedX * state[\\playDuration];  // Direct conversion to actual time
};

~nUPIC[\\ui][\\simplifiedTimeToScreen] = { |time, width|
    var state = ~nUPIC[\\ui][\\state];
    var viewportX = state[\\viewportX] ? 0;
    var normalizedTime = time / state[\\playDuration];
    var virtualX = normalizedTime * width;
    virtualX - viewportX;  // Convert to screen coordinates
};

"Simplified Time Controls design loaded".postln;
