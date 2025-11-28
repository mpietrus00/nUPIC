// Test script for UI/Controls.scd syntax only
try {
    "UI/Controls.scd".load;
    "✓ SUCCESS: UI/Controls.scd loaded without syntax errors".postln;
} { |error|
    ("✗ ERROR: " ++ error.errorString).postln;
};

// Exit
0.exit;
