(
~drumDefs[\resonatorPerc] = SynthDef(\resonatorPerc, {
    |out = 0, amp = 0.65, frequency = 130, decay = 0.8,
    brightness = 0.6, resonance = 0.6, spread = 0.2,
    noiseAmount = 0.35, foldAmount = 0.04, drive = 1.2,
    bits = 14, sampleRateReduction = 32000, combAmount = 0.08, seed = 1|

    var ampEnv, exciterEnv, exciter, resonators;
    var highLayer, comb, signal;

    RandSeed.ir(1, seed);

    ampEnv = EnvGen.kr(
        Env.perc(0.0005, decay, 1, -4),
        doneAction: 2
    );
    exciterEnv = EnvGen.kr(Env.perc(0.0001, 0.045, 1, -8));
    exciter = ((PinkNoise.ar * noiseAmount) + Impulse.ar(0)) * exciterEnv;

    resonators = Mix.ar([
        Ringz.ar(exciter, frequency, resonance),
        Ringz.ar(exciter, frequency * (1.5 + spread), resonance * 0.85),
        Ringz.ar(exciter,
            frequency * (2.02 + (spread * 0.5)), resonance * 0.7),
        Ringz.ar(exciter,
            frequency * (2.91 + (spread * 0.8)), resonance * 0.55),
        Ringz.ar(exciter,
            frequency * (4.17 + spread),
            resonance * brightness * 0.4)
    ]);

    highLayer = BPF.ar(
        WhiteNoise.ar,
        frequency * (8 + (brightness * 12)),
        0.3
    ) * exciterEnv * brightness * 0.2;

    signal = (resonators + highLayer) * ampEnv;
    comb = CombC.ar(
        signal,
        0.08,
        (1 / (frequency * (1.7 + spread))).clip(0.0005, 0.08),
        decay * 0.5
    );
    signal = signal + (comb * combAmount);
    signal = ~processDrumSignal.(
        signal, foldAmount, 10, drive, bits, sampleRateReduction, 25
    );

    Out.ar(out, signal * amp);
});

~drumDefs[\resonatorPerc].add;
)
