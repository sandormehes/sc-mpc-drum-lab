// Pitched, radar-like electronic pings for sparse rhythmic roles.

(
~drumDefs[\sonarPing] = SynthDef(\sonarPing, {
    |out = 0, amp = 0.58, frequency = 320, sweep = 1.8, decay = 1.1,
    pulseAmount = 0.35, shimmer = 0.28, echoAmount = 0.16,
    echoTime = 0.14, drive = 1.15, bits = 16,
    sampleRateReduction = 44100, seed = 1|

    var ampEnv, pitchEnv, carrier, ping, echo, signal;

    RandSeed.ir(1, seed);
    ampEnv = EnvGen.kr(Env.perc(0.001, decay, 1, -5), doneAction: 2);
    pitchEnv = EnvGen.kr(Env([
        frequency * sweep.clip(1, 4), frequency
    ], [(decay * 0.12).clip(0.008, 0.14)], -7));
    carrier = SinOsc.ar(pitchEnv)
        + (SinOsc.ar(pitchEnv * 2.01) * shimmer * 0.35)
        + (SinOsc.ar(pitchEnv * 3.97) * shimmer * 0.12);
    ping = carrier + (Pulse.ar(pitchEnv * 0.5, 0.45) * pulseAmount * 0.18);
    signal = ping * ampEnv;
    echo = CombC.ar(signal, 0.3, echoTime.clip(0.015, 0.3), decay * 0.6);
    signal = signal + (echo * echoAmount);
    signal = ~processDrumSignal.(
        signal, 0, 12, drive, bits, sampleRateReduction, 25
    );

    Out.ar(out, signal * amp);
});

~drumDefs[\sonarPing].add;
)
