// Focused percussion voices for the thickClub profile. Each voice occupies a
// different register and role so a generated pack can build a full rhythm,
// rather than only supplying alternate backbeats.

(
~drumDefs[\clubTom] = SynthDef(\clubTom, {
    |out = 0, amp = 0.72, frequency = 105, decay = 0.42,
    pitchAmount = 1.9, pitchDecay = 0.035,
    harmonicAmount = 0.18, skinAmount = 0.12,
    drive = 1.6, lowBoost = 2.0,
    bits = 16, sampleRateReduction = 44100, seed = 1|

    var pitchEnv, bodyEnv, skinEnv;
    var body, harmonic, skin, dry, warm, signal;

    RandSeed.ir(1, seed);

    pitchEnv = EnvGen.kr(Env(
        [frequency * pitchAmount, frequency * 1.05, frequency],
        [pitchDecay, decay * 0.65],
        curve: [-10, -5]
    ));
    bodyEnv = EnvGen.kr(
        Env.perc(0.0008, decay, 1, -6),
        doneAction: 2
    );
    skinEnv = EnvGen.kr(Env.perc(0.0001, 0.025, 1, -8));

    body = SinOsc.ar(pitchEnv) * bodyEnv;
    harmonic = SinOsc.ar(pitchEnv * 1.52)
        * bodyEnv * harmonicAmount;
    skin = BPF.ar(
        WhiteNoise.ar,
        (frequency * 9).clip(700, 2600),
        0.65
    ) * skinEnv * skinAmount;

    dry = body + harmonic + skin;
    warm = (dry * drive).tanh;
    signal = (dry * 0.5) + (warm * 0.68);
    signal = BLowShelf.ar(signal, 130, 0.8, lowBoost.clip(0, 5));
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));
    signal = HPF.ar(signal, 35);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.94, 0.006);

    Out.ar(out, signal * amp);
});

~drumDefs[\clubTom].add;


~drumDefs[\woodRim] = SynthDef(\woodRim, {
    |out = 0, amp = 0.66, frequency = 720, decay = 0.10,
    tone = 0.45, noiseAmount = 0.16,
    drive = 1.5, bits = 16, sampleRateReduction = 44100, seed = 1|

    var lifeEnv, noiseEnv, exciter, resonators, knock, signal;

    RandSeed.ir(1, seed);

    lifeEnv = EnvGen.kr(
        Env.perc(0.0001, decay * 1.35, 1, -8),
        doneAction: 2
    );
    noiseEnv = EnvGen.kr(Env.perc(0.0001, 0.008, 1, -10));
    exciter = Impulse.ar(0) + (WhiteNoise.ar * noiseEnv * noiseAmount);

    resonators = Mix.ar(Ringz.ar(
        exciter,
        frequency * [1, 1.47, 2.09, 3.37],
        decay * [1, 0.72, 0.48, 0.25]
    ) * [1, 0.62, 0.32, tone * 0.2]);
    knock = BPF.ar(
        WhiteNoise.ar,
        (frequency * 0.72).clip(300, 1200),
        0.45
    ) * noiseEnv * 0.18;

    signal = ((resonators * 0.28) + knock) * lifeEnv;
    signal = (signal * drive).tanh;
    signal = BPeakEQ.ar(signal, frequency.clip(450, 1300), 0.8, 2.0);
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));
    signal = HPF.ar(signal, 140);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.94, 0.004);

    Out.ar(out, signal * amp);
});

~drumDefs[\woodRim].add;


~drumDefs[\closedHat] = SynthDef(\closedHat, {
    |out = 0, amp = 0.58, decay = 0.075,
    metallicTone = 6100, noiseAmount = 0.62,
    metalAmount = 0.38, brightness = 0.55,
    drive = 1.35, bits = 16, sampleRateReduction = 44100, seed = 1|

    var ampEnv, clickEnv, noise, metal, signal;

    RandSeed.ir(1, seed);

    ampEnv = EnvGen.kr(
        Env.perc(0.0001, decay, 1, -11),
        doneAction: 2
    );
    clickEnv = EnvGen.kr(Env.perc(0.0001, 0.007, 1, -12));

    noise = BPF.ar(
        HPF.ar(WhiteNoise.ar, 4200),
        metallicTone.clip(4800, 11000),
        (0.45 + (brightness * 0.4)).clip(0.4, 0.9)
    ) * noiseAmount;
    metal = Mix.ar(Pulse.ar(
        metallicTone * [0.71, 0.93, 1.19, 1.54],
        [0.38, 0.47, 0.53, 0.61]
    )) * 0.08 * metalAmount;

    signal = ((noise + metal) * ampEnv)
        + (HPF.ar(WhiteNoise.ar, 8500) * clickEnv * 0.12);
    signal = (signal * drive).tanh;
    signal = BHiShelf.ar(
        signal, 7200, 0.7, brightness.linlin(0, 1, -2, 3)
    );
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));
    signal = HPF.ar(signal, 3000);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.92, 0.003);

    Out.ar(out, signal * amp);
});

~drumDefs[\closedHat].add;


~drumDefs[\clubShaker] = SynthDef(\clubShaker, {
    |out = 0, amp = 0.62, decay = 0.24,
    grainRate = 34, tone = 6900, spread = 0.45,
    bodyAmount = 0.16, drive = 1.25,
    bits = 16, sampleRateReduction = 44100, seed = 1|

    var ampEnv, transientEnv, grainEnvelope;
    var grains, body, signal;

    RandSeed.ir(1, seed);

    ampEnv = EnvGen.kr(
        Env.perc(0.001, decay, 1, -5),
        doneAction: 2
    );
    transientEnv = EnvGen.kr(Env.perc(0.0001, 0.012, 1, -9));
    grainEnvelope = Decay2.ar(
        Dust2.ar(grainRate.clip(12, 90)),
        0.0003,
        (0.012 + (spread * 0.035)).clip(0.01, 0.05)
    );

    grains = BPF.ar(
        WhiteNoise.ar * grainEnvelope,
        tone.clip(3500, 10500),
        (0.28 + (spread * 0.5)).clip(0.25, 0.8)
    );
    body = BPF.ar(WhiteNoise.ar, 2400, 0.8)
        * transientEnv * bodyAmount;

    signal = ((grains * 2.2) + (body * 1.35)) * ampEnv;
    signal = (signal * drive).tanh;
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));
    signal = HPF.ar(signal, 1000);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.92, 0.004);

    Out.ar(out, signal * amp);
});

~drumDefs[\clubShaker].add;
)
