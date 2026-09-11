// Focused profiles reuse the validated core voices with intentional family
// selection and macro direction. They coexist with the broad original and
// thickClub profiles rather than replacing either.

(
~profiles[\dubTechno] = (
    displayName: "Dub Techno",
    description: "Weighty, spacious percussion for slow chord-driven rhythms.",
    defaults: (
        samplesPerEngine: 5,
        masterAmp: 0.90,
        macros: ~macroSnapshotOptions.(\heavy)[\macros],
        enabledEngines: [\gqomKick, \gqomTom, \gqomPerc, \dancehallRim, \dancehallShaker]
    )
);
~profiles[\electro] = (
    displayName: "Electro",
    description: "Punchy kicks, metallic timing voices, and crisp hats.",
    defaults: (
        samplesPerEngine: 5,
        masterAmp: 0.90,
        macros: ~macroSnapshotOptions.(\cutting)[\macros],
        enabledEngines: [\grimeKick, \dancehallSnare, \gqomPerc, \dancehallRim, \grimeHat]
    )
);
~profiles[\industrial] = (
    displayName: "Industrial",
    description: "Dense, degraded club percussion with hard transient detail.",
    defaults: (
        samplesPerEngine: 5,
        masterAmp: 0.88,
        macros: ~macroSnapshotOptions.(\wornTape)[\macros],
        enabledEngines: [\grimeKick, \grimeSnare, \gqomPerc, \gqomTom, \grimeHat]
    )
);
)
