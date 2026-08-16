// Friendly launcher: evaluate this entire file to load the project and open
// the native SC MPC Drum Lab control panel.

(
var projectRoot, sourcePath;
sourcePath = thisProcess.nowExecutingPath;

if(sourcePath.isNil) {
    Error("Save gui.scd inside the project before running it.").throw;
};

projectRoot = PathName(sourcePath).pathOnly;
(projectRoot +/+ "main.scd").load;
{ ~openDrumLab.() }.defer;
)
