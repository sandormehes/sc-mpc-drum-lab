// Original high-pitched voices for sparse, bass-pressure rhythm design.

(
~generatorSpecs[\sonarPing] = (
    synth: \sonarPing,
    prefix: "SONAR",
    duration: 2.6,
    generator: {
        (
            amp: 0.56,
            frequency: exprand(150.0, 780.0),
            sweep: rrand(1.15, 2.9),
            decay: exprand(0.38, 1.75),
            pulseAmount: rrand(0.05, 0.55),
            shimmer: rrand(0.08, 0.68),
            echoAmount: rrand(0.03, 0.30),
            echoTime: exprand(0.045, 0.22),
            drive: rrand(1.0, 1.65),
            bits: [10, 12, 14, 16].choose,
            sampleRateReduction: [16000, 22050, 32000, 44100].choose
        )
    },
    label: "Sonar Ping",
    category: \percussion,
    description: "Falling, radar-like sine pings with controlled echo."
);

~generatorSpecs[\crystalPing] = (
    synth: \resonatorPerc,
    prefix: "CRYSTAL",
    duration: 2.8,
    generator: {
        (
            amp: 0.52,
            frequency: exprand(380.0, 2400.0),
            decay: exprand(0.28, 1.5),
            brightness: rrand(0.45, 1.0),
            resonance: rrand(0.35, 0.88),
            spread: rrand(-0.12, 0.38),
            noiseAmount: rrand(0.04, 0.26),
            foldAmount: rrand(0.0, 0.08),
            drive: rrand(1.0, 1.5),
            bits: [12, 14, 16].choose,
            sampleRateReduction: [22050, 32000, 44100].choose,
            combAmount: rrand(0.03, 0.22)
        )
    },
    label: "Crystal Ping",
    category: \percussion,
    description: "High, glassy resonator strikes with a clean ringing tail."
);

~generatorSpecs[\packetPing] = (
    synth: \glitchPerc,
    prefix: "PACKET",
    duration: 1.1,
    generator: {
        (
            amp: 0.48,
            frequency: exprand(260.0, 1800.0),
            decay: exprand(0.045, 0.22),
            pulseWidth: rrand(0.12, 0.68),
            chaosAmount: rrand(0.02, 0.28),
            noiseAmount: rrand(0.0, 0.16),
            ringRatio: rrand(1.25, 3.8),
            foldAmount: rrand(0.02, 0.28),
            drive: rrand(1.05, 2.1),
            bits: [6, 8, 10, 12].choose,
            sampleRateReduction: [6000, 8000, 12000, 16000].choose,
            combAmount: rrand(0.02, 0.18),
            combTime: exprand(0.001, 0.008),
            combDecay: rrand(0.03, 0.14)
        )
    },
    label: "Packet Ping",
    category: \percussion,
    description: "Short, clipped digital pings for syncopated detail."
);

~profiles[\ping] = (
    displayName: "Ping",
    description: "Original sonar, crystalline, and digital ping percussion.",
    defaults: (
        samplesPerEngine: 5,
        masterAmp: 0.84,
        enabledEngines: [\sonarPing, \crystalPing, \packetPing]
    )
);
)
