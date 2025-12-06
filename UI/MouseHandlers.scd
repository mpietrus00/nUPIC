// nUPIC Mouse Interaction Handlers
// Handles mouse interactions for drawing, selection, erasing, and dragging
// Part of the nUPIC (nu-UPIC) modular system

(
// Ensure nUPIC UI namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

// Mouse down handler
~nUPIC[\ui][\handleMouseDown] = { |x, y, modifiers, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var viewportX, viewportY, virtualX, virtualY;  // For viewport translation

    if(state.isNil or: { data.isNil }) { ^nil };

    // Check for DRAG mode first - interactive scrubbing
    if(state[\playbackDirection] == \drag) {
        ~nUPIC[\ui][\startScrub].value(x, y, width, height);
        ^nil;  // Don't process other mouse actions in drag mode
    };

    // Convert mouse coordinates using zoom-aware coordinate system
    viewportX = state[\viewportX] ? 0;
    viewportY = state[\viewportY] ? 0;

    // Use spatial coordinate conversion - completely independent of playback duration
    if(~nUPIC[\ui][\screenToSpatial].notNil) {
        // Convert screen coordinate to normalized spatial coordinate (0.0 to 1.0)
        var spatialPos = ~nUPIC[\ui][\screenToSpatial].value(x, width);
        // Convert spatial position to canvas pixel coordinate for storage
        virtualX = spatialPos * width;
    } {
        // Fallback to direct coordinate when zoom system not available
        virtualX = x;
    };
    virtualY = y + viewportY;

    if(state[\isPlaying].not) {
        if(state[\eraseMode]) {
            // Erase mode - start erasing
            state[\isDrawing] = true;
            ~nUPIC[\ui][\eraseAt].value(x, y);
        } {
            // Normal mode - check if in select mode
            if(state[\selectMode]) {
                // Selection mode - look for trajectories to select or start marquee selection
                var clickedArc = nil;
                var threshold = 10;  // Click threshold in pixels
                
                // Check if clicking on existing arc
                if(data[\arcs].notNil) {
                    data[\arcs].do { |traj, i|
                        traj.do { |point|
                            var pointX, pointY, displayX;
                            pointX = if(point.isKindOf(Event)) { point.x } { point.x };
                            // Convert to display coordinates using spatial system
                            if(~nUPIC[\ui][\spatialToScreen].notNil) {
                                var spatialPos = pointX / width;  // Normalize to 0.0-1.0
                                displayX = ~nUPIC[\ui][\spatialToScreen].value(spatialPos, width);
                            } {
                                displayX = pointX;  // Fallback to direct coordinate
                            };
                            
                            if(point.isKindOf(Event)) {
                                pointY = point.freq.linlin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                            } {
                                var constants = ~nUPIC[\constants];
                                var freq = point.y.linlin(0, height, 
                                    constants[\freqMax] ? 7500, constants[\freqMin] ? 20);
                                pointY = freq.linlin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                            };
                            
                            // Check if click is near this point
                            if((displayX - x).abs < threshold and: { (pointY - y).abs < threshold }) {
                                clickedArc = i;
                            };
                        };
                    };
                };
                
                if(clickedArc.notNil) {
                    // Check if clicking on already selected arc - start drag
                    if(data[\selectedArcs].notNil and: { 
                        data[\selectedArcs].includes(clickedArc) 
                    }) {
                        // Start dragging
                        state[\isDragging] = true;
                        state[\dragStartX] = x;
                        state[\dragStartY] = y;
                        // Store original positions of all selected trajectories
                        state[\draggedArcs] = IdentityDictionary.new;
                        if(data[\selectedArcs].notNil) {
                            data[\selectedArcs].do { |i|
                                if(i < data[\arcs].size) {
                                    state[\draggedArcs][i] = data[\arcs][i].deepCopy;
                                };
                            };
                        };
                    } {
                        // Handle selection
                        if(data[\selectedArcs].isNil) {
                            data[\selectedArcs] = Set.new;
                        };
                        
                        if(modifiers.isShift) {
                            // Shift-click: toggle selection
                            if(data[\selectedArcs].includes(clickedArc)) {
                                data[\selectedArcs].remove(clickedArc);
                            } {
                                data[\selectedArcs].add(clickedArc);
                            };
                        } {
                            if(modifiers.isCmd) {
                                // Cmd-click: add to selection
                                data[\selectedArcs].add(clickedArc);
                            } {
                                // Regular click: select only this one
                                data[\selectedArcs].clear;
                                data[\selectedArcs].add(clickedArc);
                            };
                        };
                    };
                    
                    // Trigger selection change callback
                    if(~nUPIC[\ui][\onArcSelectionChanged].notNil) {
                        ~nUPIC[\ui][\onArcSelectionChanged].value;
                    };
                    
                    ~nUPIC[\ui][\refreshDisplay].value;
                } {
                    // No arc clicked - start marquee selection
                    state[\isMarqueeSelecting] = true;
                    state[\marqueeStartX] = x;
                    state[\marqueeStartY] = y;
                    state[\marqueeCurrentX] = x;
                    state[\marqueeCurrentY] = y;
                    
                    // Clear selection unless holding Cmd/Shift to add to selection
                    if(modifiers.isCmd.not and: { modifiers.isShift.not }) {
                        if(data[\selectedArcs].isNil) {
                            data[\selectedArcs] = Set.new;
                        } {
                            data[\selectedArcs].clear;
                        };
                    };
                };
            } {
                // No arc clicked - start drawing new one
                var freq;
                ("Starting to draw at virtual (% , %)".format(virtualX, virtualY)).postln;
                state[\isDrawing] = true;
                state[\currentArc] = List.new;
                // Convert y position to frequency using zoomed range
                freq = y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]);
                // Store ONLY spatial coordinates (x, y) and frequency - NO TIME
                // Time will be calculated during playback based on current duration
                state[\currentArc].add((x: virtualX, y: virtualY, freq: freq));
                ("First point added: x=%, y=%, freq=%".format(virtualX, virtualY, freq)).postln;
                ~nUPIC[\ui][\refreshDisplay].value;
            };
        };
    };
};

// Mouse move handler
~nUPIC[\ui][\handleMouseMove] = { |x, y, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];

    if(state.isNil) { ^nil };

    // Check for scrubbing (DRAG mode)
    if(state[\isScrubbing] == true) {
        ~nUPIC[\ui][\updateScrub].value(x, y, width, height);
        ^nil;  // Don't process other mouse actions while scrubbing
    };

    // Track mouse position for erase cursor
    state[\mouseX] = x;
    state[\mouseY] = y;

    if(state[\isMarqueeSelecting] == true) {
        // Update marquee selection rectangle
        state[\marqueeCurrentX] = x;
        state[\marqueeCurrentY] = y;
        ~nUPIC[\ui][\refreshDisplay].value;
    } {
        if(state[\isDragging] == true) {
            // Calculate drag offset
            var deltaX = x - state[\dragStartX];
            var deltaY = y - state[\dragStartY];
            var constrainedDeltaY = deltaY;

        // Update all selected trajectories
        if(data.notNil and: { data[\selectedArcs].notNil } and: {
            state[\draggedArcs].notNil
        }) {
            // First pass: find min/max Y across all selected trajectories to constrain deltaY
            // This prevents flattening by limiting the drag rather than clipping individual points
            var globalMinY = inf;
            var globalMaxY = inf.neg;

            data[\selectedArcs].do { |i|
                var originalTraj = state[\draggedArcs][i];
                if(originalTraj.notNil) {
                    originalTraj.do { |point|
                        var pointY = if(point.isKindOf(Event)) { point.y } { point.y };
                        if(pointY < globalMinY) { globalMinY = pointY };
                        if(pointY > globalMaxY) { globalMaxY = pointY };
                    };
                };
            };

            // Constrain deltaY so arc shape is preserved
            if(globalMinY < inf) {
                // Don't let minimum point go below 0
                if((globalMinY + deltaY) < 0) {
                    constrainedDeltaY = globalMinY.neg;
                };
                // Don't let maximum point go above height
                if((globalMaxY + constrainedDeltaY) > height) {
                    constrainedDeltaY = height - globalMaxY;
                };
            };

            // Second pass: apply constrained delta to all points
            data[\selectedArcs].do { |i|
                var originalTraj = state[\draggedArcs][i];
                if(originalTraj.notNil and: { i < data[\arcs].size }) {
                    data[\arcs][i] = originalTraj.collect { |point|
                        if(point.isKindOf(Event)) {
                            var newY = point.y + constrainedDeltaY;
                            var uiState = ~nUPIC[\ui][\state];
                            var newFreq = newY.linlin(0, height,
                                uiState[\zoomFreqMax], uiState[\zoomFreqMin]);
                            (x: point.x + deltaX,
                             y: newY,
                             freq: newFreq)
                        } {
                            Point(point.x + deltaX, point.y + constrainedDeltaY)
                        };
                    };

                    // Also update amplitude envelope positions if they exist
                    if(data[\amplitudeEnvelopes].notNil and: {
                        i < data[\amplitudeEnvelopes].size
                    } and: { data[\amplitudeEnvelopes][i].notNil }) {
                        data[\amplitudeEnvelopes][i] = data[\amplitudeEnvelopes][i].collect { |ampPoint|
                            (x: ampPoint.x + deltaX, amp: ampPoint.amp)
                        };
                    };
                };
            };
        };
        ~nUPIC[\ui][\refreshDisplay].value;
        } {
            if(state[\eraseMode]) {
                ~nUPIC[\ui][\refreshDisplay].value;  // Update erase cursor
            };
        };
    };
    
    if(state[\isDrawing] and: { state[\isPlaying].not }) {
        if(state[\eraseMode]) {
            // Continue erasing
            ~nUPIC[\ui][\eraseAt].value(x, y);
        } {
            // Continue drawing
            var freq, viewportX, viewportY, virtualX, virtualY;
            if(state[\currentArc].notNil) {
                // Translate mouse coordinates to spatial coordinates (same logic as mouse down)
                viewportX = state[\viewportX] ? 0;
                viewportY = state[\viewportY] ? 0;
                
                // Use spatial coordinate conversion - same logic as mouse down for consistency
                if(~nUPIC[\ui][\screenToSpatial].notNil) {
                    // Convert screen coordinate to normalized spatial coordinate (0.0 to 1.0)
                    var spatialPos = ~nUPIC[\ui][\screenToSpatial].value(x, width);
                    // Convert spatial position to canvas pixel coordinate for storage
                    virtualX = spatialPos * width;
                } {
                    // Fallback to direct coordinate when zoom system not available
                    virtualX = x;
                };
                virtualY = y + viewportY;
                
                // Convert y position to frequency using zoomed range
                freq = y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]);
                // Store ONLY spatial coordinates (x, y) and frequency - NO TIME
                // Time will be calculated during playback based on current duration
                state[\currentArc].add((x: virtualX, y: virtualY, freq: freq));
                // Status message removed for cleaner output
                // if((state[\currentArc].size % 5) == 0) {
                //     ("Drawing continues - % points".format(state[\currentArc].size)).postln;
                // };
                ~nUPIC[\ui][\refreshDisplay].value;
            };
        };
    };
};

// Mouse up handler
~nUPIC[\ui][\handleMouseUp] = { |x, y, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var defaults = ~nUPIC[\defaults];
    var synthDef;

    if(state.isNil) { ^nil };

    // Check for scrubbing (DRAG mode) - stop scrub on mouse up
    if(state[\isScrubbing] == true) {
        ~nUPIC[\ui][\stopScrub].value;
        ^nil;  // Don't process other mouse actions
    };

    if(state[\isMarqueeSelecting] == true) {
        // Finish marquee selection
        state[\isMarqueeSelecting] = false;
        ~nUPIC[\ui][\finishMarqueeSelection].value(width, height);
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    if(state[\isDragging] == true) {
        state[\isDragging] = false;
        state[\draggedArcs] = nil;
        "Finished dragging trajectories".postln;
    };
    
    if(state[\isDrawing]) {
        state[\isDrawing] = false;
        
        // Save arc if it has points
        if(state[\currentArc].notNil and: { state[\currentArc].size > 1 }) {
            var sortedArc;
            
            ("Saving arc with % points".format(state[\currentArc].size)).postln;
            
            // Sort arc points by X coordinate to handle right-to-left drawing
            // This ensures playback works correctly regardless of drawing direction
            sortedArc = state[\currentArc].sort({ |a, b| a.x < b.x });
            
            // Check if we reversed the arc
            if(sortedArc[0].x != state[\currentArc][0].x) {
                "Arc was drawn right-to-left - automatically sorted for correct playback".postln;
            };
            
            // Get the SynthDef name
            synthDef = if(~nUPIC[\defaults].notNil) {
                ~nUPIC[\defaults][\defaultSynthDef] ? \upicWavetable
            } {
                defaults[\defaultSynthDef] ? \upicWavetable
            };

            // Create default spatial envelope for multi-channel SynthDefs
            // Parse channel count from SynthDef name (e.g., upicWavetable8ch -> 8)
            block { |break|
                var synthDefStr = synthDef.asString;
                var numChannels = 1;
                var spatialEnv = nil;

                // Check for channel count in SynthDef name
                if(synthDefStr.contains("ch")) {
                    var chIndex = synthDefStr.find("ch");
                    if(chIndex.notNil and: { chIndex > 0 }) {
                        // Extract number before "ch"
                        var numStr = "";
                        var i = chIndex - 1;
                        while { i >= 0 and: { synthDefStr[i].isDecDigit } } {
                            numStr = synthDefStr[i].asString ++ numStr;
                            i = i - 1;
                        };
                        if(numStr.size > 0) {
                            numChannels = numStr.asInteger;
                        };
                    };
                };

                // Create first-to-last spatial envelope for multi-channel SynthDefs
                if(numChannels > 1) {
                    var startX = sortedArc[0].x;
                    var endX = sortedArc.last.x;
                    spatialEnv = List[
                        (x: startX, channel: 0),                  // Start at first speaker
                        (x: endX, channel: numChannels - 1)       // End at last speaker
                    ];
                    ("Creating spatial envelope: speaker 0 -> speaker " ++ (numChannels - 1)).postln;
                };

                // Use the arc manager if available, otherwise use direct data access
                if(data.respondsTo(\addArc)) {
                    data[\addArc].value(sortedArc, synthDef, nil, spatialEnv);
                } {
                    // Direct data access fallback
                    var maxSynths = constants[\maxTrajectories] ? 200;
                    var defaultWavetable = Array.fill(2048, { |i| sin(2pi * i / 2048) });

                    // Ensure data structures exist
                    if(data[\arcs].isNil) { data[\arcs] = List.new };
                    if(data[\amplitudeEnvelopes].isNil) { data[\amplitudeEnvelopes] = List.new };
                    if(data[\arcSynthDefs].isNil) { data[\arcSynthDefs] = List.new };
                    if(data[\spatialEnvelopes].isNil) { data[\spatialEnvelopes] = List.new };
                    if(data[\wavetables].isNil) { data[\wavetables] = List.new };
                    if(data[\wavetableBuffers].isNil) { data[\wavetableBuffers] = List.new };

                    if(data[\arcs].size >= maxSynths) {
                        // Remove oldest arc
                        data[\arcs].removeAt(0);
                        data[\amplitudeEnvelopes].removeAt(0);
                        data[\arcSynthDefs].removeAt(0);
                        if(data[\spatialEnvelopes].size > 0) { data[\spatialEnvelopes].removeAt(0) };
                        // Free and remove wavetable buffer
                        if(data[\wavetableBuffers].size > 0) {
                            if(data[\wavetableBuffers][0].notNil) { data[\wavetableBuffers][0].free };
                            data[\wavetableBuffers].removeAt(0);
                        };
                        if(data[\wavetables].size > 0) { data[\wavetables].removeAt(0) };
                    };

                    data[\arcs].add(sortedArc);
                    data[\amplitudeEnvelopes].add(nil);
                    data[\arcSynthDefs].add(synthDef);
                    data[\spatialEnvelopes].add(spatialEnv);
                    data[\wavetables].add(defaultWavetable.copy);
                    // Create server buffer for wavetable
                    if(Server.default.serverRunning) {
                        data[\wavetableBuffers].add(Buffer.loadCollection(Server.default, defaultWavetable));
                    } {
                        data[\wavetableBuffers].add(nil);
                    };
                };
            };
            
            ("New arc added (SynthDef: " ++ synthDef ++ ")").postln;
        };
        
        state[\currentArc] = nil;
        ~nUPIC[\ui][\refreshDisplay].value;
    };
};

// Erase function
~nUPIC[\ui][\eraseAt] = { |x, y|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var eraseRadius = 20;  // Erase radius in pixels
    var trajectoriesToRemove = List.new;
    var modifiedTrajectories = List.new;
    var width = constants[\defaultWidth] ? 1200;
    var height = constants[\defaultHeight] ? 800;
    
    if(state.isNil or: { data.isNil } or: { data[\arcs].isNil }) { ^nil };
    
    data[\arcs].do { |traj, trajIndex|
        var newTraj = List.new;
        var segments = List.new;
        var currentSegment = List.new;
        var hasErased = false;
        
        traj.do { |point|
            var pointX, pointY, displayX;
            pointX = if(point.isKindOf(Event)) { point.x } { point.x };
            // Convert to display coordinates using zoom-aware system
            if(~nUPIC[\ui][\timeToScreen].notNil) {
                var absoluteTime = (pointX / width) * state[\playDuration];
                displayX = ~nUPIC[\ui][\timeToScreen].value(absoluteTime, width);
            } {
                displayX = pointX;  // Fallback to direct coordinate
            };
            
            if(point.isKindOf(Event)) {
                pointY = point.freq.linlin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
            } {
                var freq = point.y.linlin(0, height, constants[\freqMax] ? 7500, constants[\freqMin] ? 20);
                pointY = freq.linlin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
            };
            
            // Check if point is within erase radius
            if((displayX - x).abs < eraseRadius and: { (pointY - y).abs < eraseRadius }) {
                // This point should be erased
                if(currentSegment.size > 0) {
                    segments.add(currentSegment.copy);
                    currentSegment = List.new;
                };
                hasErased = true;
            } {
                // Keep this point
                currentSegment.add(point);
            };
        };
        
        // Add last segment if any
        if(currentSegment.size > 0) {
            segments.add(currentSegment);
        };
        
        if(hasErased) {
            // If we erased something, check what's left
            if(segments.size == 0) {
                // Entire arc erased
                trajectoriesToRemove.add(trajIndex);
            } {
                if(segments.size == 1) {
                    // Single segment remains
                    newTraj = segments[0];
                } {
                    // Multiple segments - keep the largest
                    var largestSegment = segments[0];
                    segments.do { |seg|
                        if(seg.size > largestSegment.size) {
                            largestSegment = seg;
                        };
                    };
                    newTraj = largestSegment;
                };
                modifiedTrajectories.add([trajIndex, newTraj]);
            };
        };
    };
    
    // Apply modifications
    modifiedTrajectories.do { |mod|
        data[\arcs][mod[0]] = mod[1];
    };
    
    // Remove trajectories marked for deletion (in reverse order)
    trajectoriesToRemove.sort.reverse.do { |index|
        data[\arcs].removeAt(index);
        if(data[\amplitudeEnvelopes].notNil and: { index < data[\amplitudeEnvelopes].size }) {
            data[\amplitudeEnvelopes].removeAt(index);
        };
        if(data[\arcSynthDefs].notNil and: { index < data[\arcSynthDefs].size }) {
            data[\arcSynthDefs].removeAt(index);
        };
        if(data[\selectedArcs].notNil) {
            data[\selectedArcs].remove(index);
        };
    };
    
    // Adjust selected arc indices after removal
    if(data[\selectedArcs].notNil and: { trajectoriesToRemove.size > 0 }) {
        var newSelectedTrajectories = Set.new;
        data[\selectedArcs].do { |index|
            var adjustedIndex = index;
            trajectoriesToRemove.do { |removedIndex|
                if(removedIndex < index) {
                    adjustedIndex = adjustedIndex - 1;
                };
            };
            if(adjustedIndex >= 0 and: { adjustedIndex < data[\arcs].size }) {
                newSelectedTrajectories.add(adjustedIndex);
            };
        };
        data[\selectedArcs] = newSelectedTrajectories;
    };
    
    ~nUPIC[\ui][\refreshDisplay].value;
};

// Complete marquee selection - find trajectories within rectangle
~nUPIC[\ui][\finishMarqueeSelection] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var selectionRect;
    
    if(state.isNil or: { data.isNil } or: { data[\arcs].isNil }) { ^nil };
    
    // Calculate selection rectangle bounds
    selectionRect = Rect(
        state[\marqueeStartX].min(state[\marqueeCurrentX]),
        state[\marqueeStartY].min(state[\marqueeCurrentY]),
        (state[\marqueeCurrentX] - state[\marqueeStartX]).abs,
        (state[\marqueeCurrentY] - state[\marqueeStartY]).abs
    );
    
    // Only proceed if rectangle has some size
    if(selectionRect.width > 5 and: { selectionRect.height > 5 }) {
        // Initialize selection set if needed
        if(data[\selectedArcs].isNil) {
            data[\selectedArcs] = Set.new;
        };
        
        // Check each arc
        data[\arcs].do { |traj, trajIndex|
            var arcInSelection = false;
            
            // Check if any point of arc is within selection rectangle
            traj.do { |point|
                var pointX, pointY, displayX;
                pointX = if(point.isKindOf(Event)) { point.x } { point.x };
                // Convert to display coordinates using zoom-aware system
                if(~nUPIC[\ui][\timeToScreen].notNil) {
                    var absoluteTime = (pointX / width) * state[\playDuration];
                    displayX = ~nUPIC[\ui][\timeToScreen].value(absoluteTime, width);
                } {
                    displayX = pointX;  // Fallback to direct coordinate
                };
                
                if(point.isKindOf(Event)) {
                    pointY = point.freq.linlin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                } {
                    var freq = point.y.linlin(0, height, constants[\freqMax] ? 7500, constants[\freqMin] ? 20);
                    pointY = freq.linlin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                };
                
                // Check if point is within selection rectangle
                if(selectionRect.containsPoint(Point(displayX, pointY))) {
                    arcInSelection = true;
                };
            };
            
            // Add/remove arc from selection
            if(arcInSelection) {
                data[\selectedArcs].add(trajIndex);
            };
        };
        
        // Trigger selection change callback
        if(~nUPIC[\ui][\onArcSelectionChanged].notNil) {
            ~nUPIC[\ui][\onArcSelectionChanged].value;
        };
        
        ("Marquee selection completed: " ++ data[\selectedArcs].size ++ " arcs selected").postln;
    };
    
    // Clean up marquee state
    state[\marqueeStartX] = nil;
    state[\marqueeStartY] = nil;
    state[\marqueeCurrentX] = nil;
    state[\marqueeCurrentY] = nil;
};

// Move selected trajectories by specified offset
~nUPIC[\ui][\moveSelectedTrajectories] = { |deltaX, deltaY|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    
    if(state.isNil or: { data.isNil } or: { data[\selectedArcs].isNil }) { ^nil };
    
    if(data[\selectedArcs].size == 0) { ^nil };
    
    // Move each selected arc
    data[\selectedArcs].do { |trajIndex|
        if(trajIndex < data[\arcs].size) {
            data[\arcs][trajIndex] = data[\arcs][trajIndex].collect { |point|
                if(point.isKindOf(Event)) {
                    var newX = (point.x + deltaX).max(0);  // Prevent negative time
                    var newFreq;
                    
                    if(deltaY != 0) {
                        // Adjust frequency proportionally
                        var freqFactor = if(deltaY > 0) { 1.05 } { 0.95 };  // 5% change per step
                        newFreq = (point.freq * freqFactor).clip(
                            constants[\freqMin] ? 20, 
                            constants[\freqMax] ? 7500
                        );
                    } {
                        newFreq = point.freq;
                    };
                    
                    (x: newX, y: point.y, freq: newFreq)
                } {
                    // Old format points
                    var newX = (point.x + deltaX).max(0);
                    var newY = (point.y + (deltaY * 5)).clip(0, 800);  // Scale Y movement
                    Point(newX, newY)
                };
            };
        };
    };
    
    ~nUPIC[\ui][\refreshDisplay].value;
};

// Copy selected trajectories to clipboard
~nUPIC[\ui][\copySelected] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var copiedCount = 0;
    
    if(state.isNil or: { data.isNil } or: { data[\selectedArcs].isNil }) { ^0 };
    
    if(data[\selectedArcs].size == 0) { ^0 };
    
    // Create clipboard data structure
    if(data[\clipboard].isNil) {
        data[\clipboard] = (
            trajectories: List.new,
            amplitudeEnvelopes: List.new,
            synthDefs: List.new
        );
    } {
        // Clear existing clipboard
        data[\clipboard][\arcs].clear;
        data[\clipboard][\amplitudeEnvelopes].clear;
        data[\clipboard][\synthDefs].clear;
    };
    
    // Copy selected trajectories
    data[\selectedArcs].do { |trajIndex|
        if(trajIndex < data[\arcs].size) {
            data[\clipboard][\arcs].add(data[\arcs][trajIndex].deepCopy);
            
            // Copy amplitude envelope if it exists
            if(data[\amplitudeEnvelopes].notNil and: { trajIndex < data[\amplitudeEnvelopes].size }) {
                var ampEnv = data[\amplitudeEnvelopes][trajIndex];
                if(ampEnv.notNil) {
                    data[\clipboard][\amplitudeEnvelopes].add(ampEnv.deepCopy);
                } {
                    data[\clipboard][\amplitudeEnvelopes].add(nil);
                };
            } {
                data[\clipboard][\amplitudeEnvelopes].add(nil);
            };
            
            // Copy SynthDef if it exists
            if(data[\arcSynthDefs].notNil and: { trajIndex < data[\arcSynthDefs].size }) {
                data[\clipboard][\synthDefs].add(data[\arcSynthDefs][trajIndex]);
            } {
                data[\clipboard][\synthDefs].add(nil);
            };
            
            copiedCount = copiedCount + 1;
        };
    };
    
    copiedCount
};

// Paste trajectories from clipboard with offset
~nUPIC[\ui][\pasteTrajectories] = { |offsetX = 30, offsetY = -30|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var defaults = ~nUPIC[\defaults];
    var pastedIndices = List.new;
    
    if(state.isNil or: { data.isNil } or: { data[\clipboard].isNil }) { ^[] };
    
    if(data[\clipboard][\arcs].size == 0) { ^[] };
    
    // Ensure data structures exist
    if(data[\arcs].isNil) { data[\arcs] = List.new };
    if(data[\amplitudeEnvelopes].isNil) { data[\amplitudeEnvelopes] = List.new };
    if(data[\arcSynthDefs].isNil) { data[\arcSynthDefs] = List.new };
    if(data[\selectedArcs].isNil) { data[\selectedArcs] = Set.new };
    
    // Clear current selection
    data[\selectedArcs].clear;
    
    // Paste each arc
    data[\clipboard][\arcs].do { |traj, i|
        var newTraj = traj.collect { |point|
            if(point.isKindOf(Event)) {
                var newX = (point.x + offsetX).max(0);
                var newY = (point.y + offsetY).clip(0, constants[\defaultHeight] ? 800);
                var newFreq = if(point.freq.notNil) {
                    point.freq  // Keep original frequency
                } {
                    newY.linlin(0, constants[\defaultHeight] ? 800, 
                        constants[\freqMax] ? 7500, constants[\freqMin] ? 20)
                };
                (x: newX, y: newY, freq: newFreq)
            } {
                var newX = (point.x + offsetX).max(0);
                var newY = (point.y + offsetY).clip(0, constants[\defaultHeight] ? 800);
                Point(newX, newY)
            };
        };
        
        var newIndex = data[\arcs].size;
        data[\arcs].add(newTraj);
        pastedIndices.add(newIndex);
        data[\selectedArcs].add(newIndex);
        
        // Paste amplitude envelope if available
        if(i < data[\clipboard][\amplitudeEnvelopes].size and: { 
            data[\clipboard][\amplitudeEnvelopes][i].notNil 
        }) {
            var ampEnv = data[\clipboard][\amplitudeEnvelopes][i].collect { |ampPoint|
                (x: ampPoint.x + offsetX, amp: ampPoint.amp)
            };
            data[\amplitudeEnvelopes].add(ampEnv);
        } {
            data[\amplitudeEnvelopes].add(nil);
        };
        
        // Paste SynthDef if available
        if(i < data[\clipboard][\synthDefs].size and: { 
            data[\clipboard][\synthDefs][i].notNil 
        }) {
            data[\arcSynthDefs].add(data[\clipboard][\synthDefs][i]);
        } {
            data[\arcSynthDefs].add(defaults[\defaultSynthDef] ? \upicWavetable);
        };
    };
    
    ~nUPIC[\ui][\refreshDisplay].value;
    pastedIndices
};

// Utility function to reverse arc direction
// Useful for manually changing direction of existing trajectories
~nUPIC[\ui][\reverseArcDirection] = { |arcIndex|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    
    if(state.isNil or: { data.isNil } or: { data[\arcs].isNil }) {
        "Cannot reverse arc - data not available".postln;
        ^nil;
    };
    
    if(arcIndex.isNil or: { arcIndex >= data[\arcs].size }) {
        "Invalid arc index".postln;
        ^nil;
    };
    
    // Reverse the arc points
    data[\arcs][arcIndex] = data[\arcs][arcIndex].reverse;
    
    // Also reverse amplitude envelope if it exists
    if(data[\amplitudeEnvelopes].notNil and: { 
        arcIndex < data[\amplitudeEnvelopes].size 
    } and: { data[\amplitudeEnvelopes][arcIndex].notNil }) {
        data[\amplitudeEnvelopes][arcIndex] = data[\amplitudeEnvelopes][arcIndex].reverse;
    };
    
    ("Reversed arc " ++ arcIndex).postln;
    ~nUPIC[\ui][\refreshDisplay].value;
};

// Utility function to reverse all selected trajectories
~nUPIC[\ui][\reverseSelectedTrajectories] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var reversedCount = 0;
    
    if(state.isNil or: { data.isNil } or: { data[\selectedArcs].isNil }) {
        "No arcs selected for reversal".postln;
        ^0;
    };
    
    if(data[\selectedArcs].size == 0) {
        "No arcs selected".postln;
        ^0;
    };
    
    data[\selectedArcs].do { |trajIndex|
        ~nUPIC[\ui][\reverseArcDirection].value(trajIndex);
        reversedCount = reversedCount + 1;
    };
    
    ("Reversed " ++ reversedCount ++ " trajectories").postln;
    reversedCount
};

// Time Compression/Expansion for selected trajectories
// factor < 1 = compress (shorter), factor > 1 = expand (longer)
~nUPIC[\ui][\compressTimeSelected] = { |factor|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var transformedCount = 0;

    if(state.isNil or: { data.isNil } or: { data[\selectedArcs].isNil }) {
        "No arcs selected for time transformation".postln;
        ^0;
    };

    if(data[\selectedArcs].size == 0) {
        "No arcs selected".postln;
        ^0;
    };

    data[\selectedArcs].do { |trajIndex|
        if(trajIndex < data[\arcs].size) {
            var traj = data[\arcs][trajIndex];
            var xValues = traj.collect { |pt| pt.x };
            var centerX = (xValues.minItem + xValues.maxItem) / 2;

            // Transform arc points
            data[\arcs][trajIndex] = traj.collect { |point|
                if(point.isKindOf(Event)) {
                    var newX = centerX + ((point.x - centerX) * factor);
                    (x: newX, y: point.y, freq: point.freq)
                } {
                    Point(centerX + ((point.x - centerX) * factor), point.y)
                };
            };

            // Also scale amplitude envelope
            if(data[\amplitudeEnvelopes].notNil and: {
                trajIndex < data[\amplitudeEnvelopes].size
            } and: { data[\amplitudeEnvelopes][trajIndex].notNil }) {
                var ampEnv = data[\amplitudeEnvelopes][trajIndex];
                var ampXValues = ampEnv.collect { |pt| pt.x };
                var ampCenterX = (ampXValues.minItem + ampXValues.maxItem) / 2;
                data[\amplitudeEnvelopes][trajIndex] = ampEnv.collect { |ampPoint|
                    (x: ampCenterX + ((ampPoint.x - ampCenterX) * factor), amp: ampPoint.amp)
                };
            };

            transformedCount = transformedCount + 1;
        };
    };

    if(factor < 1) {
        ("Compressed time by " ++ ((1 - factor) * 100).round(1) ++ "% for " ++ transformedCount ++ " arcs").postln;
    } {
        ("Expanded time by " ++ ((factor - 1) * 100).round(1) ++ "% for " ++ transformedCount ++ " arcs").postln;
    };

    ~nUPIC[\ui][\refreshDisplay].value;
    transformedCount
};

// Frequency Compression/Expansion for selected trajectories
// factor < 1 = compress (narrower range), factor > 1 = expand (wider range)
// Uses log-space scaling around geometric mean to preserve glissando character
~nUPIC[\ui][\compressFrequencySelected] = { |factor|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var transformedCount = 0;
    var viewHeight, zoomFreqMax, zoomFreqMin;

    if(state.isNil or: { data.isNil } or: { data[\selectedArcs].isNil }) {
        "No arcs selected for frequency transformation".postln;
        ^0;
    };

    if(data[\selectedArcs].size == 0) {
        "No arcs selected".postln;
        ^0;
    };

    // Get view parameters for Y recalculation
    viewHeight = state[\viewHeight] ? 800;
    zoomFreqMax = state[\zoomFreqMax] ? (constants[\freqMax] ? 7500);
    zoomFreqMin = state[\zoomFreqMin] ? (constants[\freqMin] ? 20);

    data[\selectedArcs].do { |trajIndex|
        if(trajIndex < data[\arcs].size) {
            var traj = data[\arcs][trajIndex];
            var freqs, logFreqs, logCenter;

            freqs = traj.collect { |pt|
                if(pt.isKindOf(Event)) { pt.freq } { nil }
            }.reject { |f| f.isNil };

            if(freqs.size > 0) {
                // Calculate geometric mean (center in log space)
                logFreqs = freqs.collect { |f| f.log };
                logCenter = logFreqs.sum / logFreqs.size;

                data[\arcs][trajIndex] = traj.collect { |point|
                    if(point.isKindOf(Event)) {
                        // Scale in log space around center
                        var logFreq = point.freq.log;
                        var newLogFreq = logCenter + ((logFreq - logCenter) * factor);
                        var newFreq = newLogFreq.exp.clip(
                            constants[\freqMin] ? 20,
                            constants[\freqMax] ? 7500
                        );
                        // Recalculate Y position from new frequency
                        var newY = newFreq.explin(zoomFreqMin, zoomFreqMax, viewHeight, 0);
                        (x: point.x, y: newY, freq: newFreq)
                    } {
                        point;
                    };
                };

                transformedCount = transformedCount + 1;
            };
        };
    };

    if(factor < 1) {
        ("Compressed frequency range by " ++ ((1 - factor) * 100).round(1) ++ "% for " ++ transformedCount ++ " arcs").postln;
    } {
        ("Expanded frequency range by " ++ ((factor - 1) * 100).round(1) ++ "% for " ++ transformedCount ++ " arcs").postln;
    };

    ~nUPIC[\ui][\refreshDisplay].value;
    transformedCount
};

// ============================================
// DRAG/SCRUB MODE - Interactive audio scrubbing
// ============================================

// Start scrubbing - create synths for all arcs
~nUPIC[\ui][\startScrub] = { |x, y, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];

    if(state.isNil or: { data.isNil }) { ^nil };

    "Starting scrub mode...".postln;
    state[\isScrubbing] = true;
    state[\scrubSynths] = List.new;

    // Create a synth for each arc
    if(data[\arcs].notNil) {
        data[\arcs].do { |traj, i|
            if(traj.size > 1) {
                var synthDef = if(data[\trajectorySynthDefs].notNil and: {
                    i < data[\trajectorySynthDefs].size
                }) {
                    data[\trajectorySynthDefs][i] ? \simpleGravObject
                } { \simpleGravObject };

                try {
                    var synth = Synth(synthDef, [
                        \freq, 440,
                        \amp, 0,
                        \pan, 0,
                        \gate, 1
                    ], s);
                    state[\scrubSynths].add(synth);
                } { |err|
                    state[\scrubSynths].add(nil);
                };
            } {
                state[\scrubSynths].add(nil);
            };
        };
    };

    // Update synths for initial position
    ~nUPIC[\ui][\updateScrub].value(x, y, width, height);
};

// Update scrub - update synth parameters based on mouse position
~nUPIC[\ui][\updateScrub] = { |x, y, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var currentTime, currentDuration;

    if(state.isNil or: { data.isNil } or: { state[\isScrubbing].not }) { ^nil };
    if(state[\scrubSynths].isNil) { ^nil };

    // Calculate time position from mouse X
    currentDuration = state[\playDuration] ? 10;
    currentTime = (x / width) * currentDuration;
    currentTime = currentTime.clip(0, currentDuration);

    // Update playback position for visual display
    state[\playbackPosition] = currentTime;

    // Update each arc synth
    if(data[\arcs].notNil) {
        data[\arcs].do { |traj, i|
            var synth = state[\scrubSynths][i];

            if(synth.notNil and: { traj.size > 1 }) {
                var canvasWidth = constants[\defaultWidth] ? 1200;
                var firstPoint = traj[0];
                var lastPoint = traj.last;
                var arcStartTime, arcEndTime, arcDuration;

                // Calculate arc time range
                arcStartTime = (firstPoint.x / canvasWidth) * currentDuration;
                arcEndTime = (lastPoint.x / canvasWidth) * currentDuration;
                arcDuration = arcEndTime - arcStartTime;

                // Check if current time is within arc's time range
                if(currentTime >= arcStartTime and: { currentTime <= arcEndTime } and: { arcDuration > 0 }) {
                    // Interpolate within arc
                    var arcProgress = (currentTime - arcStartTime) / arcDuration;
                    var numPoints = traj.size;
                    var floatIndex = arcProgress * (numPoints - 1);
                    var index1 = floatIndex.floor.asInteger.clip(0, numPoints - 2);
                    var index2 = (index1 + 1).clip(0, numPoints - 1);
                    var interpFactor = floatIndex - index1;

                    var point1 = traj[index1];
                    var point2 = traj[index2];
                    var freq1 = if(point1.isKindOf(Event)) { point1.freq } { 440 };
                    var freq2 = if(point2.isKindOf(Event)) { point2.freq } { 440 };
                    var freq = freq1 + ((freq2 - freq1) * interpFactor);

                    // Get amplitude from envelope if available
                    var amp = 0.3;
                    if(data[\amplitudeEnvelopes].notNil and: {
                        i < data[\amplitudeEnvelopes].size
                    } and: { data[\amplitudeEnvelopes][i].notNil }) {
                        var ampEnv = data[\amplitudeEnvelopes][i];
                        amp = ~nUPIC[\ui][\interpolateAmplitudeAt].value(ampEnv, currentTime, canvasWidth, currentDuration) ? 0.3;
                    };

                    synth.set(\freq, freq, \amp, amp * 0.5, \pan, 0);
                } {
                    // Outside arc range - silence
                    synth.set(\amp, 0);
                };
            };
        };
    };

    // Refresh display to show playback position
    { state[\drawView].refresh }.defer;
};

// Stop scrubbing - release all synths
~nUPIC[\ui][\stopScrub] = {
    var state = ~nUPIC[\ui][\state];

    if(state.isNil) { ^nil };

    "Stopping scrub mode".postln;
    state[\isScrubbing] = false;

    // Release all scrub synths
    if(state[\scrubSynths].notNil) {
        state[\scrubSynths].do { |synth|
            if(synth.notNil) {
                try {
                    synth.set(\gate, 0);
                    { synth.free }.defer(0.1);
                } { };
            };
        };
        state[\scrubSynths].clear;
    };

    state[\playbackPosition] = 0;
    { state[\drawView].refresh }.defer;
};

// Helper to interpolate amplitude at a given time position
~nUPIC[\ui][\interpolateAmplitudeAt] = { |ampEnv, currentTime, canvasWidth, duration|
    var result = 0.3;  // Default amplitude
    var currentX = (currentTime / duration) * canvasWidth;

    if(ampEnv.notNil and: { ampEnv.size > 0 }) {
        // Find surrounding points
        var prevPoint, nextPoint;
        ampEnv.do { |point|
            if(point.x <= currentX) { prevPoint = point };
        };
        ampEnv.do { |point|
            if(nextPoint.isNil and: { point.x >= currentX }) { nextPoint = point };
        };

        if(prevPoint.notNil and: { nextPoint.notNil }) {
            if(prevPoint.x == nextPoint.x) {
                result = prevPoint.amp;
            } {
                var factor = (currentX - prevPoint.x) / (nextPoint.x - prevPoint.x);
                result = prevPoint.amp + ((nextPoint.amp - prevPoint.amp) * factor);
            };
        } {
            if(prevPoint.notNil) { result = prevPoint.amp };
            if(nextPoint.notNil) { result = nextPoint.amp };
        };
    };
    result
};

"nUPIC Mouse Handlers loaded".postln;
"Additional functions available:".postln;
"  ~nUPIC[\\ui][\\reverseArcDirection].value(index) - Reverse specific arc".postln;
"  ~nUPIC[\\ui][\\reverseSelectedTrajectories].value - Reverse all selected trajectories".postln;
"  ~nUPIC[\\ui][\\compressTimeSelected].value(factor) - Time compress/expand selected (0.9=compress, 1.1=expand)".postln;
"  ~nUPIC[\\ui][\\compressFrequencySelected].value(factor) - Freq compress/expand selected (0.9=compress, 1.1=expand)".postln;
"  Drag mode: Select DRAG from playback menu, then click and drag on canvas to scrub through sound".postln;
)
