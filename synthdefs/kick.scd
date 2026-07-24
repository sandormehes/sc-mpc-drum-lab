(
~drumDefs[\experimentalKick] = SynthDef(\experimentalKick, {
    |out = 0, amp = 0.75, frequency = 48, decay = 0.55,
    pitchAmount = 5, pitchBounce = 0.15, clickAmount = 0.12,
    clickTone = 6500, fmAmount = 0.15, fmRatio = 1.618,
    foldAmount = 0.05, drive = 1.4, bits = 16,
    sampleRateReduction = 44100, combAmount = 0,
    combTime = 0.008, combDecay = 0.12|

    var pitchEnv, ampEnv, clickEnv, freq, fm;
    var body, sub, click, comb, signal;

    pitchEnv = EnvGen.kr(Env(
        [frequency * pitchAmount, frequency * 0.82,
            frequency * (1 + pitchBounce), frequency],
        [0.006, 0.025, decay],
        curves: [-10, 5, -5]
    ));

    ampEnv = EnvGen.kr(
        Env.perc(0.0005, decay, 1, -6),
        doneAction: 2
    );
    clickEnv = EnvGen.kr(Env.perc(0.0001, 0.018, 1, -8));
    freq = pitchEnv.max(20);
    fm = SinOsc.ar(freq * fmRatio, 0, freq * fmAmount);

    body = SinOsc.ar(freq + fm);
    sub = SinOsc.ar(freq * 0.5) * 0.3;
    click = HPF.ar(WhiteNoise.ar, clickTone) * clickEnv * clickAmount;
    signal = ((body + sub) * ampEnv) + click;

    comb = CombC.ar(
        signal, 0.05, combTime.clip(0.0005, 0.05), combDecay
    );
    signal = signal + (comb * combAmount);
    signal = ~processDrumSignal.(
        signal, foldAmount, 8, drive, bits, sampleRateReduction, 20
    );

    Out.ar(out, signal * amp);
});

~drumDefs[\experimentalKick].add;
)
