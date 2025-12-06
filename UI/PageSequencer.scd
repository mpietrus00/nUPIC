// nUPIC Page Sequence Editor
// Visual editor for arranging pages into playback sequence
// Left: Available pages | Right: Sequence order

(
~nUPIC = ~nUPIC ?? ();
~nUPIC[\pageSequencer] = ~nUPIC[\pageSequencer] ?? ();

~nUPIC[\pageSequencer][\open] = {
    var win, pagesView, sequenceView, controlView;
    var width = 600, height = 400;
    var pageListWidth = 200;
    var controlHeight = 40;
    var pageButtons = List.new;
    var sequenceButtons = List.new;
    var selectedPageIndex = nil;
    var selectedSequencePos = nil;
    var pageManager = ~nUPIC[\pages][\manager];
    var totalDurationText;

    // Helper to refresh page list
    var refreshPageList = {
        var pages = pageManager.pages;
        var currentIdx = pageManager.getCurrentIndex.value;

        // Clear old buttons
        pageButtons.do { |btn| btn.remove };
        pageButtons.clear;

        // Create buttons for each page
        pages.do { |page, i|
            var yPos = 5 + (i * 35);
            var btn, labelText;

            labelText = "% - % (% sec, % arcs)".format(
                (i + 1).asString.padLeft(2, " "),
                page.label.asString.keep(12),
                page.duration.round(0.1),
                page.arcs.size
            );

            btn = Button(pagesView, Rect(5, yPos, pageListWidth - 10, 30))
                .states_([
                    [labelText, Color.black, if(i == currentIdx) { Color.yellow(0.7) } { Color.gray(0.85) }],
                    [labelText, Color.white, Color.blue(0.7)]  // Selected state
                ])
                .font_(Font("Monaco", 10))
                .value_(if(selectedPageIndex == i) { 1 } { 0 })
                .action_({ |b|
                    // Toggle selection
                    if(selectedPageIndex == i) {
                        selectedPageIndex = nil;
                        b.value = 0;
                    } {
                        // Deselect previous
                        pageButtons.do { |pb| pb.value = 0 };
                        selectedPageIndex = i;
                        b.value = 1;
                    };
                });

            // Double-click to switch to page
            btn.mouseDownAction = { |view, x, y, modifiers, buttonNumber, clickCount|
                if(clickCount == 2) {
                    pageManager.syncFromData.value;
                    pageManager.switchTo.value(i);
                    { refreshPageList.value }.defer(0.1);
                };
            };

            pageButtons.add(btn);
        };

        pagesView.refresh;
    };

    // Helper to refresh sequence view
    var refreshSequence = {
        var sequence = pageManager.sequence;
        var pages = pageManager.pages;
        var xPos = 5;
        var totalDur = pageManager.getTotalDuration.value;

        // Clear old buttons
        sequenceButtons.do { |btn| btn.remove };
        sequenceButtons.clear;

        // Create buttons for sequence
        sequence.do { |pageIdx, pos|
            var page = pages[pageIdx];
            var labelText = page.label.asString.keep(8);
            var btn;

            btn = Button(sequenceView, Rect(xPos, 30, 70, 50))
                .states_([
                    [labelText ++ "\n" ++ page.duration ++ "s", Color.black, Color.cyan(0.7)],
                    [labelText ++ "\n" ++ page.duration ++ "s", Color.white, Color.magenta(0.8)]
                ])
                .font_(Font("Arial", 9, true))
                .value_(if(selectedSequencePos == pos) { 1 } { 0 })
                .action_({ |b|
                    if(selectedSequencePos == pos) {
                        selectedSequencePos = nil;
                        b.value = 0;
                    } {
                        sequenceButtons.do { |sb| sb.value = 0 };
                        selectedSequencePos = pos;
                        b.value = 1;
                    };
                });

            sequenceButtons.add(btn);
            xPos = xPos + 75;
        };

        // Update total duration display
        totalDurationText.string = "Total: % min % sec".format(
            (totalDur / 60).floor.asInteger,
            (totalDur % 60).round(0.1)
        );

        sequenceView.refresh;
    };

    // Check if page manager exists
    if(pageManager.isNil) {
        "Page manager not initialized. Load PageData.scd first.".warn;
        ^nil;
    };

    // Ensure at least one page exists
    pageManager.ensureInitialized.value;

    // Create window
    win = Window("nUPIC Page Sequence Editor", Rect(100, 100, width, height));
    win.background = Color.gray(0.9);

    // === LEFT PANEL: Available Pages ===
    StaticText(win, Rect(5, 5, pageListWidth, 20))
        .string_("Available Pages")
        .font_(Font("Arial", 12, true));

    pagesView = ScrollView(win, Rect(0, 25, pageListWidth, height - controlHeight - 30))
        .background_(Color.gray(0.95))
        .hasBorder_(true);
    pagesView.canvas = View().background_(Color.gray(0.95));
    pagesView.canvas.resize_(5);

    // === RIGHT PANEL: Sequence ===
    StaticText(win, Rect(pageListWidth + 10, 5, width - pageListWidth - 20, 20))
        .string_("Playback Sequence (drag pages here)")
        .font_(Font("Arial", 12, true));

    sequenceView = ScrollView(win, Rect(pageListWidth + 5, 25, width - pageListWidth - 10, height - controlHeight - 60))
        .background_(Color.white)
        .hasBorder_(true);
    sequenceView.canvas = View().background_(Color.white);
    sequenceView.canvas.resize_(5);

    // Total duration display
    totalDurationText = StaticText(win, Rect(pageListWidth + 10, height - controlHeight - 30, 200, 20))
        .string_("Total: 0 min 0 sec")
        .font_(Font("Arial", 11, true));

    // === CONTROL PANEL ===
    controlView = CompositeView(win, Rect(0, height - controlHeight, width, controlHeight));
    controlView.background = Color.gray(0.8);

    // New Page button
    Button(controlView, Rect(5, 8, 60, 24))
        .states_([["+Page", Color.black, Color.green(0.7)]])
        .font_(Font("Arial", 10, true))
        .action_({
            var newIdx = pageManager.create.value;
            if(newIdx.notNil) {
                { refreshPageList.value }.defer(0.1);
            };
        });

    // Delete Page button
    Button(controlView, Rect(70, 8, 50, 24))
        .states_([["-Page", Color.white, Color.red(0.7)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedPageIndex.notNil) {
                if(pageManager.pages.size > 1) {
                    pageManager.delete.value(selectedPageIndex);
                    selectedPageIndex = nil;
                    { refreshPageList.value; refreshSequence.value }.defer(0.1);
                } {
                    "Cannot delete last page".warn;
                };
            } {
                "Select a page first".warn;
            };
        });

    // Duplicate Page button
    Button(controlView, Rect(125, 8, 40, 24))
        .states_([["Dup", Color.black, Color.yellow(0.7)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedPageIndex.notNil) {
                pageManager.duplicate.value(selectedPageIndex);
                { refreshPageList.value }.defer(0.1);
            } {
                "Select a page first".warn;
            };
        });

    // Rename Page button
    Button(controlView, Rect(170, 8, 50, 24))
        .states_([["Rename", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedPageIndex.notNil) {
                var page = pageManager.pages[selectedPageIndex];
                var dialog = Window("Rename Page", Rect(300, 300, 250, 80));
                var textField = TextField(dialog, Rect(10, 10, 230, 24))
                    .string_(page.label);
                Button(dialog, Rect(80, 45, 80, 24))
                    .states_([["OK", Color.black, Color.green(0.7)]])
                    .action_({
                        pageManager.setLabel.value(selectedPageIndex, textField.string);
                        dialog.close;
                        { refreshPageList.value; refreshSequence.value }.defer(0.1);
                    });
                dialog.front;
            } {
                "Select a page first".warn;
            };
        });

    // Separator
    StaticText(controlView, Rect(230, 8, 10, 24)).string_("|");

    // Add to Sequence button
    Button(controlView, Rect(245, 8, 60, 24))
        .states_([["Add >>", Color.white, Color.blue(0.7)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedPageIndex.notNil) {
                pageManager.addToSequence.value(selectedPageIndex);
                { refreshSequence.value }.defer(0.1);
            } {
                "Select a page first".warn;
            };
        });

    // Remove from Sequence button
    Button(controlView, Rect(310, 8, 60, 24))
        .states_([["<< Rem", Color.white, Color.red(0.6)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedSequencePos.notNil) {
                pageManager.removeFromSequence.value(selectedSequencePos);
                selectedSequencePos = nil;
                { refreshSequence.value }.defer(0.1);
            } {
                "Select a sequence item first".warn;
            };
        });

    // Move Left in Sequence
    Button(controlView, Rect(375, 8, 30, 24))
        .states_([["<", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedSequencePos.notNil and: { selectedSequencePos > 0 }) {
                pageManager.moveInSequence.value(selectedSequencePos, selectedSequencePos - 1);
                selectedSequencePos = selectedSequencePos - 1;
                { refreshSequence.value }.defer(0.1);
            };
        });

    // Move Right in Sequence
    Button(controlView, Rect(408, 8, 30, 24))
        .states_([[">", Color.black, Color.gray(0.85)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedSequencePos.notNil and: { selectedSequencePos < (pageManager.sequence.size - 1) }) {
                pageManager.moveInSequence.value(selectedSequencePos, selectedSequencePos + 1);
                selectedSequencePos = selectedSequencePos + 1;
                { refreshSequence.value }.defer(0.1);
            };
        });

    // Separator
    StaticText(controlView, Rect(445, 8, 10, 24)).string_("|");

    // Play Sequence button
    Button(controlView, Rect(460, 8, 70, 24))
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

    // Edit Page button (switch to main UI)
    Button(controlView, Rect(535, 8, 55, 24))
        .states_([["Edit", Color.black, Color.cyan(0.7)]])
        .font_(Font("Arial", 10, true))
        .action_({
            if(selectedPageIndex.notNil) {
                pageManager.syncFromData.value;
                pageManager.switchTo.value(selectedPageIndex);
                { refreshPageList.value }.defer(0.1);
                "Now editing page %: %".format(selectedPageIndex, pageManager.pages[selectedPageIndex].label).postln;
            } {
                "Select a page first".warn;
            };
        });

    // Initial refresh
    { refreshPageList.value; refreshSequence.value }.defer(0.1);

    // Store window reference
    ~nUPIC[\pageSequencer][\window] = win;

    win.onClose = {
        ~nUPIC[\pageSequencer][\window] = nil;
    };

    win.front;
};

// Keyboard shortcut to open (can be bound elsewhere)
~nUPIC[\pageSequencer][\toggle] = {
    if(~nUPIC[\pageSequencer][\window].notNil) {
        ~nUPIC[\pageSequencer][\window].close;
    } {
        ~nUPIC[\pageSequencer][\open].value;
    };
};

"Page Sequence Editor loaded".postln;
"  - Call ~nUPIC[\\pageSequencer][\\open].value to open".postln;
)
