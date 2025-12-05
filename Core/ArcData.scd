// nUPIC Arc Data Management
// Handles arc storage, manipulation, and validation
// Includes amplitude envelopes and spatial envelopes per arc

(
// Initialize arc data management
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
~nUPIC[\arcData] = IdentityDictionary.new;

// Arc data structure
~nUPIC[\arcData][\manager] = {
    var trajectories, amplitudeEnvelopes, spatialEnvelopes, arcSynthDefs;
    var wavetables, wavetableBuffers;  // Per-arc wavetable data and server buffers
    var selectedTrajectories, copiedTrajectories;
    var undoStack, redoStack;
    var maxSynths, maxUndoSteps, maxChannels;
    var numWavetableSamples = 2048;  // Standard wavetable size
    var defaultWavetable;  // Default sine wave

    // Initialize with safe defaults (will be updated when constants are available)
    trajectories = List.new;
    amplitudeEnvelopes = List.new;
    spatialEnvelopes = List.new;  // Spatial envelope per arc: List of (x: time, channel: 0-maxChannels)
    arcSynthDefs = List.new;
    wavetables = List.new;  // Per-arc wavetable data (Array of 2048 floats)
    wavetableBuffers = List.new;  // Per-arc Buffer references
    selectedTrajectories = Set.new;
    copiedTrajectories = List.new;
    undoStack = List.new;
    redoStack = List.new;
    maxSynths = 200;  // Default value
    maxUndoSteps = 50;  // Default value
    maxChannels = 12;  // Maximum channel count for spatial envelopes (supports up to 12ch)

    // Default wavetable (sine wave)
    defaultWavetable = Array.fill(numWavetableSamples, { |i|
        sin(2pi * i / numWavetableSamples)
    });

    // Public interface
    (
        // Data access
        trajectories: trajectories,
        amplitudeEnvelopes: amplitudeEnvelopes,
        spatialEnvelopes: spatialEnvelopes,
        arcSynthDefs: arcSynthDefs,
        wavetables: wavetables,
        wavetableBuffers: wavetableBuffers,
        selectedTrajectories: selectedTrajectories,
        copiedTrajectories: copiedTrajectories,
        maxChannels: maxChannels,
        numWavetableSamples: numWavetableSamples,
        defaultWavetable: defaultWavetable,

        // Arc management
        addArc: { |arc, synthDef = nil, amplitudeEnv = nil, spatialEnv = nil, wavetableData = nil|
            var actualSynthDef = synthDef ?? { \upicWavetable };  // Safe default - mono wavetable
            var actualWavetable = wavetableData ?? { defaultWavetable.copy };
            var newBuffer;

            // Check if we need to remove old arc
            if(trajectories.size >= maxSynths) {
                // Free the oldest buffer before removing
                if(wavetableBuffers[0].notNil) {
                    wavetableBuffers[0].free;
                };
                trajectories.removeAt(0);
                amplitudeEnvelopes.removeAt(0);
                spatialEnvelopes.removeAt(0);
                arcSynthDefs.removeAt(0);
                wavetables.removeAt(0);
                wavetableBuffers.removeAt(0);
            };

            // Add new arc
            trajectories.add(arc);
            amplitudeEnvelopes.add(amplitudeEnv);
            spatialEnvelopes.add(spatialEnv);  // nil = default center position
            arcSynthDefs.add(actualSynthDef);
            wavetables.add(actualWavetable);

            // Create server buffer for this arc's wavetable
            if(Server.default.serverRunning) {
                newBuffer = Buffer.loadCollection(Server.default, actualWavetable);
                wavetableBuffers.add(newBuffer);
            } {
                wavetableBuffers.add(nil);  // Will be created when server starts
            };

            // Return index of added arc
            trajectories.size - 1;
        },

        removeArc: { |index|
            if(index >= 0 and: { index < trajectories.size }) {
                var newSelected;

                // Free the wavetable buffer
                if(wavetableBuffers[index].notNil) {
                    wavetableBuffers[index].free;
                };

                trajectories.removeAt(index);
                amplitudeEnvelopes.removeAt(index);
                spatialEnvelopes.removeAt(index);
                arcSynthDefs.removeAt(index);
                wavetables.removeAt(index);
                wavetableBuffers.removeAt(index);
                selectedTrajectories.remove(index);

                // Adjust selected indices after removal
                newSelected = Set.new;
                selectedTrajectories.do { |idx|
                    if(idx > index) {
                        newSelected.add(idx - 1);
                    } { if(idx < index) {
                        newSelected.add(idx);
                    }};
                };
                selectedTrajectories = newSelected;
            };
        },

        clearAll: {
            // Free all wavetable buffers
            wavetableBuffers.do { |buf|
                if(buf.notNil) { buf.free };
            };

            trajectories.clear;
            amplitudeEnvelopes.clear;
            spatialEnvelopes.clear;
            arcSynthDefs.clear;
            wavetables.clear;
            wavetableBuffers.clear;
            selectedTrajectories.clear;
            copiedTrajectories.clear;
            undoStack.clear;
            redoStack.clear;
        },
        
        // Selection management
        selectArc: { |index|
            if(index >= 0 and: { index < trajectories.size }) {
                selectedTrajectories.add(index);
            };
        },
        
        deselectArc: { |index|
            selectedTrajectories.remove(index);
        },
        
        toggleSelection: { |index|
            if(selectedTrajectories.includes(index)) {
                selectedTrajectories.remove(index);
            } {
                selectedTrajectories.add(index);
            };
        },
        
        selectAll: {
            selectedTrajectories.clear;
            trajectories.size.do { |i| selectedTrajectories.add(i) };
        },
        
        deselectAll: {
            selectedTrajectories.clear;
        },
        
        // Copy/paste operations
        copy: {
            copiedTrajectories.clear;
            selectedTrajectories.do { |i|
                if(i < trajectories.size) {
                    copiedTrajectories.add((
                        arc: trajectories[i].deepCopy,
                        amplitude: if(amplitudeEnvelopes[i].notNil) {
                            amplitudeEnvelopes[i].deepCopy
                        } { nil },
                        spatial: if(spatialEnvelopes[i].notNil) {
                            spatialEnvelopes[i].deepCopy
                        } { nil },
                        synthDef: arcSynthDefs[i],
                        wavetable: if(wavetables[i].notNil) {
                            wavetables[i].copy
                        } { nil }
                    ));
                };
            };
            copiedTrajectories.size;
        },

        paste: { |offsetX = 30, offsetY = -30|
            var pastedIndices = [];

            copiedTrajectories.do { |item, idx|
                var newTraj = item.arc.collect { |point|
                    if(point.isKindOf(Event)) {
                        (
                            x: point.x + offsetX,
                            y: (point.y + offsetY + (idx * 10)).clip(0, 800),  // Safe default height
                            freq: point.freq
                        )
                    } {
                        Point(
                            point.x + offsetX,
                            (point.y + offsetY + (idx * 10)).clip(0, 800)  // Safe default height
                        )
                    };
                };

                var newAmp = if(item.amplitude.notNil) {
                    item.amplitude.collect { |ampPoint|
                        (x: ampPoint.x + offsetX, amp: ampPoint.amp)
                    }
                } { nil };

                var newSpatial = if(item.spatial.notNil) {
                    item.spatial.collect { |spatialPoint|
                        (x: spatialPoint.x + offsetX, channel: spatialPoint.channel)
                    }
                } { nil };

                var newWavetable = if(item.wavetable.notNil) {
                    item.wavetable.copy
                } { nil };

                var newIndex = this.addArc(newTraj, item.synthDef, newAmp, newSpatial, newWavetable);
                pastedIndices = pastedIndices.add(newIndex);
            };

            // Select pasted trajectories
            selectedTrajectories.clear;
            pastedIndices.do { |idx| selectedTrajectories.add(idx) };

            pastedIndices;
        },

        // Undo/redo system
        saveState: {
            var state = (
                trajectories: trajectories.deepCopy,
                amplitudeEnvelopes: amplitudeEnvelopes.deepCopy,
                spatialEnvelopes: spatialEnvelopes.deepCopy,
                arcSynthDefs: arcSynthDefs.deepCopy,
                selectedTrajectories: selectedTrajectories.copy
            );

            undoStack.add(state);
            if(undoStack.size > maxUndoSteps) {
                undoStack.removeAt(0);
            };
            redoStack.clear;
        },

        undo: {
            if(undoStack.size > 0) {
                var currentState, previousState;

                currentState = (
                    trajectories: trajectories.deepCopy,
                    amplitudeEnvelopes: amplitudeEnvelopes.deepCopy,
                    spatialEnvelopes: spatialEnvelopes.deepCopy,
                    arcSynthDefs: arcSynthDefs.deepCopy,
                    selectedTrajectories: selectedTrajectories.copy
                );

                redoStack.add(currentState);
                previousState = undoStack.pop;

                trajectories = previousState.trajectories;
                amplitudeEnvelopes = previousState.amplitudeEnvelopes;
                spatialEnvelopes = previousState.spatialEnvelopes;
                arcSynthDefs = previousState.arcSynthDefs;
                selectedTrajectories = previousState.selectedTrajectories;

                true; // Successfully undone
            } {
                false; // Nothing to undo
            };
        },

        redo: {
            if(redoStack.size > 0) {
                var currentState, nextState;

                currentState = (
                    trajectories: trajectories.deepCopy,
                    amplitudeEnvelopes: amplitudeEnvelopes.deepCopy,
                    spatialEnvelopes: spatialEnvelopes.deepCopy,
                    arcSynthDefs: arcSynthDefs.deepCopy,
                    selectedTrajectories: selectedTrajectories.copy
                );

                undoStack.add(currentState);
                nextState = redoStack.pop;

                trajectories = nextState.trajectories;
                amplitudeEnvelopes = nextState.amplitudeEnvelopes;
                spatialEnvelopes = nextState.spatialEnvelopes;
                arcSynthDefs = nextState.arcSynthDefs;
                selectedTrajectories = nextState.selectedTrajectories;

                true; // Successfully redone
            } {
                false; // Nothing to redo
            };
        },
        
        // Validation
        validateArc: { |traj|
            traj.isKindOf(List) and: { 
                traj.size > 1 and: { 
                    traj.every { |point| 
                        point.respondsTo(\x) and: { point.respondsTo(\y) }
                    }
                }
            }
        },
        
        // Transformation operations
        moveSelected: { |deltaX, deltaY|
            selectedTrajectories.do { |i|
                if(i < trajectories.size) {
                    trajectories[i] = trajectories[i].collect { |point|
                        if(point.isKindOf(Event)) {
                            var newY = (point.y + deltaY).clip(0, 800);  // Safe default height
                            var state = ~nUPIC[\ui][\state];
                            var constants = ~nUPIC[\constants];
                            var zoomFreqMax = state[\zoomFreqMax] ? (constants[\freqMax] ? 7500);
                            var zoomFreqMin = state[\zoomFreqMin] ? (constants[\freqMin] ? 20);
                            var newFreq = newY.linlin(0, 800, zoomFreqMax, zoomFreqMin);  // Use zoom-aware freq range
                            (x: point.x + deltaX, y: newY, freq: newFreq)
                        } {
                            Point(point.x + deltaX, (point.y + deltaY).clip(0, 800))  // Safe default height
                        };
                    };

                    // Also move amplitude envelope
                    if(amplitudeEnvelopes[i].notNil) {
                        amplitudeEnvelopes[i] = amplitudeEnvelopes[i].collect { |ampPoint|
                            (x: ampPoint.x + deltaX, amp: ampPoint.amp)
                        };
                    };

                    // Also move spatial envelope
                    if(spatialEnvelopes[i].notNil) {
                        spatialEnvelopes[i] = spatialEnvelopes[i].collect { |spatialPoint|
                            (x: spatialPoint.x + deltaX, channel: spatialPoint.channel)
                        };
                    };
                };
            };
        },
        
        transposeSelected: { |factor|
            selectedTrajectories.do { |i|
                if(i < trajectories.size) {
                    trajectories[i] = trajectories[i].collect { |point|
                        if(point.isKindOf(Event)) {
                            var newFreq = (point.freq * factor).clip(20, 7500);  // Safe default freq range
                            (x: point.x, y: point.y, freq: newFreq)
                        } {
                            point;
                        };
                    };
                };
            };
        },
        
        // Utility functions
        size: { trajectories.size },
        
        isEmpty: { trajectories.size == 0 },
        
        getArc: { |index|
            if(index >= 0 and: { index < trajectories.size }) {
                trajectories[index]
            } { nil };
        },
        
        getAmplitudeEnvelope: { |index|
            if(index >= 0 and: { index < amplitudeEnvelopes.size }) {
                amplitudeEnvelopes[index]
            } { nil };
        },

        setAmplitudeEnvelope: { |index, envelope|
            if(index >= 0 and: { index < amplitudeEnvelopes.size }) {
                amplitudeEnvelopes[index] = envelope;
            };
        },

        // Spatial envelope management
        // Envelope format: List of (x: timePosition, channel: channelValue)
        // x = time position along arc (in pixels/time units)
        // channel = 0 to maxChannels (e.g., 0-11 for 12-channel)
        getSpatialEnvelope: { |index|
            if(index >= 0 and: { index < spatialEnvelopes.size }) {
                spatialEnvelopes[index]
            } { nil };
        },

        setSpatialEnvelope: { |index, envelope|
            if(index >= 0 and: { index < spatialEnvelopes.size }) {
                spatialEnvelopes[index] = envelope;
            };
        },

        // Wavetable management
        // Each arc has its own wavetable (512 samples, -1 to 1)
        getWavetable: { |index|
            if(index >= 0 and: { index < wavetables.size }) {
                wavetables[index]
            } { nil };
        },

        setWavetable: { |index, data|
            if(index >= 0 and: { index < wavetables.size }) {
                wavetables[index] = data;
                // Update server buffer if it exists
                if(wavetableBuffers[index].notNil) {
                    wavetableBuffers[index].loadCollection(data);
                };
            };
        },

        getWavetableBuffer: { |index|
            if(index >= 0 and: { index < wavetableBuffers.size }) {
                wavetableBuffers[index]
            } { nil };
        },

        // Ensure all trajectories have valid server buffers
        // Call this after server boot
        ensureWavetableBuffers: {
            if(Server.default.serverRunning) {
                wavetables.do { |wt, i|
                    if(wavetableBuffers[i].isNil and: { wt.notNil }) {
                        wavetableBuffers[i] = Buffer.loadCollection(Server.default, wt);
                    };
                };
            };
        },

        // Create default spatial envelope (center position for full arc length)
        createDefaultSpatialEnvelope: { |index, numChannels = 8|
            if(index >= 0 and: { index < trajectories.size }) {
                var traj = trajectories[index];
                var startX = traj[0].x;
                var endX = traj.last.x;
                var centerChannel = (numChannels - 1) / 2;  // Center position

                var envelope = List[
                    (x: startX, channel: centerChannel),
                    (x: endX, channel: centerChannel)
                ];

                spatialEnvelopes[index] = envelope;
                envelope;
            } { nil };
        },

        // Create spatial envelope that sweeps from first speaker to last speaker
        createFirstToLastSpatialEnvelope: { |index, numChannels = 8|
            if(index >= 0 and: { index < trajectories.size }) {
                var traj = trajectories[index];
                var startX = traj[0].x;
                var endX = traj.last.x;

                var envelope = List[
                    (x: startX, channel: 0),                    // Start at first speaker
                    (x: endX, channel: numChannels - 1)         // End at last speaker
                ];

                spatialEnvelopes[index] = envelope;
                envelope;
            } { nil };
        },

        // Get interpolated channel position at a given x position
        getChannelAtPosition: { |index, xPos|
            var envelope = spatialEnvelopes[index];
            if(envelope.notNil and: { envelope.size >= 2 }) {
                var prevPoint, nextPoint;

                // Find surrounding points
                envelope.do { |point, i|
                    if(point.x <= xPos) {
                        prevPoint = point;
                    };
                    if(nextPoint.isNil and: { point.x >= xPos }) {
                        nextPoint = point;
                    };
                };

                // Handle edge cases
                if(prevPoint.isNil) { prevPoint = envelope[0] };
                if(nextPoint.isNil) { nextPoint = envelope.last };

                // Interpolate
                if(prevPoint.x == nextPoint.x) {
                    prevPoint.channel
                } {
                    var t = (xPos - prevPoint.x) / (nextPoint.x - prevPoint.x);
                    prevPoint.channel + (t * (nextPoint.channel - prevPoint.channel));
                };
            } {
                // Default to center if no envelope
                (maxChannels - 1) / 2;
            };
        },

        getSynthDef: { |index|
            if(index >= 0 and: { index < arcSynthDefs.size }) {
                arcSynthDefs[index]
            } { \upicWavetable };  // Safe default - mono wavetable
        },

        setSynthDef: { |index, synthDef|
            if(index >= 0 and: { index < arcSynthDefs.size }) {
                arcSynthDefs[index] = synthDef;
            };
        },

        // Statistics
        getStats: {
            (
                totalTrajectories: trajectories.size,
                selectedTrajectories: selectedTrajectories.size,
                copiedTrajectories: copiedTrajectories.size,
                undoStepsAvailable: undoStack.size,
                redoStepsAvailable: redoStack.size,
                spatialEnvelopesCount: spatialEnvelopes.select({ |e| e.notNil }).size,
                memoryUsage: {
                    var totalPoints = 0;
                    trajectories.do { |traj| totalPoints = totalPoints + traj.size };
                    spatialEnvelopes.do { |env| if(env.notNil) { totalPoints = totalPoints + env.size } };
                    totalPoints;
                }.value
            )
        }
    )
}.value;

"nUPIC arc data management loaded (with spatial envelopes)".postln;
)
