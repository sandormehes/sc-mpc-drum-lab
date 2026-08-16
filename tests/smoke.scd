// Language-only smoke tests. No audio files are rendered.

(
var assert, customJobs, filenames, macroJobs, originalJobs, projectRoot;
var repeatJobs, selectedJobs, session, sessionJobs, thickJobs;

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

    session = ~newDrumSession.((
        activeProfile: \original,
        samplesPerEngine: 2,
        enabledEngines: [\kick],
        engineCounts: nil
    ));
    sessionJobs = session[\plan].value(nil);
    assert.(sessionJobs.size == 2, "session options should be independently plannable");

    filenames = thickJobs.collect { |job| job[\filename] };
    assert.(
        filenames.asSet.size == filenames.size,
        "planned filenames should be unique"
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
