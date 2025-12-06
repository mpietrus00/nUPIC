// nUPIC Drawing Module
// Canvas drawing functionality, arc rendering, zoom/pan, mouse interactions
// Part of the nUPIC (nu-UPIC) modular system

(
// Ensure nUPIC UI namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
if(~nUPIC[\ui].isNil) { ~nUPIC[\ui] = IdentityDictionary.new };

// Initialize drawing functionality
~nUPIC[\ui][\initializeDrawing] = { |drawView, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var gridSystems = ~nUPIC[\gridSystems];
    
    if(state.isNil) {
        "UI state not initialized".postln;
        ^nil;
    };
    
    // Mouse tracking for erase cursor
    drawView.mouseOverAction = { |view, x, y|
        state[\mouseX] = x;
        state[\mouseY] = y;
        if(state[\eraseMode]) {
            drawView.refresh;
        };
    };
    
    // Main drawing function
    drawView.drawFunc = {
        ~nUPIC[\ui][\drawCanvas].value(drawView, width, height);
    };
    
    // Mouse interactions
    drawView.mouseDownAction = { |view, x, y, modifiers|
        ~nUPIC[\ui][\handleMouseDown].value(x, y, modifiers, width, height);
    };
    
    drawView.mouseMoveAction = { |view, x, y|
        ~nUPIC[\ui][\handleMouseMove].value(x, y, width, height);
    };
    
    drawView.mouseUpAction = { |view, x, y|
        ~nUPIC[\ui][\handleMouseUp].value(x, y, width, height);
    };
    
    "Drawing module initialized".postln;
};

// Main canvas drawing function
~nUPIC[\ui][\drawCanvas] = { |drawView, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    
    if(state.isNil or: { data.isNil }) { ^nil };
    
    // Clear background
    Pen.fillColor = colors[\background] ? Color.white;
    Pen.fillRect(drawView.bounds);
    
    // Draw grid if enabled
    if(state[\showGrid]) {
        ~nUPIC[\ui][\drawGrid].value(width, height);
    };
    
    // Draw all completed trajectories
    if(data[\arcs].notNil) {
        data[\arcs].do { |traj, i|
            ~nUPIC[\ui][\drawArc].value(traj, i, width, height);
        };
    };
    
    // Draw current arc being drawn
    if(state[\currentArc].notNil and: { state[\currentArc].size > 1 }) {
        ~nUPIC[\ui][\drawCurrentArc].value(state[\currentArc], width, height);
    };
    
    // Draw playback position
    if(state[\isPlaying]) {
        ~nUPIC[\ui][\drawPlaybackPosition].value(width, height);
    };
    
    // Draw UI overlays
    ~nUPIC[\ui][\drawUIOverlays].value(width, height);
    
    // Draw erase cursor
    if(state[\eraseMode] and: { state[\mouseX].notNil }) {
        ~nUPIC[\ui][\drawEraseCursor].value();
    };
    
    // Draw marquee selection rectangle
    if(state[\isMarqueeSelecting] == true and: { state[\marqueeStartX].notNil }) {
        ~nUPIC[\ui][\drawMarqueeSelection].value();
    };
};

// Grid drawing function
~nUPIC[\ui][\drawGrid] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var constants = ~nUPIC[\constants];
    var colors = ~nUPIC[\colors];
    var gridSystems = ~nUPIC[\gridSystems];
    var viewportX, viewportY;  // Viewport offsets for panning
    
    if(state.isNil) { ^nil };
    
    // Get viewport offsets
    viewportX = state[\viewportX] ? 0;
    viewportY = state[\viewportY] ? 0;
    
    Pen.strokeColor = colors[\grid] ? Color.gray(0.3, 0.5);
    Pen.width = 0.5;
    
    // Time grid lines removed - using variable speed function instead
    // Drawing area now represents musical space rather than fixed time divisions
    
    // Horizontal lines (frequency) - use tuning-specific grid
    if(gridSystems.notNil and: { state[\gridType].notNil }) {
        ~nUPIC[\ui][\drawFrequencyGrid].value(width, height);
    } {
        // Fallback: simple frequency grid - match labels (8 lines)
        8.do { |i|
            var y = (i + 1) * (height / 9);  // 8 divisions = 9 segments
            
            Pen.strokeColor = colors[\grid] ? Color.gray(0.3, 0.5);
            Pen.width = 0.5;
            Pen.line(Point(0, y), Point(width, y));
            Pen.stroke;
        };
    };
};

// Frequency grid drawing with tuning systems
~nUPIC[\ui][\drawFrequencyGrid] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var colors = ~nUPIC[\colors];
    var gridSystems = ~nUPIC[\gridSystems];
    var gridFreqs;
    
    if(state.isNil) { ^nil };
    
    // Calculate frequencies directly - same logic as labels to ensure perfect sync
    if(gridSystems.notNil and: { state[\gridType].notNil }) {
        // Get tuning-system specific frequencies  
        gridFreqs = ~nUPIC[\ui][\getTuningSystemFrequencies].value(state[\gridType], height);
        
        if(gridFreqs.notNil and: { gridFreqs.size > 0 }) {
            var minSpacing = ~nUPIC[\ui][\getMinSpacingForTuning].value(state[\gridType], height);
            var lastY = -1000;   // Track last position to match label filtering
            
            gridFreqs.do { |freq|
                var y = freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                
                // Use same filtering logic as labels to ensure 1:1 correspondence
                if(y >= 15 and: { y <= (height - 15) } and: { (y - lastY).abs >= minSpacing }) {
                    // Draw grid line
                    Pen.strokeColor = colors[\grid] ? Color.gray(0.3, 0.5);
                    Pen.width = 0.5;
                    Pen.line(Point(0, y), Point(width, y));
                    Pen.stroke;
                    
                    lastY = y;  // Update last position
                };
            };
        };
    } {
        // Fallback: simple frequency grid - use exactly 8 lines to match labels
        8.do { |i|
            var y = (i + 1) * (height / 9);  // 8 divisions = 9 segments
            
            Pen.strokeColor = colors[\grid] ? Color.gray(0.3, 0.5);
            Pen.width = 0.5;
            Pen.line(Point(0, y), Point(width, y));
            Pen.stroke;
        };
    };
};

// Get tuning system specific frequencies for current zoom range
~nUPIC[\ui][\getTuningSystemFrequencies] = { |gridType, height|
    var state = ~nUPIC[\ui][\state];
    var gridSystems = ~nUPIC[\gridSystems];
    var freqs = [];
    var minFreq = state[\zoomFreqMin];
    var maxFreq = state[\zoomFreqMax];
    var numLines = (height / 30).clip(8, 20).asInteger;
    
    if(state.isNil or: { gridSystems.isNil }) { ^[] };
    
    // Use tuning-specific frequency calculation
    if(gridSystems[gridType].notNil and: { gridSystems[gridType][\calculation].notNil }) {
        freqs = gridSystems[gridType][\calculation].value(440, minFreq, maxFreq, numLines);
    } {
        // Fallback to equal temperament calculation
        freqs = ~nUPIC[\ui][\calculateGridFrequencies].value(440, numLines);
    };
    
    freqs.sort;
};

// Get minimum spacing between labels based on tuning system
~nUPIC[\ui][\getMinSpacingForTuning] = { |gridType, height|
    var spacing = 20;  // Default minimum spacing
    
    case 
    { gridType == \equalTemperament } { spacing = 25; }
    { gridType == \justIntonation } { spacing = 30; }
    { gridType.asString.contains("fokker") } { spacing = 25; }
    { gridType.asString.contains("31") } { spacing = 20; }
    { gridType == \harmonicSeries } { spacing = 35; }
    { gridType == \quarterTone } { spacing = 18; }
    { gridType == \pythagorean } { spacing = 28; }
    { spacing = 20; };  // Default
    
    // Adjust for height - more space needed for smaller heights
    spacing = spacing * (300.0 / height).clip(0.8, 1.5);
    
    spacing;
};

// Format frequency labels based on tuning system
~nUPIC[\ui][\formatFrequencyLabel] = { |freq, gridType|
    var labelText;
    
    case 
    { gridType == \equalTemperament } {
        // For equal temperament, show only frequency to save space
        labelText = freq.round(0.1).asString ++ "Hz";
    }
    { gridType == \justIntonation } {
        // For just intonation, show ratio if available from gridSystems
        var gridSystems = ~nUPIC[\gridSystems];
        if(gridSystems.notNil and: { gridSystems[\justIntonation].notNil } and: {
            gridSystems[\justIntonation][\ratioLabels].notNil
        }) {
            var ratios = gridSystems[\justIntonation][\ratioLabels];
            var closestRatio = ratios.minItem { |ratio| (ratio[1] - freq).abs };
            labelText = closestRatio[0] ++ " (" ++ freq.round(0.1) ++ "Hz)";
        } {
            labelText = freq.round(0.1).asString ++ "Hz";
        };
    }
    { gridType.asString.contains("fokker") or: { gridType.asString.contains("31") } } {
        // For Fokker periodicity blocks and 31-TET
        var gridSystems = ~nUPIC[\gridSystems];
        if(gridSystems.notNil and: { gridSystems[gridType].notNil } and: {
            gridSystems[gridType][\noteNames].notNil
        }) {
            var noteNames = gridSystems[gridType][\noteNames];
            var freqs = gridSystems[gridType][\frequencies] ? [];
            var closestIndex = freqs.minIndex { |f| (f - freq).abs };
            if(closestIndex.notNil and: { closestIndex < noteNames.size }) {
                labelText = noteNames[closestIndex] ++ " (" ++ freq.round(0.1) ++ "Hz)";
            } {
                labelText = freq.round(0.1).asString ++ "Hz";
            };
        } {
            labelText = freq.round(0.1).asString ++ "Hz";
        };
    }
    {
        // Default: just show frequency
        labelText = freq.round(0.1).asString ++ "Hz";
    };
    
    labelText;
};

// Calculate grid frequencies for different tuning systems
~nUPIC[\ui][\calculateGridFrequencies] = { |baseFreq = 440, numLines = 15|
    var state = ~nUPIC[\ui][\state];
    var gridSystems = ~nUPIC[\gridSystems];
    var freqs = [];
    var minFreq = state[\zoomFreqMin];
    var maxFreq = state[\zoomFreqMax];
    
    if(state.isNil or: { gridSystems.isNil }) { ^[] };
    
    // Debug: Log frequency range being used
    "[DEBUG] Calculating grid frequencies: min=%, max=%, lines=%".format(minFreq, maxFreq, numLines).postln;
    
    // Use grid system calculation if available
    if(gridSystems[state[\gridType]].notNil and: { 
        gridSystems[state[\gridType]][\calculation].notNil 
    }) {
        freqs = gridSystems[state[\gridType]][\calculation].value(baseFreq, minFreq, maxFreq, numLines);
        "[DEBUG] Used tuning-specific grid, generated % frequencies".format(freqs.size).postln;
    } {
        // Fallback: equal temperament
        var semitone = 2.pow(1/12);
        var startNote = (minFreq / baseFreq).log2 * 12;
        var endNote = (maxFreq / baseFreq).log2 * 12;
        var noteRange = endNote - startNote;
        var step = noteRange / numLines;
        
        numLines.do { |i|
            var note = startNote + (i * step);
            var freq = baseFreq * semitone.pow(note);
            if(freq >= minFreq and: { freq <= maxFreq }) {
                freqs = freqs.add(freq);
            };
        };
        "[DEBUG] Used equal temperament fallback, generated % frequencies".format(freqs.size).postln;
    };
    
    // Always ensure boundary frequencies are included for full range coverage
    if(freqs.size > 0) {
        // Add minFreq if it's not very close to an existing frequency
        if(freqs.minItem > (minFreq * 1.2)) {
            freqs = freqs.add(minFreq);
            "[DEBUG] Added minFreq boundary: %Hz".format(minFreq).postln;
        };
        // Add maxFreq if it's not very close to an existing frequency  
        if(freqs.maxItem < (maxFreq * 0.8)) {
            freqs = freqs.add(maxFreq);
            "[DEBUG] Added maxFreq boundary: %Hz".format(maxFreq).postln;
        };
    };
    
    freqs.sort;
    
    // Final debug info
    if(freqs.size > 0) {
        "[DEBUG] Final frequency range: %Hz - %Hz (% total frequencies)".format(
            freqs.minItem.round(0.1), freqs.maxItem.round(0.1), freqs.size
        ).postln;
    };
    
    freqs;
};

// Draw individual arc
~nUPIC[\ui][\drawArc] = { |traj, index, width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var colors = ~nUPIC[\colors];
    var constants = ~nUPIC[\constants];
    var isSelected, ampEnv, visiblePoints, visibleAmplitudes;
    var viewportX, viewportY;  // Get viewport offsets for panning
    
    if(state.isNil or: { data.isNil } or: { traj.isNil } or: { traj.size < 2 }) { ^nil };
    
    // Get viewport offsets for panning support
    viewportX = state[\viewportX] ? 0;
    viewportY = state[\viewportY] ? 0;
    
    isSelected = if(data[\selectedArcs].notNil) {
        data[\selectedArcs].includes(index)
    } { false };
    
    ampEnv = if(data[\amplitudeEnvelopes].notNil and: { index < data[\amplitudeEnvelopes].size }) {
        data[\amplitudeEnvelopes][index]
    } { nil };
    
    visiblePoints = List.new;
    visibleAmplitudes = List.new;
    
    // Filter and map points based on zoom view
    traj.do { |point|
        var originalX, originalY, screenX, screenY, y, amp, freq, absoluteTime;
        
        amp = 0.3;  // Default amplitude
        
        // Get original coordinates - trajectories are now stored as pure spatial coordinates
        originalX = if(point.isKindOf(Event)) { point.x } { point.x };
        originalY = if(point.isKindOf(Event)) { point.y } { point.y };
        
        // Use spatial coordinate system for zoom-aware drawing
        if(~nUPIC[\ui][\spatialToScreen].notNil) {
            var spatialPos = originalX / width;  // Normalize to 0.0-1.0 space
            screenX = ~nUPIC[\ui][\spatialToScreen].value(spatialPos, width);
            
            // Check if point is within visible spatial view
            if(screenX.isNil or: { screenX < 0 } or: { screenX > width }) {
                screenX = -1000;  // Mark as invisible
            };
        } {
            // Fallback to old viewport system if zoom not initialized
            screenX = originalX - viewportX;
        };
        
        screenY = originalY - viewportY;
        
        // Calculate frequency-mapped Y coordinate (exponential mapping for perceptual scaling)
        if(point.isKindOf(Event)) {
            y = point.freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0).clip(0, height);
        } {
            // Old format - recalculate frequency from y using zoom-aware ranges
            var zoomFreqMax = state[\zoomFreqMax] ? (constants[\freqMax] ? 7500);
            var zoomFreqMin = state[\zoomFreqMin] ? (constants[\freqMin] ? 20);
            freq = point.y.linexp(0, height, zoomFreqMax, zoomFreqMin);
            y = freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0).clip(0, height);
        };
        
        // Check if point is visible within current viewport (using frequency-mapped coordinates)
        if((screenX >= 0) and: { screenX <= width } and: { y >= 0 } and: { y <= height }) {
            
            // Calculate amplitude at this point if envelope exists
            if(ampEnv.notNil and: { ampEnv.size > 1 }) {
                var firstPoint = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
                var lastPoint = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
                var normalizedPos = (originalX - firstPoint) / (lastPoint - firstPoint).max(1);
                var trajLength = (lastPoint - firstPoint).max(1);
                var ampX = normalizedPos.clip(0, 1) * trajLength;  // Map to actual arc length
                
                // Find amplitude by interpolation
                var foundAmp = false;
                block { |break|
                    (ampEnv.size - 1).do { |j|
                        if((ampEnv[j].x <= ampX) and: { (ampEnv[j + 1].x >= ampX) }) {
                            var interpFactor = (ampX - ampEnv[j].x) / (ampEnv[j + 1].x - ampEnv[j].x).max(0.001);
                            amp = ampEnv[j].amp.blend(ampEnv[j + 1].amp, interpFactor).clip(0, 1);
                            foundAmp = true;
                            break.value;
                        };
                    };
                };
                
                // Handle edge cases if no interpolation was found
                if(foundAmp.not) {
                    if(ampX <= ampEnv.first.x) { 
                        amp = ampEnv.first.amp.clip(0, 1);
                    } {
                        if(ampX >= ampEnv.last.x) { 
                            amp = ampEnv.last.amp.clip(0, 1);
                        } {
                            // Fallback - use default
                            amp = 0.3;
                        };
                    };
                };
                
                // Debug output for first few points (disabled to reduce console spam)
                /*
                if(index == 0 and: { originalX < 50 }) {
                    ("Point x=%, ampX=%, amp=%").format(originalX.round(1), ampX.round(1), amp.round(0.01)).postln;
                };
                */
            } {
                // No amplitude envelope - use default based on arc index for visual variety
                amp = 0.2 + (index * 0.1 % 0.6);  // Range from 0.2 to 0.8 based on arc index
                
                // Debug for trajectories without amplitude envelopes (disabled to reduce console spam)
                /*
                if(index == 0 and: { originalX < 50 }) {
                    ("No ampEnv for arc %, using default amp=%").format(index, amp.round(0.01)).postln;
                };
                */
            };
            
            // Use frequency-mapped Y coordinate instead of original screen coordinate
            visiblePoints.add(Point(screenX, y));
            visibleAmplitudes.add(amp);
        };
    };
    
    // Draw the visible portion with smooth gradient based on amplitude
    if(visiblePoints.size > 1) {
        (visiblePoints.size - 1).do { |j|
            var point1 = visiblePoints[j];
            var point2 = visiblePoints[j + 1];
            var amp1 = visibleAmplitudes[j];
            var amp2 = visibleAmplitudes[j + 1];
            var numSubdivisions = 3;  // Subdivide for smoother color
            
            // Draw subdivided segments for smooth color transitions
            numSubdivisions.do { |k|
                var t1 = k / numSubdivisions;
                var t2 = (k + 1) / numSubdivisions;
                var subPoint1 = Point(
                    point1.x.blend(point2.x, t1),
                    point1.y.blend(point2.y, t1)
                );
                var subPoint2 = Point(
                    point1.x.blend(point2.x, t2),
                    point1.y.blend(point2.y, t2)
                );
                var subAmp = amp1.blend(amp2, (t1 + t2) / 2);
                
                // Perceptually uniform amplitude color mapping
                var hue, saturation, brightness;
                
                // Multi-stage color progression: Dark Blue → Cyan → Yellow → Red
                case 
                { subAmp <= 0.33 } {
                    // Silent to quiet: Dark blue to cyan
                    hue = subAmp.linlin(0, 0.33, 0.67, 0.5);  // Blue to cyan
                    saturation = subAmp.linlin(0, 0.33, 0.8, 1.0);
                    brightness = subAmp.linlin(0, 0.33, 0.3, 0.7);
                }
                { subAmp <= 0.66 } {
                    // Quiet to medium: Cyan to yellow
                    hue = subAmp.linlin(0.33, 0.66, 0.5, 0.17);  // Cyan to yellow
                    saturation = 1.0;
                    brightness = subAmp.linlin(0.33, 0.66, 0.7, 0.9);
                }
                {
                    // Medium to loud: Yellow to red
                    hue = subAmp.linlin(0.66, 1.0, 0.17, 0.0);  // Yellow to red
                    saturation = 1.0;
                    brightness = subAmp.linlin(0.66, 1.0, 0.9, 1.0);
                };
                
                // Apply selection highlighting
                if(isSelected) {
                    brightness = (brightness + 0.2).min(1);
                    saturation = 1.0;
                };
                
                Pen.strokeColor = Color.hsv(hue, saturation, brightness, if(isSelected, 1.0, 0.8));
                Pen.width = if(isSelected, 4, 2) * subAmp.linlin(0, 1, 0.8, 1.2);
                Pen.line(subPoint1, subPoint2);
                Pen.stroke;
            };
        };
    };
};

// Draw current arc being drawn
~nUPIC[\ui][\drawCurrentArc] = { |currentTraj, width, height|
    var state = ~nUPIC[\ui][\state];
    
    if(state.isNil) { ^nil };
    
    Pen.strokeColor = Color.black;
    Pen.width = 3;
    
    if(currentTraj[0].isKindOf(Event)) {
        // Use spatial coordinate system for zoom-aware drawing
        var firstPoint = currentTraj[0];
        var firstY = firstPoint.freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
        var firstX;
        
        // Convert spatial coordinate to screen coordinate using spatial zoom system
        if(~nUPIC[\ui][\spatialToScreen].notNil) {
            var spatialPos = firstPoint.x / width;  // Normalize to 0.0-1.0 space
            firstX = ~nUPIC[\ui][\spatialToScreen].value(spatialPos, width);
            
            // Check if point is within visible spatial view
            if(firstX.isNil or: { firstX < 0 } or: { firstX > width }) {
                firstX = -1000;  // Outside view range
            };
        } {
            firstX = firstPoint.x;  // Fallback to direct coordinate
        };
        
        if(firstX >= 0) {
            Pen.moveTo(Point(firstX, firstY));
            
            currentTraj.do { |point|
                var y = point.freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                var x;
                
                // Convert each point using spatial coordinate system
                if(~nUPIC[\ui][\spatialToScreen].notNil) {
                    var spatialPos = point.x / width;  // Normalize to 0.0-1.0 space
                    x = ~nUPIC[\ui][\spatialToScreen].value(spatialPos, width);
                    
                    // Only draw if point is within visible spatial view
                    if(x.notNil and: { x >= 0 } and: { x <= width }) {
                        Pen.lineTo(Point(x, y));
                    };
                } {
                    x = point.x;  // Fallback
                    Pen.lineTo(Point(x, y));
                };
            };
        };
    } {
        // Old format trajectories - draw as-is
        Pen.moveTo(currentTraj[0]);
        currentTraj.do { |point|
            Pen.lineTo(point);
        };
    };
    Pen.stroke;
};

// Draw playback position
~nUPIC[\ui][\drawPlaybackPosition] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var playbackX, timeText, spatialPos;
    
    if(state.isNil) { ^nil };
    
    // First convert current playback time to normalized spatial position (0.0-1.0)
    // This ensures consistent timing with how trajectories are played
    if(state[\playbackPosition].notNil and: { state[\playDuration].notNil }) {
        spatialPos = state[\playbackPosition] / state[\playDuration];
        
        // Then convert spatial position to screen coordinate using the zoom system
        if(~nUPIC[\ui][\spatialToScreen].notNil) {
            playbackX = ~nUPIC[\ui][\spatialToScreen].value(spatialPos, width);
            
            // Only draw if playback position is within visible view
            if(playbackX.notNil and: { playbackX >= 0 } and: { playbackX <= width }) {
                // Draw playback line
                Pen.strokeColor = Color.red;
                Pen.width = 2;
                Pen.line(Point(playbackX, 0), Point(playbackX, height));
                Pen.stroke;
                
                // Draw time indicator at top
                timeText = state[\playbackPosition].round(0.01).asString ++ "s";
                Pen.stringAtPoint(
                    timeText,
                    Point(playbackX - 20, 10),
                    Font("Arial", 10, true),
                    Color.red
                );
            };
        } {
            // Fallback to old system
            var viewportX = state[\viewportX] ? 0;
            var normalizedPos = state[\playbackPosition] / state[\playDuration];
            var virtualPlaybackX = normalizedPos * width;
            var screenPlaybackX = virtualPlaybackX - viewportX;
            
            if((screenPlaybackX >= 0) and: { screenPlaybackX <= width }) {
                Pen.strokeColor = Color.red;
                Pen.width = 2;
                Pen.line(Point(screenPlaybackX, 0), Point(screenPlaybackX, height));
                Pen.stroke;
            };
        };
    };
};

// Draw UI overlays (instructions, mode indicators, etc.)
~nUPIC[\ui][\drawUIOverlays] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var data = ~nUPIC[\data];
    var modeText, modeColor;
    var viewportX, viewportY;
    
    if(state.isNil) { ^nil };
    
    // Instructions
    Pen.fillColor = Color.black;
    Pen.stringAtPoint(
        "G: Select | E: Erase | SPACE: Play | P: Pages | ,/.: Prev/Next Page | H: Help",
        Point(10, 10),
        Font("Arial", 11),
        Color.black
    );

    // Page indicator (show current page if pages system is active)
    if(~nUPIC[\pages].notNil and: { ~nUPIC[\pages][\manager].notNil }) {
        var mgr = ~nUPIC[\pages][\manager];
        var pageIdx = mgr.getCurrentIndex.value;
        var pageCount = mgr.count.value;
        var page = mgr.getCurrent.value;
        if(page.notNil) {
            var pageText = "Page %/% : % (% sec)".format(
                pageIdx + 1,
                pageCount,
                page.label,
                page.duration.round(0.1)
            );
            Pen.stringAtPoint(
                pageText,
                Point(width / 2 - 80, 10),
                Font("Arial", 12, true),
                Color.new(0.2, 0.4, 0.6)
            );
        };
    };
    
    // Show current mode
    modeText = if(state[\isPlaying]) { "PLAYING" } {
        if(state[\playbackDirection] == \drag) { "DRAG MODE" } {
            if(state[\eraseMode]) { "ERASE MODE" } {
                if(state[\selectMode]) { "SELECT MODE" } { "DRAW MODE" }
            }
        }
    };

    modeColor = if(state[\isPlaying]) { Color.green } {
        if(state[\playbackDirection] == \drag) { Color.magenta } {
            if(state[\eraseMode]) { Color.red } {
                if(state[\selectMode]) { Color.blue } { Color.gray }
            }
        }
    };
    
    Pen.stringAtPoint(
        modeText,
        Point(width - 140, 10),
        Font("Arial", 14, true),
        modeColor
    );
    
    // Show selected arc info
    if(data.notNil and: { data[\selectedArcs].notNil } and: { data[\selectedArcs].size > 0 }) {
        Pen.stringAtPoint(
            "Selected: " ++ data[\selectedArcs].size ++ " trajectories",
            Point(width - 200, 30),
            Font("Arial", 12),
            Color.blue
        );
    };
    
    // Show viewport position for debugging (small font, bottom left)
    viewportX = state[\viewportX] ? 0;
    viewportY = state[\viewportY] ? 0;
    if(viewportX != 0 or: { viewportY != 0 }) {
        Pen.stringAtPoint(
            "Viewport: (" ++ viewportX.round ++ ", " ++ viewportY.round ++ ")",
            Point(10, height - 30),
            Font("Arial", 10),
            Color.gray(0.6)
        );
    };
};

// Draw erase cursor
~nUPIC[\ui][\drawEraseCursor] = {
    var state = ~nUPIC[\ui][\state];
    var eraseRadius;
    
    if(state.isNil or: { state[\mouseX].isNil }) { ^nil };
    
    eraseRadius = 20;
    Pen.strokeColor = Color.red.alpha_(0.5);
    Pen.fillColor = Color.red.alpha_(0.1);
    Pen.width = 2;
    Pen.addOval(Rect.aboutPoint(Point(state[\mouseX], state[\mouseY]), eraseRadius, eraseRadius));
    Pen.fillStroke;
};

// Refresh display function
~nUPIC[\ui][\refreshDisplay] = {
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        if(state[\drawView].notNil) {
            { state[\drawView].refresh }.defer;
        };
        if(state[\freqLabelView].notNil) {
            { state[\freqLabelView].refresh }.defer;
        };
    };
};

// Emergency stop function
~nUPIC[\ui][\emergencyStop] = {
    var state = ~nUPIC[\ui][\state];
    
    if(state.notNil) {
        // Stop playback
        ~nUPIC[\ui][\stopPlayback].value;
        
        // Clear all synths immediately
        if(state[\synths].notNil) {
            state[\synths].do { |synth|
                if(synth.notNil) { synth.free };
            };
            state[\synths].clear;
        };
        
        // Free synth group
        if(state[\synthGroup].notNil) {
            state[\synthGroup].free;
            state[\synthGroup] = nil;
        };
        
        "Emergency stop - all audio stopped".postln;
    };
};

// Helper function for coordinate conversions (exponential for perceptual frequency)
~nUPIC[\ui][\screenToFreq] = { |y, height|
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        y.linexp(height, 0, state[\zoomFreqMin], state[\zoomFreqMax])
    } { nil };
};

~nUPIC[\ui][\freqToScreen] = { |freq, height|
    var state = ~nUPIC[\ui][\state];
    if(state.notNil) {
        freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0)
    } { nil };
};

// Zoom-based coordinate conversion functions
~nUPIC[\ui][\screenToTime] = { |x, width|
    var state = ~nUPIC[\ui][\state];
    if(state.notNil and: { state[\viewStartTime].notNil } and: { state[\viewDuration].notNil }) {
        // Use zoom system if available
        var normalizedX = x / width;
        state[\viewStartTime] + (normalizedX * state[\viewDuration]);
    } {
        // Fallback to full duration if zoom not initialized  
        var normalizedX = x / width;
        normalizedX * state[\playDuration];
    };
};

~nUPIC[\ui][\timeToScreen] = { |time, width|
    var state = ~nUPIC[\ui][\state];
    if(state.notNil and: { state[\viewStartTime].notNil } and: { state[\viewDuration].notNil }) {
        // Use zoom system if available
        var normalizedTime = (time - state[\viewStartTime]) / state[\viewDuration];
        normalizedTime * width;
    } {
        // Fallback to full duration if zoom not initialized
        var normalizedTime = time / state[\playDuration];
        normalizedTime * width;
    };
};

// Draw marquee selection rectangle
~nUPIC[\ui][\drawMarqueeSelection] = {
    var state = ~nUPIC[\ui][\state];
    var colors = ~nUPIC[\colors];
    var selectionRect;
    
    if(state.isNil or: { state[\marqueeStartX].isNil }) { ^nil };
    
    // Create rectangle from start and current points
    selectionRect = Rect(
        state[\marqueeStartX].min(state[\marqueeCurrentX]),
        state[\marqueeStartY].min(state[\marqueeCurrentY]),
        (state[\marqueeCurrentX] - state[\marqueeStartX]).abs,
        (state[\marqueeCurrentY] - state[\marqueeStartY]).abs
    );
    
    // Draw selection rectangle
    Pen.strokeColor = colors[\selectMode] ? Color.blue;
    Pen.fillColor = colors[\selectMode].copy.alpha_(0.1) ? Color.blue.alpha_(0.1);
    Pen.width = 1.5;
    Pen.addRect(selectionRect);
    Pen.fillStroke;
};

// Draw frequency labels in the left margin area
~nUPIC[\ui][\drawFrequencyLabels] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var colors = ~nUPIC[\colors];
    var gridSystems = ~nUPIC[\gridSystems];
    var gridFreqs;
    
    if(state.isNil) { ^nil };
    
    // Ensure zoom state is properly initialized
    if(state[\zoomFreqMin].isNil or: { state[\zoomFreqMax].isNil }) {
        state[\zoomFreqMin] = ~nUPIC[\constants][\freqMin] ? 20;
        state[\zoomFreqMax] = ~nUPIC[\constants][\freqMax] ? 7500;
        "Warning: Zoom state was nil, reset to default frequency range".postln;
    };
    
    // Clear background
    Pen.fillColor = colors[\background] ? Color.white;
    Pen.fillRect(Rect(0, 0, width, height));
    
    // Set text color
    Pen.strokeColor = colors[\gridText] ? Color.gray(0.4);
    
    if(state[\showGrid]) {
        if(gridSystems.notNil and: { state[\gridType].notNil }) {
            // Get tuning-system specific frequencies - same calculation as grid
            gridFreqs = ~nUPIC[\ui][\getTuningSystemFrequencies].value(state[\gridType], height);
            
            if(gridFreqs.notNil and: { gridFreqs.size > 0 }) {
                var minSpacing = ~nUPIC[\ui][\getMinSpacingForTuning].value(state[\gridType], height);
                var lastY = -1000;   // Track last label position to avoid overlaps
                
                gridFreqs.do { |freq|
                    var y = freq.explin(state[\zoomFreqMin], state[\zoomFreqMax], height, 0);
                    var labelText;

                    // Only draw if within bounds and not too close to previous label
                    // Same filtering logic as grid to ensure perfect 1:1 correspondence
                    if(y >= 15 and: { y <= (height - 15) } and: { (y - lastY).abs >= minSpacing }) {
                        labelText = ~nUPIC[\ui][\formatFrequencyLabel].value(freq, state[\gridType]);
                        
                        Pen.stringAtPoint(
                            labelText,
                            Point(5, y - 6),  // Position in left margin
                            Font("Arial", 8),  // Slightly smaller font
                            colors[\gridText] ? Color.gray(0.4)
                        );
                        
                        // Draw thicker tick marks that align with grid lines
                        Pen.strokeColor = colors[\grid] ? Color.gray(0.2, 0.8);
                        Pen.width = 2;  // Thicker line
                        Pen.line(Point(width - 15, y), Point(width, y));
                        Pen.stroke;
                        
                        lastY = y;  // Update last position
                    };
                };
            };
        } {
            // Fallback: simple frequency grid - use exactly 8 lines
            8.do { |i|
                var y = (i + 1) * (height / 9);  // 8 divisions = 9 segments
                // Use exponential mapping for perceptual frequency
                var freq = y.linexp(0, height, state[\zoomFreqMax], state[\zoomFreqMin]);
                var labelText = freq.round(0.1).asString ++ "Hz";
                
                Pen.stringAtPoint(
                    labelText,
                    Point(5, y - 6),  // Position in left margin
                    Font("Arial", 9),
                    colors[\gridText] ? Color.gray(0.4)
                );
                
                // Draw thicker tick marks
                Pen.strokeColor = colors[\grid] ? Color.gray(0.2, 0.8);
                Pen.width = 2;  // Thicker line
                Pen.line(Point(width - 15, y), Point(width, y));
                Pen.stroke;
            };
        };
    };
};

// Draw speed labels in the left margin area
~nUPIC[\ui][\drawSpeedLabels] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var colors = ~nUPIC[\colors];
    var speedValues;
    
    if(state.isNil) { ^nil };
    
    // Clear background
    Pen.fillColor = colors[\background] ? Color.white;
    Pen.fillRect(Rect(0, 0, width, height));
    
    // Speed scale labels (0 = stop, 1 = normal, >1 = fast) - fewer labels for smaller area
    speedValues = [0, 0.5, 1.0, 2.0];
    
    speedValues.do { |speed|
        var y = speed.linlin(0, 2.0, height, 0).clip(5, height - 5);
        var labelText = case 
            { speed == 0 } { "Stop" }
            { speed == 1.0 } { "Normal" }
            { speed < 1.0 } { "x" ++ speed.asString }
            { speed > 1.0 } { "x" ++ speed.asString }
            { speed.asString ++ "x" };
            
        // Draw label
        Pen.stringAtPoint(
            labelText,
            Point(5, y - 5),
            Font("Arial", 9),
            colors[\gridText] ? Color.gray(0.4)
        );
        
        // Draw tick mark
        Pen.strokeColor = colors[\grid] ? Color.gray(0.3, 0.5);
        Pen.line(Point(width - 10, y), Point(width, y));
        Pen.stroke;
    };
};

// Draw speed function curve
~nUPIC[\ui][\drawSpeedFunction] = { |width, height|
    var state = ~nUPIC[\ui][\state];
    var colors = ~nUPIC[\colors];
    var speedFunction;
    
    if(state.isNil) { ^nil };
    
    // Get speed function data
    speedFunction = state[\speedFunction];
    if(speedFunction.isNil or: { speedFunction.size < 2 }) {
        ^nil;  // Nothing to draw
    };
    
    // Clear background
    Pen.fillColor = Color.gray(0.95);
    Pen.fillRect(Rect(0, 0, width, height));
    
    // Draw horizontal grid lines for speed reference - using smaller scale
    [0, 0.5, 1.0, 2.0].do { |speed|
        var y = speed.linlin(0, 2.0, height, 0);
        if(y >= 0 and: { y <= height }) {
            var alpha = if(speed == 1.0) { 0.8 } { 0.3 };  // Emphasize normal speed line
            Pen.strokeColor = Color.gray(0.6, alpha);
            Pen.width = if(speed == 1.0) { 2 } { 1 };
            Pen.line(Point(0, y), Point(width, y));
            Pen.stroke;
        };
    };
    
    // Draw speed curve as filled area
    if(speedFunction.size > 1) {
        // First draw filled area under curve
        Pen.fillColor = Color.blue.alpha_(0.2);
        Pen.moveTo(Point(0, height));  // Start at bottom left
        
        speedFunction.do { |point|
            var x = point.x.clip(0, width);
            var y = point.speed.linlin(0, 2.0, height, 0).clip(0, height);
            Pen.lineTo(Point(x, y));
        };
        
        Pen.lineTo(Point(width, height));  // Close at bottom right
        Pen.fill;
        
        // Then draw the curve line
        Pen.strokeColor = Color.blue;
        Pen.width = 3;
        
        speedFunction.do { |point, i|
            var x = point.x.clip(0, width);
            var y = point.speed.linlin(0, 2.0, height, 0).clip(0, height);
            
            if(i == 0) {
                Pen.moveTo(Point(x, y));
            } {
                Pen.lineTo(Point(x, y));
            };
        };
        Pen.stroke;
        
        // Draw control points
        Pen.fillColor = Color.red;
        speedFunction.do { |point|
            var x = point.x.clip(0, width);
            var y = point.speed.linlin(0, 2.0, height, 0).clip(0, height);
            Pen.fillOval(Rect.aboutPoint(Point(x, y), 4, 4));
        };
    };
    
    // Draw instructions
    Pen.fillColor = Color.black;
    Pen.stringAtPoint(
        "Click and drag to draw speed curve (0=stop, 1=normal, >1=fast)",
        Point(10, 10),
        Font("Arial", 10),
        Color.gray(0.3)
    );
};

// Speed function mouse interactions (to be called from MouseHandlers.scd)
~nUPIC[\ui][\handleSpeedFunctionMouse] = { |x, y, isDown, isMove, isUp, width, height|
    var state = ~nUPIC[\ui][\state];
    var speedFunctionArea;
    
    if(state.isNil) { ^nil };
    
    speedFunctionArea = state[\speedFunctionArea];
    if(speedFunctionArea.isNil) { ^nil };
    
    // Check if mouse is in speed function area
    if(y >= speedFunctionArea[\topY] and: { 
        y <= (speedFunctionArea[\topY] + speedFunctionArea[\height])
    }) {
        var localY = y - speedFunctionArea[\topY];
        var speed = localY.linlin(speedFunctionArea[\height], 0, 0, 2.0).clip(0, 2.0);
        
        case 
        { isDown } {
            // Start new speed function or add point
            state[\isDrawingSpeedFunction] = true;
            state[\speedFunction] = List[(x: x, speed: speed)];
            "Started drawing speed function at x=%, speed=%".format(x.round(1), speed.round(0.01)).postln;
        }
        { isMove and: { state[\isDrawingSpeedFunction] == true } } {
            // Add point to speed function if far enough from last point
            var lastPoint = state[\speedFunction].last;
            if(lastPoint.isNil or: { (x - lastPoint.x).abs > 5 }) {
                state[\speedFunction].add((x: x, speed: speed));
            };
        }
        { isUp and: { state[\isDrawingSpeedFunction] == true } } {
            // Finish speed function
            state[\isDrawingSpeedFunction] = false;
            "Completed speed function with % points".format(state[\speedFunction].size).postln;
            
            // Ensure speed function covers full width
            if(state[\speedFunction].size > 0) {
                var firstPoint = state[\speedFunction].first;
                var lastPoint = state[\speedFunction].last;
                
                // Add point at x=0 if needed
                if(firstPoint.x > 0) {
                    state[\speedFunction] = List[(x: 0, speed: firstPoint.speed)] ++ state[\speedFunction];
                };
                
                // Add point at x=width if needed
                if(lastPoint.x < width) {
                    state[\speedFunction].add((x: width, speed: lastPoint.speed));
                };
                
                // Sort by x coordinate
                state[\speedFunction] = state[\speedFunction].sort({ |a, b| a.x < b.x });
            };
        };
        
        // Refresh speed function view
        if(state[\speedFunctionView].notNil) {
            { state[\speedFunctionView].refresh }.defer;
        };
        
        ^true;  // Indicate that speed function handled the mouse event
    };
    
    ^false;  // Speed function did not handle the mouse event
};

// Debug function to test amplitude-based coloring
~nUPIC[\ui][\testAmplitudeColors] = {
    var data;  // Declare data variable at the beginning
    
    "Testing amplitude-based arc coloring:".postln;
    
    // Test color mapping for different amplitude values
    [0.0, 0.2, 0.33, 0.5, 0.66, 0.8, 1.0].do { |amp|
        var hue, saturation, brightness;
        
        // Same color mapping logic as in drawArc
        case 
        { amp <= 0.33 } {
            hue = amp.linlin(0, 0.33, 0.67, 0.5);  // Blue to cyan
            saturation = amp.linlin(0, 0.33, 0.8, 1.0);
            brightness = amp.linlin(0, 0.33, 0.3, 0.7);
        }
        { amp <= 0.66 } {
            hue = amp.linlin(0.33, 0.66, 0.5, 0.17);  // Cyan to yellow
            saturation = 1.0;
            brightness = amp.linlin(0.33, 0.66, 0.7, 0.9);
        }
        {
            hue = amp.linlin(0.66, 1.0, 0.17, 0.0);  // Yellow to red
            saturation = 1.0;
            brightness = amp.linlin(0.66, 1.0, 0.9, 1.0);
        };
        
        ("Amp=% -> H=% S=% B=% (Color: %)").format(
            amp.round(0.01),
            hue.round(0.01),
            saturation.round(0.01),
            brightness.round(0.01),
            case
            { hue > 0.5 } { "BLUE/CYAN" }
            { hue > 0.1 } { "YELLOW" }
            { "RED" }
        ).postln;
    };
    
    "Expected: 0.0=Dark Blue, 0.33=Cyan, 0.66=Yellow, 1.0=Bright Red".postln;
    
    // Check if amplitude envelopes exist
    data = ~nUPIC[\data];
    if(data.notNil and: { data[\amplitudeEnvelopes].notNil }) {
        ("Found % amplitude envelopes in data").format(data[\amplitudeEnvelopes].size).postln;
        data[\amplitudeEnvelopes].do { |env, i|
            if(env.notNil) {
                ("  Envelope %: % points, amp range: % - %").format(
                    i,
                    env.size,
                    env.collect(_.amp).minItem.round(0.01),
                    env.collect(_.amp).maxItem.round(0.01)
                ).postln;
            } {
                ("  Envelope %: nil").format(i).postln;
            };
        };
    } {
        "No amplitude envelopes found in data - trajectories will use default colors".postln;
    };
};

"nUPIC Drawing module loaded".postln;
"Call ~nUPIC[\\ui][\\testAmplitudeColors].value; to test amplitude coloring".postln;
)
