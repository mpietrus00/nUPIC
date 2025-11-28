// Test syntax of UI/Controls.scd
(
try {
    "Testing syntax of UI/Controls.scd...".postln;
    "UI/Controls.scd".load;
    "✓ SUCCESS: UI/Controls.scd loaded without syntax errors".postln;
    "Syntax check completed successfully!".postln;
    0.exit;
} { |error|
    ("✗ SYNTAX ERROR in UI/Controls.scd:").postln;
    error.errorString.postln;
    error.reportError;
    1.exit;
};
)
