// SC MPC Drum Lab
// Evaluate this entire file once. Then run: ~start.();

(
var root;
var sourcePath;
var loadProject;

loadProject = { |projectDirectory|
    var configPath;

    configPath = projectDirectory +/+ "config.scd";

    if(PathName(configPath).isFile.not) {
        Error(
            "The selected folder is not sc-mpc-drum-lab: "
            ++ configPath ++ " was not found."
        ).throw;
    };

    root = projectDirectory;
    ~projectRoot = root;

    (root +/+ "config.scd").load;
    (root +/+ "lib/processing.scd").load;

    (root +/+ "synthdefs/kick.scd").load;
    (root +/+ "synthdefs/snare.scd").load;
    (root +/+ "synthdefs/metal.scd").load;
    (root +/+ "synthdefs/glitch.scd").load;
    (root +/+ "synthdefs/resonator.scd").load;

    (root +/+ "lib/renderer.scd").load;
    (root +/+ "lib/manifest.scd").load;
    (root +/+ "presets/presets.scd").load;
    (root +/+ "lib/generator.scd").load;

    "".postln;
    "SC MPC Drum Lab loaded.".postln;
    ("Output: " ++ ~config[\outputDirectory]).postln;
    "Run ~start.() to generate a pack.".postln;
    "Run ~renderPreset.(\\deepKick) to export one preset.".postln;

    if(~config[\autoStart]) {
        ~start.();
    };
};

// nowExecutingPath is available when main.scd is loaded as a file. Some IDE
// evaluation modes return nil; in that case ask for the repository folder.
sourcePath = thisProcess.nowExecutingPath;

if(sourcePath.notNil) {
    loadProject.(PathName(sourcePath).pathOnly);
} {
    "Select the sc-mpc-drum-lab folder in the dialog.".postln;

    FileDialog(
        { |selectedDirectory|
            {
                loadProject.(selectedDirectory);
            }.defer;
        },
        {
            "Project loading cancelled.".warn;
        },
        fileMode: 2,
        stripResult: true,
        path: Platform.userHomeDir
    );
};
)

~start.();
