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

~createRunDirectory = {
    var baseName, candidate, counter, outputRoot;
    outputRoot = ~runtimeConfig[\outputDirectory];
    File.mkdir(outputRoot);

    if(~runtimeConfig[\useRunDirectories]) {
        baseName = Date.getDate.asSortableString
            ++ "_" ++ ~activeProfile.asString;
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

~prepareRun = { |jobs|
    var counts, families, file, git, recipe, recipeFile;
    ~currentRunDirectory = ~createRunDirectory.();
    ~manifestPath = ~currentRunDirectory +/+ "sample_manifest.txt";
    ~recipePath = ~currentRunDirectory +/+ "recipe.scd";
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

    file = File(~manifestPath, "w");
    if(file.isOpen.not) {
        Error("Cannot write manifest: " ++ ~manifestPath).throw;
    };

    protect {
        file.write("SC MPC DRUM LAB MANIFEST v3\n");
        file.write("Generated: " ++ Date.getDate.asString ++ "\n");
        file.write("Project version: "
            ++ ~runtimeConfig[\projectVersion] ++ "\n");
        file.write("SuperCollider: " ++ Main.version ++ "\n");
        file.write("Git revision: " ++ git[\revision] ++ "\n");
        file.write("Git dirty: " ++ git[\dirty] ++ "\n");
        file.write("Profile: " ++ ~activeProfile ++ "\n");
        file.write("Seed: " ++ ~runtimeConfig[\randomSeed] ++ "\n");
        file.write("Planned samples: " ++ jobs.size ++ "\n");
        file.write("Sample rate: " ++ ~runtimeConfig[\sampleRate] ++ "\n");
        file.write("Header format: " ++ ~runtimeConfig[\headerFormat] ++ "\n");
        file.write("Sample format: " ++ ~runtimeConfig[\sampleFormat] ++ "\n");
        file.write("Master amp: " ++ ~runtimeConfig[\masterAmp] ++ "\n\n");
        file.write("Musical macros: "
            ++ ~runtimeConfig[\macros].asCompileString ++ "\n");
        file.write("Enabled families: "
            ++ families.asArray.asCompileString ++ "\n");
        file.write("Family counts: "
            ++ counts.asCompileString ++ "\n\n");
    } {
        file.close;
    };

    recipe = if(families.includes(\preset)) {
        (
            kind: \sound,
            sound: jobs.first.copy,
            options: (
                activeProfile: ~activeProfile,
                masterAmp: ~runtimeConfig[\masterAmp]
            )
        )
    } {
        (
            kind: \pack,
            options: (
                activeProfile: ~activeProfile,
                randomSeed: ~runtimeConfig[\randomSeed],
                samplesPerEngine: ~runtimeConfig[\samplesPerEngine],
                engineCounts: counts,
                enabledEngines: families.asArray,
                macros: ~runtimeConfig[\macros],
                masterAmp: ~runtimeConfig[\masterAmp],
                maxConcurrentRenders: ~runtimeConfig[\maxConcurrentRenders]
            )
        )
    };
    recipeFile = File(~recipePath, "w");
    if(recipeFile.isOpen.not) {
        Error("Cannot write recipe: " ++ ~recipePath).throw;
    };
    protect {
        recipeFile.write(recipe.asCompileString ++ "\n");
    } {
        recipeFile.close;
    };
    ~currentRunDirectory;
};

~appendManifestLine = { |line|
    var file;
    file = File(~manifestPath, "a");
    if(file.isOpen.not) {
        Error("Cannot append manifest: " ++ ~manifestPath).throw;
    };
    protect {
        file.write(line ++ "\n");
    } {
        file.close;
    };
};

~writeManifestEntry = { |job, outputPath, validation, finalParameters|
    var entry;
    entry = (
        status: \complete,
        filename: job[\filename],
        family: job[\family],
        synth: job[\engine],
        duration: job[\duration],
        parameters: job[\parameters],
        effectiveParameters: finalParameters,
        validation: validation,
        outputPath: outputPath
    );
    ~appendManifestLine.(entry.asCompileString);
};

~writeManifestFailure = { |job, message|
    ~appendManifestLine.((
        status: \failed,
        filename: job[\filename],
        family: job[\family],
        synth: job[\engine],
        error: message
    ).asCompileString);
};

~finalizeManifest = { |state|
    ~appendManifestLine.("");
    ~appendManifestLine.((
        summary: (
            completed: state[\completed],
            failed: state[\failures].size,
            cancelled: state[\cancelled]
        )
    ).asCompileString);
};
)
