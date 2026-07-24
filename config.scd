// Edit this file for everyday use.

(
~config = (
    // Output is kept inside the repository by default.
    outputDirectory: ~projectRoot +/+ "output",

    sampleRate: 44100,
    headerFormat: "WAV",
    sampleFormat: "int16",

    randomSeed: 26071986,
    samplesPerEngine: 12,
    masterAmp: 0.8,

    // Set true to start rendering immediately after evaluating main.scd.
    autoStart: false,

    // Remove engines from this list to skip them.
    enabledEngines: [
        \kick,
        \snare,
        \metal,
        \glitch,
        \resonator
    ]
);

File.mkdir(~config[\outputDirectory]);
~drumDefs = IdentityDictionary.new;
~generatorSpecs = IdentityDictionary.new;
~presets = IdentityDictionary.new;
)
