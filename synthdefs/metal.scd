(
~drumDefs[\metalPerc] = SynthDef(\metalPerc, {
    |out = 0, amp = 0.65, frequency = 210, decay = 0.5,
    exciterAmount = 0.4, resonance = 0.35, inharmonicity = 1,
    fmAmount = 0.4, foldAmount = 0.08, drive = 1.4, bits = 12,
    sampleRateReduction = 18000, combAmount = 0.15,
    combDecay = 0.2|

    var ampEnv, exciterEnv, exciter, resonators;
    var fmLayer, comb, signal;

    ampEnv = EnvGen.kr(
        Env.perc(0.0005, decay, 1, -5),
        doneAction: 2
    );
    exciterEnv = EnvGen.kr(Env.perc(0.0001, 0.03, 1, -8));
    exciter = Impulse.ar(0) + (WhiteNoise.ar * exciterEnv * exciterAmount);

    resonators = Mix.ar([
        Ringz.ar(exciter, frequency, resonance),
        Ringz.ar(exciter,
            frequency * (1.417 + (inharmonicity * 0.07)),
            resonance * 0.8),
        Ringz.ar(exciter,
            frequency * (2.113 + (inharmonicity * 0.13)),
            resonance * 0.65),
        Ringz.ar(exciter,
            frequency * (3.731 + (inharmonicity * 0.19)),
            resonance * 0.45),
        Ringz.ar(exciter,
            frequency * (5.179 + (inharmonicity * 0.23)),
            resonance * 0.3)
    ]);

    fmLayer = SinOsc.ar(
        frequency + SinOsc.ar(frequency * 1.618, 0, frequency * fmAmount)
    ) * ampEnv * 0.25;

    signal = (resonators + fmLayer) * ampEnv;
    comb = Mix.ar([
        CombC.ar(signal, 0.05,
            (1 / (frequency * 1.37)).clip(0.0005, 0.05),
            combDecay),
        CombC.ar(signal, 0.05,
            (1 / (frequency * 2.11)).clip(0.0005, 0.05),
            combDecay * 0.7)
    ]);
    signal = signal + (comb * combAmount);
    signal = ~processDrumSignal.(
        signal, foldAmount, 12, drive, bits, sampleRateReduction, 25
    );

    Out.ar(out, signal * amp);
});

~drumDefs[\metalPerc].add;
)
