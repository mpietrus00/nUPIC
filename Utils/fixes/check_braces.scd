// Check brace matching in START_NUPIC.scd
(
var file = File("START_NUPIC.scd", "r");
var content = file.readAllString;
file.close;

var openCount = 0;
var parenCount = 0;
var bracketCount = 0;
var inComment = false;
var inString = false;
var lineNum = 1;

content.do { |char, i|
    if(char == $\n) { lineNum = lineNum + 1 };
    
    if(inString.not and: inComment.not) {
        case
        { char == ${ } { openCount = openCount + 1; ("Line " ++ lineNum ++ ": { (open=" ++ openCount ++ ")").postln; }
        { char == $} } { openCount = openCount - 1; ("Line " ++ lineNum ++ ": } (open=" ++ openCount ++ ")").postln; }
        { char == $( } { parenCount = parenCount + 1 }
        { char == $) } { parenCount = parenCount - 1 }
        { char == $[ } { bracketCount = bracketCount + 1 }
        { char == $] } { bracketCount = bracketCount - 1 };
    };
    
    // Simple string/comment detection
    if(char == $" and: inComment.not) { inString = inString.not };
    if(char == $/ and: inString.not and: (i < (content.size - 1)) and: (content[i+1] == $/)) { inComment = true };
    if(char == $\n) { inComment = false };
};

"".postln;
"Brace count analysis:".postln;
("Open braces: " ++ openCount).postln;
("Parentheses: " ++ parenCount).postln;
("Brackets: " ++ bracketCount).postln;

if(openCount != 0) {
    "ERROR: Unmatched braces!".postln;
} {
    "Braces appear to be balanced".postln;
};
)