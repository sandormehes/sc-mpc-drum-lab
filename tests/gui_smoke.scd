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
        var browser, kitBuilder, options, restored, session, window;
        window = ~openDrumLab.();
        if(window.isNil) {
            Error("GUI smoke test failed: no Window was returned.").throw;
        };
        options = (
            activeProfile: \thickClub,
            randomSeed: 112233,
            samplesPerEngine: 8,
            enabledEngines: [\dancehallKick, \grimeSnare],
            engineCounts: (dancehallKick: 3, grimeSnare: 5),
            macros: (
                weight: 0.72, punch: 0.61, brightness: 0.43,
                tail: 0.54, dirt: 0.25
            )
        );
        session = ~makeDrumLabSession.(options, [], "GUI Restore Smoke");
        ~applyDrumLabSessionToGui.(session);
        if(~currentDrumLabGuiOptions.isNil) {
            Error("GUI smoke test failed: state inspection hook was cleared.").throw;
        };
        restored = ~currentDrumLabGuiOptions.();
        if(restored.isNil) {
            Error("GUI smoke test failed: restored controls selected no families.").throw;
        };
        if(restored[\randomSeed] != 112233) {
            Error("GUI smoke test failed: seed was not restored.").throw;
        };
        if(restored[\engineCounts][\dancehallKick] != 3
            or: { restored[\engineCounts][\grimeSnare] != 5 }) {
            Error("GUI smoke test failed: family counts were not restored.").throw;
        };
        if((restored[\macros][\weight] - 0.72).abs > 0.001) {
            Error("GUI smoke test failed: macros were not restored.").throw;
        };
        browser = ~openCandidateBrowser.(\dancehallKick, options);
        if(browser.isNil) {
            Error("GUI smoke test failed: no candidate browser was returned.").throw;
        };
        kitBuilder = ~openFavoriteKitBuilder.(
            ~drumLabFavorites, \thickClub
        );
        if(kitBuilder.isNil) {
            Error("GUI smoke test failed: no favorite kit builder was returned.").throw;
        };
        "SC MPC Drum Lab GUI smoke test passed.".postln;
        kitBuilder.close;
        browser.close;
        window.close;
        0.exit;
    } { |error|
        error.reportError;
        1.exit;
    };
}.defer;
)
