// Render the focused percussion voices and exercise promotion, validation,
// concurrency, and manifests.

(
var projectRoot;

try {
    projectRoot = File.realpath(
        PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".."
    );
    (projectRoot +/+ "main.scd").load;

    ~config[\activeProfile] = \thickClub;
    ~config[\samplesPerEngine] = 1;
    ~config[\maxConcurrentRenders] = 2;
    ~start.([\gqomTom, \dancehallRim, \grimeHat, \dancehallShaker]);

    Routine({
        var exportDirectory, favorites, passed, recipe, replayJobs;
        while({ ~generationRunning == true }, { 0.1.wait });

        recipe = ~recipePath.load;
        replayJobs = ~planJobs.(nil, recipe[\options]);
        favorites = [
            (
                job: ~generationState[\jobs][0],
                outputPath: ~currentRunDirectory +/+ "GQTOM_001.wav"
            ),
            (
                job: ~generationState[\jobs][1],
                outputPath: ~currentRunDirectory +/+ "DHRIM_001.wav"
            )
        ];
        exportDirectory = ~exportDrumLabFavorites.(favorites);

        passed = ~generationState.notNil
            and: { ~generationState[\failures].isEmpty }
            and: { ~generationState[\completed] == 4 }
            and: {
                File.exists(~currentRunDirectory +/+ "GQTOM_001.wav")
            }
            and: {
                File.exists(~currentRunDirectory +/+ "DHRIM_001.wav")
            }
            and: {
                File.exists(~currentRunDirectory +/+ "GRHAT_001.wav")
            }
            and: {
                File.exists(~currentRunDirectory +/+ "DHSHAKE_001.wav")
            }
            and: { recipe[\kind] == \pack }
            and: { replayJobs.size == 4 }
            and: {
                File.exists(exportDirectory +/+ "A01_GQTOM.WAV")
            }
            and: {
                File.exists(exportDirectory +/+ "A02_DHRIM.WAV")
            }
            and: {
                File.exists(exportDirectory +/+ "favorites_manifest.txt")
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
