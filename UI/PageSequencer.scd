// nUPIC Page Sequence Editor
// Matrix-based editor for arranging pages into playback sequence
// Rows: Pages A, B, C, D | Columns: 12 sequence slots

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\pageSequencer] = ~nUPIC[\pageSequencer] ?? ();

~nUPIC[\pageSequencer][\open] = {
    var win, matrixView, controlView;
    var width = 700, height = 260;
    var matrixWidth = 660, matrixHeight = 160;
    var controlHeight = 45;
    var labelWidth = 35;
    var cellWidth = 50, cellHeight = 32;
    var numSlots = 12;
    var pageLabels = ["_a", "_b", "_c", "_d"];
    var bkGreen = Color.new(205/255, 250/255, 205/255);  // B&K green
    var pageManager = ~nUPIC[\pages][\manager];
    var matrixButtons = Array2D.new(4, numSlots);  // 4 rows (pages) x 12 columns (slots)
    var totalDurationText;
    var sequenceDisplayText;

    // Helper to get sequence array from matrix state
    var getSequenceFromMatrix = {
        var seq = List.new;
        numSlots.do { |col|
            var foundPage = nil;
            4.do { |row|
                if(matrixButtons[row, col].notNil and: { matrixButtons[row, col].value == 1 }) {
                    foundPage = row;
                };
            };
            if(foundPage.notNil) {
                seq.add(foundPage);
            };
        };
        seq
    };

    // Helper to update total duration display
    var updateDurationDisplay = {
        var seq = getSequenceFromMatrix.value;
        var totalDur = 0;
        var seqLabels = List.new;

        if(pageManager.notNil) {
            seq.do { |pageIdx|
                var dur = pageManager[\getDuration].value(pageIdx);
                totalDur = totalDur + dur;
                seqLabels.add(pageLabels[pageIdx]);
            };
        };

        totalDurationText.string = "_total: %m %s".format(
            (totalDur / 60).floor.asInteger,
            (totalDur % 60).round(0.1)
        );

        sequenceDisplayText.string = "_sequence: " ++ if(seqLabels.size > 0) {
            seqLabels.join(" > ")
        } { "(empty)" };
    };

    // Helper to sync matrix to page manager sequence
    var syncMatrixToSequence = {
        var seq = pageManager[\sequence];

        // Clear all buttons first
        4.do { |row|
            numSlots.do { |col|
                if(matrixButtons[row, col].notNil) {
                    matrixButtons[row, col].value = 0;
                };
            };
        };

        // Set buttons based on sequence
        seq.do { |pageIdx, slotIdx|
            if(slotIdx < numSlots and: { pageIdx < 4 }) {
                if(matrixButtons[pageIdx, slotIdx].notNil) {
                    matrixButtons[pageIdx, slotIdx].value = 1;
                };
            };
        };

        updateDurationDisplay.value;
    };

    // Helper to sync page manager sequence from matrix
    var syncSequenceFromMatrix = {
        var seq = getSequenceFromMatrix.value;
        if(pageManager.notNil) {
            pageManager[\setSequence].value(seq);
        };
        updateDurationDisplay.value;
    };

    // Check if page manager exists
    if(pageManager.isNil) {
        "Page manager not initialized. Load PageData.scd first.".warn;
        ^nil;
    };

    // Ensure pages are initialized
    pageManager[\ensureInitialized].value;

    // Create window
    win = Window("nUPIC Page Sequence Editor", Rect(100, 450, width, height));
    win.background = bkGreen;

    // Title
    StaticText(win, Rect(10, 5, width - 20, 18))
        .string_("_page_sequence")
        .font_(Font("Arial", 10))
        .align_(\center);

    // === MATRIX VIEW ===
    matrixView = CompositeView(win, Rect(10, 25, matrixWidth, matrixHeight));
    matrixView.background = Color.white;

    // Column headers (slot numbers 1-12)
    numSlots.do { |col|
        StaticText(matrixView, Rect(labelWidth + (col * cellWidth), 0, cellWidth, 16))
            .string_("_" ++ (col + 1).asString)
            .font_(Font("Arial", 9))
            .align_(\center);
    };

    // Row labels and matrix buttons
    4.do { |row|
        var yPos = 18 + (row * cellHeight);
        var pageColor = [
            Color.new(0.6, 0.3, 0.3),   // _a - muted red
            Color.new(0.3, 0.5, 0.3),   // _b - muted green
            Color.new(0.3, 0.3, 0.6),   // _c - muted blue
            Color.new(0.5, 0.5, 0.3)    // _d - muted yellow
        ][row];

        // Row label (_a, _b, _c, _d)
        StaticText(matrixView, Rect(2, yPos + 4, labelWidth - 2, cellHeight - 8))
            .string_(pageLabels[row])
            .font_(Font("Arial", 10))
            .align_(\center)
            .background_(pageColor.alpha_(0.2));

        // Matrix cells for this row
        numSlots.do { |col|
            var btn = Button(matrixView, Rect(labelWidth + (col * cellWidth) + 1, yPos + 1, cellWidth - 2, cellHeight - 2))
                .states_([
                    ["", Color.black, Color.gray(0.92)],  // Empty slot
                    [pageLabels[row], Color.white, pageColor]  // Page assigned
                ])
                .font_(Font("Arial", 9))
                .action_({ |b|
                    // Toggle this cell
                    if(b.value == 1) {
                        // Clear any other page in this column (only one page per slot)
                        4.do { |otherRow|
                            if(otherRow != row and: { matrixButtons[otherRow, col].notNil }) {
                                matrixButtons[otherRow, col].value = 0;
                            };
                        };
                    };
                    syncSequenceFromMatrix.value;
                });

            matrixButtons[row, col] = btn;
        };
    };

    // === CONTROL PANEL ===
    controlView = CompositeView(win, Rect(0, height - controlHeight, width, controlHeight));
    controlView.background = bkGreen;

    // Total duration display
    totalDurationText = StaticText(controlView, Rect(10, 3, 140, 18))
        .string_("_total: 0m 0s")
        .font_(Font("Arial", 9));

    // Sequence display
    sequenceDisplayText = StaticText(controlView, Rect(10, 22, 380, 18))
        .string_("_sequence: (empty)")
        .font_(Font("Monaco", 9));

    // Clear Sequence button
    Button(controlView, Rect(400, 5, 65, 28))
        .states_([["_clear", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 9))
        .action_({
            4.do { |row|
                numSlots.do { |col|
                    if(matrixButtons[row, col].notNil) {
                        matrixButtons[row, col].value = 0;
                    };
                };
            };
            syncSequenceFromMatrix.value;
        });

    // Fill with _a button (quick preset)
    Button(controlView, Rect(470, 5, 55, 28))
        .states_([["_fill_a", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 9))
        .action_({
            numSlots.do { |col|
                4.do { |row|
                    if(matrixButtons[row, col].notNil) {
                        matrixButtons[row, col].value = if(row == 0) { 1 } { 0 };
                    };
                };
            };
            syncSequenceFromMatrix.value;
        });

    // Play Sequence button
    Button(controlView, Rect(530, 5, 55, 28))
        .states_([
            ["_play", Color.black, Color.gray(0.85)],
            ["_stop", Color.white, Color.new(0.5, 0.3, 0.3)]
        ])
        .font_(Font("Arial", 9))
        .action_({ |btn|
            if(btn.value == 1) {
                // Start sequence playback
                if(~nUPIC[\pages][\playSequence].notNil) {
                    ~nUPIC[\pages][\playSequence].value({
                        { btn.value = 0 }.defer;
                    });
                } {
                    "Sequence playback not implemented yet".warn;
                    btn.value = 0;
                };
            } {
                // Stop playback
                if(~nUPIC[\ui][\stopPlayback].notNil) {
                    ~nUPIC[\ui][\stopPlayback].value;
                };
            };
        });

    // Refresh button (sync from page manager)
    Button(controlView, Rect(590, 5, 45, 28))
        .states_([["_sync", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 9))
        .action_({
            syncMatrixToSequence.value;
        });

    // Initial sync
    { syncMatrixToSequence.value }.defer(0.1);

    // Store window reference
    ~nUPIC[\pageSequencer][\window] = win;

    win.onClose = {
        ~nUPIC[\pageSequencer][\window] = nil;
    };

    win.front;
};

// Toggle function
~nUPIC[\pageSequencer][\toggle] = {
    if(~nUPIC[\pageSequencer][\window].notNil) {
        ~nUPIC[\pageSequencer][\window].close;
    } {
        ~nUPIC[\pageSequencer][\open].value;
    };
};

"Page Sequence Editor loaded (matrix layout)".postln;
"  - Call ~nUPIC[\\pageSequencer][\\open].value to open".postln;
)
