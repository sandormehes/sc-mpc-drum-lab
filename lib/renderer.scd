// Offline mono WAV renderer with validation and temporary-file promotion.

(
~removeFileIfExists = { |path|
    if(path.notNil and: { File.exists(path) }) {
        File.delete(path);
    };
};

~validateRenderedFile = { |path, expectedDuration, runtimeConfig|
    var errors, file, result;
    runtimeConfig = runtimeConfig ? ~runtimeConfig;
    errors = List.new;
    file = SoundFile.openRead(path);

    if(file.isNil) {
        result = (valid: false, error: "Cannot open rendered WAV file.");
    } {
        protect {
            var dcOffset, duration, peak, rms, samples;
            var tailFrames, tailPeak;
            duration = file.numFrames / file.sampleRate;
            peak = file.channelPeaks.maxItem;
            samples = FloatArray.newClear(file.numFrames * file.numChannels);
            file.seek(0, 0);
            file.readData(samples);
            dcOffset = samples.mean;
            rms = samples.mean { |sample| sample.squared }.sqrt;
            tailFrames = (
                runtimeConfig[\tailDuration] * file.sampleRate
            ).asInteger.clip(1, file.numFrames);
            tailPeak = file.channelPeaks(
                file.numFrames - tailFrames, tailFrames
            ).maxItem;

            if(file.numChannels != 1) {
                errors.add("Expected mono audio, found " ++ file.numChannels ++ " channels");
            };
            if(file.sampleRate != runtimeConfig[\sampleRate]) {
                errors.add(
                    "Expected " ++ runtimeConfig[\sampleRate]
                    ++ " Hz, found " ++ file.sampleRate
                );
            };
            if(file.sampleFormat.asString.toLower
                != runtimeConfig[\sampleFormat].asString.toLower) {
                errors.add(
                    "Expected " ++ runtimeConfig[\sampleFormat]
                    ++ ", found " ++ file.sampleFormat
                );
            };
            if((duration - expectedDuration).abs
                > runtimeConfig[\durationTolerance]) {
                errors.add(
                    "Expected duration " ++ expectedDuration
                    ++ ", found " ++ duration.round(0.0001)
                );
            };
            if(peak < runtimeConfig[\minimumPeak]) {
                errors.add("Rendered file is silent or nearly silent");
            };
            if(peak > runtimeConfig[\maximumPeak]) {
                errors.add("Rendered file exceeds the configured peak limit");
            };
            if(dcOffset.abs > runtimeConfig[\maximumDcOffset]) {
                errors.add("Rendered file has excessive DC offset");
            };
            if(tailPeak > runtimeConfig[\maximumTailPeak]) {
                errors.add("Rendered file has not decayed before its end");
            };

            result = (
                valid: errors.isEmpty,
                error: errors.join("; "),
                numChannels: file.numChannels,
                sampleRate: file.sampleRate,
                sampleFormat: file.sampleFormat.asString,
                numFrames: file.numFrames,
                duration: duration,
                peak: peak,
                rms: rms,
                dcOffset: dcOffset,
                tailPeak: tailPeak
            );
        } {
            file.close;
        };
    };

    result;
};

~renderSample = {
    |engine, parameters, filename, duration = 1.5, onComplete, onError, run|

    var finalParameters, options, oscPath, outputPath, runtimeConfig;
    var score, synthDef, temporaryPath;

    synthDef = ~drumDefs[engine];
    if(synthDef.isNil) {
        Error("Unknown engine: " ++ engine).throw;
    };
    run = run ? ~generationState.tryPerform(\at, \run);
    runtimeConfig = if(run.notNil) { run[\config] } { ~runtimeConfig };
    if(run.isNil and: { ~currentRunDirectory.notNil }) {
        run = (directory: ~currentRunDirectory, config: runtimeConfig);
    };
    if(run.isNil or: { run[\directory].isNil }) {
        Error("No output run is prepared. Use ~start.() or ~renderPreset.().").throw;
    };

    outputPath = run[\directory] +/+ filename;
    temporaryPath = run[\directory] +/+ ("." ++ filename ++ ".partial.wav");
    oscPath = run[\directory] +/+ ("." ++ filename ++ ".osc");

    finalParameters = parameters.copy;
    finalParameters[\amp] = (finalParameters[\amp] ? 0.7)
        * runtimeConfig[\masterAmp];

    options = ServerOptions.new;
    options.numOutputBusChannels = 1;
    options.numInputBusChannels = 0;
    options.sampleRate = runtimeConfig[\sampleRate];
    options.blockSize = 64;
    options.memSize = 8192 * 16;

    score = Score([
        [0.0, [\d_recv, synthDef.asBytes]],
        [0.01, [\s_new, engine, 1000, 0, 0]
            ++ finalParameters.asKeyValuePairs]
    ]);

    ~removeFileIfExists.(temporaryPath);
    ~removeFileIfExists.(oscPath);
    ("Rendering: " ++ filename).postln;

    try {
        score.recordNRT(
            oscFilePath: oscPath,
            outputFilePath: temporaryPath,
            sampleRate: runtimeConfig[\sampleRate],
            headerFormat: runtimeConfig[\headerFormat],
            sampleFormat: runtimeConfig[\sampleFormat],
            options: options,
            duration: duration,
            action: { |exitCode|
                {
                    var renderError, validation;
                    try {
                        ~removeFileIfExists.(oscPath);

                        if(exitCode != 0) {
                            Error("scsynth exited with status " ++ exitCode).throw;
                        };

                        validation = ~validateRenderedFile.(
                            temporaryPath, duration, runtimeConfig
                        );
                        if(validation[\valid].not) {
                            Error(validation[\error]).throw;
                        };

                        ~removeFileIfExists.(outputPath);
                        File.copy(temporaryPath, outputPath);
                        if(File.exists(outputPath).not) {
                            Error("Could not promote the temporary WAV file.").throw;
                        };
                        ~removeFileIfExists.(temporaryPath);
                        ("Finished:  " ++ filename).postln;

                    } { |error|
                        ~removeFileIfExists.(oscPath);
                        ~removeFileIfExists.(temporaryPath);
                        renderError = error;
                    };

                    // Consumer callback failures are not render failures. The
                    // scheduler owns callback error handling and settlement.
                    if(renderError.notNil) {
                        if(onError.notNil) {
                            onError.value(renderError.errorString);
                        } {
                            renderError.reportError;
                        };
                    } {
                        if(onComplete.notNil) {
                            onComplete.value(outputPath, validation, finalParameters);
                        };
                    };
                }.defer;
            }
        );
    } { |error|
        ~removeFileIfExists.(oscPath);
        ~removeFileIfExists.(temporaryPath);
        if(onError.notNil) {
            { onError.value(error.errorString) }.defer;
        } {
            error.reportError;
        };
    };
};
)
