// Hand-edited sounds. Change only the values inside "parameters".

(
~presets[\deepKick] = (
    engine: \experimentalKick,
    filename: "DEEP_KICK.wav",
    duration: 1.7,
    parameters: (
        amp: 0.72, frequency: 43, decay: 0.75,
        pitchAmount: 6.5, pitchBounce: 0.18,
        clickAmount: 0.08, clickTone: 6000,
        fmAmount: 0.3, fmRatio: 1.618,
        foldAmount: 0.12, drive: 2.0, bits: 12,
        sampleRateReduction: 18000,
        combAmount: 0.08, combTime: 0.006, combDecay: 0.15
    )
);

~presets[\industrialSnare] = (
    engine: \experimentalSnare,
    filename: "IND_SNARE.wav",
    duration: 1.5,
    parameters: (
        amp: 0.68, frequency: 145, decay: 0.42,
        bodyAmount: 0.5, noiseAmount: 0.9,
        noiseTone: 2400, noiseWidth: 0.7,
        fmAmount: 0.65, fmRatio: 1.73,
        ringAmount: 0.32, ringRatio: 3.17,
        foldAmount: 0.25, drive: 2.7, bits: 8,
        sampleRateReduction: 8500,
        combAmount: 0.2, combTime: 0.0043, combDecay: 0.15
    )
);

~presets[\metalObject] = (
    engine: \metalPerc,
    filename: "METAL_OBJECT.wav",
    duration: 2.2,
    parameters: (
        amp: 0.62, frequency: 187, decay: 0.9,
        exciterAmount: 0.7, resonance: 0.55,
        inharmonicity: 1.8, fmAmount: 0.9,
        foldAmount: 0.18, drive: 2.1, bits: 10,
        sampleRateReduction: 12000,
        combAmount: 0.3, combDecay: 0.35
    )
);

~presets[\extremeGlitch] = (
    engine: \glitchPerc,
    filename: "EXT_GLITCH.wav",
    duration: 1.0,
    parameters: (
        amp: 0.56, frequency: 270, decay: 0.18,
        pulseWidth: 0.21, chaosAmount: 0.7,
        noiseAmount: 0.3, ringRatio: 4.71,
        foldAmount: 0.72, drive: 4.2, bits: 4,
        sampleRateReduction: 1800,
        combAmount: 0.32, combTime: 0.0029, combDecay: 0.18
    )
);

~renderSound = {
    |sound, filename|
    var job, outputName;
    if(~generationRunning == true) {
        "A generation job is already running.".warn;
    } {
        try {
            outputName = filename ? sound[\filename];
            if(outputName.find("/").notNil
                or: { outputName.find("\\").notNil }) {
                Error("Preset filename must not contain a directory path.").throw;
            };

            ~activateProfile.(~config[\activeProfile]);
            job = (
                family: \preset,
                engine: sound[\engine],
                parameters: sound[\parameters],
                filename: outputName,
                duration: sound[\duration]
            );
            ~prepareRun.([job]);
            ~generationRunning = true;

            ~renderSample.(
            job[\engine], job[\parameters], job[\filename], job[\duration],
            { |outputPath, validation, finalParameters|
                var state;
                state = (
                    completed: 1, failures: List.new, cancelled: false
                );
                ~writeManifestEntry.(
                    job, outputPath, validation, finalParameters
                );
                ~finalizeManifest.(state);
                ~generationRunning = false;
                ("Preset written to: " ++ outputPath).postln;
            },
            { |message|
                var failures, state;
                failures = List.new;
                failures.add((job: job, error: message));
                state = (
                    completed: 0, failures: failures, cancelled: false
                );
                ~writeManifestFailure.(job, message);
                ~finalizeManifest.(state);
                ~generationRunning = false;
                ("Preset render failed: " ++ message).warn;
            }
            );
        } { |error|
            ~generationRunning = false;
            error.reportError;
        };
    };
};

~renderPreset = { |presetName, filename|
    var preset;
    preset = ~presets[presetName];
    if(preset.isNil) {
        Error("Unknown preset: " ++ presetName).throw;
    };
    ~renderSound.(preset, filename);
};

~presetVariation = {
    |presetName, changes|
    var preset;
    preset = ~presets[presetName].deepCopy;
    if(preset.isNil) {
        Error("Unknown preset: " ++ presetName).throw;
    };
    changes.keysValuesDo { |key, value|
        preset[\parameters][key] = value;
    };
    preset;
};
)
