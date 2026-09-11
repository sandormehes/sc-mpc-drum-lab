// Named 16-pad starting points. Templates are declarative: they select and
// order existing profile families without duplicating any synthesis ranges.

(
~kitTemplates = IdentityDictionary.new;

~registerDrumLabKitTemplate = { |name, definition|
    var counts, families;
    if(name.isKindOf(Symbol).not or: { definition.isKindOf(Dictionary).not }) {
        Error("Kit templates need a symbol name and an Event definition.").throw;
    };
    families = definition[\families];
    counts = definition[\engineCounts];
    if(families.isArray.not or: { families.isEmpty }
        or: { counts.isKindOf(Dictionary).not }) {
        Error("Kit template needs ordered families and engine counts.").throw;
    };
    if(families.asSet.size != families.size) {
        Error("Kit template " ++ name ++ " cannot repeat a family.").throw;
    };
    if(families.sum { |family| counts[family] ? 0 } != 16) {
        Error("Kit template " ++ name ++ " must contain exactly 16 pads.").throw;
    };
    families.do { |family|
        if(~generatorSpecs[family].isNil or: { counts[family].isInteger.not }
            or: { counts[family] <= 0 }) {
            Error("Kit template has an invalid family: " ++ family).throw;
        };
    };
    ~kitTemplates[name] = definition.deepCopy;
    definition;
};

~kitTemplateOptions = { |name, overrides|
    var definition, options;
    definition = ~kitTemplates[name];
    if(definition.isNil) { Error("Unknown kit template: " ++ name).throw };
    options = (
        activeProfile: definition[\activeProfile],
        samplesPerEngine: 1,
        engineCounts: definition[\engineCounts].deepCopy,
        enabledEngines: definition[\families].deepCopy,
        macros: definition[\macros].deepCopy
    );
    if(overrides.notNil) {
        overrides.keysValuesDo { |key, value| options[key] = value.deepCopy };
    };
    options;
};

~listKitTemplates = {
    ~kitTemplates.keys.asArray.sort.do { |name|
        var template;
        template = ~kitTemplates[name];
        (name.asCompileString ++ " - " ++ template[\label]
            ++ ": " ++ template[\description]).postln;
    };
};

~dryRunKitTemplate = { |name, overrides|
    ~dryRun.(nil, ~kitTemplateOptions.(name, overrides));
};

~startKitTemplate = { |name, overrides|
    ~start.(nil, ~kitTemplateOptions.(name, overrides));
};

~registerDrumLabKitTemplate.(\dancehall16, (
    label: "Dancehall 16",
    description: "Four kicks, compact snares, rims, shakers, and hats.",
    activeProfile: \thickClub,
    families: [
        \dancehallKick, \dancehallSnare, \dancehallRim,
        \dancehallShaker, \grimeHat
    ],
    engineCounts: (
        dancehallKick: 4, dancehallSnare: 3, dancehallRim: 3,
        dancehallShaker: 3, grimeHat: 3
    ),
    macros: nil
));

~registerDrumLabKitTemplate.(\grime16, (
    label: "Grime 16",
    description: "Hard kicks and snares with hats, rims, and dark accents.",
    activeProfile: \thickClub,
    families: [
        \grimeKick, \grimeSnare, \grimeHat, \dancehallRim, \gqomPerc
    ],
    engineCounts: (
        grimeKick: 4, grimeSnare: 4, grimeHat: 4,
        dancehallRim: 2, gqomPerc: 2
    ),
    macros: nil
));

~registerDrumLabKitTemplate.(\gqom16, (
    label: "Gqom 16",
    description: "Low kicks and toms with sparse dark percussion.",
    activeProfile: \thickClub,
    families: [
        \gqomKick, \gqomTom, \gqomPerc, \dancehallRim, \dancehallShaker
    ],
    engineCounts: (
        gqomKick: 4, gqomTom: 4, gqomPerc: 4,
        dancehallRim: 2, dancehallShaker: 2
    ),
    macros: nil
));

~registerDrumLabKitTemplate.(\dubTechno16, (
    label: "Dub Techno 16",
    description: "Subby kicks and toms with spacious metal, rims, and shaker motion.",
    activeProfile: \dubTechno,
    families: [\gqomKick, \gqomTom, \gqomPerc, \dancehallRim, \dancehallShaker],
    engineCounts: (gqomKick: 4, gqomTom: 3, gqomPerc: 3, dancehallRim: 3, dancehallShaker: 3),
    macros: ~macroSnapshotOptions.(\heavy)[\macros]
));

~registerDrumLabKitTemplate.(\electro16, (
    label: "Electro 16",
    description: "Fast, punchy drum-machine foundations with metal and hats.",
    activeProfile: \electro,
    families: [\grimeKick, \dancehallSnare, \gqomPerc, \dancehallRim, \grimeHat],
    engineCounts: (grimeKick: 4, dancehallSnare: 3, gqomPerc: 3, dancehallRim: 2, grimeHat: 4),
    macros: ~macroSnapshotOptions.(\cutting)[\macros]
));

~registerDrumLabKitTemplate.(\industrial16, (
    label: "Industrial 16",
    description: "Driven kicks and snares with dark, degraded metallic detail.",
    activeProfile: \industrial,
    families: [\grimeKick, \grimeSnare, \gqomPerc, \gqomTom, \grimeHat],
    engineCounts: (grimeKick: 4, grimeSnare: 4, gqomPerc: 3, gqomTom: 2, grimeHat: 3),
    macros: ~macroSnapshotOptions.(\wornTape)[\macros]
));

~registerDrumLabKitTemplate.(\ping16, (
    label: "Ping 16",
    description: "Sonar sweeps, glassy resonators, and clipped digital pings.",
    activeProfile: \ping,
    families: [\sonarPing, \crystalPing, \packetPing],
    engineCounts: (sonarPing: 6, crystalPing: 6, packetPing: 4),
    macros: nil
));
)
