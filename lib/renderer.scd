// Offline mono WAV renderer. Completion callbacks keep pack jobs sequential.

(
~renderSample = {
    |engine, parameters, filename, duration = 1.5, onComplete|

    var synthDef, score, outputPath, options, finalParameters;

    synthDef = ~drumDefs[engine];
    if(synthDef.isNil) {
        Error("Unknown engine: " ++ engine).throw;
    };

    outputPath = ~config[\outputDirectory] +/+ filename;
    finalParameters = parameters.copy;
    finalParameters[\amp] = (finalParameters[\amp] ? 0.7)
        * ~config[\masterAmp];

    options = ServerOptions.new;
    options.numOutputBusChannels = 1;
    options.numInputBusChannels = 0;
    options.sampleRate = ~config[\sampleRate];
    options.blockSize = 64;
    options.memSize = 8192 * 16;

    score = Score([
        [0.0, [\d_recv, synthDef.asBytes]],
        [0.01, [\s_new, engine, 1000, 0, 0]
            ++ finalParameters.asKeyValuePairs]
    ]);

    ("Rendering: " ++ filename).postln;
    score.recordNRT(
        outputFilePath: outputPath,
        sampleRate: ~config[\sampleRate],
        headerFormat: ~config[\headerFormat],
        sampleFormat: ~config[\sampleFormat],
        options: options,
        duration: duration,
        action: {
            ("Finished:  " ++ filename).postln;
            if(onComplete.notNil) {
                { onComplete.value(outputPath) }.defer;
            };
        }
    );
};
)
