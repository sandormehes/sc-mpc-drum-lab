// Kick and snare voices shared by the thick-club profile families.

(
~drumDefs[\thickClubKick] = SynthDef(\thickClubKick, {
    |out = 0, amp = 0.78, frequency = 48, decay = 0.42,
    pitchAmount = 4.5, pitchDecay = 0.035,
    punchAmount = 0.32, punchRatio = 2.15, punchDecay = 0.085,
    harmonicAmount = 0.12, clickAmount = 0.08, clickTone = 3200,
    drive = 1.8, lowBoost = 3.0, punchBoost = 2.0,
    bits = 16, sampleRateReduction = 44100, seed = 1|

    var pitchEnv, bodyEnv, punchEnv, clickEnv;
    var core, punch, harmonic, click, dry, warm, signal;

    RandSeed.ir(1, seed);
    pitchEnv = EnvGen.kr(Env(
        [frequency * pitchAmount, frequency * 1.08, frequency],
        [pitchDecay, decay * 0.55],
        curve: [-9, -4]
    ));
    bodyEnv = EnvGen.kr(
        Env.perc(0.0005, decay, 1, -6),
        doneAction: 2
    );
    punchEnv = EnvGen.kr(Env.perc(0.0003, punchDecay, 1, -7));
    clickEnv = EnvGen.kr(Env.perc(0.0001, 0.014, 1, -9));

    core = SinOsc.ar(pitchEnv) * bodyEnv;
    punch = SinOsc.ar(frequency * punchRatio) * punchEnv * punchAmount;
    harmonic = SinOsc.ar(pitchEnv * 2) * bodyEnv * harmonicAmount;
    click = BPF.ar(
        WhiteNoise.ar,
        clickTone.clip(1600, 7500),
        0.55
    ) * clickEnv * clickAmount;
    dry = core + punch + harmonic + click;
    warm = (dry * drive).tanh;
    signal = (dry * 0.42) + (warm * 0.78);
    signal = BLowShelf.ar(signal, 92, 0.7, lowBoost.clip(0, 6));
    signal = BPeakEQ.ar(
        signal,
        (frequency * punchRatio).clip(90, 180),
        0.8,
        punchBoost.clip(0, 5)
    );
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));
    signal = HPF.ar(signal, 28);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.94, 0.008);
    Out.ar(out, signal * amp);
});

~drumDefs[\thickClubKick].add;

~drumDefs[\thickClubSnare] = SynthDef(\thickClubSnare, {
    |out = 0, amp = 0.72, frequency = 185, decay = 0.24,
    bodyAmount = 0.62, noiseAmount = 0.58,
    noiseTone = 2800, noiseWidth = 0.65,
    clapAmount = 0.18, ringAmount = 0.08, ringRatio = 1.83,
    drive = 1.7, bodyBoost = 2.5, crackBoost = 1.5,
    bits = 16, sampleRateReduction = 44100, seed = 1|

    var bodyEnv, noiseEnv, transientEnv, clapEnv;
    var body, shell, noise, transient, clap, ring;
    var dry, warm, signal;

    RandSeed.ir(1, seed);
    bodyEnv = EnvGen.kr(Env.perc(0.0005, decay * 0.7, 1, -6));
    noiseEnv = EnvGen.kr(
        Env.perc(0.0005, decay, 1, -7),
        doneAction: 2
    );
    transientEnv = EnvGen.kr(Env.perc(0.0001, 0.012, 1, -9));
    clapEnv = EnvGen.kr(Env(
        [0, 1, 0, 0.8, 0, 0.55, 0],
        [0.001, 0.012, 0.010, 0.014, 0.012, 0.055],
        curve: [-4, -5, -4, -5, -4, -6]
    ));

    body = SinOsc.ar(frequency) * bodyEnv * bodyAmount;
    shell = SinOsc.ar(frequency * 1.47) * bodyEnv * bodyAmount * 0.28;
    noise = BPF.ar(
        HPF.ar(WhiteNoise.ar, 650),
        noiseTone.clip(1400, 6500),
        noiseWidth.clip(0.2, 0.95)
    ) * noiseEnv * noiseAmount;
    transient = HPF.ar(WhiteNoise.ar, 4800) * transientEnv * 0.18;
    clap = BPF.ar(WhiteNoise.ar, 1900, 0.75) * clapEnv * clapAmount;
    ring = body * SinOsc.ar(frequency * ringRatio) * ringAmount;

    dry = body + shell + noise + transient + clap + ring;
    warm = (dry * drive).tanh;
    signal = (dry * 0.48) + (warm * 0.72);
    signal = BPeakEQ.ar(signal, frequency, 0.8, bodyBoost.clip(0, 5));
    signal = BPeakEQ.ar(signal, 2400, 0.7, crackBoost.clip(0, 4));
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));
    signal = HPF.ar(signal, 55);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.94, 0.008);
    Out.ar(out, signal * amp);
});

~drumDefs[\thickClubSnare].add;
)
