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
    var file, git;
    ~currentRunDirectory = ~createRunDirectory.();
    ~manifestPath = ~currentRunDirectory +/+ "sample_manifest.txt";
    git = ~gitMetadata.();

    file = File(~manifestPath, "w");
    if(file.isOpen.not) {
        Error("Cannot write manifest: " ++ ~manifestPath).throw;
    };

    protect {
        file.write("SC MPC DRUM LAB MANIFEST v2\n");
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
    } {
        file.close;
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
