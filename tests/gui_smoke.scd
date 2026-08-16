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
        var browser, options, window;
        window = ~openDrumLab.();
        if(window.isNil) {
            Error("GUI smoke test failed: no Window was returned.").throw;
        };
        options = (
            activeProfile: \thickClub,
            randomSeed: 26071986,
            samplesPerEngine: 8,
            enabledEngines: [\dancehallKick],
            engineCounts: (dancehallKick: 8),
            macros: (
                weight: 0.5, punch: 0.5, brightness: 0.5,
                tail: 0.5, dirt: 0.5
            )
        );
        browser = ~openCandidateBrowser.(\dancehallKick, options);
        if(browser.isNil) {
            Error("GUI smoke test failed: no candidate browser was returned.").throw;
        };
        "SC MPC Drum Lab GUI smoke test passed.".postln;
        browser.close;
        window.close;
        0.exit;
    } { |error|
        error.reportError;
        1.exit;
    };
}.defer;
)
