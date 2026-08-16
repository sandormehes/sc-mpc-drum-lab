// Optional local GUI smoke test. It opens and immediately closes the control
// panel; use it only in a graphical desktop session.

(
var projectRoot;
projectRoot = File.realpath(
    PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".."
);
(projectRoot +/+ "main.scd").load;

{
    try {
        var window;
        window = ~openDrumLab.();
        if(window.isNil) {
            Error("GUI smoke test failed: no Window was returned.").throw;
        };
        "SC MPC Drum Lab GUI smoke test passed.".postln;
        window.close;
        0.exit;
    } { |error|
        error.reportError;
        1.exit;
    };
}.defer;
)
