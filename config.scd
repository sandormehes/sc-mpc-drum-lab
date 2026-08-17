// Edit this file for everyday use.

(
~config = (
    projectVersion: "0.6.0",

    // Output is kept inside the repository by default.
    outputDirectory: ~projectRoot +/+ "output",

    // User-created lab sessions are stored separately from rendered audio.
    sessionDirectory: ~projectRoot +/+ "sessions",

    sampleRate: 44100,
    headerFormat: "WAV",
    sampleFormat: "int16",

    randomSeed: 26071986,

    // Profiles supply these values when they are nil. Set a value here to
    // override the selected profile without editing the profile itself.
    activeProfile: \thickClub,
    samplesPerEngine: nil,
    // Optional Event of per-family counts, for example:
    // (dancehallKick: 8, grimeSnare: 4, dancehallRim: 2)
    engineCounts: nil,
    // Optional musical macro Event. Values range from 0 (less) to 1 (more),
    // with 0.5 leaving the generated engine parameters unchanged.
    macros: nil,
    masterAmp: nil,
    enabledEngines: nil,

    // Offline renders use separate scsynth processes. Keep this conservative
    // on older machines and increase it only after measuring performance.
    maxConcurrentRenders: 2,

    // Each generation gets its own directory so an older pack is never
    // overwritten by accident.
    useRunDirectories: true,

    // Post-render validation thresholds.
    minimumPeak: 0.0001,
    maximumPeak: 1.0,
    maximumDcOffset: 0.01,
    tailDuration: 0.02,
    maximumTailPeak: 0.02,
    durationTolerance: 0.02,

    // Set true to start rendering immediately after evaluating main.scd.
    autoStart: false,

    // gui.scd opens the control panel explicitly. Keep main.scd headless-safe.
    openGuiOnLoad: false
);

File.mkdir(~config[\outputDirectory]);
File.mkdir(~config[\sessionDirectory]);
~drumDefs = IdentityDictionary.new;
~generatorSpecs = IdentityDictionary.new;
~presets = IdentityDictionary.new;
~profiles = IdentityDictionary.new;
)
