// Debug utility for amplitude envelope issues
// Run this after drawing amplitude envelopes to inspect the data

(
~debugAmplitudeEnvelopes = {
    var data = ~nUPIC[\data];
    
    if(data.isNil or: { data[\amplitudeEnvelopes].isNil }) {
        "No amplitude envelope data available".postln;
        ^nil;
    };
    
    "=== AMPLITUDE ENVELOPE DEBUG ===".postln;
    
    data[\amplitudeEnvelopes].do { |env, i|
        if(env.notNil) {
            ("Trajectory " ++ i ++ " envelope:").postln;
            ("  Points: " ++ env.size).postln;
            env.do { |point, j|
                ("    Point " ++ j ++ ": x=" ++ point.x.round(0.1) ++ ", amp=" ++ point.amp.round(0.001)).postln;
            };
            
            // Check if trajectory exists
            if(i < data[\trajectories].size and: { data[\trajectories][i].notNil }) {
                var traj = data[\trajectories][i];
                if(traj.size > 0) {
                    var firstX = if(traj[0].isKindOf(Event)) { traj[0].x } { traj[0].x };
                    var lastX = if(traj.last.isKindOf(Event)) { traj.last.x } { traj.last.x };
                    var trajLength = lastX - firstX;
                    ("  Trajectory range: " ++ firstX.round(0.1) ++ " to " ++ lastX.round(0.1) ++ " (length: " ++ trajLength.round(0.1) ++ ")").postln;
                };
            };
            
            // Check amplitude range
            var minAmp = env.collect(_.amp).minItem;
            var maxAmp = env.collect(_.amp).maxItem;
            var avgAmp = env.collect(_.amp).mean;
            ("  Amplitude range: " ++ minAmp.round(0.001) ++ " to " ++ maxAmp.round(0.001) ++ " (avg: " ++ avgAmp.round(0.001) ++ ")").postln;
            
            if(maxAmp < 0.01) {
                "  WARNING: Maximum amplitude is very low! This will be barely audible.".postln;
            };
            if(avgAmp < 0.05) {
                "  WARNING: Average amplitude is very low! Consider increasing envelope levels.".postln;
            };
            
            "".postln;
        };
    };
    
    "=== END DEBUG ===".postln;
};

// Also create a function to fix very low amplitude envelopes
~fixLowAmplitudeEnvelopes = {
    var data = ~nUPIC[\data];
    var fixed = 0;
    
    if(data.isNil or: { data[\amplitudeEnvelopes].isNil }) {
        "No amplitude envelope data to fix".postln;
        ^0;
    };
    
    data[\amplitudeEnvelopes].do { |env, i|
        if(env.notNil) {
            var maxAmp = env.collect(_.amp).maxItem;
            if(maxAmp < 0.1) {
                // Boost all amplitude values by 5x but cap at 1.0
                data[\amplitudeEnvelopes][i] = env.collect { |point|
                    (x: point.x, amp: (point.amp * 5).min(1.0))
                };
                ("Fixed low amplitude envelope for trajectory " ++ i ++ " (boosted by 5x)").postln;
                fixed = fixed + 1;
            };
        };
    };
    
    if(fixed > 0) {
        // Refresh amplitude editor if open
        if(~nUPIC[\ui][\ampEditorWindow].notNil and: { 
            ~nUPIC[\ui][\ampEditorWindow].isClosed.not 
        }) {
            var container = ~nUPIC[\ui][\ampEditorContainer];
            if(container.notNil) {
                var trajIndex = container.getProperty(\trajIndex);
                var ampView = container.getProperty(\ampView);
                if(ampView.notNil and: { trajIndex.notNil }) {
                    { ~nUPIC[\ui][\updateAmplitudeDisplay].value(ampView, trajIndex); }.defer(0.1);
                };
            };
        };
        
        ("Fixed " ++ fixed ++ " low amplitude envelopes").postln;
    } {
        "No low amplitude envelopes found to fix".postln;
    };
    
    fixed;
};

"Debug functions loaded:".postln;
"  ~debugAmplitudeEnvelopes.value  - inspect amplitude envelope data".postln;
"  ~fixLowAmplitudeEnvelopes.value - boost very low amplitude values".postln;
)
