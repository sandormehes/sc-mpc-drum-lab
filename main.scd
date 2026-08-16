// SC MPC Drum Lab
// Evaluate this entire file once. Rendering starts only when requested.

(
var loadProject;
var sourcePath;

loadProject = { |projectDirectory|
    var configPath, profilePaths;

    configPath = projectDirectory +/+ "config.scd";
    if(PathName(configPath).isFile.not) {
        Error(
            "The selected folder is not sc-mpc-drum-lab: "
            ++ configPath ++ " was not found."
        ).throw;
    };

    ~projectRoot = projectDirectory;

    // Configuration and shared processing.
    (projectDirectory +/+ "config.scd").load;
    (projectDirectory +/+ "lib/processing.scd").load;

    // Synthesis engines.
    (projectDirectory +/+ "synthdefs/kick.scd").load;
    (projectDirectory +/+ "synthdefs/snare.scd").load;
    (projectDirectory +/+ "synthdefs/metal.scd").load;
    (projectDirectory +/+ "synthdefs/glitch.scd").load;
    (projectDirectory +/+ "synthdefs/resonator.scd").load;
    (projectDirectory +/+ "synthdefs/club_perc.scd").load;

    // Rendering and generation system.
    (projectDirectory +/+ "lib/renderer.scd").load;
    (projectDirectory +/+ "lib/manifest.scd").load;
    (projectDirectory +/+ "presets/presets.scd").load;
    (projectDirectory +/+ "lib/generator.scd").load;

    // Profiles register additional engines, ranges, and defaults. Loading all
    // profile files is safe because profiles do not activate themselves.
    profilePaths = (projectDirectory +/+ "profiles/*.scd").pathMatch.sort;
    profilePaths.do { |profilePath| profilePath.load };

    ~activateProfile.(~config[\activeProfile]);
    (projectDirectory +/+ "lib/gui.scd").load;

    "".postln;
    "SC MPC Drum Lab loaded.".postln;
    ("Version: " ++ ~runtimeConfig[\projectVersion]).postln;
    ("Profile: " ++ ~activeProfileDefinition[\displayName]).postln;
    ("Output root: " ++ ~runtimeConfig[\outputDirectory]).postln;

    if(~runtimeConfig[\autoStart]) {
        "Starting sample generation...".postln;
        ~start.();
    } {
        "Run ~openDrumLab.() for the control panel.".postln;
        "Run ~dryRun.() to inspect the plan.".postln;
        "Run ~start.() to generate the sample pack.".postln;
    };

    if(~runtimeConfig[\openGuiOnLoad]) {
        { ~openDrumLab.() }.defer;
    };
};

sourcePath = thisProcess.nowExecutingPath;

if(sourcePath.notNil) {
    loadProject.(PathName(sourcePath).pathOnly);
} {
    "Select the sc-mpc-drum-lab folder.".postln;
    FileDialog(
        { |selectedDirectory|
            { loadProject.(selectedDirectory) }.defer;
        },
        { "Project loading cancelled.".warn },
        fileMode: 2,
        stripResult: true,
        path: Platform.userHomeDir
    );
};
)

~openDrumLab.()