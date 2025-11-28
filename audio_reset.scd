// SuperCollider Audio Reset Script
// Run this to reset SC audio to safe defaults

(
"=== SuperCollider Audio Reset ===".postln;

// Stop server completely
if(s.serverRunning) {
    s.quit;
    "Server stopped".postln;
    3.wait;
};

// Reset all server options to defaults
s.options = ServerOptions.new;

// Set safe, conservative settings
s.options.memSize = 8192;          // Small memory footprint
s.options.blockSize = 64;          // Conservative block size
s.options.numBuffers = 1024;       // Standard buffering
s.options.sampleRate = nil;        // Use system sample rate
s.options.device = nil;            // Use system default device
s.options.numInputBusChannels = 0; // No inputs to avoid conflicts
s.options.numOutputBusChannels = 2; // Stereo only

// Additional conservative settings
s.options.maxNodes = 512;          // Fewer nodes
s.options.numAudioBusChannels = 128; // Fewer audio buses
s.options.numControlBusChannels = 4096; // Standard control buses

"Audio options reset to safe defaults".postln;
"Available audio devices:".postln;

// List available audio devices
ServerOptions.devices.do { |device, i|
    ("  " ++ i ++ ": " ++ device).postln;
};

"".postln;
"To test audio:".postln;
"1. Boot server: s.boot".postln;
"2. Test sound: { SinOsc.ar(440) * 0.1 }.play".postln;

)
