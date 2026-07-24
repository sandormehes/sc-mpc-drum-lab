// Random ranges live here. Edit these Events to shape the generated pack.

(
~generatorSpecs[\kick] = (
    synth: \experimentalKick,
    prefix: "XKICK",
    duration: 1.5,
    generator: {
        (
            amp: 0.72,
            frequency: exprand(38.0, 72.0),
            decay: exprand(0.22, 0.9),
            pitchAmount: rrand(2.5, 9.0),
            pitchBounce: rrand(0.0, 0.45),
            clickAmount: rrand(0.02, 0.35),
            clickTone: exprand(3000.0, 11000.0),
            fmAmount: rrand(0.0, 0.8),
            fmRatio: rrand(1.2, 2.7),
            foldAmount: rrand(0.0, 0.3),
            drive: rrand(1.0, 3.2),
            bits: [5, 6, 7, 8, 9, 10, 12, 14, 16].choose,
            sampleRateReduction: exprand(4000.0, 44100.0),
            combAmount: rrand(0.0, 0.2),
            combTime: exprand(0.0015, 0.015),
            combDecay: rrand(0.04, 0.3)
        )
    }
);

~generatorSpecs[\snare] = (
    synth: \experimentalSnare,
    prefix: "XSNARE",
    duration: 1.4,
    generator: {
        (
            amp: 0.68,
            frequency: exprand(110.0, 270.0),
            decay: exprand(0.12, 0.65),
            bodyAmount: rrand(0.15, 0.75),
            noiseAmount: rrand(0.35, 1.0),
            noiseTone: exprand(1500.0, 9000.0),
            noiseWidth: rrand(0.15, 0.95),
            fmAmount: rrand(0.0, 1.2),
            fmRatio: rrand(1.1, 3.2),
            ringAmount: rrand(0.0, 0.5),
            ringRatio: rrand(1.3, 4.5),
            foldAmount: rrand(0.0, 0.35),
            drive: rrand(1.0, 3.5),
            bits: [5, 6, 7, 8, 9, 10, 12, 14, 16].choose,
            sampleRateReduction: exprand(3500.0, 44100.0),
            combAmount: rrand(0.0, 0.3),
            combTime: exprand(0.001, 0.014),
            combDecay: rrand(0.04, 0.28)
        )
    }
);

~generatorSpecs[\metal] = (
    synth: \metalPerc,
    prefix: "METAL",
    duration: 2.0,
    generator: {
        (
            amp: 0.62,
            frequency: exprand(65.0, 650.0),
            decay: exprand(0.12, 1.2),
            exciterAmount: rrand(0.1, 0.9),
            resonance: rrand(0.08, 0.8),
            inharmonicity: rrand(0.0, 2.5),
            fmAmount: rrand(0.0, 2.0),
            foldAmount: rrand(0.0, 0.4),
            drive: rrand(1.0, 3.0),
            bits: [5, 6, 7, 8, 9, 10, 12, 14, 16].choose,
            sampleRateReduction: exprand(2500.0, 44100.0),
            combAmount: rrand(0.0, 0.4),
            combDecay: rrand(0.05, 0.55)
        )
    }
);

~generatorSpecs[\glitch] = (
    synth: \glitchPerc,
    prefix: "GLITCH",
    duration: 1.2,
    generator: {
        (
            amp: 0.58,
            frequency: exprand(50.0, 800.0),
            decay: exprand(0.04, 0.55),
            pulseWidth: rrand(0.08, 0.92),
            chaosAmount: rrand(0.0, 0.9),
            noiseAmount: rrand(0.0, 0.7),
            ringRatio: rrand(1.1, 6.0),
            foldAmount: rrand(0.05, 0.8),
            drive: rrand(1.1, 4.5),
            bits: rrand(3, 10),
            sampleRateReduction: exprand(700.0, 16000.0),
            combAmount: rrand(0.0, 0.4),
            combTime: exprand(0.0008, 0.018),
            combDecay: rrand(0.02, 0.35)
        )
    }
);

~generatorSpecs[\resonator] = (
    synth: \resonatorPerc,
    prefix: "RESON",
    duration: 2.5,
    generator: {
        (
            amp: 0.62,
            frequency: exprand(55.0, 520.0),
            decay: exprand(0.2, 1.8),
            brightness: rrand(0.05, 1.0),
            resonance: rrand(0.08, 0.9),
            spread: rrand(-0.2, 0.8),
            noiseAmount: rrand(0.05, 0.8),
            foldAmount: rrand(0.0, 0.25),
            drive: rrand(1.0, 2.8),
            bits: [5, 6, 7, 8, 9, 10, 12, 14, 16].choose,
            sampleRateReduction: exprand(4000.0, 44100.0),
            combAmount: rrand(0.0, 0.35)
        )
    }
);

~makeJobs = {
    var jobs;
    jobs = List.new;
    thisThread.randSeed = ~config[\randomSeed];

    ~config[\enabledEngines].do { |engineName|
        var spec;
        spec = ~generatorSpecs[engineName];
        if(spec.isNil) {
            Error("Missing generator specification: " ++ engineName).throw;
        };

        ~config[\samplesPerEngine].do { |index|
            var parameters, filename;
            parameters = spec[\generator].value;
            filename = spec[\prefix]
                ++ "_" ++ "%03d".format(index + 1) ++ ".wav";
            jobs.add((
                engine: spec[\synth],
                parameters: parameters,
                filename: filename,
                duration: spec[\duration]
            ));
        };
    };
    jobs.asArray;
};

~runJobQueue = {
    |jobs, index = 0|
    if(index >= jobs.size) {
        ~generationRunning = false;
        "".postln;
        "Sample pack generation finished.".postln;
        ("Samples:  " ++ ~config[\outputDirectory]).postln;
        ("Manifest: " ++ ~manifestPath).postln;
    } {
        var job;
        job = jobs[index];
        ~writeManifestEntry.(
            job[\filename],
            job[\engine],
            job[\parameters]
        );
        ~renderSample.(
            job[\engine],
            job[\parameters],
            job[\filename],
            job[\duration],
            {
                ~runJobQueue.(jobs, index + 1);
            }
        );
    };
};

~start = {
    var jobs;
    if(~generationRunning == true) {
        "A generation job is already running.".warn;
    } {
        ~generationRunning = true;
        ~resetManifest.();
        jobs = ~makeJobs.();
        ("Starting " ++ jobs.size ++ " renders...").postln;
        ~runJobQueue.(jobs);
    };
};
)
