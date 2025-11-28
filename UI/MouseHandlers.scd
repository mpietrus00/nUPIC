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
                var clickedTrajectory = nil;
                var threshold = 10;  // Click threshold in pixels
                
                // Check if clicking on existing trajectory
                if(data[\trajectories].notNil) {
                    data[\trajectories].do { |traj, i|
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
                                clickedTrajectory = i;
                            };
                        };
                    };
                };
                
                if(clickedTrajectory.notNil) {
                    // Check if clicking on already selected trajectory - start drag
                    if(data[\selectedTrajectories].notNil and: { 
                        data[\selectedTrajectories].includes(clickedTrajectory) 
                    }) {
                        // Start dragging
                        state[\isDragging] = true;
                        state[\dragStartX] = x;
                        state[\dragStartY] = y;
                        // Store original positions of all selected trajectories
                        state[\draggedTrajectories] = IdentityDictionary.new;
                        if(data[\selectedTrajectories].notNil) {
                            data[\selectedTrajectories].do { |i|
                                if(i < data[\trajectories].size) {
                                    state[\draggedTrajectories][i] = data[\trajectories][i].deepCopy;
                                };
                            };
                        };
                    } {
                        // Handle selection
                        if(data[\selectedTrajectories].isNil) {
                            data[\selectedTrajectories] = Set.new;
                        };
                        
                        if(modifiers.isShift) {
                            // Shift-click: toggle selection
                            if(data[\selectedTrajectories].includes(clickedTrajectory)) {
                                data[\selectedTrajectories].remove(clickedTrajectory);
                            } {
                                data[\selectedTrajectories].add(clickedTrajectory);
                            };
                        } {
                            if(modifiers.isCmd) {
                                // Cmd-click: add to selection
                                data[\selectedTrajectories].add(clickedTrajectory);
                            } {
                                // Regular click: select only this one
                                data[\selectedTrajectories].clear;
                                data[\selectedTrajectories].add(clickedTrajectory);
                            };
                        };
                    };
                    
                    // Trigger selection change callback
                    if(~nUPIC[\ui][\onTrajectorySelectionChanged].notNil) {
                        ~nUPIC[\ui][\onTrajectorySelectionChanged].value;
                    };
                    
                    ~nUPIC[\ui][\refreshDisplay].value;
                } {
                    // No trajectory clicked - start marquee selection
                    state[\isMarqueeSelecting] = true;
                    state[\marqueeStartX] = x;
                    state[\marqueeStartY] = y;
                    state[\marqueeCurrentX] = x;
                    state[\marqueeCurrentY] = y;
                    
                    // Clear selection unless holding Cmd/Shift to add to selection
                    if(modifiers.isCmd.not and: { modifiers.isShift.not }) {
                        if(data[\selectedTrajectories].isNil) {
                            data[\selectedTrajectories] = Set.new;
                        } {
                            data[\selectedTrajectories].clear;
                        };
                    };
                };
            } {
                // No trajectory clicked - start drawing new one
                var freq;
                ("Starting to draw at virtual (% , %)".format(virtualX, virtualY)).postln;
                state[\isDrawing] = true;
                state[\currentTrajectory] = List.new;
                // Convert y position to frequency using zoomed range
                freq = y.linlin(0, height, state[\zoomFreqMax], state[\zoomFreqMin]);
                // Store ONLY spatial coordinates (x, y) and frequency - NO TIME
                // Time will be calculated during playback based on current duration
                state[\currentTrajectory].add((x: virtualX, y: virtualY, freq: freq));
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
        
        // Update all selected trajectories
        if(data.notNil and: { data[\selectedTrajectories].notNil } and: { 
            state[\draggedTrajectories].notNil 
        }) {
            data[\selectedTrajectories].do { |i|
                var originalTraj = state[\draggedTrajectories][i];
                if(originalTraj.notNil and: { i < data[\trajectories].size }) {
                    data[\trajectories][i] = originalTraj.collect { |point|
                        if(point.isKindOf(Event)) {
                            var newY = (point.y + deltaY).clip(0, height);
                            var state = ~nUPIC[\ui][\state];
                            var newFreq = newY.linlin(0, height, 
                                state[\zoomFreqMax], state[\zoomFreqMin]);
                            (x: point.x + deltaX,
                             y: newY,
                             freq: newFreq)
                        } {
                            Point(point.x + deltaX, (point.y + deltaY).clip(0, height))
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
            if(state[\currentTrajectory].notNil) {
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
                state[\currentTrajectory].add((x: virtualX, y: virtualY, freq: freq));
                // Status message removed for cleaner output
                // if((state[\currentTrajectory].size % 5) == 0) {
                //     ("Drawing continues - % points".format(state[\currentTrajectory].size)).postln;
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
    
    if(state[\isMarqueeSelecting] == true) {
        // Finish marquee selection
        state[\isMarqueeSelecting] = false;
        ~nUPIC[\ui][\finishMarqueeSelection].value(width, height);
        ~nUPIC[\ui][\refreshDisplay].value;
    };
    
    if(state[\isDragging] == true) {
        state[\isDragging] = false;
        state[\draggedTrajectories] = nil;
        "Finished dragging trajectories".postln;
    };
    
    if(state[\isDrawing]) {
        state[\isDrawing] = false;
        
        // Save trajectory if it has points
        if(state[\currentTrajectory].notNil and: { state[\currentTrajectory].size > 1 }) {
            var sortedTrajectory;
            
            ("Saving trajectory with % points".format(state[\currentTrajectory].size)).postln;
            
            // Sort trajectory points by X coordinate to handle right-to-left drawing
            // This ensures playback works correctly regardless of drawing direction
            sortedTrajectory = state[\currentTrajectory].sort({ |a, b| a.x < b.x });
            
            // Check if we reversed the trajectory
            if(sortedTrajectory[0].x != state[\currentTrajectory][0].x) {
                "Trajectory was drawn right-to-left - automatically sorted for correct playback".postln;
            };
            
            // Use the trajectory manager if available, otherwise use direct data access
            if(data.respondsTo(\addTrajectory)) {
                // Using trajectory manager
                synthDef = defaults[\defaultSynthDef] ? \simpleGravObject;
                data[\addTrajectory].value(sortedTrajectory, synthDef, nil);
            } {
                // Direct data access fallback
                var maxSynths = constants[\maxTrajectories] ? 200;
                
                // Ensure data structures exist
                if(data[\trajectories].isNil) { data[\trajectories] = List.new };
                if(data[\amplitudeEnvelopes].isNil) { data[\amplitudeEnvelopes] = List.new };
                if(data[\trajectorySynthDefs].isNil) { data[\trajectorySynthDefs] = List.new };
                
                if(data[\trajectories].size >= maxSynths) {
                    // Remove oldest trajectory
                    data[\trajectories].removeAt(0);
                    data[\amplitudeEnvelopes].removeAt(0);
                    data[\trajectorySynthDefs].removeAt(0);
                };
                
                data[\trajectories].add(sortedTrajectory);
                data[\amplitudeEnvelopes].add(nil);  // Add placeholder for amplitude envelope
                
                // Use currently selected SynthDef or default
                synthDef = defaults[\defaultSynthDef] ? \simpleGravObject;
                data[\trajectorySynthDefs].add(synthDef);
            };
            
            ("New trajectory added (SynthDef: " ++ synthDef ++ ")").postln;
        };
        
        state[\currentTrajectory] = nil;
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
    
    if(state.isNil or: { data.isNil } or: { data[\trajectories].isNil }) { ^nil };
    
    data[\trajectories].do { |traj, trajIndex|
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
                // Entire trajectory erased
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
        data[\trajectories][mod[0]] = mod[1];
    };
    
    // Remove trajectories marked for deletion (in reverse order)
    trajectoriesToRemove.sort.reverse.do { |index|
        data[\trajectories].removeAt(index);
        if(data[\amplitudeEnvelopes].notNil and: { index < data[\amplitudeEnvelopes].size }) {
            data[\amplitudeEnvelopes].removeAt(index);
        };
        if(data[\trajectorySynthDefs].notNil and: { index < data[\trajectorySynthDefs].size }) {
            data[\trajectorySynthDefs].removeAt(index);
        };
        if(data[\selectedTrajectories].notNil) {
            data[\selectedTrajectories].remove(index);
        };
    };
    
    // Adjust selected trajectory indices after removal
    if(data[\selectedTrajectories].notNil and: { trajectoriesToRemove.size > 0 }) {
        var newSelectedTrajectories = Set.new;
        data[\selectedTrajectories].do { |index|
            var adjustedIndex = index;
            trajectoriesToRemove.do { |removedIndex|
                if(removedIndex < index) {
                    adjustedIndex = adjustedIndex - 1;
                };
            };
            if(adjustedIndex >= 0 and: { adjustedIndex < data[\trajectories].size }) {
                newSelectedTrajectories.add(adjustedIndex);
            };
        };
        data[\selectedTrajectories] = newSelectedTrajectories;
    };
    
    ~nUPIC[\ui][\refreshDisplay].value;
};

// Complete marquee selection - find trajectories within rectangle
~nUPIC[\ui][\finishMarqueeSelection] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var selectionRect;
    
    if(state.isNil or: { data.isNil } or: { data[\trajectories].isNil }) { ^nil };
    
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
        if(data[\selectedTrajectories].isNil) {
            data[\selectedTrajectories] = Set.new;
        };
        
        // Check each trajectory
        data[\trajectories].do { |traj, trajIndex|
            var trajectoryInSelection = false;
            
            // Check if any point of trajectory is within selection rectangle
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
                    trajectoryInSelection = true;
                };
            };
            
            // Add/remove trajectory from selection
            if(trajectoryInSelection) {
                data[\selectedTrajectories].add(trajIndex);
            };
        };
        
        // Trigger selection change callback
        if(~nUPIC[\ui][\onTrajectorySelectionChanged].notNil) {
            ~nUPIC[\ui][\onTrajectorySelectionChanged].value;
        };
        
        ("Marquee selection completed: " ++ data[\selectedTrajectories].size ++ " trajectories selected").postln;
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
    
    if(state.isNil or: { data.isNil } or: { data[\selectedTrajectories].isNil }) { ^nil };
    
    if(data[\selectedTrajectories].size == 0) { ^nil };
    
    // Move each selected trajectory
    data[\selectedTrajectories].do { |trajIndex|
        if(trajIndex < data[\trajectories].size) {
            data[\trajectories][trajIndex] = data[\trajectories][trajIndex].collect { |point|
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
    
    if(state.isNil or: { data.isNil } or: { data[\selectedTrajectories].isNil }) { ^0 };
    
    if(data[\selectedTrajectories].size == 0) { ^0 };
    
    // Create clipboard data structure
    if(data[\clipboard].isNil) {
        data[\clipboard] = (
            trajectories: List.new,
            amplitudeEnvelopes: List.new,
            synthDefs: List.new
        );
    } {
        // Clear existing clipboard
        data[\clipboard][\trajectories].clear;
        data[\clipboard][\amplitudeEnvelopes].clear;
        data[\clipboard][\synthDefs].clear;
    };
    
    // Copy selected trajectories
    data[\selectedTrajectories].do { |trajIndex|
        if(trajIndex < data[\trajectories].size) {
            data[\clipboard][\trajectories].add(data[\trajectories][trajIndex].deepCopy);
            
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
            if(data[\trajectorySynthDefs].notNil and: { trajIndex < data[\trajectorySynthDefs].size }) {
                data[\clipboard][\synthDefs].add(data[\trajectorySynthDefs][trajIndex]);
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
    
    if(data[\clipboard][\trajectories].size == 0) { ^[] };
    
    // Ensure data structures exist
    if(data[\trajectories].isNil) { data[\trajectories] = List.new };
    if(data[\amplitudeEnvelopes].isNil) { data[\amplitudeEnvelopes] = List.new };
    if(data[\trajectorySynthDefs].isNil) { data[\trajectorySynthDefs] = List.new };
    if(data[\selectedTrajectories].isNil) { data[\selectedTrajectories] = Set.new };
    
    // Clear current selection
    data[\selectedTrajectories].clear;
    
    // Paste each trajectory
    data[\clipboard][\trajectories].do { |traj, i|
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
        
        var newIndex = data[\trajectories].size;
        data[\trajectories].add(newTraj);
        pastedIndices.add(newIndex);
        data[\selectedTrajectories].add(newIndex);
        
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
            data[\trajectorySynthDefs].add(data[\clipboard][\synthDefs][i]);
        } {
            data[\trajectorySynthDefs].add(defaults[\defaultSynthDef] ? \simpleGravObject);
        };
    };
    
    ~nUPIC[\ui][\refreshDisplay].value;
    pastedIndices
};

// Utility function to reverse trajectory direction
// Useful for manually changing direction of existing trajectories
~nUPIC[\ui][\reverseTrajectoryDirection] = { |trajectoryIndex|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    
    if(state.isNil or: { data.isNil } or: { data[\trajectories].isNil }) {
        "Cannot reverse trajectory - data not available".postln;
        ^nil;
    };
    
    if(trajectoryIndex.isNil or: { trajectoryIndex >= data[\trajectories].size }) {
        "Invalid trajectory index".postln;
        ^nil;
    };
    
    // Reverse the trajectory points
    data[\trajectories][trajectoryIndex] = data[\trajectories][trajectoryIndex].reverse;
    
    // Also reverse amplitude envelope if it exists
    if(data[\amplitudeEnvelopes].notNil and: { 
        trajectoryIndex < data[\amplitudeEnvelopes].size 
    } and: { data[\amplitudeEnvelopes][trajectoryIndex].notNil }) {
        data[\amplitudeEnvelopes][trajectoryIndex] = data[\amplitudeEnvelopes][trajectoryIndex].reverse;
    };
    
    ("Reversed trajectory " ++ trajectoryIndex).postln;
    ~nUPIC[\ui][\refreshDisplay].value;
};

// Utility function to reverse all selected trajectories
~nUPIC[\ui][\reverseSelectedTrajectories] = {
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var reversedCount = 0;
    
    if(state.isNil or: { data.isNil } or: { data[\selectedTrajectories].isNil }) {
        "No trajectories selected for reversal".postln;
        ^0;
    };
    
    if(data[\selectedTrajectories].size == 0) {
        "No trajectories selected".postln;
        ^0;
    };
    
    data[\selectedTrajectories].do { |trajIndex|
        ~nUPIC[\ui][\reverseTrajectoryDirection].value(trajIndex);
        reversedCount = reversedCount + 1;
    };
    
    ("Reversed " ++ reversedCount ++ " trajectories").postln;
    reversedCount
};

"nUPIC Mouse Handlers loaded".postln;
"Additional functions available:".postln;
"  ~nUPIC[\\ui][\\reverseTrajectoryDirection].value(index) - Reverse specific trajectory".postln;
"  ~nUPIC[\\ui][\\reverseSelectedTrajectories].value - Reverse all selected trajectories".postln;
)
