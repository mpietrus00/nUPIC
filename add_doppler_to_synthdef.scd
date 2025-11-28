// Add Doppler effect to simpleGravObject to reduce high-frequency artifacts
// This matches the original implementation from MultiObjectBarycenterSonification.scd

(
"Adding Doppler effect to simpleGravObject SynthDef...".postln;

// Override the simpleGravObject SynthDef with Doppler effect
SynthDef(\simpleGravObject, {
    var sig, freq, amp, pan, mass, velocity, distance, width;
    var gate = \gate.kr(1);
    var dopplerFreq, radialVelocity, dopplerShift, dopplerSensitivity, dopplerDeadZone;
    
    // Get parameters with safe defaults and add smoothing via lag filters
    freq = Lag.kr(\freq.kr(300).clip(0.1, 8000), 0.1);  // Increased lag for smoother glides
    amp = Lag.kr(\amp.kr(0.0).clip(0, 0.5), 0.05);  // Faster lag for quicker response
    pan = Lag.kr(\pan.kr(0).clip(-1, 1), 0.1);
    mass = \mass.kr(1).clip(0.1, 25);
    velocity = Lag.kr(\velocity.kr(0).clip(0, 20), 0.2);
    distance = Lag.kr(\distance.kr(100).clip(2, 500), 0.1);
    width = Lag.kr(\width.kr(0.5).clip(0.01, 2.9), 0.1);
    
    // DOPPLER EFFECT (helps prevent high-frequency artifacts):
    // Radial velocity component (+ = moving away, - = moving towards)
    // In nUPIC context, we simulate this based on velocity and distance changes
    radialVelocity = Lag.kr(\radialVel.kr(velocity * 0.5).clip(-20, 20), 0.2);
    dopplerSensitivity = \dopplerSens.kr(0.5).clip(0, 3.0);  // Default to subtle effect
    
    // Anti-flicker: reduce Doppler effect when very close
    dopplerDeadZone = distance.linlin(10, 50, 0, 1).clip(0, 1);
    
    // Doppler frequency shift: creates subtle frequency modulation
    dopplerShift = 1 + (radialVelocity * dopplerSensitivity * dopplerDeadZone * 0.05);
    dopplerShift = dopplerShift.clip(0.9, 1.1);  // Subtle ±10% shift for nUPIC
    dopplerFreq = freq * dopplerShift;
    
    // SOUND GENERATION - using Doppler-shifted frequency:
    // Use regular oscillators when many synths are playing
    sig = Select.ar(K2A.ar(mass > 2), [
        // Simple mode for lighter CPU load
        VarSawOS.ar(dopplerFreq, 0, width, oversample: 2) * 0.4,
        // Full mode (using oversampled VarSaw)
        VarSawOS.ar(dopplerFreq, 0, width, oversample: 4) * 0.4
    ]);
    
    // Simplified harmonics (also using Doppler-shifted frequency)
    sig = sig + (VarSawOS.ar(dopplerFreq * 2, 0, width, oversample: 2) * mass.linlin(0.1, 5, 0, 0.1));
    
    // Simplified modulation
    sig = sig * (1 + (SinOscOS.ar(velocity * 2 + 0.1, oversample: 2) * velocity.linlin(0, 20, 0, 0.03)));
    
    // Distance affects brightness - using Doppler frequency for filter
    sig = LPF.ar(sig, dopplerFreq * distance.linlin(20, 500, 3, 1));
    
    // Apply amplitude with envelope
    sig = sig * amp * EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
    
    // Safety limiter to prevent clipping
    sig = sig.tanh * 0.7;  // Reduce overall level for many synths
    
    // Output with panning
    Out.ar(0, Pan2.ar(sig, pan));
}).add;

"✓ simpleGravObject updated with Doppler effect".postln;
"The Doppler effect will:".postln;
"  • Add subtle frequency modulation to prevent static high-frequency artifacts".postln;
"  • Create more natural, dynamic sound".postln;
"  • Reduce listener fatigue from static frequencies".postln;
"\nYou can control the effect with:".postln;
"  • \\radialVel parameter (defaults to velocity * 0.5)".postln;
"  • \\dopplerSens parameter (0=off, 0.5=subtle, 1=normal, 2=strong)".postln;
)
