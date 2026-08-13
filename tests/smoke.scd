// Language-only smoke tests. No audio files are rendered.

(
var assert, filenames, originalJobs, projectRoot, thickJobs;

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
