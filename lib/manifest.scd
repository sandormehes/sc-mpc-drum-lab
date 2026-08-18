// Run directories and reproducible, success-aware manifests.

(
~gitMetadata = {
    var dirtyOutput, result, revisionOutput;
    result = (revision: "unknown", dirty: "unknown");

    try {
        revisionOutput = [
            "git", "-C", ~projectRoot, "rev-parse", "--short", "HEAD"
        ].unixCmdGetStdOut;
        dirtyOutput = [
            "git", "-C", ~projectRoot, "status", "--porcelain"
        ].unixCmdGetStdOut;
        result[\revision] = revisionOutput.split($\n)[0];
        result[\dirty] = dirtyOutput.isEmpty.not;
    } { |error|
        ("Git metadata unavailable: " ++ error.asString).warn;
    };
    result;
};

~createRunDirectory = { |context|
    var baseName, candidate, counter, outputRoot;
    context = context ? (
        config: ~runtimeConfig,
        profileName: ~activeProfile,
        profileDefinition: ~activeProfileDefinition
    );
    outputRoot = context[\config][\outputDirectory];
    File.mkdir(outputRoot);

    if(context[\config][\useRunDirectories]) {
        baseName = Date.getDate.asSortableString
            ++ "_" ++ context[\profileName].asString;
        candidate = outputRoot +/+ baseName;
        counter = 2;
        while({ File.exists(candidate) }, {
            candidate = outputRoot +/+ (baseName ++ "_" ++ counter);
            counter = counter + 1;
        });
        File.mkdir(candidate);
    } {
        candidate = outputRoot;
    };

    if(File.exists(candidate).not) {
        Error("Cannot create output directory: " ++ candidate).throw;
    };
    candidate;
};

~prepareRun = { |jobs, context|
    var config, counts, families, file, git, options, recipe, recipeFile, run;
    context = context ? (
        config: ~runtimeConfig,
        profileName: ~activeProfile,
        profileDefinition: ~activeProfileDefinition
    );
    config = context[\config];
    run = (
        config: config.deepCopy,
        profileName: context[\profileName],
        profileDefinition: context[\profileDefinition],
        directory: ~createRunDirectory.(context)
    );
    run[\manifestPath] = run[\directory] +/+ "sample_manifest.txt";
    run[\recipePath] = run[\directory] +/+ "recipe.json";
    ~currentRunDirectory = run[\directory];
    ~manifestPath = run[\manifestPath];
    ~recipePath = run[\recipePath];
    git = ~gitMetadata.();
    families = List.new;
    jobs.do { |job|
        if(families.includes(job[\family]).not) {
            families.add(job[\family]);
        };
    };
    counts = IdentityDictionary.new;
    families.do { |family|
        counts[family] = jobs.count { |job| job[\family] == family };
    };

    file = File(run[\manifestPath], "w");
    if(file.isOpen.not) {
        Error("Cannot write manifest: " ++ run[\manifestPath]).throw;
    };

    protect {
        file.write("SC MPC DRUM LAB MANIFEST v3\n");
        file.write("Generated: " ++ Date.getDate.asString ++ "\n");
        file.write("Project version: "
            ++ config[\projectVersion] ++ "\n");
        file.write("SuperCollider: " ++ Main.version ++ "\n");
        file.write("Git revision: " ++ git[\revision] ++ "\n");
        file.write("Git dirty: " ++ git[\dirty] ++ "\n");
        file.write("Profile: " ++ run[\profileName] ++ "\n");
        file.write("Seed: " ++ config[\randomSeed] ++ "\n");
        file.write("Planned samples: " ++ jobs.size ++ "\n");
        file.write("Sample rate: " ++ config[\sampleRate] ++ "\n");
        file.write("Header format: " ++ config[\headerFormat] ++ "\n");
        file.write("Sample format: " ++ config[\sampleFormat] ++ "\n");
        file.write("Master amp: " ++ config[\masterAmp] ++ "\n\n");
        file.write("Musical macros: "
            ++ config[\macros].asCompileString ++ "\n");
        file.write("Enabled families: "
            ++ families.asArray.asCompileString ++ "\n");
        file.write("Family counts: "
            ++ counts.asCompileString ++ "\n\n");
    } {
        file.close;
    };

    options = (
        activeProfile: run[\profileName],
        randomSeed: config[\randomSeed],
        samplesPerEngine: config[\samplesPerEngine],
        engineCounts: counts,
        enabledEngines: families.asArray,
        macros: config[\macros],
        masterAmp: config[\masterAmp],
        maxConcurrentRenders: config[\maxConcurrentRenders]
    );
    recipe = if(families.includes(\preset)) {
        (
            kind: \sound,
            sound: jobs.first.copy,
            options: (
                activeProfile: run[\profileName],
                masterAmp: config[\masterAmp]
            )
        )
    } {
        if(jobs.any { |job| job[\custom] == true }) {
            (
                kind: \jobs,
                jobs: jobs.deepCopy,
                options: options
            )
        } {
            (
                kind: \pack,
                options: options
            )
        }
    };
    recipeFile = File(run[\recipePath], "w");
    if(recipeFile.isOpen.not) {
        Error("Cannot write recipe: " ++ run[\recipePath]).throw;
    };
    protect {
        recipeFile.write(~encodeDrumLabJson.(recipe) ++ "\n");
    } {
        recipeFile.close;
    };
    run;
};

~appendManifestLine = { |line, run|
    var file;
    run = run ? ~generationState.tryPerform(\at, \run);
    file = File(if(run.notNil) { run[\manifestPath] } { ~manifestPath }, "a");
    if(file.isOpen.not) {
        Error("Cannot append manifest.").throw;
    };
    protect {
        file.write(line ++ "\n");
    } {
        file.close;
    };
};

~writeManifestEntry = { |job, outputPath, validation, finalParameters, run|
    var entry;
    entry = (
        status: \complete,
        filename: job[\filename],
        family: job[\family],
        synth: job[\engine],
        duration: job[\duration],
        parameters: job[\parameters],
        effectiveParameters: finalParameters,
        custom: job[\custom] ? false,
        variationOf: job[\variationOf],
        locks: job[\locks],
        mutationAmount: job[\mutationAmount],
        validation: validation,
        outputPath: outputPath
    );
    ~appendManifestLine.(entry.asCompileString, run);
};

~writeManifestFailure = { |job, message, run|
    ~appendManifestLine.((
        status: \failed,
        filename: job[\filename],
        family: job[\family],
        synth: job[\engine],
        error: message
    ).asCompileString, run);
};

~finalizeManifest = { |state, run|
    ~appendManifestLine.("", run);
    ~appendManifestLine.((
        summary: (
            completed: state[\completed],
            failed: state[\failures].size,
            cancelled: state[\cancelled]
        )
    ).asCompileString, run);
};
)
