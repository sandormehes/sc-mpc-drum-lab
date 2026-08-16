// SC MPC Drum Lab: Thick 2000s Dancehall / Modern Grime / Gqom profile
//
// This file registers a profile. Select it with:
//   activeProfile: \thickClub
// in config.scd, then load main.scd and run ~start.().

(
// --------------------------------------------------------------------------
// THICK KICK
// Fundamental + short upper-bass punch + controlled harmonic layer.
// No half-frequency sub: it consumes headroom below the useful MPC range.
// --------------------------------------------------------------------------

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
    punch = SinOsc.ar(frequency * punchRatio)
        * punchEnv * punchAmount;
    harmonic = SinOsc.ar(pitchEnv * 2)
        * bodyEnv * harmonicAmount;
    click = BPF.ar(
        WhiteNoise.ar,
        clickTone.clip(1600, 7500),
        0.55
    ) * clickEnv * clickAmount;

    dry = core + punch + harmonic + click;

    // Parallel saturation preserves the transient and creates density.
    warm = (dry * drive).tanh;
    signal = (dry * 0.42) + (warm * 0.78);

    // Useful weight and knock rather than inaudible sub energy.
    signal = BLowShelf.ar(signal, 92, 0.7, lowBoost.clip(0, 6));
    signal = BPeakEQ.ar(
        signal,
        (frequency * punchRatio).clip(90, 180),
        0.8,
        punchBoost.clip(0, 5)
    );

    // Optional restrained degradation; club profiles keep this mostly clean.
    signal = ~reduceDrumSampleRate.(signal, sampleRateReduction, 8000);
    signal = ~quantizeDrumSignal.(signal, bits.clip(10, 16));

    signal = HPF.ar(signal, 28);
    signal = LeakDC.ar(signal);
    signal = Limiter.ar(signal, 0.94, 0.008);

    Out.ar(out, signal * amp);
});

~drumDefs[\thickClubKick].add;


// --------------------------------------------------------------------------
// THICK SNARE / CLAP BODY
// Lower noise focus and a short tonal shell produce more weight.
// --------------------------------------------------------------------------

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
    shell = SinOsc.ar(frequency * 1.47)
        * bodyEnv * bodyAmount * 0.28;
    noise = BPF.ar(
        HPF.ar(WhiteNoise.ar, 650),
        noiseTone.clip(1400, 6500),
        noiseWidth.clip(0.2, 0.95)
    ) * noiseEnv * noiseAmount;
    transient = HPF.ar(WhiteNoise.ar, 4800)
        * transientEnv * 0.18;
    clap = BPF.ar(WhiteNoise.ar, 1900, 0.75)
        * clapEnv * clapAmount;
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


// --------------------------------------------------------------------------
// TARGETED GENERATOR FAMILIES
// --------------------------------------------------------------------------

~generatorSpecs[\dancehallKick] = (
    synth: \thickClubKick,
    prefix: "DHKICK",
    duration: 1.1,
    generator: {
        (
            amp: 0.80,
            frequency: exprand(48.0, 61.0),
            decay: rrand(0.28, 0.48),
            pitchAmount: rrand(3.2, 5.5),
            pitchDecay: rrand(0.022, 0.042),
            punchAmount: rrand(0.30, 0.48),
            punchRatio: rrand(1.85, 2.35),
            punchDecay: rrand(0.055, 0.095),
            harmonicAmount: rrand(0.08, 0.17),
            clickAmount: rrand(0.06, 0.14),
            clickTone: exprand(2200.0, 4200.0),
            drive: rrand(1.5, 2.2),
            lowBoost: rrand(2.0, 4.0),
            punchBoost: rrand(1.0, 3.0),
            bits: [14, 16].choose,
            sampleRateReduction: [32000, 44100].choose
        )
    }
);

~generatorSpecs[\grimeKick] = (
    synth: \thickClubKick,
    prefix: "GRKICK",
    duration: 1.1,
    generator: {
        (
            amp: 0.78,
            frequency: exprand(43.0, 55.0),
            decay: rrand(0.24, 0.43),
            pitchAmount: rrand(4.0, 6.8),
            pitchDecay: rrand(0.018, 0.038),
            punchAmount: rrand(0.36, 0.56),
            punchRatio: rrand(2.0, 2.8),
            punchDecay: rrand(0.045, 0.085),
            harmonicAmount: rrand(0.13, 0.24),
            clickAmount: rrand(0.08, 0.17),
            clickTone: exprand(2800.0, 5500.0),
            drive: rrand(2.0, 2.9),
            lowBoost: rrand(2.0, 4.5),
            punchBoost: rrand(2.0, 4.0),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose
        )
    }
);

~generatorSpecs[\gqomKick] = (
    synth: \thickClubKick,
    prefix: "GQKICK",
    duration: 1.4,
    generator: {
        (
            amp: 0.82,
            frequency: exprand(38.0, 49.0),
            decay: rrand(0.42, 0.72),
            pitchAmount: rrand(2.4, 4.2),
            pitchDecay: rrand(0.028, 0.060),
            punchAmount: rrand(0.22, 0.42),
            punchRatio: rrand(1.7, 2.2),
            punchDecay: rrand(0.070, 0.130),
            harmonicAmount: rrand(0.08, 0.18),
            clickAmount: rrand(0.01, 0.07),
            clickTone: exprand(1600.0, 3000.0),
            drive: rrand(1.8, 2.7),
            lowBoost: rrand(3.0, 5.5),
            punchBoost: rrand(1.0, 3.0),
            bits: [14, 16].choose,
            sampleRateReduction: [32000, 44100].choose
        )
    }
);

~generatorSpecs[\dancehallSnare] = (
    synth: \thickClubSnare,
    prefix: "DHSNARE",
    duration: 0.9,
    generator: {
        (
            amp: 0.74,
            frequency: exprand(175.0, 230.0),
            decay: rrand(0.14, 0.28),
            bodyAmount: rrand(0.55, 0.78),
            noiseAmount: rrand(0.42, 0.68),
            noiseTone: exprand(1900.0, 3800.0),
            noiseWidth: rrand(0.48, 0.82),
            clapAmount: rrand(0.08, 0.25),
            ringAmount: rrand(0.02, 0.12),
            ringRatio: rrand(1.5, 2.2),
            drive: rrand(1.4, 2.1),
            bodyBoost: rrand(1.5, 3.5),
            crackBoost: rrand(0.5, 2.5),
            bits: [14, 16].choose,
            sampleRateReduction: [32000, 44100].choose
        )
    }
);

~generatorSpecs[\grimeSnare] = (
    synth: \thickClubSnare,
    prefix: "GRSNARE",
    duration: 0.9,
    generator: {
        (
            amp: 0.72,
            frequency: exprand(145.0, 205.0),
            decay: rrand(0.16, 0.34),
            bodyAmount: rrand(0.58, 0.82),
            noiseAmount: rrand(0.48, 0.76),
            noiseTone: exprand(2200.0, 4800.0),
            noiseWidth: rrand(0.38, 0.75),
            clapAmount: rrand(0.12, 0.32),
            ringAmount: rrand(0.05, 0.18),
            ringRatio: rrand(1.7, 2.8),
            drive: rrand(1.9, 2.8),
            bodyBoost: rrand(2.0, 4.0),
            crackBoost: rrand(1.0, 3.0),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose
        )
    }
);

// Keep gqom percussion dark, low, short, and much less randomized.
~generatorSpecs[\gqomPerc] = (
    synth: \metalPerc,
    prefix: "GQPERC",
    duration: 1.2,
    generator: {
        (
            amp: 0.66,
            frequency: exprand(70.0, 190.0),
            decay: rrand(0.10, 0.38),
            exciterAmount: rrand(0.16, 0.48),
            resonance: rrand(0.14, 0.42),
            inharmonicity: rrand(0.15, 0.9),
            fmAmount: rrand(0.05, 0.55),
            foldAmount: rrand(0.0, 0.10),
            drive: rrand(1.5, 2.3),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose,
            combAmount: rrand(0.0, 0.10),
            combDecay: rrand(0.04, 0.16)
        )
    }
);

// Low tuned drums for gqom-style rolling patterns and call-and-response with
// the kick. Kept above sub range so they layer without swallowing headroom.
~generatorSpecs[\gqomTom] = (
    synth: \clubTom,
    prefix: "GQTOM",
    duration: 1.1,
    generator: {
        (
            amp: 0.72,
            frequency: exprand(78.0, 145.0),
            decay: rrand(0.25, 0.56),
            pitchAmount: rrand(1.35, 2.5),
            pitchDecay: rrand(0.018, 0.055),
            harmonicAmount: rrand(0.08, 0.28),
            skinAmount: rrand(0.04, 0.20),
            drive: rrand(1.3, 2.2),
            lowBoost: rrand(0.5, 3.0),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose
        )
    }
);

// Dry wooden side-stick and rim tones suited to sparse dancehall patterns.
~generatorSpecs[\dancehallRim] = (
    synth: \woodRim,
    prefix: "DHRIM",
    duration: 0.6,
    generator: {
        (
            amp: 0.66,
            frequency: exprand(520.0, 1050.0),
            decay: rrand(0.045, 0.14),
            tone: rrand(0.15, 0.75),
            noiseAmount: rrand(0.06, 0.24),
            drive: rrand(1.2, 2.0),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose
        )
    }
);

// Tight high-frequency timekeepers, from clean hats to slightly degraded
// grime ticks. Their short envelopes leave room for the snares and rims.
~generatorSpecs[\grimeHat] = (
    synth: \closedHat,
    prefix: "GRHAT",
    duration: 0.5,
    generator: {
        (
            amp: 0.58,
            decay: rrand(0.035, 0.13),
            metallicTone: exprand(5200.0, 9200.0),
            noiseAmount: rrand(0.45, 0.78),
            metalAmount: rrand(0.20, 0.58),
            brightness: rrand(0.25, 0.9),
            drive: rrand(1.15, 1.8),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [16000, 22050, 32000, 44100].choose
        )
    }
);

// Looser, grainy top loops and off-beat accents; intentionally longer and
// softer than the hats so both families remain useful in the same kit.
~generatorSpecs[\dancehallShaker] = (
    synth: \clubShaker,
    prefix: "DHSHAKE",
    duration: 0.8,
    generator: {
        (
            amp: 0.62,
            decay: rrand(0.14, 0.38),
            grainRate: rrand(22.0, 58.0),
            tone: exprand(4600.0, 9000.0),
            spread: rrand(0.15, 0.85),
            bodyAmount: rrand(0.06, 0.24),
            drive: rrand(1.05, 1.6),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose
        )
    }
);

~generatorSpecs[\dancehallKick].putAll((
    label: "Dancehall Kick", category: \kick,
    description: "Round low end with a short, warm upper-bass knock."
));
~generatorSpecs[\grimeKick].putAll((
    label: "Grime Kick", category: \kick,
    description: "Harder attack, stronger harmonics, and controlled grit."
));
~generatorSpecs[\gqomKick].putAll((
    label: "Gqom Kick", category: \kick,
    description: "Dark, low, and longer-bodied for sparse rolling patterns."
));
~generatorSpecs[\dancehallSnare].putAll((
    label: "Dancehall Snare", category: \snare,
    description: "Warm body with a compact clap and restrained crack."
));
~generatorSpecs[\grimeSnare].putAll((
    label: "Grime Snare", category: \snare,
    description: "Dense body, brighter crack, and a more driven finish."
));
~generatorSpecs[\gqomPerc].putAll((
    label: "Gqom Percussion", category: \percussion,
    description: "Dark, short metallic accents kept clear of the sub range."
));
~generatorSpecs[\gqomTom].putAll((
    label: "Gqom Low Tom", category: \tom,
    description: "Low tuned drum for rolling kick-and-tom conversations."
));
~generatorSpecs[\dancehallRim].putAll((
    label: "Dancehall Rim", category: \rim,
    description: "Dry wooden rim and side-stick tones."
));
~generatorSpecs[\grimeHat].putAll((
    label: "Grime Closed Hat", category: \hat,
    description: "Tight metallic ticks from clean to lightly degraded."
));
~generatorSpecs[\dancehallShaker].putAll((
    label: "Dancehall Shaker", category: \shaker,
    description: "Loose, grainy top-end movement for off-beat accents."
));

// Profile data is registered without mutating configuration or replacing the
// shared job planner. Explicit values in config.scd override these defaults.
~profiles[\thickClub] = (
    displayName: "Thick 2000s Club",
    description: "Focused dancehall, grime, and gqom drums for MPC kits.",
    defaults: (
        samplesPerEngine: 6,
        masterAmp: 0.92,
        enabledEngines: [
            \dancehallKick,
            \grimeKick,
            \gqomKick,
            \dancehallSnare,
            \grimeSnare,
            \gqomPerc,
            \gqomTom,
            \dancehallRim,
            \grimeHat,
            \dancehallShaker
        ]
    )
);

"Profile registered: Thick 2000s Club".postln;
)
