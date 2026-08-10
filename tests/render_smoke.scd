// Render two samples concurrently and exercise promotion, validation, and manifests.

(
var projectRoot;

try {
    projectRoot = File.realpath(
        PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".."
    );
    (projectRoot +/+ "main.scd").load;

    ~config[\activeProfile] = \thickClub;
    ~config[\samplesPerEngine] = 2;
    ~config[\maxConcurrentRenders] = 2;
    ~start.([\dancehallKick]);

    Routine({
        var passed;
        while({ ~generationRunning == true }, { 0.1.wait });

        passed = ~generationState.notNil
            and: { ~generationState[\failures].isEmpty }
            and: { ~generationState[\completed] == 2 }
            and: {
                File.exists(~currentRunDirectory +/+ "DHKICK_001.wav")
            }
            and: {
                File.exists(~currentRunDirectory +/+ "DHKICK_002.wav")
            };

        if(passed) {
            "SC MPC Drum Lab render smoke test passed.".postln;
            0.exit;
        } {
            "SC MPC Drum Lab render smoke test failed.".error;
            if(~generationState.notNil) {
                ~generationState[\failures].postln;
            };
            1.exit;
        };
    }).play(AppClock);
} { |error|
    error.reportError;
    1.exit;
};
)
