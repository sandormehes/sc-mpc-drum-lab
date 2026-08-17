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

// Human-facing metadata is deliberately kept beside the sound generators so
// the command API, GUI, and documentation all describe the same engines.
~generatorSpecs[\kick].putAll((
    label: "Experimental Kick", category: \kick,
    description: "Wide-ranging synthesized kick with FM, fold, and comb color."
));
~generatorSpecs[\snare].putAll((
    label: "Experimental Snare", category: \snare,
    description: "Tonal and noisy snare spanning clean hits to digital grit."
));
~generatorSpecs[\metal].putAll((
    label: "Metal Percussion", category: \percussion,
    description: "Inharmonic struck-metal and industrial percussion."
));
~generatorSpecs[\glitch].putAll((
    label: "Glitch Percussion", category: \percussion,
    description: "Short chaotic, folded, deliberately low-resolution hits."
));
~generatorSpecs[\resonator].putAll((
    label: "Resonator", category: \percussion,
    description: "Pitched resonant impacts with bright, ringing tails."
));

~profiles[\original] = (
    displayName: "Original Experimental",
    description: "Broad synthetic drums, metals, glitches, and resonators.",
    defaults: (
        samplesPerEngine: 12,
        masterAmp: 0.8,
        enabledEngines: [\kick, \snare, \metal, \glitch, \resonator]
    )
);

~generationListeners = List.new;

~addGenerationListener = { |listener|
    ~generationListeners.add(listener);
    listener;
};

~removeGenerationListener = { |listener|
    ~generationListeners.remove(listener);
    listener;
};

~notifyGeneration = { |event, data|
    data = data ? ();
    ~generationListeners.copy.do { |listener|
        try {
            listener.value(event, data);
        } { |error|
            ("Generation listener failed: " ++ error.errorString).warn;
        };
    };
};

~validateRuntimeConfig = { |runtimeConfig|
    if(runtimeConfig[\samplesPerEngine].isInteger.not
        or: { runtimeConfig[\samplesPerEngine] <= 0 }) {
        Error("samplesPerEngine must be a positive integer.").throw;
    };
    if(runtimeConfig[\randomSeed].isInteger.not) {
        Error("randomSeed must be an integer.").throw;
    };
    if(runtimeConfig[\masterAmp].isNumber.not
        or: { runtimeConfig[\masterAmp] <= 0 }) {
        Error("masterAmp must be a positive number.").throw;
    };
    if(runtimeConfig[\enabledEngines].isArray.not
        or: { runtimeConfig[\enabledEngines].isEmpty }) {
        Error("enabledEngines must be a non-empty Array.").throw;
    };
    if(runtimeConfig[\maxConcurrentRenders].isInteger.not
        or: { runtimeConfig[\maxConcurrentRenders] <= 0 }) {
        Error("maxConcurrentRenders must be a positive integer.").throw;
    };
    if(runtimeConfig[\sampleRate].isNumber.not
        or: { runtimeConfig[\sampleRate] <= 0 }) {
        Error("sampleRate must be a positive number.").throw;
    };
    if(runtimeConfig[\outputDirectory].isKindOf(String).not) {
        Error("outputDirectory must be a path String.").throw;
    };

    if(runtimeConfig[\engineCounts].notNil
        and: { runtimeConfig[\engineCounts].isKindOf(Dictionary).not }) {
        Error("engineCounts must be an Event or Dictionary.").throw;
    };
    if(runtimeConfig[\macros].notNil
        and: { runtimeConfig[\macros].isKindOf(Dictionary).not }) {
        Error("macros must be an Event or Dictionary.").throw;
    };
    if(runtimeConfig[\macros].notNil) {
        runtimeConfig[\macros].keysValuesDo { |name, value|
            name = name.asString.asSymbol;
            if([\weight, \punch, \brightness, \tail, \dirt]
                .includes(name).not
                or: { value.isNumber.not }
                or: { value < 0 or: { value > 1 } }) {
                Error("Invalid musical macro: " ++ name).throw;
            };
        };
    };

    runtimeConfig[\enabledEngines].do { |engineName|
        var count, spec;
        spec = ~generatorSpecs[engineName];
        if(spec.isNil) {
            Error("Missing generator specification: " ++ engineName).throw;
        };
        if(~drumDefs[spec[\synth]].isNil) {
            Error("Missing SynthDef: " ++ spec[\synth]).throw;
        };
        count = if(runtimeConfig[\engineCounts].notNil) {
            runtimeConfig[\engineCounts][engineName]
        };
        if(count.notNil and: { count.isInteger.not or: { count <= 0 } }) {
            Error(
                "engineCounts[" ++ engineName ++ "] must be a positive integer."
            ).throw;
        };
    };
    runtimeConfig;
};

~resolveProfileContext = { |profileName, overrides|
    var defaults, profile, runtimeConfig;

    profile = ~profiles[profileName];
    if(profile.isNil) {
        Error("Unknown profile: " ++ profileName).throw;
    };

    runtimeConfig = ~config.deepCopy;
    defaults = profile[\defaults];
    defaults.keysValuesDo { |key, value|
        if(runtimeConfig[key].isNil) {
            runtimeConfig[key] = value.deepCopy;
        };
    };

    if(overrides.notNil) {
        overrides.keysValuesDo { |key, value|
            if(key != \activeProfile) {
                runtimeConfig[key] = value.deepCopy;
            };
        };
    };
    runtimeConfig[\activeProfile] = profileName;
    ~validateRuntimeConfig.(runtimeConfig);
    (
        profileName: profileName,
        profileDefinition: profile,
        config: runtimeConfig
    );
};

~activateProfile = { |profileName, overrides|
    var context;
    context = ~resolveProfileContext.(profileName, overrides);
    ~runtimeConfig = context[\config];
    ~activeProfile = profileName;
    ~activeProfileDefinition = context[\profileDefinition];
    ~activeProfileDefinition;
};

~engineSampleCount = { |engineName, runtimeConfig|
    var count, counts;
    runtimeConfig = runtimeConfig ? ~runtimeConfig;
    counts = runtimeConfig[\engineCounts];
    count = if(counts.notNil) { counts[engineName] };
    count ? runtimeConfig[\samplesPerEngine];
};

~jobSeed = { |engineName, index, runtimeConfig|
    var nameValue;
    runtimeConfig = runtimeConfig ? ~runtimeConfig;
    nameValue = 0;
    engineName.asString.do { |character, characterIndex|
        nameValue = nameValue + (character.ascii * (characterIndex + 1));
    };
    (((runtimeConfig[\randomSeed].asInteger
        + (nameValue * 1009)
        + ((index + 1) * 7919)).abs % 2147483646) + 1).asInteger;
};

~macroValue = { |macros, key|
    var value;
    value = if(macros.notNil) { macros[key] };
    (value ? 0.5).asFloat.clip(0, 1);
};

~applyMusicalMacros = { |parameters, macros|
    var brightness, dirt, punch, result, tail, weight;
    var add, scale;
    result = parameters.copy;
    if(macros.notNil) {
        weight = (~macroValue.(macros, \weight) - 0.5) * 2;
        punch = (~macroValue.(macros, \punch) - 0.5) * 2;
        brightness = (~macroValue.(macros, \brightness) - 0.5) * 2;
        tail = (~macroValue.(macros, \tail) - 0.5) * 2;
        dirt = (~macroValue.(macros, \dirt) - 0.5) * 2;

        scale = { |key, factor, low = 0, high = 20000|
            if(result[key].notNil) {
                result[key] = (result[key] * factor).clip(low, high);
            };
        };
        add = { |key, amount, low = 0, high = 20000|
            if(result[key].notNil) {
                result[key] = (result[key] + amount).clip(low, high);
            };
        };

        scale.(\amp, 1 + (weight * 0.16), 0.05, 1.2);
        scale.(\bodyAmount, 1 + (weight * 0.28), 0, 1.2);
        scale.(\harmonicAmount, 1 + (weight * 0.18), 0, 1);
        add.(\lowBoost, weight * 1.4, 0, 6);
        add.(\bodyBoost, weight * 1.0, 0, 6);

        scale.(\punchAmount, 1 + (punch * 0.35), 0, 1.2);
        scale.(\pitchAmount, 1 + (punch * 0.18), 0.2, 12);
        scale.(\clickAmount, 1 + (punch * 0.3), 0, 1);
        add.(\punchBoost, punch * 1.0, 0, 6);
        add.(\crackBoost, punch * 0.8, 0, 6);

        scale.(\clickTone, 1 + (brightness * 0.3), 500, 14000);
        scale.(\noiseTone, 1 + (brightness * 0.3), 500, 14000);
        scale.(\metallicTone, 1 + (brightness * 0.25), 2500, 12000);
        scale.(\tone, 1 + (brightness * 0.22), 0.01, 12000);
        add.(\brightness, brightness * 0.22, 0, 1);

        scale.(\decay, 1 + (tail * 0.45), 0.015, 4);
        scale.(\resonance, 1 + (tail * 0.3), 0.01, 2);
        scale.(\combDecay, 1 + (tail * 0.35), 0.005, 2);

        scale.(\drive, 1 + (dirt * 0.4), 0.5, 8);
        scale.(\foldAmount, 1 + (dirt * 0.7), 0, 1);
        if(result[\bits].notNil) {
            result[\bits] = (result[\bits] - (dirt * 3)).round.clip(3, 16);
        };
        if(result[\sampleRateReduction].notNil) {
            result[\sampleRateReduction] = (
                result[\sampleRateReduction] * (1 - (dirt * 0.32))
            ).clip(700, 44100);
        };
    };
    result;
};

~parameterLockGroups = (
    pitch: [
        \frequency, \pitchAmount, \pitchBounce, \pitchDecay,
        \fmRatio, \ringRatio, \punchRatio
    ],
    envelope: [
        \decay, \punchDecay, \combDecay, \resonance
    ],
    texture: [
        \bodyAmount, \noiseAmount, \noiseTone, \noiseWidth,
        \clickAmount, \clickTone, \clapAmount, \ringAmount,
        \fmAmount, \harmonicAmount, \exciterAmount,
        \inharmonicity, \metalAmount, \metallicTone,
        \brightness, \grainRate, \spread, \skinAmount, \tone
    ],
    dirt: [
        \drive, \foldAmount, \bits, \sampleRateReduction,
        \combAmount, \combTime
    ]
);

~makeVariationJob = {
    |sourceJob, locks, amount = 0.25, seed, variationIndex = 1, options|
    var context, isLocked, parameters, previousSeed, profileName;
    var runtimeConfig, sourceParameters, spec;

    if(sourceJob.isNil) { Error("Select a candidate first.").throw };
    spec = ~generatorSpecs[sourceJob[\family]];
    if(spec.isNil) {
        Error("Cannot vary unknown family: " ++ sourceJob[\family]).throw;
    };

    profileName = if(options.notNil) { options[\activeProfile] };
    profileName = profileName ? ~config[\activeProfile];
    context = ~resolveProfileContext.(profileName, options);
    runtimeConfig = context[\config];
    amount = amount.asFloat.clip(0.02, 1);
    seed = seed ? ~jobSeed.(
        sourceJob[\family], variationIndex + 1000, runtimeConfig
    );
    previousSeed = thisThread.randData.copy;
    protect {
        thisThread.randSeed = seed;
        parameters = ~applyMusicalMacros.(
            spec[\generator].value, runtimeConfig[\macros]
        );
    } {
        thisThread.randData = previousSeed;
    };
    sourceParameters = sourceJob[\parameters];

    sourceParameters.keysValuesDo { |key, sourceValue|
        var proposedValue;
        proposedValue = parameters[key];
        if(key != \seed and: { proposedValue.notNil }) {
            parameters[key] = if(sourceValue.isNumber
                and: { proposedValue.isNumber }) {
                sourceValue + ((proposedValue - sourceValue) * amount)
            } {
                if(amount >= 0.5) { proposedValue } { sourceValue }
            };
        };
    };

    isLocked = { |group|
        if(locks.isKindOf(Dictionary)) {
            locks[group] == true or: { locks[group] == 1 }
        } {
            locks.notNil and: { locks.asArray.includes(group) }
        };
    };
    ~parameterLockGroups.keysValuesDo { |group, keys|
        if(isLocked.(group)) {
            keys.do { |key|
                if(sourceParameters[key].notNil) {
                    parameters[key] = sourceParameters[key];
                };
            };
        };
    };
    if(parameters[\bits].notNil) {
        parameters[\bits] = parameters[\bits].round.asInteger;
    };
    parameters[\seed] = seed.asInteger;

    (
        family: sourceJob[\family],
        engine: spec[\synth],
        parameters: parameters,
        filename: ~sampleFilename.(
            spec[\prefix] ++ "V", variationIndex
        ),
        duration: sourceJob[\duration] ? spec[\duration],
        custom: true,
        variationOf: sourceJob[\filename],
        locks: locks.deepCopy,
        mutationAmount: amount
    );
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

~validateRenderJobs = { |jobs|
    var allowedFilenameCharacters, filenames;
    if(jobs.isArray.not or: { jobs.isEmpty }) {
        Error("Render jobs must be a non-empty Array.").throw;
    };
    allowedFilenameCharacters =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-";
    filenames = Set.new;
    jobs.do { |job|
        var extension, filename, stem;
        if(job.isKindOf(Dictionary).not) {
            Error("Every render job must be an Event or Dictionary.").throw;
        };
        if(~drumDefs[job[\engine]].isNil) {
            Error("Unknown render-job engine: " ++ job[\engine]).throw;
        };
        if(job[\parameters].isKindOf(Dictionary).not) {
            Error("Render-job parameters must be an Event or Dictionary.").throw;
        };
        job[\parameters].keysValuesDo { |name, value|
            if(value.isNumber.not) {
                Error("Render-job parameter must be numeric: " ++ name).throw;
            };
        };
        if(job[\duration].isNumber.not or: { job[\duration] <= 0 }) {
            Error("Render-job duration must be a positive number.").throw;
        };
        filename = job[\filename];
        if(filename.isKindOf(String).not
            or: { filename.isEmpty }
            or: { filename.find("/").notNil }
            or: { filename.find("\\").notNil }
            or: { filename.beginsWith(".") }) {
            Error("Unsafe render-job filename: " ++ filename).throw;
        };
        extension = PathName(filename).extension ? "";
        if(extension.toLower != "wav") {
            Error("Render-job filename must use the WAV extension: "
                ++ filename).throw;
        };
        stem = PathName(filename).fileNameWithoutExtension;
        stem.do { |character|
            if(allowedFilenameCharacters.includes(character).not) {
                Error("Unsafe character in render-job filename: "
                    ++ filename).throw;
            };
        };
        if(filenames.includes(filename.toLower)) {
            Error("Duplicate render-job filename: " ++ filename).throw;
        };
        filenames.add(filename.toLower);
    };
    jobs;
};

~makeJobs = { |runtimeConfig|
    var jobs, previousSeed;
    runtimeConfig = runtimeConfig ? ~runtimeConfig;
    jobs = List.new;
    previousSeed = thisThread.randData.copy;
    protect {
        runtimeConfig[\enabledEngines].do { |engineName|
            var spec;
            spec = ~generatorSpecs[engineName];

            ~engineSampleCount.(engineName, runtimeConfig).do { |index|
                var parameters, seed;
                seed = ~jobSeed.(engineName, index, runtimeConfig);
                thisThread.randSeed = seed;
                parameters = spec[\generator].value;
                parameters = ~applyMusicalMacros.(
                    parameters, runtimeConfig[\macros]
                );
                parameters[\seed] = seed;
                jobs.add((
                    family: engineName,
                    engine: spec[\synth],
                    parameters: parameters,
                    filename: ~sampleFilename.(spec[\prefix], index + 1),
                    duration: spec[\duration]
                ));
            };
        };
    } {
        thisThread.randData = previousSeed;
    };
    jobs.asArray;
};

~planJobBundle = { |engineNames, options|
    var context, jobs, profileName;
    profileName = if(options.notNil) { options[\activeProfile] };
    profileName = profileName ? ~config[\activeProfile];
    context = ~resolveProfileContext.(profileName, options);
    jobs = ~makeJobs.(context[\config]);

    if(engineNames.notNil) {
        jobs = jobs.select { |job| engineNames.asArray.includes(job[\family]) };
    };
    if(jobs.isEmpty) {
        Error("No render jobs matched the requested engines.").throw;
    };
    (jobs: jobs, context: context);
};

~planJobs = { |engineNames, options|
    var bundle;
    bundle = ~planJobBundle.(engineNames, options);
    ~lastPlannedContext = bundle[\context];
    if(~generationRunning != true) {
        ~runtimeConfig = bundle[\context][\config];
        ~activeProfile = bundle[\context][\profileName];
        ~activeProfileDefinition = bundle[\context][\profileDefinition];
    };
    bundle[\jobs];
};

~dryRun = { |engineNames, options|
    var approximateBytes, approximateSeconds, bundle, families, jobs;
    bundle = ~planJobBundle.(engineNames, options);
    jobs = bundle[\jobs];
    families = jobs.collect { |job| job[\family] }.asSet.asArray;
    approximateSeconds = jobs.sum { |job| job[\duration] };
    approximateBytes = approximateSeconds
        * bundle[\context][\config][\sampleRate] * 2;

    ("Planned " ++ jobs.size ++ " renders across "
        ++ families.size ++ " families:").postln;
    families.do { |family|
        var count, spec;
        spec = ~generatorSpecs[family];
        count = jobs.count { |job| job[\family] == family };
        ("  " ++ (spec[\label] ? family.asString)
            ++ ": " ++ count).postln;
    };
    ("Combined audio duration: "
        ++ approximateSeconds.round(0.1) ++ " seconds").postln;
    ("Approximate WAV data: "
        ++ (approximateBytes / (1024 * 1024)).round(0.1) ++ " MB").postln;
    jobs;
};

~listProfiles = {
    ~profiles.keys.asArray.sort.do { |name|
        var profile;
        profile = ~profiles[name];
        (name.asCompileString ++ " - " ++ profile[\displayName]
            ++ ": " ++ (profile[\description] ? "")).postln;
    };
};

~listFamilies = { |profileName|
    var profile;
    profile = ~profiles[profileName ? ~config[\activeProfile]];
    if(profile.isNil) { Error("Unknown profile.").throw };
    profile[\defaults][\enabledEngines].do { |name|
        var spec;
        spec = ~generatorSpecs[name];
        (name.asCompileString ++ " - " ++ (spec[\label] ? name.asString)
            ++ ": " ++ (spec[\description] ? "")).postln;
    };
};

~status = {
    var result, state;
    state = ~generationState;
    result = if(~generationRunning == true and: { state.notNil }) {
        (
            running: true,
            completed: state[\completed],
            total: state[\jobs].size,
            active: state[\active],
            failed: state[\failures].size,
            cancelled: state[\cancelled],
            outputDirectory: ~currentRunDirectory
        )
    } {
        (
            running: false,
            outputDirectory: ~currentRunDirectory
                ? ~runtimeConfig[\outputDirectory]
        )
    };
    result.postln;
    result;
};

~help = {
    "SC MPC Drum Lab commands".postln;
    "  ~openDrumLab.()                 Open the control panel".postln;
    "  ~openFavoriteKitBuilder.(~drumLabFavorites)  Arrange the 16-pad kit".postln;
    "  ~listProfiles.()                List available profiles".postln;
    "  ~listFamilies.()                List families in the active profile".postln;
    "  ~dryRun.()                      Summarize the next pack".postln;
    "  ~start.()                       Generate the configured pack".postln;
    "  ~generateEngine.(\\family)      Generate one family".postln;
    "  ~replayRecipe.(path)            Regenerate a saved recipe".postln;
    "  ~loadDrumLabSession.(path)      Load saved GUI/session data".postln;
    "  ~renderSessionFavorites.(data)  Rebuild a session's favorite kit".postln;
    "  ~cancelGeneration.()            Stop scheduling new renders".postln;
    "  ~status.()                      Show current progress and output".postln;
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
        try {
            ~finalizeManifest.(state, state[\run]);
        } { |error|
            state[\failures].add((job: nil, error: error.errorString));
            ("Could not finalize manifest: " ++ error.errorString).warn;
        };
        "".postln;

        if(state[\cancelled]) {
            "Sample pack generation cancelled.".warn;
        } {
            "Sample pack generation finished.".postln;
        };
        ("Completed: " ++ state[\completed]).postln;
        ("Failed:    " ++ state[\failures].size).postln;
        ("Samples:   " ++ state[\run][\directory]).postln;
        ("Manifest:  " ++ state[\run][\manifestPath]).postln;
        ("Recipe:    " ++ state[\run][\recipePath]).postln;
        ~notifyGeneration.(\finished, (
            completed: state[\completed],
            failed: state[\failures].size,
            cancelled: state[\cancelled],
            total: state[\jobs].size,
            outputDirectory: state[\run][\directory],
            manifestPath: state[\run][\manifestPath],
            recipePath: state[\run][\recipePath]
        ));
    };
};

~settleGenerationJob = { |state, jobIndex, succeeded, data|
    var job, message;
    if(state[\settled].includes(jobIndex).not) {
        state[\settled].add(jobIndex);
        state[\active] = (state[\active] - 1).max(0);
        state[\processed] = state[\processed] + 1;
        job = state[\jobs][jobIndex];

        if(succeeded) {
            state[\completed] = state[\completed] + 1;
            try {
                ~writeManifestEntry.(
                    job,
                    data[\outputPath],
                    data[\validation],
                    data[\finalParameters],
                    state[\run]
                );
            } { |error|
                state[\failures].add((
                    job: job,
                    error: "Manifest write failed: " ++ error.errorString
                ));
                ("Manifest write failed for " ++ job[\filename]
                    ++ ": " ++ error.errorString).warn;
            };
            ~notifyGeneration.(\rendered, (
                job: job,
                outputPath: data[\outputPath],
                validation: data[\validation],
                effectiveParameters: data[\finalParameters],
                completed: state[\completed],
                processed: state[\processed],
                total: state[\jobs].size
            ));
            ("Progress: " ++ state[\processed]
                ++ "/" ++ state[\jobs].size).postln;
        } {
            message = data[\message] ? "Unknown render failure";
            state[\failures].add((job: job, error: message));
            try {
                ~writeManifestFailure.(job, message, state[\run]);
            } { |error|
                ("Could not record render failure: " ++ error.errorString).warn;
            };
            ~notifyGeneration.(\failed, (
                job: job,
                message: message,
                completed: state[\completed],
                processed: state[\processed],
                total: state[\jobs].size
            ));
            ("Render failed: " ++ job[\filename] ++ " - " ++ message).warn;
        };
        ~pumpJobQueue.();
    };
};

~pumpJobQueue = {
    var maximumWorkers, state;
    state = ~generationState;
    maximumWorkers = state[\run][\config][\maxConcurrentRenders]
        .asInteger.clip(1, 8);

    while({
        state[\cancelled].not
        and: { state[\active] < maximumWorkers }
        and: { state[\nextIndex] < state[\jobs].size }
    }, {
        var job, jobIndex;
        jobIndex = state[\nextIndex];
        job = state[\jobs][state[\nextIndex]];
        state[\nextIndex] = state[\nextIndex] + 1;
        state[\active] = state[\active] + 1;

        ~notifyGeneration.(\rendering, (
            job: job,
            completed: state[\completed],
            total: state[\jobs].size
        ));

        ~renderSample.(
            job[\engine],
            job[\parameters],
            job[\filename],
            job[\duration],
            { |outputPath, validation, finalParameters|
                ~settleGenerationJob.(state, jobIndex, true, (
                    outputPath: outputPath,
                    validation: validation,
                    finalParameters: finalParameters
                ));
            },
            { |message|
                ~settleGenerationJob.(state, jobIndex, false, (message: message));
            },
            state[\run]
        );
    });

    ~finishGenerationIfReady.();
};

~launchJobs = { |jobs, context|
    var run;
    ~validateRenderJobs.(jobs);
    run = ~prepareRun.(jobs, context);
    ~generationState = (
        jobs: jobs.deepCopy,
        run: run,
        nextIndex: 0,
        active: 0,
        processed: 0,
        completed: 0,
        failures: List.new,
        cancelled: false,
        settled: Set.new
    );
    // Compatibility globals are snapshots; active services read run[\config].
    ~runtimeConfig = run[\config].deepCopy;
    ~activeProfile = run[\profileName];
    ~activeProfileDefinition = run[\profileDefinition];
    ~generationRunning = true;
    ~notifyGeneration.(\started, (
        total: jobs.size,
        outputDirectory: run[\directory],
        profile: run[\profileName]
    ));
    ("Starting " ++ jobs.size ++ " renders with up to "
        ++ run[\config][\maxConcurrentRenders]
        ++ " workers...").postln;
    ~pumpJobQueue.();
};

~start = { |engineNames, options|
    if(~generationRunning == true) {
        "A generation job is already running.".warn;
    } {
        try {
            var bundle;
            bundle = ~planJobBundle.(engineNames, options);
            ~launchJobs.(bundle[\jobs], bundle[\context]);
        } { |error|
            ~generationRunning = false;
            error.reportError;
        };
    };
};

~startJobs = { |jobs, options|
    var context, profileName;
    if(~generationRunning == true) {
        "A generation job is already running.".warn;
    } {
        try {
            profileName = if(options.notNil) { options[\activeProfile] };
            profileName = profileName ? ~config[\activeProfile];
            context = ~resolveProfileContext.(profileName, options);
            ~validateRenderJobs.(jobs);
            ~launchJobs.(jobs.deepCopy, context);
        } { |error|
            ~generationRunning = false;
            error.reportError;
        };
    };
};

~generateEngine = { |engineName, options| ~start.([engineName], options) };

~newDrumSession = { |options|
    var session;
    options = options ? ();
    session = (options: options.deepCopy);
    session[\plan] = { |engineNames|
        ~planJobs.(engineNames, session[\options])
    };
    session[\dryRun] = { |engineNames|
        ~dryRun.(engineNames, session[\options])
    };
    session[\generate] = { |engineNames|
        ~start.(engineNames, session[\options])
    };
    session;
};

~replayRecipe = { |path|
    var recipe;
    if(path.isNil or: { File.exists(path).not }) {
        Error("Recipe file was not found: " ++ path).throw;
    };
    recipe = ~readDrumLabDataFile.(path);
    if(recipe.isKindOf(Dictionary).not) {
        Error("Recipe did not contain a configuration Event.").throw;
    };
    switch(recipe[\kind],
        \pack, { ~start.(nil, recipe[\options]) },
        \sound, {
            ~renderSound.(
                recipe[\sound], recipe[\sound][\filename], recipe[\options]
            )
        },
        \jobs, { ~startJobs.(recipe[\jobs], recipe[\options]) },
        { ~start.(nil, recipe) }
    );
};

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
