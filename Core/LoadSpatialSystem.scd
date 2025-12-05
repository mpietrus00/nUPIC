// LoadSpatialSystem - Load the new spatial architecture
// Run this after START_NUPIC.scd to enable improved spatial playback

(
var basePath = PathName(thisProcess.nowExecutingPath).pathOnly;

"Loading Spatial System...".postln;

// Load Utils
(basePath +/+ "Utils/SpatialHelpers.scd").load;

// Load Model
(basePath +/+ "Model/SpatialModel.scd").load;

// Load Connections
(basePath +/+ "Connections/SpatialPlayback.scd").load;

// Override the main playback with spatial version
~nUPIC[\ui][\startPlayback] = {
    ~nUPIC[\playback][\startWithSpatial].value;
};

"".postln;
"═══════════════════════════════════════════════════".postln;
"  SPATIAL SYSTEM LOADED".postln;
"═══════════════════════════════════════════════════".postln;
"".postln;
"  Architecture:".postln;
"  • SpatialModel - Reactive channel/pan data".postln;
"  • SpatialPlayback - Clean playback engine".postln;
"".postln;
"  Pan Mapping:".postln;
"  • 2ch (Pan2): channel 0→-1, channel 1→1".postln;
"  • 3ch+ (PanAz): channel c → c*2/n".postln;
"".postln;
"  Playback will now use spatial envelopes properly.".postln;
"═══════════════════════════════════════════════════".postln;
)
