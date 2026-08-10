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

~profiles[\original] = (
    displayName: "Original Experimental",
    defaults: (
        samplesPerEngine: 12,
        masterAmp: 0.8,
        enabledEngines: [\kick, \snare, \metal, \glitch, \resonator]
    )
);

~activateProfile = { |profileName|
    var profile, defaults;

    profile = ~profiles[profileName];
    if(profile.isNil) {
        Error("Unknown profile: " ++ profileName).throw;
    };

    ~runtimeConfig = ~config.deepCopy;
    defaults = profile[\defaults];
    defaults.keysValuesDo { |key, value|
        if(~runtimeConfig[key].isNil) {
            ~runtimeConfig[key] = value.deepCopy;
        };
    };

    if(~runtimeConfig[\samplesPerEngine].isInteger.not
        or: { ~runtimeConfig[\samplesPerEngine] <= 0 }) {
        Error("samplesPerEngine must be a positive integer.").throw;
    };
    if(~runtimeConfig[\masterAmp].isNumber.not
        or: { ~runtimeConfig[\masterAmp] <= 0 }) {
        Error("masterAmp must be a positive number.").throw;
    };
    if(~runtimeConfig[\enabledEngines].isArray.not
        or: { ~runtimeConfig[\enabledEngines].isEmpty }) {
        Error("enabledEngines must be a non-empty Array.").throw;
    };
    if(~runtimeConfig[\maxConcurrentRenders].isInteger.not
        or: { ~runtimeConfig[\maxConcurrentRenders] <= 0 }) {
        Error("maxConcurrentRenders must be a positive integer.").throw;
    };

    ~runtimeConfig[\enabledEngines].do { |engineName|
        var spec;
        spec = ~generatorSpecs[engineName];
        if(spec.isNil) {
            Error("Missing generator specification: " ++ engineName).throw;
        };
        if(~drumDefs[spec[\synth]].isNil) {
            Error("Missing SynthDef: " ++ spec[\synth]).throw;
        };
    };

    ~activeProfile = profileName;
    ~activeProfileDefinition = profile;
    profile;
};

~zeroPadNumber = { |number, width = 3|
    var result;
    result = number.asInteger.asString;
    while({ result.size < width }, {
        result = "0" ++ result;
    });
    result;
};

~sampleFilename = { |prefix, index|
    var allowed, filename, prefixString;
    allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    prefixString = prefix.asString.toUpper;

    prefixString.do { |character|
        if(allowed.includes(character).not) {
            Error("Unsafe sample filename prefix: " ++ prefixString).throw;
        };
    };

    filename = prefixString
        ++ "_" ++ ~zeroPadNumber.(index, 3) ++ ".wav";
    filename;
};

~makeJobs = {
    var jobs;
    jobs = List.new;
    thisThread.randSeed = ~runtimeConfig[\randomSeed];

    ~runtimeConfig[\enabledEngines].do { |engineName|
        var spec;
        spec = ~generatorSpecs[engineName];

        ~runtimeConfig[\samplesPerEngine].do { |index|
            var parameters;
            parameters = spec[\generator].value;
            jobs.add((
                family: engineName,
                engine: spec[\synth],
                parameters: parameters,
                filename: ~sampleFilename.(spec[\prefix], index + 1),
                duration: spec[\duration]
            ));
        };
    };
    jobs.asArray;
};

~planJobs = { |engineNames|
    var jobs;
    ~activateProfile.(~config[\activeProfile]);
    jobs = ~makeJobs.();

    if(engineNames.notNil) {
        jobs = jobs.select { |job| engineNames.asArray.includes(job[\family]) };
    };
    if(jobs.isEmpty) {
        Error("No render jobs matched the requested engines.").throw;
    };
    jobs;
};

~dryRun = { |engineNames|
    var jobs;
    jobs = ~planJobs.(engineNames);
    ("Planned " ++ jobs.size ++ " renders:").postln;
    jobs.do { |job| ("  " ++ job[\filename]).postln };
    jobs;
};

~finishGenerationIfReady = {
    var state;
    state = ~generationState;

    if(state.notNil
        and: { state[\active] == 0 }
        and: {
            state[\nextIndex] >= state[\jobs].size
            or: { state[\cancelled] }
        }) {

        ~generationRunning = false;
        ~finalizeManifest.(state);
        "".postln;

        if(state[\cancelled]) {
            "Sample pack generation cancelled.".warn;
        } {
            "Sample pack generation finished.".postln;
        };
        ("Completed: " ++ state[\completed]).postln;
        ("Failed:    " ++ state[\failures].size).postln;
        ("Samples:   " ++ ~currentRunDirectory).postln;
        ("Manifest:  " ++ ~manifestPath).postln;
    };
};

~pumpJobQueue = {
    var maximumWorkers, state;
    state = ~generationState;
    maximumWorkers = ~runtimeConfig[\maxConcurrentRenders].asInteger.clip(1, 8);

    while({
        state[\cancelled].not
        and: { state[\active] < maximumWorkers }
        and: { state[\nextIndex] < state[\jobs].size }
    }, {
        var job;
        job = state[\jobs][state[\nextIndex]];
        state[\nextIndex] = state[\nextIndex] + 1;
        state[\active] = state[\active] + 1;

        ~renderSample.(
            job[\engine],
            job[\parameters],
            job[\filename],
            job[\duration],
            { |outputPath, validation, finalParameters|
                state[\active] = state[\active] - 1;
                state[\completed] = state[\completed] + 1;
                ~writeManifestEntry.(
                    job, outputPath, validation, finalParameters
                );
                (
                    "Progress: " ++ state[\completed]
                    ++ "/" ++ state[\jobs].size
                ).postln;
                ~pumpJobQueue.();
            },
            { |message|
                state[\active] = state[\active] - 1;
                state[\failures].add((job: job, error: message));
                ~writeManifestFailure.(job, message);
                ("Render failed: " ++ job[\filename] ++ " - " ++ message).warn;
                ~pumpJobQueue.();
            }
        );
    });

    ~finishGenerationIfReady.();
};

~start = { |engineNames|
    var jobs;
    if(~generationRunning == true) {
        "A generation job is already running.".warn;
    } {
        try {
            jobs = ~planJobs.(engineNames);
            ~prepareRun.(jobs);
            ~generationState = (
                jobs: jobs,
                nextIndex: 0,
                active: 0,
                completed: 0,
                failures: List.new,
                cancelled: false
            );
            ~generationRunning = true;
            ("Starting " ++ jobs.size ++ " renders with up to "
                ++ ~runtimeConfig[\maxConcurrentRenders]
                ++ " workers...").postln;
            ~pumpJobQueue.();
        } { |error|
            ~generationRunning = false;
            error.reportError;
        };
    };
};

~generateEngine = { |engineName| ~start.([engineName]) };

~cancelGeneration = {
    if(~generationRunning == true) {
        ~generationState[\cancelled] = true;
        "Cancellation requested; active renders will finish.".postln;
        ~finishGenerationIfReady.();
    } {
        "No generation job is running.".warn;
    };
};
)
