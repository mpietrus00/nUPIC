// nUPIC Trajectory Data Management
// Handles trajectory storage, manipulation, and validation

(
// Initialize trajectory data management
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
~nUPIC[\trajectoryData] = IdentityDictionary.new;

// Trajectory data structure
~nUPIC[\trajectoryData][\manager] = {
    var trajectories, amplitudeEnvelopes, trajectorySynthDefs;
    var selectedTrajectories, copiedTrajectories;
    var undoStack, redoStack;
    var maxSynths, maxUndoSteps;
    
    // Initialize with safe defaults (will be updated when constants are available)
    trajectories = List.new;
    amplitudeEnvelopes = List.new;
    trajectorySynthDefs = List.new;
    selectedTrajectories = Set.new;
    copiedTrajectories = List.new;
    undoStack = List.new;
    redoStack = List.new;
    maxSynths = 200;  // Default value
    maxUndoSteps = 50;  // Default value
    
    // Public interface
    (
        // Data access
        trajectories: trajectories,
        amplitudeEnvelopes: amplitudeEnvelopes,
        trajectorySynthDefs: trajectorySynthDefs,
        selectedTrajectories: selectedTrajectories,
        copiedTrajectories: copiedTrajectories,
        
        // Trajectory management
        addTrajectory: { |trajectory, synthDef = nil, amplitudeEnv = nil|
            var actualSynthDef = synthDef ?? { \simpleGravObject };  // Safe default - grav object synth
            
            // Check if we need to remove old trajectory
            if(trajectories.size >= maxSynths) {
                trajectories.removeAt(0);
                amplitudeEnvelopes.removeAt(0);
                trajectorySynthDefs.removeAt(0);
            };
            
            // Add new trajectory
            trajectories.add(trajectory);
            amplitudeEnvelopes.add(amplitudeEnv);
            trajectorySynthDefs.add(actualSynthDef);
            
            // Return index of added trajectory
            trajectories.size - 1;
        },
        
        removeTrajectory: { |index|
            if(index >= 0 and: { index < trajectories.size }) {
                var newSelected;
                
                trajectories.removeAt(index);
                amplitudeEnvelopes.removeAt(index);
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
                
                var newIndex = this.addTrajectory(newTraj, item.synthDef, newAmp);
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
                    trajectorySynthDefs: trajectorySynthDefs.deepCopy,
                    selectedTrajectories: selectedTrajectories.copy
                );
                
                redoStack.add(currentState);
                previousState = undoStack.pop;
                
                trajectories = previousState.trajectories;
                amplitudeEnvelopes = previousState.amplitudeEnvelopes;
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
                    trajectorySynthDefs: trajectorySynthDefs.deepCopy,
                    selectedTrajectories: selectedTrajectories.copy
                );
                
                undoStack.add(currentState);
                nextState = redoStack.pop;
                
                trajectories = nextState.trajectories;
                amplitudeEnvelopes = nextState.amplitudeEnvelopes;
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
        
        getSynthDef: { |index|
            if(index >= 0 and: { index < trajectorySynthDefs.size }) {
                trajectorySynthDefs[index]
            } { \simpleGravObject };  // Safe default - grav object synth
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
                memoryUsage: {
                    var totalPoints = 0;
                    trajectories.do { |traj| totalPoints = totalPoints + traj.size };
                    totalPoints;
                }.value
            )
        }
    )
}.value;

"nUPIC trajectory data management loaded".postln;
)
