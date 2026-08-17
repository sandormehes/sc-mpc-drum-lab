// Friendly launcher: evaluate this entire file to load the project and open
// the native SC MPC Drum Lab control panel.

(
var chooseProject, launch, projectRoot, sourcePath;

launch = { |root|
    var mainPath;
    mainPath = root +/+ "main.scd";
    if(File.exists(mainPath).not) {
        Error("Could not find main.scd in " ++ root).throw;
    };
    mainPath.load;
    { ~openDrumLab.() }.defer;
};

sourcePath = thisProcess.nowExecutingPath;
if(sourcePath.isNil) {
    sourcePath = \ScIDE.asClass.tryPerform(\currentPath);
};
if(sourcePath.isNil and: { \Document.asClass.notNil }) {
    sourcePath = \Document.asClass.tryPerform(\current)
        .tryPerform(\path);
};

if(sourcePath.notNil) {
    projectRoot = PathName(sourcePath).pathOnly;
};

if(projectRoot.notNil
    and: { File.exists(projectRoot +/+ "main.scd") }) {
    launch.(projectRoot);
} {
    chooseProject = {
        Dialog.openPanel({ |mainPath|
            {
                if(PathName(mainPath).fileName != "main.scd") {
                    Error("Select this project's main.scd file.").throw;
                };
                launch.(PathName(mainPath).pathOnly);
            }.defer;
        }, {
            "SC MPC Drum Lab launch cancelled.".postln;
        }, path: File.getcwd);
    };
    {
        "Choose the SC MPC Drum Lab main.scd file once to locate the project."
            .postln;
        chooseProject.();
    }.defer;
};
)
