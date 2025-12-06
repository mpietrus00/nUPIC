// nUPIC Page Data Management
// Handles multi-page composition structure
// Each page contains its own arcs, envelopes, wavetables, and duration

(
// Ensure nUPIC namespace exists
if(~nUPIC.isNil) { ~nUPIC = IdentityDictionary.new };
~nUPIC[\pages] = IdentityDictionary.new;

~nUPIC[\pages][\manager] = {
    var pages, sequence, currentPageIndex;
    var maxPages = 24;  // Original UPIC limit
    var defaultDuration = 60;  // 1 minute default (original UPIC page limit)
    var createEmptyPageData;  // Forward declaration
    var defaultPageLabels = ["_a", "_b", "_c", "_d"];  // Default page labels

    // Initialize
    pages = List.new;
    sequence = List.new;
    currentPageIndex = 0;

    // Create an empty page structure
    createEmptyPageData = { |label, duration|
        (
            label: label ?? "Untitled",
            duration: duration ?? defaultDuration,
            arcs: List.new,
            amplitudeEnvelopes: List.new,
            spatialEnvelopes: List.new,
            arcSynthDefs: List.new,
            wavetables: List.new,
            wavetableBuffers: List.new,
            selectedArcs: Set.new,
            // Metadata
            created: Date.localtime.stamp,
            modified: Date.localtime.stamp
        )
    };

    // Public interface
    (
        // Page list access
        pages: pages,
        sequence: sequence,

        // Get current page index
        getCurrentIndex: { currentPageIndex },

        // Get current page data
        getCurrent: {
            if(currentPageIndex < pages.size) {
                pages[currentPageIndex]
            } { nil }
        },

        // Get page by index
        getPage: { |index|
            if(index >= 0 and: { index < pages.size }) {
                pages[index]
            } { nil }
        },

        // Get page count
        count: { pages.size },

        // Create a new page
        create: { |label, duration|
            var newPage, index;

            if(pages.size >= maxPages) {
                "Maximum page limit (%) reached".format(maxPages).warn;
                nil
            } {
                index = pages.size;
                newPage = createEmptyPageData.value(
                    label ?? ("Page " ++ (index + 1)),
                    duration ?? defaultDuration
                );
                pages.add(newPage);
                "Created page %: '%' (% sec)".format(index, newPage.label, newPage.duration).postln;
                index
            }
        },

        // Delete a page
        delete: { |index|
            if(index >= 0 and: { index < pages.size }) {
                var page = pages[index];

                // Free any wavetable buffers
                if(page.wavetableBuffers.notNil) {
                    page.wavetableBuffers.do { |buf|
                        if(buf.notNil) { buf.free };
                    };
                };

                pages.removeAt(index);

                // Update sequence - remove references to deleted page
                sequence = sequence.reject { |i| i == index };
                // Adjust indices for pages after deleted one
                sequence = sequence.collect { |i|
                    if(i > index) { i - 1 } { i }
                };

                // Adjust current page index if needed
                if(currentPageIndex >= pages.size) {
                    currentPageIndex = (pages.size - 1).max(0);
                };

                "Deleted page %".format(index).postln;
                true
            } {
                "Invalid page index: %".format(index).warn;
                false
            }
        },

        // Duplicate a page
        duplicate: { |index|
            if(index >= 0 and: { index < pages.size }) {
                var original = pages[index];
                var copy, newIndex;

                if(pages.size >= maxPages) {
                    "Maximum page limit (%) reached".format(maxPages).warn;
                    nil
                } {
                    copy = (
                        label: original.label ++ " (copy)",
                        duration: original.duration,
                        arcs: original.arcs.deepCopy,
                        amplitudeEnvelopes: original.amplitudeEnvelopes.deepCopy,
                        spatialEnvelopes: original.spatialEnvelopes.deepCopy,
                        arcSynthDefs: original.arcSynthDefs.copy,
                        wavetables: original.wavetables.collect { |wt|
                            if(wt.notNil) { wt.copy } { nil }
                        },
                        wavetableBuffers: List.new,  // Will be created on demand
                        selectedArcs: Set.new,
                        created: Date.localtime.stamp,
                        modified: Date.localtime.stamp
                    );

                    newIndex = pages.size;
                    pages.add(copy);
                    "Duplicated page % to page %".format(index, newIndex).postln;
                    newIndex
                }
            } {
                "Invalid page index: %".format(index).warn;
                nil
            }
        },

        // Switch to a different page
        switchTo: { |index|
            if(index >= 0 and: { index < pages.size }) {
                var oldIndex = currentPageIndex;
                currentPageIndex = index;

                // Sync current page data with ~nUPIC[\data]
                ~nUPIC[\pages][\manager][\syncToData].value;

                "Switched from page % to page %".format(oldIndex, index).postln;
                true
            } {
                "Invalid page index: %".format(index).warn;
                false
            }
        },

        // Sync current page data to ~nUPIC[\data] (for Main UI compatibility)
        syncToData: {
            var page = pages[currentPageIndex];
            if(page.notNil and: { ~nUPIC[\data].notNil }) {
                // Point data references to current page's data
                ~nUPIC[\data][\arcs] = page.arcs;
                ~nUPIC[\data][\trajectories] = page.arcs;  // Alias
                ~nUPIC[\data][\amplitudeEnvelopes] = page.amplitudeEnvelopes;
                ~nUPIC[\data][\spatialEnvelopes] = page.spatialEnvelopes;
                ~nUPIC[\data][\arcSynthDefs] = page.arcSynthDefs;
                ~nUPIC[\data][\wavetables] = page.wavetables;
                ~nUPIC[\data][\wavetableBuffers] = page.wavetableBuffers;
                ~nUPIC[\data][\selectedArcs] = page.selectedArcs;

                // Update duration in UI state and controls
                if(~nUPIC[\ui][\state].notNil) {
                    ~nUPIC[\ui][\state][\playDuration] = page.duration;

                    // Update duration control widget if it exists
                    if(~nUPIC[\ui][\state][\controls].notNil and: {
                        ~nUPIC[\ui][\state][\controls][\durationNumberBox].notNil
                    }) {
                        {
                            ~nUPIC[\ui][\state][\controls][\durationNumberBox].value = page.duration;
                        }.defer;
                    };
                };

                // Update page tabs
                if(~nUPIC[\ui][\updatePageTabs].notNil) {
                    { ~nUPIC[\ui][\updatePageTabs].value(currentPageIndex) }.defer;
                };

                // Refresh display
                if(~nUPIC[\ui][\refreshDisplay].notNil) {
                    { ~nUPIC[\ui][\refreshDisplay].value }.defer;
                };

                "Page synced: % arcs, duration=% sec".format(page.arcs.size, page.duration).postln;
            };
        },

        // Sync ~nUPIC[\data] back to current page (call before switching)
        syncFromData: {
            var page = pages[currentPageIndex];
            if(page.notNil and: { ~nUPIC[\data].notNil }) {
                // Copy references back (in case Lists were replaced)
                page.arcs = ~nUPIC[\data][\arcs] ?? page.arcs;
                page.amplitudeEnvelopes = ~nUPIC[\data][\amplitudeEnvelopes] ?? page.amplitudeEnvelopes;
                page.spatialEnvelopes = ~nUPIC[\data][\spatialEnvelopes] ?? page.spatialEnvelopes;
                page.arcSynthDefs = ~nUPIC[\data][\arcSynthDefs] ?? page.arcSynthDefs;
                page.wavetables = ~nUPIC[\data][\wavetables] ?? page.wavetables;
                page.wavetableBuffers = ~nUPIC[\data][\wavetableBuffers] ?? page.wavetableBuffers;
                page.selectedArcs = ~nUPIC[\data][\selectedArcs] ?? page.selectedArcs;

                // Update duration from UI state
                if(~nUPIC[\ui][\state].notNil) {
                    page.duration = ~nUPIC[\ui][\state][\playDuration] ?? page.duration;
                };

                page.modified = Date.localtime.stamp;
            };
        },

        // Set page label
        setLabel: { |index, label|
            if(index >= 0 and: { index < pages.size }) {
                pages[index].label = label;
                pages[index].modified = Date.localtime.stamp;
            };
        },

        // Set page duration (also updates UI if current page)
        setDuration: { |index, duration|
            if(index >= 0 and: { index < pages.size }) {
                pages[index].duration = duration.max(1);  // Minimum 1 second
                pages[index].modified = Date.localtime.stamp;

                // Update UI state if this is the current page
                if(index == currentPageIndex and: { ~nUPIC[\ui][\state].notNil }) {
                    ~nUPIC[\ui][\state][\playDuration] = duration;
                };
            };
        },

        // Get page duration
        getDuration: { |index|
            if(index >= 0 and: { index < pages.size }) {
                pages[index].duration
            } { defaultDuration }
        },

        // === SEQUENCE MANAGEMENT ===

        // Set the entire sequence
        setSequence: { |newSequence|
            // Validate all indices
            var valid = newSequence.every { |i| i >= 0 and: { i < pages.size } };
            if(valid) {
                sequence = newSequence.asList;
                "Sequence set: %".format(sequence).postln;
                true
            } {
                "Invalid sequence - contains out-of-range page indices".warn;
                false
            }
        },

        // Add page to sequence
        addToSequence: { |pageIndex, position = nil|
            if(pageIndex >= 0 and: { pageIndex < pages.size }) {
                if(position.isNil) {
                    sequence.add(pageIndex);
                } {
                    sequence.insert(position.clip(0, sequence.size), pageIndex);
                };
                true
            } { false }
        },

        // Remove from sequence at position
        removeFromSequence: { |position|
            if(position >= 0 and: { position < sequence.size }) {
                sequence.removeAt(position);
                true
            } { false }
        },

        // Move item in sequence
        moveInSequence: { |fromPos, toPos|
            if(fromPos >= 0 and: { fromPos < sequence.size } and:
               { toPos >= 0 } and: { toPos < sequence.size }) {
                var item = sequence.removeAt(fromPos);
                sequence.insert(toPos, item);
                true
            } { false }
        },

        // Get total sequence duration
        getTotalDuration: {
            sequence.sum { |pageIdx|
                if(pageIdx < pages.size) {
                    pages[pageIdx].duration
                } { 0 }
            }
        },

        // Get sequence as page labels
        getSequenceLabels: {
            sequence.collect { |pageIdx|
                if(pageIdx < pages.size) {
                    pages[pageIdx].label
                } { "?" }
            }
        },

        // === INITIALIZATION ===

        // Initialize with default pages (A, B, C, D) if empty
        ensureInitialized: {
            if(pages.size == 0) {
                // Create default pages A, B, C, D
                defaultPageLabels.do { |label, i|
                    var newPage = createEmptyPageData.value(label, defaultDuration);
                    pages.add(newPage);
                    "Created page %: '%' (% sec)".format(i, label, defaultDuration).postln;
                };
                // Add first page to sequence
                sequence.add(0);
                // Sync to data
                ~nUPIC[\pages][\manager][\syncToData].value;
            };
        },

        // Clear all pages
        clearAll: {
            // Free all wavetable buffers
            pages.do { |page|
                if(page.wavetableBuffers.notNil) {
                    page.wavetableBuffers.do { |buf|
                        if(buf.notNil) { buf.free };
                    };
                };
            };

            pages.clear;
            sequence.clear;
            currentPageIndex = 0;

            // Create default pages A, B, C, D
            defaultPageLabels.do { |label, i|
                var newPage = createEmptyPageData.value(label, defaultDuration);
                pages.add(newPage);
            };
            sequence.add(0);
            ~nUPIC[\pages][\manager][\syncToData].value;

            "All pages cleared, created default pages _a, _b, _c, _d".postln;
        },

        // Get summary for display
        getSummary: {
            pages.collect { |page, i|
                (
                    index: i,
                    label: page.label,
                    duration: page.duration,
                    arcCount: page.arcs.size,
                    isCurrent: i == currentPageIndex
                )
            }
        }
    )
}.value;

// Convenience accessors - use bracket notation to avoid Collection method conflicts
~nUPIC[\pages][\current] = { ~nUPIC[\pages][\manager][\getCurrent].value };
~nUPIC[\pages][\count] = { ~nUPIC[\pages][\manager][\count].value };
~nUPIC[\pages][\create] = { |label, duration| ~nUPIC[\pages][\manager][\create].value(label, duration) };
~nUPIC[\pages][\delete] = { |index| ~nUPIC[\pages][\manager][\delete].value(index) };
~nUPIC[\pages][\duplicate] = { |index| ~nUPIC[\pages][\manager][\duplicate].value(index) };
~nUPIC[\pages][\switchTo] = { |index| ~nUPIC[\pages][\manager][\switchTo].value(index) };
~nUPIC[\pages][\setLabel] = { |index, label| ~nUPIC[\pages][\manager][\setLabel].value(index, label) };
~nUPIC[\pages][\setDuration] = { |index, duration| ~nUPIC[\pages][\manager][\setDuration].value(index, duration) };
~nUPIC[\pages][\getDuration] = { |index| ~nUPIC[\pages][\manager][\getDuration].value(index) };

"nUPIC Page Data Management loaded".postln;
"  - Up to 24 pages per project".postln;
"  - Each page has own duration, arcs, envelopes".postln;
"  - Sequence editor for playback order".postln;
)
