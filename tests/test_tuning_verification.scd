// Test script to verify tuning system frequency generation
// This will show how many frequencies each tuning system generates

(
// Load the constants first
"Core/Constants.scd".load;

// Test frequency range: one octave from A4 to A5 (440Hz to 880Hz)
var testMinFreq = 440;
var testMaxFreq = 880;
var testNumLines = 15; // This should be ignored by the new implementations

"=== TUNING SYSTEM VERIFICATION ===".postln;
"Testing frequency range: %Hz - %Hz (one octave)".format(testMinFreq, testMaxFreq).postln;
"".postln;

~nUPIC[\\gridSystems].keysValuesDo { |key, tuningSystem|
    var freqs = tuningSystem[\\calculation].value(440, testMinFreq, testMaxFreq, testNumLines);
    var expectedCount;
    
    // Calculate expected counts for verification
    case 
    { key == \\equalTemperament } { expectedCount = "12 (semitones per octave)"; }
    { key == \\fokker31 } { expectedCount = "31 (31-TET steps per octave)"; }
    { key == \\quarterTone } { expectedCount = "24 (quarter-tones per octave)"; }
    { key == \\harmonicSeries } { 
        var fundamental = tuningSystem[\\baseFreq] ? 110;
        var startHarm = (testMinFreq / fundamental).ceil.max(1);
        var endHarm = (testMaxFreq / fundamental).floor;
        expectedCount = "% (harmonics %-%% of %Hz fundamental)".format(
            endHarm - startHarm + 1, startHarm, endHarm, fundamental
        );
    }
    { key == \\just } { 
        expectedCount = "8 ratios × octaves in range"; 
    }
    { key == \\pythagorean } { 
        expectedCount = "13 ratios × octaves in range"; 
    }
    { expectedCount = "varies"; };
    
    "% (%):".format(tuningSystem[\\name], key).postln;
    "  Generated: % frequencies".format(freqs.size).postln;
    "  Expected: %".format(expectedCount).postln;
    "  Range: %Hz - %Hz".format(
        if(freqs.size > 0) { freqs.minItem.round(0.1) } { "none" },
        if(freqs.size > 0) { freqs.maxItem.round(0.1) } { "none" }
    ).postln;
    
    // Show first few frequencies for verification
    if(freqs.size > 0) {
        "  First few: %".format(freqs[0..4.min(freqs.size-1)].collect(_.round(0.1))).postln;
    };
    "".postln;
};

"=== TEST COMPLETE ===".postln;
)
