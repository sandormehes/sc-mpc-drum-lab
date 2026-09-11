// Named musical directions. Snapshots are plain data so they work from the
// command line, kit templates, saved sessions, and the control panel.

(
~macroSnapshots = IdentityDictionary.new;

~registerMacroSnapshot = { |name, definition|
    var macros;
    if(name.isKindOf(Symbol).not or: { definition.isKindOf(Dictionary).not }) {
        Error("Macro snapshots need a symbol name and an Event definition.").throw;
    };
    macros = definition[\macros];
    if(macros.isKindOf(Dictionary).not) {
        Error("Macro snapshots need a macros Event.").throw;
    };
    macros.keysValuesDo { |key, value|
        if([\weight, \punch, \brightness, \tail, \dirt].includes(key).not
            or: { value.isNumber.not }
            or: { value < 0 or: { value > 1 } }) {
            Error("Macro snapshot contains an invalid value: " ++ key).throw;
        };
    };
    ~macroSnapshots[name] = definition.deepCopy;
};

~macroSnapshotOptions = { |name, overrides|
    var definition, options;
    definition = ~macroSnapshots[name];
    if(definition.isNil) { Error("Unknown macro snapshot: " ++ name).throw };
    options = (macros: definition[\macros].deepCopy);
    if(overrides.notNil) {
        overrides.keysValuesDo { |key, value| options[key] = value.deepCopy };
    };
    options;
};

~listMacroSnapshots = {
    ~macroSnapshots.keys.asArray.sort.do { |name|
        var definition;
        definition = ~macroSnapshots[name];
        (name.asCompileString ++ " - " ++ definition[\label] ++ ": "
            ++ definition[\description]).postln;
    };
};

~registerMacroSnapshot.(\heavy, (
    label: "Heavy",
    description: "More weight and tail with a restrained top end.",
    macros: (weight: 0.82, punch: 0.62, brightness: 0.38, tail: 0.70, dirt: 0.42)
));
~registerMacroSnapshot.(\cutting, (
    label: "Cutting",
    description: "Sharper transient and brighter articulation.",
    macros: (weight: 0.48, punch: 0.82, brightness: 0.78, tail: 0.35, dirt: 0.30)
));
~registerMacroSnapshot.(\wornTape, (
    label: "Worn Tape",
    description: "Softer attack, compact tail, and deliberate degradation.",
    macros: (weight: 0.62, punch: 0.38, brightness: 0.35, tail: 0.42, dirt: 0.82)
));
)
