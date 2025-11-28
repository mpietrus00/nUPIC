# nUPIC SynthDef Error Solution

## The Problem
The error "SynthDef: could not write def: DoesNotUnderstandError" occurs when:
1. SynthDefs are defined inside `fork` blocks within `waitForBoot`
2. VarSaw.ar is given incorrect number of arguments
3. The server context isn't properly available for SynthDef compilation

## The Solution

### Quick Fix - Use This Script:
```bash
# In SuperCollider IDE, run:
"init_simple_no_fork.scd".load
```

This script:
- Configures the server properly
- Defines SynthDefs in the main thread (not in fork)
- Tests each SynthDef after creation
- Sets up the global registry

### Step-by-Step Manual Fix:

1. **First, start the server:**
```supercollider
s.boot;
```

2. **Wait for boot to complete, then run:**
```supercollider
"init_simple_no_fork.scd".load
```

3. **After SynthDefs are loaded, run nUPIC:**
```supercollider
"nUPIC_Main.scd".load
```

## Debug Scripts Available

1. **`debug_synthdef_error.scd`** - Tests individual SynthDef components
2. **`check_varsaw.scd`** - Verifies VarSaw syntax
3. **`init_simple_no_fork.scd`** - Working initialization without fork
4. **`test_synthdef_compilation.scd`** - Basic compilation tests

## Common Syntax Errors Fixed

### VarSaw Arguments
**Wrong:**
```supercollider
VarSaw.ar(freq, 0, width, amp)  // 4th arg is mul, not needed here
```

**Correct:**
```supercollider
VarSaw.ar(freq, 0, width) * amp  // Multiply after
// OR
VarSaw.ar(freq, 0, width, amp)   // Use mul parameter correctly
```

### Mix.ar with Amplitude
**Wrong:**
```supercollider
Saw.ar(freq, amp * factor)  // Saw doesn't take amp as 2nd arg
```

**Correct:**
```supercollider
Saw.ar(freq) * amp * factor  // Multiply after
```

## Verified Working SynthDefs

These SynthDefs have been tested and work:
- `\testMinimal` - Basic sine oscillator
- `\trajectorySimple` - Simple VarSaw trajectory
- `\trajectoryWithEnv` - With envelope control
- `\trajectoryFull` - Full trajectory with all parameters
- `\gravObjectSimple` - Gravity object with Mix

## Testing Your Fix

Run this to verify everything works:
```supercollider
(
// Check if SynthDefs are loaded
SynthDescLib.global.synthDescs.keys.select({ |key|
    [\trajectoryFull, \gravObjectSimple].includes(key)
}).do { |key|
    ("✓ SynthDef loaded: \\" ++ key).postln;
};

// Test creating a synth
fork {
    var synth = Synth(\trajectoryFull, [\freq, 440, \amp, 0]);
    "✓ Test synth created".postln;
    1.wait;
    synth.free;
    "✓ Test complete".postln;
};
)
```

## If Errors Persist

1. **Kill all SC processes:**
```supercollider
Server.killAll;
```

2. **Start fresh:**
```supercollider
s.boot;
```

3. **Use the simple script:**
```supercollider
"init_simple_no_fork.scd".load
```

4. **Check server status:**
```supercollider
s.queryAllNodes;
```

## Important Notes

- Don't define SynthDefs inside `fork` blocks if possible
- Always check VarSaw argument count (3-5 args, not 4 with amp)
- Multiply amplitude after UGen creation for clearer code
- Use `Server.default.sync` after adding SynthDefs
- Test SynthDefs immediately after creation to catch errors early
