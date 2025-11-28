# Gravity Ob Synthdef Aliasing Analysis

## Current Implementation

The gravity ob synthdefs (`simpleGravObject` and `simpleGravObj2`) are using oversampled (OS) oscillators which should prevent aliasing. Here's what I found:

### Oscillators Used:

1. **VarSawOS.ar** - Variable sawtooth with oversampling
   - Line 34: `VarSawOS.ar(freq, 0, width, oversample: 2)` (light mode)
   - Line 36: `VarSawOS.ar(freq, 0, width, oversample: 4)` (full mode)
   - Line 40: Harmonic at `freq * 2` with `oversample: 2`

2. **SinOscOS.ar** - Sine oscillator with oversampling
   - Line 43: Used for modulation with `oversample: 2`

## Why You Might Still Hear Aliasing

Despite using OS oscillators, you might experience aliasing due to:

### 1. **Oversampling Factor Too Low**
The synthdef uses `oversample: 2` in light mode and `oversample: 4` in full mode. For very high frequencies, this might not be sufficient.

### 2. **Frequency Clipping Range**
The frequency is clipped to 8000 Hz (`freq.kr(300).clip(0.1, 8000)`), but harmonics can go beyond this:
- Second harmonic can reach 16000 Hz
- With modulation, sidebands can exceed Nyquist frequency

### 3. **Mode Selection Based on Mass**
Line 32-37 shows that when `mass > 2`, it switches to light mode with only 2x oversampling, which might not be enough for high frequencies.

### 4. **Filter Cutoff Frequencies**
The LPF at line 46 uses `freq * distance.linlin(20, 500, 3, 1)` which can create very high cutoff frequencies that might introduce artifacts.

## Potential Solutions

### Solution 1: Increase Oversampling Factor
```supercollider
// Change line 34 from:
VarSawOS.ar(freq, 0, width, oversample: 2)
// To:
VarSawOS.ar(freq, 0, width, oversample: 8)
```

### Solution 2: Add Frequency-Dependent Oversampling
```supercollider
// Adaptive oversampling based on frequency
var oversampleFactor = Select.kr(
    freq > 4000,
    [4, 8]  // Use 8x oversampling for high frequencies
);
sig = VarSawOS.ar(freq, 0, width, oversample: oversampleFactor);
```

### Solution 3: Pre-filter High Frequencies
```supercollider
// Add before oscillator generation
freq = freq.min(s.sampleRate / 4);  // Limit to 1/4 of sample rate
```

### Solution 4: Use Band-Limited Oscillators
Consider using `Saw.ar` or `VarSaw.ar` which are band-limited by default in SuperCollider, instead of oversampled versions if the oversampling is causing issues.

## Testing Recommendations

1. Run `test_gravity_aliasing.scd` to hear if aliasing occurs at high frequencies
2. Run `test_gravity_spectrum.scd` to visually see aliasing in the spectrum analyzer
3. Compare the current synthdef with a modified version using higher oversampling factors

## Verification Steps

To verify if aliasing is actually occurring:

1. **Listen Test**: Play high frequencies (5000-8000 Hz) and listen for harsh digital artifacts
2. **Spectral Analysis**: Look for mirror frequencies below the fundamental
3. **A/B Comparison**: Compare with known anti-aliased oscillators

The OS oscillators should prevent aliasing, but the current settings might need adjustment for optimal performance at high frequencies.
