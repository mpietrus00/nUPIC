# nUPIC Drawing Functionality Test

## Issue: GUI opens but drawing doesn't work

## Step 1: Restart SuperCollider with fresh system
1. **Close SuperCollider completely**
2. **Reopen SuperCollider IDE**
3. **Load the main system:**
   ```supercollider
   "nUPIC_Main.scd".load;
   ```
4. **Wait for the GUI to appear**

## Step 2: Run diagnostics
In SuperCollider, execute:
```supercollider
"debug_drawing.scd".load;
```

This will check if all systems are properly initialized.

## Step 3: Test manual drawing
Try to draw on the canvas and watch the console for debug messages.

**Expected console output when drawing works:**
```
Starting to draw at (150 , 300)
First point added: x=150, y=300, freq=1234.5
Drawing continues - 5 points
Drawing continues - 10 points
Saving trajectory with 15 points
New trajectory added (SynthDef: simpleGravObject)
```

## Step 4: If drawing still doesn't work

### Check the mode
- Make sure you're **NOT in select mode** (press G to toggle)
- Make sure you're **NOT in erase mode** (press E to toggle)
- You should see "DRAW MODE" in the top right corner

### Check UI state manually
```supercollider
// Check current UI state
~nUPIC[\ui][\state][\eraseMode].postln;    // Should be false
~nUPIC[\ui][\state][\selectMode].postln;   // Should be false
~nUPIC[\ui][\state][\isPlaying].postln;    // Should be false

// Force drawing mode
~nUPIC[\ui][\state][\eraseMode] = false;
~nUPIC[\ui][\state][\selectMode] = false;
~nUPIC[\ui][\refreshDisplay].value;
```

### Test mouse handler directly
```supercollider
// Test mouse down event manually
~nUPIC[\ui][\handleMouseDown].value(200, 300, (), 1200, 800);

// Check if drawing started
~nUPIC[\ui][\state][\isDrawing].postln;    // Should be true
~nUPIC[\ui][\state][\currentTrajectory].size.postln;  // Should be 1

// Test mouse up
~nUPIC[\ui][\handleMouseUp].value(250, 250, 1200, 800);

// Check trajectory count
~nUPIC[\data][\trajectories].size.postln;  // Should be 1
```

## Step 5: Common fixes

### Fix 1: Reinitialize data structures
```supercollider
// Ensure data arrays exist
~nUPIC[\data][\trajectories] = List.new;
~nUPIC[\data][\amplitudeEnvelopes] = List.new;
~nUPIC[\data][\trajectorySynthDefs] = List.new;
~nUPIC[\data][\selectedTrajectories] = Set.new;

"Data structures reinitialized".postln;
```

### Fix 2: Reset UI state
```supercollider
// Reset UI state
~nUPIC[\ui][\state][\isDrawing] = false;
~nUPIC[\ui][\state][\eraseMode] = false;
~nUPIC[\ui][\state][\selectMode] = false;
~nUPIC[\ui][\state][\isPlaying] = false;
~nUPIC[\ui][\state][\currentTrajectory] = nil;

~nUPIC[\ui][\refreshDisplay].value;
"UI state reset".postln;
```

### Fix 3: Reconnect mouse handlers (if needed)
```supercollider
// Reload mouse handlers
"UI/MouseHandlers.scd".load;

// Reinitialize drawing
var drawView = ~nUPIC[\ui][\state][\drawView];
if(drawView.notNil) {
    ~nUPIC[\ui][\initializeDrawing].value(drawView, 1200, 800);
    "Drawing reinitialized".postln;
};
```

## Expected Results
After following these steps, you should be able to:
1. **See debug output** when clicking and dragging on the canvas
2. **See trajectories appear** as colored lines
3. **Save trajectories** that persist when you release the mouse
4. **Switch between modes** using keyboard shortcuts

If drawing works after these fixes, the issue was likely a state initialization problem.
