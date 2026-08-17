// Language-only smoke tests. No audio files are rendered.

(
var assert, assertThrows, customJobs, favorite, favoriteList, favoriteRecipe;
var filenames;
var labSession;
var loadedSession, macroJobs, originalJobs, projectRoot, repeatJobs;
var repeatVariation, selectedJobs, session, sessionJobs, sessionPath;
var randomAfterPlanning, randomExpected, randomState, runningConfig;
var originalPump, originalWriteEntry, settlementState;
var sessionOptions, thickJobs, variationJob;

try {
    projectRoot = File.realpath(
        PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".."
    );
    (projectRoot +/+ "main.scd").load;

    assert = { |condition, message|
        if(condition.not) {
            Error("Smoke test failed: " ++ message).throw;
        };
    };
    assertThrows = { |function, message|
        var didThrow;
        didThrow = false;
        try { function.value } { didThrow = true };
        assert.(didThrow, message);
    };

    ~config[\activeProfile] = \original;
    originalJobs = ~planJobs.();
    assert.(originalJobs.size == 60, "original profile should plan 60 jobs");
    assert.(
        originalJobs[0][\filename] == "XKICK_001.wav",
        "original filenames should be zero-padded"
    );

    ~config[\activeProfile] = \thickClub;
    thickJobs = ~planJobs.();
    assert.(thickJobs.size == 60, "thickClub profile should plan 60 jobs");
    assert.(
        thickJobs[0][\filename] == "DHKICK_001.wav",
        "thickClub filenames should be zero-padded"
    );
    assert.(
        thickJobs[0][\engine] == \thickClubKick,
        "thickClub should use its own kick SynthDef"
    );
    assert.(
        ~generatorSpecs[\dancehallKick][\label] == "Dancehall Kick",
        "engine metadata should expose a human-facing label"
    );
    assert.(
        thickJobs[0][\parameters][\seed].isInteger,
        "every generated sound should receive a synthesis seed"
    );
    repeatJobs = ~planJobs.();
    assert.(
        repeatJobs[0][\parameters][\seed]
            == thickJobs[0][\parameters][\seed],
        "sound seeds should be reproducible"
    );
    thisThread.randSeed = 880055;
    randomState = thisThread.randData.copy;
    ~planJobs.();
    randomAfterPlanning = 1000000.rand;
    thisThread.randData = randomState;
    randomExpected = 1000000.rand;
    assert.(
        randomAfterPlanning == randomExpected,
        "planning should preserve the caller's random stream"
    );
    runningConfig = ~runtimeConfig;
    ~generationRunning = true;
    ~planJobs.(nil, (activeProfile: \original));
    assert.(
        ~runtimeConfig === runningConfig,
        "planning must not replace active-run configuration"
    );
    ~generationRunning = false;
    selectedJobs = ~planJobs.([\grimeSnare], (
        activeProfile: \thickClub,
        samplesPerEngine: 6,
        enabledEngines: [\grimeSnare]
    ));
    assert.(
        selectedJobs[0][\parameters]
            == thickJobs.detect { |job| job[\family] == \grimeSnare }[\parameters],
        "a sound should not change when other families are omitted"
    );

    customJobs = ~planJobs.(nil, (
        activeProfile: \thickClub,
        samplesPerEngine: 1,
        enabledEngines: [\dancehallKick, \grimeSnare],
        engineCounts: (dancehallKick: 2, grimeSnare: 3)
    ));
    assert.(customJobs.size == 5, "per-family counts should shape the pack");
    assert.(
        customJobs.count { |job| job[\family] == \dancehallKick } == 2,
        "dancehallKick should use its family count"
    );
    macroJobs = ~planJobs.([\dancehallKick], (
        activeProfile: \thickClub,
        samplesPerEngine: 1,
        enabledEngines: [\dancehallKick],
        macros: (weight: 1, punch: 0.5, brightness: 0.5, tail: 0.5, dirt: 0.5)
    ));
    assert.(
        macroJobs[0][\parameters][\amp]
            > customJobs[0][\parameters][\amp],
        "weight macro should increase effective source weight"
    );
    variationJob = ~makeVariationJob.(
        thickJobs[0],
        (pitch: true, envelope: false, texture: false, dirt: true),
        0.25,
        990011,
        1,
        (activeProfile: \thickClub)
    );
    repeatVariation = ~makeVariationJob.(
        thickJobs[0],
        (pitch: true, envelope: false, texture: false, dirt: true),
        0.25,
        990011,
        1,
        (activeProfile: \thickClub)
    );
    assert.(variationJob[\custom] == true, "variations should be exact custom jobs");
    assert.(
        variationJob[\parameters][\frequency]
            == thickJobs[0][\parameters][\frequency],
        "pitch lock should preserve frequency"
    );
    assert.(
        variationJob[\parameters][\drive]
            == thickJobs[0][\parameters][\drive],
        "dirt lock should preserve drive"
    );
    assert.(
        variationJob[\parameters] == repeatVariation[\parameters],
        "a variation should be reproducible from its mutation seed"
    );
    assert.(
        variationJob[\filename] == "DHKICKV_001.wav",
        "variation filenames should remain MPC-safe"
    );

    session = ~newDrumSession.((
        activeProfile: \original,
        samplesPerEngine: 2,
        enabledEngines: [\kick],
        engineCounts: nil
    ));
    sessionJobs = session[\plan].value(nil);
    assert.(sessionJobs.size == 2, "session options should be independently plannable");

    sessionOptions = (
        activeProfile: \thickClub,
        randomSeed: 26071986,
        samplesPerEngine: 2,
        enabledEngines: [\dancehallKick, \grimeSnare],
        engineCounts: (dancehallKick: 3, grimeSnare: 2),
        macros: (
            weight: 0.7, punch: 0.6, brightness: 0.4,
            tail: 0.5, dirt: 0.3
        ),
        masterAmp: 0.92,
        maxConcurrentRenders: 2
    );
    favorite = (
        job: thickJobs[0].deepCopy,
        outputPath: projectRoot +/+ "output/MISSING_TEST_FAVORITE.wav",
        effectiveParameters: thickJobs[0][\parameters].deepCopy
    );
    favorite[\effectiveParameters][\amp] = 0.61;
    sessionPath = PathName.tmp +/+ "sc-mpc-drum-lab-smoke-session.json";
    ~removeFileIfExists.(sessionPath);
    labSession = ~saveDrumLabSession.(
        sessionPath, sessionOptions, [favorite], "Smoke Session"
    );
    loadedSession = ~loadDrumLabSession.(sessionPath);
    assert.(
        loadedSession[\schemaVersion] == 1,
        "saved sessions should use the supported schema"
    );
    assert.(
        loadedSession[\options][\engineCounts][\dancehallKick] == 3,
        "session loading should preserve per-family counts"
    );
    assert.(
        loadedSession[\favorites].size == 1,
        "session loading should preserve favorites"
    );
    favoriteRecipe = ~favoriteKitRecipe.(
        loadedSession[\favorites], \thickClub
    );
    assert.(
        favoriteRecipe[\jobs][0][\filename] == "A01_DHKICK.WAV",
        "favorite recipes should use pad-oriented filenames"
    );
    assert.(
        favoriteRecipe[\jobs][0][\parameters][\amp] == 0.61,
        "favorite recipes should preserve effective amplitude"
    );
    assert.(
        favoriteRecipe[\options][\masterAmp] == 1.0,
        "effective favorite parameters should not be scaled twice"
    );
    favoriteList = List[
        favorite.deepCopy,
        favorite.deepCopy
    ];
    favoriteList[0][\outputPath] = "first.wav";
    favoriteList[1][\outputPath] = "second.wav";
    assert.(
        ~moveDrumLabFavorite.(favoriteList, 0, 1) == 1,
        "favorite pads should move to a valid adjacent slot"
    );
    assert.(
        favoriteList[0][\outputPath] == "second.wav"
            and: { favoriteList[1][\outputPath] == "first.wav" },
        "moving a favorite should preserve and reorder both entries"
    );
    assert.(
        ~moveDrumLabFavorite.(favoriteList, 0, -1).isNil,
        "favorite pads should not move outside the 16-pad sequence"
    );
    assert.(
        ~drumLabFavoritePadLabel.(nil, 0) == "A01\nEmpty",
        "empty pads should have clear MPC-oriented labels"
    );
    ~removeFileIfExists.(sessionPath);

    filenames = thickJobs.collect { |job| job[\filename] };
    assert.(
        filenames.asSet.size == filenames.size,
        "planned filenames should be unique"
    );
    assertThrows.({
        ~validateRenderJobs.([(
            family: \kick,
            engine: \experimentalKick,
            parameters: (),
            filename: "../UNSAFE.wav",
            duration: 1
        )]);
    }, "job validation should reject directory traversal");
    assertThrows.({
        ~validateRenderJobs.([
            thickJobs[0].copy,
            thickJobs[0].copy
        ]);
    }, "job validation should reject duplicate filenames");
    originalPump = ~pumpJobQueue;
    originalWriteEntry = ~writeManifestEntry;
    settlementState = (
        jobs: [thickJobs[0]],
        run: (),
        active: 1,
        processed: 0,
        completed: 0,
        failures: List.new,
        settled: Set.new
    );
    protect {
        ~pumpJobQueue = { };
        ~writeManifestEntry = {
            Error("simulated manifest failure").throw;
        };
        ~settleGenerationJob.(settlementState, 0, true, (
            outputPath: "test.wav",
            validation: (),
            finalParameters: ()
        ));
        ~settleGenerationJob.(settlementState, 0, false, (
            message: "duplicate callback"
        ));
    } {
        ~pumpJobQueue = originalPump;
        ~writeManifestEntry = originalWriteEntry;
    };
    assert.(
        settlementState[\active] == 0
            and: { settlementState[\processed] == 1 }
            and: { settlementState[\completed] == 1 },
        "job settlement should happen exactly once after callback failures"
    );
    assert.(
        settlementState[\failures].size == 1,
        "manifest failures should be recorded without stalling the scheduler"
    );
    assert.(
        ~drumDefs[\experimentalKick].notNil
        and: { ~drumDefs[\thickClubKick].notNil }
        and: { ~drumDefs[\clubTom].notNil }
        and: { ~drumDefs[\woodRim].notNil }
        and: { ~drumDefs[\closedHat].notNil }
        and: { ~drumDefs[\clubShaker].notNil },
        "original and profile engines should coexist"
    );
    assert.(
        thickJobs.select { |job|
            [\gqomPerc, \gqomTom, \dancehallRim,
                \grimeHat, \dancehallShaker].includes(job[\family])
        }.size == 30,
        "half of the thickClub pack should be percussion"
    );

    "SC MPC Drum Lab smoke tests passed.".postln;
    0.exit;
} { |error|
    error.reportError;
    1.exit;
};
)
