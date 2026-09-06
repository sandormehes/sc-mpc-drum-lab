// Offline mono WAV renderer with validation and temporary-file promotion.

(
~removeFileIfExists = { |path|
    if(path.notNil and: { File.exists(path) }) {
        File.delete(path);
    };
};

// A lightweight brightness estimate based on the energy in adjacent-sample
// differences. It is intentionally used only for gain compensation, never to
// change a sample's timbre with hidden EQ.
~drumLabBrightness = { |samples, rms|
    var differenceEnergy, previous;
    differenceEnergy = 0.0;
    previous = 0.0;
    samples.do { |sample, index|
        if(index > 0) {
            differenceEnergy = differenceEnergy + (sample - previous).squared;
        };
        previous = sample;
    };
    if(samples.size < 2 or: { rms <= 0 }) {
        0.0
    } {
        ((differenceEnergy / (samples.size - 1)).sqrt / (rms * 2)).clip(0, 1)
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
            var brightness, dcOffset, duration, peak, rms, samples;
            var tailFrames, tailPeak;
            duration = file.numFrames / file.sampleRate;
            peak = file.channelPeaks.maxItem;
            samples = FloatArray.newClear(file.numFrames * file.numChannels);
            file.seek(0, 0);
            file.readData(samples);
            dcOffset = samples.mean;
            rms = samples.mean { |sample| sample.squared }.sqrt;
            brightness = ~drumLabBrightness.(samples, rms);
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
                brightness: brightness,
                dcOffset: dcOffset,
                tailPeak: tailPeak
            );
        } {
            file.close;
        };
    };

    result;
};

~applyDrumLabWavGain = { |path, gain|
    var backupPath, destination, source, temporaryPath, samples;
    gain = gain ? 1.0;
    if(gain <= 0) { Error("WAV gain must be positive.").throw };
    temporaryPath = path + ".balance.partial.wav";
    source = SoundFile.openRead(path);
    if(source.isNil) { Error("Cannot open WAV for kit balancing: " ++ path).throw };
    protect {
        samples = FloatArray.newClear(source.numFrames * source.numChannels);
        source.readData(samples);
        samples.do { |sample, index|
            samples[index] = (sample * gain).clip(-1, 1);
        };
        ~removeFileIfExists.(temporaryPath);
        destination = SoundFile.new;
        destination.headerFormat = source.headerFormat;
        destination.sampleFormat = source.sampleFormat;
        destination.numChannels = source.numChannels;
        destination.sampleRate = source.sampleRate;
        if(destination.openWrite(temporaryPath).not) {
            Error("Cannot write balanced WAV: " ++ temporaryPath).throw;
        };
        protect {
            destination.writeData(samples);
        } {
            destination.close;
        };
    } {
        source.close;
    };
    backupPath = path + ".balance.backup.wav";
    ~removeFileIfExists.(backupPath);
    File.copy(path, backupPath);
    if(File.exists(backupPath).not) {
        ~removeFileIfExists.(temporaryPath);
        Error("Could not back up WAV before kit balancing: " ++ path).throw;
    };
    ~removeFileIfExists.(path);
    File.copy(temporaryPath, path);
    ~removeFileIfExists.(temporaryPath);
    if(File.exists(path).not) {
        File.copy(backupPath, path);
        ~removeFileIfExists.(backupPath);
        Error("Could not promote balanced WAV: " ++ path).throw;
    };
    ~removeFileIfExists.(backupPath);
    path;
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
