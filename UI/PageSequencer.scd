// nUPIC Page Sequence Editor
// Matrix-based editor for arranging pages into playback sequence
// Rows: Pages A, B, C, D | Columns: 12 sequence slots

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\pageSequencer] = ~nUPIC[\pageSequencer] ?? ();

~nUPIC[\pageSequencer][\open] = {
    var win, matrixView, controlView;
    var width = 700, height = 280;
    var matrixWidth = 640, matrixHeight = 180;
    var controlHeight = 50;
    var labelWidth = 40;
    var cellWidth = 48, cellHeight = 38;
    var numSlots = 12;
    var pageLabels = ["A", "B", "C", "D"];
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
                var dur = pageManager.getDuration.value(pageIdx);
                totalDur = totalDur + dur;
                seqLabels.add(pageLabels[pageIdx]);
            };
        };

        totalDurationText.string = "Total: % min % sec".format(
            (totalDur / 60).floor.asInteger,
            (totalDur % 60).round(0.1)
        );

        sequenceDisplayText.string = "Sequence: " ++ if(seqLabels.size > 0) {
            seqLabels.join(" → ")
        } { "(empty)" };
    };

    // Helper to sync matrix to page manager sequence
    var syncMatrixToSequence = {
        var seq = pageManager.sequence;

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
            pageManager.setSequence.value(seq);
        };
        updateDurationDisplay.value;
    };

    // Check if page manager exists
    if(pageManager.isNil) {
        "Page manager not initialized. Load PageData.scd first.".warn;
        ^nil;
    };

    // Ensure pages are initialized
    pageManager.ensureInitialized.value;

    // Create window
    win = Window("nUPIC Page Sequence Editor", Rect(100, 450, width, height));
    win.background = Color.gray(0.9);

    // Title
    StaticText(win, Rect(10, 5, width - 20, 20))
        .string_("Page Sequence Matrix - Click cells to build sequence")
        .font_(Font("Arial", 12, true))
        .align_(\center);

    // === MATRIX VIEW ===
    matrixView = CompositeView(win, Rect(10, 30, matrixWidth, matrixHeight));
    matrixView.background = Color.white;

    // Column headers (slot numbers 1-12)
    numSlots.do { |col|
        StaticText(matrixView, Rect(labelWidth + (col * cellWidth), 0, cellWidth, 20))
            .string_((col + 1).asString)
            .font_(Font("Arial", 10, true))
            .align_(\center);
    };

    // Row labels and matrix buttons
    4.do { |row|
        var yPos = 25 + (row * cellHeight);
        var pageColor = [
            Color.red(0.7),     // A - Red
            Color.green(0.7),   // B - Green
            Color.blue(0.7),    // C - Blue
            Color.yellow(0.7)   // D - Yellow
        ][row];

        // Row label (A, B, C, D)
        StaticText(matrixView, Rect(5, yPos + 5, labelWidth - 5, cellHeight - 10))
            .string_(pageLabels[row])
            .font_(Font("Arial", 16, true))
            .align_(\center)
            .background_(pageColor.alpha_(0.3));

        // Matrix cells for this row
        numSlots.do { |col|
            var btn = Button(matrixView, Rect(labelWidth + (col * cellWidth) + 2, yPos + 2, cellWidth - 4, cellHeight - 4))
                .states_([
                    ["", Color.black, Color.gray(0.95)],  // Empty slot
                    [pageLabels[row], Color.white, pageColor]  // Page assigned
                ])
                .font_(Font("Arial", 12, true))
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
    controlView = CompositeView(win, Rect(0, height - controlHeight - 5, width, controlHeight));
    controlView.background = Color.gray(0.8);

    // Total duration display
    totalDurationText = StaticText(controlView, Rect(10, 5, 150, 20))
        .string_("Total: 0 min 0 sec")
        .font_(Font("Arial", 11, true));

    // Sequence display
    sequenceDisplayText = StaticText(controlView, Rect(10, 25, 400, 20))
        .string_("Sequence: (empty)")
        .font_(Font("Monaco", 10));

    // Clear Sequence button
    Button(controlView, Rect(420, 8, 80, 30))
        .states_([["Clear All", Color.white, Color.red(0.6)]])
        .font_(Font("Arial", 10, true))
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

    // Fill with A button (quick preset)
    Button(controlView, Rect(505, 8, 60, 30))
        .states_([["Fill A", Color.black, Color.red(0.5)]])
        .font_(Font("Arial", 10, true))
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
    Button(controlView, Rect(570, 8, 70, 30))
        .states_([
            ["Play Seq", Color.white, Color.green(0.6)],
            ["Stop", Color.white, Color.red(0.7)]
        ])
        .font_(Font("Arial", 10, true))
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
    Button(controlView, Rect(645, 8, 45, 30))
        .states_([["Sync", Color.black, Color.cyan(0.7)]])
        .font_(Font("Arial", 10, true))
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
