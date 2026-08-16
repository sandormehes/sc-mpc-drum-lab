(
~drumDefs[\glitchPerc] = SynthDef(\glitchPerc, {
    |out = 0, amp = 0.6, frequency = 180, decay = 0.22,
    pulseWidth = 0.35, chaosAmount = 0.4, noiseAmount = 0.25,
    ringRatio = 2.51, foldAmount = 0.25, drive = 1.8, bits = 7,
    sampleRateReduction = 7000, combAmount = 0.12,
    combTime = 0.0047, combDecay = 0.12, seed = 1|

    var ampEnv, transientEnv, pitchEnv;
    var pulse, sine, noise, chaos, ring, comb, signal;

    RandSeed.ir(1, seed);

    ampEnv = EnvGen.kr(
        Env.perc(0.0001, decay, 1, -7),
        doneAction: 2
    );
    transientEnv = EnvGen.kr(Env.perc(0.0001, 0.025, 1, -9));
    pitchEnv = EnvGen.kr(Env(
        [frequency * 6, frequency * 0.5, frequency * 1.7, frequency],
        [0.003, 0.015, decay],
        curve: [-12, 8, -5]
    ));

    pulse = Pulse.ar(pitchEnv, pulseWidth.clip(0.05, 0.95));
    sine = SinOsc.ar(pitchEnv * 0.5);
    chaos = LFNoise2.ar(pitchEnv.clip(30, 12000)) * chaosAmount;
    noise = HPF.ar(WhiteNoise.ar, 2000) * transientEnv * noiseAmount;
    ring = pulse * SinOsc.ar(pitchEnv * ringRatio);

    signal = (
        (pulse * 0.35) + (sine * 0.25)
        + (ring * 0.35) + (chaos * 0.2)
    ) * ampEnv + noise;

    comb = CombC.ar(
        signal, 0.05, combTime.clip(0.0005, 0.05), combDecay
    );
    signal = signal + (comb * combAmount);
    signal = ~processDrumSignal.(
        signal, foldAmount, 14, drive, bits, sampleRateReduction, 25
    );

    Out.ar(out, signal * amp);
});

~drumDefs[\glitchPerc].add;
)
