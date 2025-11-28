// Enhanced Amplitude Precision for nUPIC
// This script improves amplitude envelope precision and adds zoom capability
// Run this after START_NUPIC.scd

(
"=== Enhancing Amplitude Envelope Precision ===".postln;

// 1. Create ultra-fast response SynthDef variants with NO built-in envelope
~createPreciseAmplitudeSynthDefs = {
    
    // Precise amplitude version of upicWavetable - NO attack/release envelope
    SynthDef(\upicWavetablePrecise, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1,
            bufnum = 0;
        
        var sig, dopplerShift, finalFreq, distAmp;
        var phase;
        
        // Calculate frequency with optional Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // NO ENVELOPE - direct amplitude control for precision
        // The amplitude envelope from the trajectory will control the level directly
        
        // Phase generation
        phase = Phasor.ar(0, finalFreq / SampleRate.ir, 0, 1);
        
        // Main oscillator using OscOS for quality
        sig = OscOS.ar(bufnum, phase, 1, 0, 2, 1.0);
        
        // Add harmonics based on mass
        sig = sig + (OscOS.ar(bufnum, phase * 2, 1, 0, 2, mass.linlin(1, 10, 0, 0.3)));
        
        // Distance amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Direct amplitude control - no envelope!
        // Use Lag for very slight smoothing (1ms) to avoid clicks
        sig = sig * Lag.kr(amp * distAmp * (1 / numSynths.sqrt.max(1)), 0.001);
        
        // Gate for note off (very fast release to maintain precision)
        sig = sig * EnvGen.kr(Env.cutoff(0.002), gate, doneAction: 2);
        
        // Soft limiting
        sig = sig.clip(-0.9, 0.9);
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    // Precise amplitude version of simpleGravObject
    SynthDef(\simpleGravObjectPrecise, {
        arg freq = 440, amp = 0.1, pan = 0, gate = 1,
            mass = 1, velocity = 0, distance = 100, width = 0.5,
            radialVel = 0, dopplerSens = 0, numSynths = 1;
        
        var sig, dopplerShift, finalFreq, distAmp;
        
        // Calculate frequency with optional Doppler
        dopplerShift = 1 + (radialVel * dopplerSens * 0.01);
        finalFreq = freq * dopplerShift.clip(0.5, 2.0);
        
        // Simple oscillator design
        sig = Mix.ar([
            SinOsc.ar(finalFreq) * 0.5,
            SinOsc.ar(finalFreq * 2) * 0.2 * mass.linlin(1, 10, 0, 1),
            SinOsc.ar(finalFreq * 3) * 0.1 * mass.linlin(1, 10, 0, 1)
        ]);
        
        // Subtle vibrato
        sig = sig * (1 + (SinOsc.kr(velocity.linlin(0, 20, 0.5, 5)) * 0.02));
        
        // Distance amplitude
        distAmp = (100 / distance.max(10)).sqrt.clip(0, 2);
        
        // Direct amplitude control with minimal lag
        sig = sig * Lag.kr(amp * distAmp * (1 / numSynths.sqrt.max(1)), 0.001);
        
        // Gate for note off (very fast)
        sig = sig * EnvGen.kr(Env.cutoff(0.002), gate, doneAction: 2);
        
        // Soft clipping
        sig = sig.tanh * 0.9;
        
        Out.ar(0, Pan2.ar(sig, pan));
    }).add;
    
    "✓ Precise amplitude SynthDefs created".postln;
};

// 2. Enhanced amplitude editor update function with zoom
~enhanceAmplitudeEditor = {
    
    // Override the createAmplitudeEditorContent function to add zoom controls
    ~nUPIC[\ui][\createAmplitudeEditorContent] = { |container, trajIndex|
        var ampView, overlayView, presetContainer, toolbarContainer, levelMeterContainer;
        var winWidth = container.bounds.width, winHeight = container.bounds.height;
        var viewHeight = winHeight - 180;
        var meterWidth = 30;
        var editorWidth = winWidth - meterWidth - 10;
        var data = ~nUPIC[\data];
        var constants = ~nUPIC[\constants];
        var colors = ~nUPIC[\colors];
        var ampZoomMin, ampZoomMax;
        var levelMeter, analysisText;
        var timeZoomSlider, ampZoomSlider;  // New zoom controls
        
        // Clear existing content
        container.children.do({ |child| child.remove });
        
        // Get zoom values for current trajectory
        ampZoomMin = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMin] ? 0;
        ampZoomMax = ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMax] ? 1;
        
        // Create amplitude editing view with HIGHER resolution
        ampView = MultiSliderView(container, Rect(0, 60, editorWidth, viewHeight - 60));  // Leave space for zoom controls
        ampView.background = colors[\amplitudeBackground] ? Color.white;
        ampView.fillColor = colors[\amplitudeEnvelope] ? Color.red.alpha_(0.6);
        ampView.strokeColor = colors[\amplitudeStroke] ? Color.red;
        ampView.drawRects = false;
        ampView.drawLines = true;
        ampView.thumbSize = 2;  // Smaller thumbs for more precision
        ampView.gap = 0;
        ampView.isFilled = true;
        ampView.elasticMode = true;
        
        // INCREASE RESOLUTION - more sliders for finer control
        ampView.size = 512;  // Increased from default for better resolution
        
        // Update amplitude envelope when multislider changes
        ampView.action = { |view|
            var values = view.value;
            var currentTraj = data[\trajectories][trajIndex];
            var trajLen = if(currentTraj.size > 0) {
                var firstX = if(currentTraj[0].isKindOf(Event)) { currentTraj[0].x } { currentTraj[0].x };
                var lastX = if(currentTraj.last.isKindOf(Event)) { currentTraj.last.x } { currentTraj.last.x };
                lastX - firstX;
            } { 600 };
            var newEnv = List.new;
            var zoomStartX = ampZoomMin * trajLen;
            var zoomEndX = ampZoomMax * trajLen;
            
            // Keep existing envelope points before zoom range
            if(data[\amplitudeEnvelopes][trajIndex].notNil) {
                data[\amplitudeEnvelopes][trajIndex].do { |point|
                    if(point.x < zoomStartX) {
                        newEnv.add(point);
                    };
                };
            };
            
            // Add points from multislider values with HIGH resolution
            values.do { |amp, i|
                var normalizedPos = i / (values.size - 1);
                var zoomedPos = normalizedPos.linlin(0, 1, ampZoomMin, ampZoomMax);
                var x = zoomedPos * trajLen;
                newEnv.add((x: x, amp: amp));
            };
            
            // Keep existing envelope points after zoom range
            if(data[\amplitudeEnvelopes][trajIndex].notNil) {
                data[\amplitudeEnvelopes][trajIndex].do { |point|
                    if(point.x > zoomEndX) {
                        newEnv.add(point);
                    };
                };
            };
            
            // Sort and store
            data[\amplitudeEnvelopes][trajIndex] = newEnv.sort({ |a, b| a.x < b.x });
            
            ~nUPIC[\ui][\refreshDisplay].value;
        };
        
        // Add TIME ZOOM control
        StaticText(container, Rect(0, 0, 100, 20))
            .string_("Time Zoom:")
            .font_(Font("Arial", 10, true));
        
        timeZoomSlider = RangeSlider(container, Rect(0, 20, editorWidth, 20))
            .lo_(ampZoomMin)
            .hi_(ampZoomMax)
            .action_({ |slider|
                ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMin] = slider.lo;
                ~nUPIC[\ui][\ampEditorZooms][trajIndex][\ampZoomMax] = slider.hi;
                
                // Refresh the display
                ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
                
                ("Time zoom: " ++ (slider.lo * 100).round(1) ++ "% to " ++ 
                 (slider.hi * 100).round(1) ++ "%").postln;
            });
        
        // Add AMPLITUDE RANGE control
        StaticText(container, Rect(0, 40, 100, 20))
            .string_("Amp Range:")
            .font_(Font("Arial", 10, true));
        
        // Add overlay for drawing
        overlayView = UserView(container, Rect(0, 60, editorWidth, viewHeight - 60));
        overlayView.acceptsMouse = false;
        overlayView.drawFunc = {
            // Draw grid
            ~nUPIC[\ui][\drawAmplitudeGrid].value(editorWidth, viewHeight - 60, ampZoomMin, ampZoomMax);
        };
        
        // Level meter (kept from original)
        levelMeterContainer = CompositeView(container, 
            Rect(editorWidth + 5, 60, meterWidth, viewHeight - 60));
        levelMeterContainer.background = Color.gray(0.9);
        
        levelMeter = LevelIndicator(levelMeterContainer, 
            Rect(5, 30, 20, viewHeight - 120))
            .warning_(0.8).critical_(0.95)
            .style_(0)
            .numTicks_(20)
            .value_(0);
        
        // Create control area
        presetContainer = CompositeView(container, 
            Rect(0, viewHeight, winWidth, winHeight - viewHeight));
        presetContainer.background = Color.gray(0.9);
        
        // Add controls
        ~nUPIC[\ui][\createAmplitudeControls].value(presetContainer, trajIndex, ampZoomMin, ampZoomMax);
        
        // Initialize display
        {
            ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex);
        }.defer(0.1);
        
        // Store references
        container.setProperty(\ampView, ampView);
        container.setProperty(\overlayView, overlayView);
        container.setProperty(\trajIndex, trajIndex);
        container.setProperty(\levelMeter, levelMeter);
        container.setProperty(\timeZoomSlider, timeZoomSlider);
        
        "Enhanced amplitude editor created with zoom controls".postln;
    };
    
    "✓ Amplitude editor enhanced with zoom and precision controls".postln;
};

// 3. Update the SynthDef list
~updateSynthDefListWithPrecise = {
    if(~nUPIC_SynthDefs.isNil) {
        ~nUPIC_SynthDefs = IdentityDictionary.new;
    };
    
    // Get current list
    var currentList = ~nUPIC_SynthDefs[\available] ? [];
    
    // Add precise versions if they're registered
    [\upicWavetablePrecise, \simpleGravObjectPrecise].do { |synthName|
        if(SynthDescLib.global.synthDescs[synthName].notNil) {
            if(currentList.includes(synthName).not) {
                currentList = currentList ++ [synthName];
                ("Added " ++ synthName ++ " to available list").postln;
            };
        };
    };
    
    ~nUPIC_SynthDefs[\available] = currentList;
    
    // Update menu if UI is open
    AppClock.sched(0, {
        var state = ~nUPIC[\ui][\state];
        if(state.notNil and: { state[\controls].notNil }) {
            var controls = state[\controls];
            if(controls[\synthDefMenu].notNil) {
                controls[\synthDefMenu].items = currentList.collect(_.asString);
                "✓ Updated SynthDef menu with precise versions".postln;
            };
        };
        nil;
    });
};

// 4. Execute all enhancements
fork {
    "Creating precise amplitude SynthDefs...".postln;
    ~createPreciseAmplitudeSynthDefs.value;
    
    s.sync;
    1.wait;
    
    "Enhancing amplitude editor...".postln;
    ~enhanceAmplitudeEditor.value;
    
    0.5.wait;
    
    "Updating SynthDef list...".postln;
    ~updateSynthDefListWithPrecise.value;
    
    "".postln;
    "=== AMPLITUDE PRECISION ENHANCEMENTS COMPLETE ===".postln;
    "".postln;
    "NEW FEATURES:".postln;
    "• Precise amplitude SynthDefs with NO attack/release envelope".postln;
    "• Direct amplitude control for instant response".postln;
    "• Time zoom slider in amplitude editor for detailed editing".postln;
    "• Higher resolution (512 points) for fine control".postln;
    "".postln;
    "AVAILABLE PRECISE SYNTHDEFS:".postln;
    "• upicWavetablePrecise - Wavetable with instant amplitude response".postln;
    "• simpleGravObjectPrecise - Simple synth with instant amplitude response".postln;
    "".postln;
    "To use precise amplitude control:".postln;
    "1. Select trajectories (G key)".postln;
    "2. Choose a 'Precise' SynthDef from the menu".postln;
    "3. Edit amplitudes - sharp attacks will now be preserved!".postln;
    "4. Use the time zoom slider to zoom in for detailed editing".postln;
};
)