(
~drumDefs[\experimentalSnare] = SynthDef(\experimentalSnare, {
    |out = 0, amp = 0.7, frequency = 175, decay = 0.32,
    bodyAmount = 0.45, noiseAmount = 0.75, noiseTone = 3200,
    noiseWidth = 0.7, fmAmount = 0.2, fmRatio = 1.73,
    ringAmount = 0.15, ringRatio = 2.37, foldAmount = 0.05,
    drive = 1.3, bits = 14, sampleRateReduction = 30000,
    combAmount = 0.08, combTime = 0.0065, combDecay = 0.1, seed = 1|

    var bodyEnv, noiseEnv, transientEnv, pitchEnv, fm;
    var body, noise, transient, ring, comb, signal;

    RandSeed.ir(1, seed);

    bodyEnv = EnvGen.kr(Env.perc(0.0005, decay * 0.65, 1, -5));
    noiseEnv = EnvGen.kr(
        Env.perc(0.0005, decay, 1, -6),
        doneAction: 2
    );
    transientEnv = EnvGen.kr(Env.perc(0.0001, 0.012, 1, -8));
    pitchEnv = EnvGen.kr(Env(
        [frequency * 2.2, frequency * 0.9, frequency],
        [0.012, decay * 0.3],
        curve: [-9, -4]
    ));

    fm = SinOsc.ar(pitchEnv * fmRatio, 0, pitchEnv * fmAmount);
    body = (
        SinOsc.ar(pitchEnv + fm)
        + (SinOsc.ar(pitchEnv * 1.51) * 0.25)
    ) * bodyEnv * bodyAmount;

    noise = BPF.ar(
        HPF.ar(WhiteNoise.ar, 700),
        noiseTone.clip(800, 12000),
        noiseWidth.clip(0.05, 1)
    ) * noiseEnv * noiseAmount;

    transient = HPF.ar(WhiteNoise.ar, 6000) * transientEnv * 0.25;
    ring = body * SinOsc.ar(pitchEnv * ringRatio) * ringAmount;
    signal = body + noise + transient + ring;
    comb = CombC.ar(
        signal, 0.05, combTime.clip(0.0005, 0.05), combDecay
    );
    signal = signal + (comb * combAmount);
    signal = ~processDrumSignal.(
        signal, foldAmount, 10, drive, bits, sampleRateReduction, 30
    );

    Out.ar(out, signal * amp);
});

~drumDefs[\experimentalSnare].add;
)
