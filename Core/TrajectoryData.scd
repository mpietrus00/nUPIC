// nUPIC Trajectory Data Management
// Handles trajectory storage, manipulation, and validation
// Includes amplitude envelopes and spatial envelopes per trajectory

(
// Initialize trajectory data management
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
~nUPIC[\trajectoryData] = IdentityDictionary.new;

// Trajectory data structure
~nUPIC[\trajectoryData][\manager] = {
    var trajectories, amplitudeEnvelopes, spatialEnvelopes, trajectorySynthDefs;
    var selectedTrajectories, copiedTrajectories;
    var undoStack, redoStack;
    var maxSynths, maxUndoSteps, maxChannels;

    // Initialize with safe defaults (will be updated when constants are available)
    trajectories = List.new;
    amplitudeEnvelopes = List.new;
    spatialEnvelopes = List.new;  // Spatial envelope per trajectory: List of (x: time, channel: 0-maxChannels)
    trajectorySynthDefs = List.new;
    selectedTrajectories = Set.new;
    copiedTrajectories = List.new;
    undoStack = List.new;
    redoStack = List.new;
    maxSynths = 200;  // Default value
    maxUndoSteps = 50;  // Default value
    maxChannels = 12;  // Maximum channel count for spatial envelopes (supports up to 12ch)

    // Public interface
    (
        // Data access
        trajectories: trajectories,
        amplitudeEnvelopes: amplitudeEnvelopes,
        spatialEnvelopes: spatialEnvelopes,
        trajectorySynthDefs: trajectorySynthDefs,
        selectedTrajectories: selectedTrajectories,
        copiedTrajectories: copiedTrajectories,
        maxChannels: maxChannels,

        // Trajectory management
        addTrajectory: { |trajectory, synthDef = nil, amplitudeEnv = nil, spatialEnv = nil|
            var actualSynthDef = synthDef ?? { \upicWavetable8ch };  // Safe default - 8ch wavetable

            // Check if we need to remove old trajectory
            if(trajectories.size >= maxSynths) {
                trajectories.removeAt(0);
                amplitudeEnvelopes.removeAt(0);
                spatialEnvelopes.removeAt(0);
                trajectorySynthDefs.removeAt(0);
            };

            // Add new trajectory
            trajectories.add(trajectory);
            amplitudeEnvelopes.add(amplitudeEnv);
            spatialEnvelopes.add(spatialEnv);  // nil = default center position
            trajectorySynthDefs.add(actualSynthDef);

            // Return index of added trajectory
            trajectories.size - 1;
        },

        removeTrajectory: { |index|
            if(index >= 0 and: { index < trajectories.size }) {
                var newSelected;

                trajectories.removeAt(index);
                amplitudeEnvelopes.removeAt(index);
                spatialEnvelopes.removeAt(index);
                trajectorySynthDefs.removeAt(index);
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
            trajectories.clear;
            amplitudeEnvelopes.clear;
            spatialEnvelopes.clear;
            trajectorySynthDefs.clear;
            selectedTrajectories.clear;
            copiedTrajectories.clear;
            undoStack.clear;
            redoStack.clear;
        },
        
        // Selection management
        selectTrajectory: { |index|
            if(index >= 0 and: { index < trajectories.size }) {
                selectedTrajectories.add(index);
            };
        },
        
        deselectTrajectory: { |index|
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
                        trajectory: trajectories[i].deepCopy,
                        amplitude: if(amplitudeEnvelopes[i].notNil) {
                            amplitudeEnvelopes[i].deepCopy
                        } { nil },
                        spatial: if(spatialEnvelopes[i].notNil) {
                            spatialEnvelopes[i].deepCopy
                        } { nil },
                        synthDef: trajectorySynthDefs[i]
                    ));
                };
            };
            copiedTrajectories.size;
        },

        paste: { |offsetX = 30, offsetY = -30|
            var pastedIndices = [];

            copiedTrajectories.do { |item, idx|
                var newTraj = item.trajectory.collect { |point|
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

                var newIndex = this.addTrajectory(newTraj, item.synthDef, newAmp, newSpatial);
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
                trajectorySynthDefs: trajectorySynthDefs.deepCopy,
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
                    trajectorySynthDefs: trajectorySynthDefs.deepCopy,
                    selectedTrajectories: selectedTrajectories.copy
                );

                redoStack.add(currentState);
                previousState = undoStack.pop;

                trajectories = previousState.trajectories;
                amplitudeEnvelopes = previousState.amplitudeEnvelopes;
                spatialEnvelopes = previousState.spatialEnvelopes;
                trajectorySynthDefs = previousState.trajectorySynthDefs;
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
                    trajectorySynthDefs: trajectorySynthDefs.deepCopy,
                    selectedTrajectories: selectedTrajectories.copy
                );

                undoStack.add(currentState);
                nextState = redoStack.pop;

                trajectories = nextState.trajectories;
                amplitudeEnvelopes = nextState.amplitudeEnvelopes;
                spatialEnvelopes = nextState.spatialEnvelopes;
                trajectorySynthDefs = nextState.trajectorySynthDefs;
                selectedTrajectories = nextState.selectedTrajectories;

                true; // Successfully redone
            } {
                false; // Nothing to redo
            };
        },
        
        // Validation
        validateTrajectory: { |traj|
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
        
        getTrajectory: { |index|
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
        // x = time position along trajectory (in pixels/time units)
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

        // Create default spatial envelope (center position for full trajectory length)
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
            if(index >= 0 and: { index < trajectorySynthDefs.size }) {
                trajectorySynthDefs[index]
            } { \upicWavetable8ch };  // Safe default - 8ch wavetable
        },

        setSynthDef: { |index, synthDef|
            if(index >= 0 and: { index < trajectorySynthDefs.size }) {
                trajectorySynthDefs[index] = synthDef;
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

"nUPIC trajectory data management loaded (with spatial envelopes)".postln;
)
