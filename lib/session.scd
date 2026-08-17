// Versioned persistence for GUI state, curated favorites, and exact kit jobs.

(
~drumLabSessionSchemaVersion = 1;

~validateDrumLabSessionOptions = { |options|
    var counts, enabled, macros, profile;
    if(options.isKindOf(Dictionary).not) {
        Error("Session options must be an Event or Dictionary.").throw;
    };
    profile = ~profiles[options[\activeProfile]];
    if(profile.isNil) {
        Error("Session references an unknown profile: "
            ++ options[\activeProfile]).throw;
    };
    enabled = options[\enabledEngines];
    if(enabled.isArray.not or: { enabled.isEmpty }) {
        Error("Session must enable at least one sound family.").throw;
    };
    enabled.do { |engineName|
        if(~generatorSpecs[engineName].isNil) {
            Error("Session references an unknown family: " ++ engineName).throw;
        };
    };
    counts = options[\engineCounts];
    if(counts.notNil and: { counts.isKindOf(Dictionary).not }) {
        Error("Session family counts must be an Event or Dictionary.").throw;
    };
    macros = options[\macros];
    if(macros.notNil) {
        if(macros.isKindOf(Dictionary).not) {
            Error("Session macros must be an Event or Dictionary.").throw;
        };
        macros.keysValuesDo { |name, value|
            if([\weight, \punch, \brightness, \tail, \dirt].includes(name).not
                or: { value.isNumber.not }
                or: { value < 0 or: { value > 1 } }) {
                Error("Invalid session macro: " ++ name).throw;
            };
        };
    };
    options;
};

~validateDrumLabFavorites = { |favorites|
    favorites = favorites ? [];
    if(favorites.isSequenceableCollection.not) {
        Error("Session favorites must be a collection.").throw;
    };
    if(favorites.size > 16) {
        Error("A session can contain at most 16 favorites.").throw;
    };
    favorites.do { |favorite|
        var job;
        if(favorite.isKindOf(Dictionary).not) {
            Error("Invalid favorite entry in session.").throw;
        };
        job = favorite[\job];
        if(job.isKindOf(Dictionary).not
            or: { ~drumDefs[job[\engine]].isNil }
            or: { job[\parameters].isKindOf(Dictionary).not }) {
            Error("Session favorite contains an invalid render job.").throw;
        };
    };
    favorites;
};

~makeDrumLabSession = { |options, favorites, name|
    var favoriteCopies;
    ~validateDrumLabSessionOptions.(options);
    ~validateDrumLabFavorites.(favorites);
    favoriteCopies = List.new;
    (favorites ? []).do { |favorite|
        favoriteCopies.add(favorite.deepCopy);
    };
    (
        kind: \drumLabSession,
        schemaVersion: ~drumLabSessionSchemaVersion,
        projectVersion: ~config[\projectVersion],
        name: name ? "Untitled Drum Lab Session",
        savedAt: Date.getDate.asString,
        options: options.deepCopy,
        favorites: favoriteCopies
    );
};

~writeDrumLabDataFile = { |path, value|
    var file;
    if(path.isNil) { Error("No destination path was supplied.").throw };
    file = File(path, "w");
    if(file.isOpen.not) { Error("Cannot write file: " ++ path).throw };
    protect {
        file.write(value.asCompileString ++ "\n");
    } {
        file.close;
    };
    path;
};

~drumLabSessionPath = { |path|
    var extension;
    extension = PathName(path).extension ? "";
    if(extension.toLower != "scd") { path = path ++ ".scd" };
    path;
};

~saveDrumLabSession = { |path, options, favorites, name|
    var session;
    path = ~drumLabSessionPath.(path);
    session = ~makeDrumLabSession.(options, favorites, name);
    ~writeDrumLabDataFile.(path, session);
    session;
};

~loadDrumLabSession = { |path|
    var favorites, session;
    if(path.isNil or: { File.exists(path).not }) {
        Error("Session file was not found: " ++ path).throw;
    };
    session = path.load;
    if(session.isKindOf(Dictionary).not
        or: { session[\kind] != \drumLabSession }) {
        Error("The selected file is not a Drum Lab session.").throw;
    };
    if(session[\schemaVersion].isInteger.not
        or: { session[\schemaVersion] > ~drumLabSessionSchemaVersion }) {
        Error("This session was created by a newer, unsupported version.").throw;
    };
    ~validateDrumLabSessionOptions.(session[\options]);
    favorites = ~validateDrumLabFavorites.(session[\favorites]);
    session[\favorites] = List.new;
    favorites.do { |favorite|
        session[\favorites].add(favorite.deepCopy);
    };
    session;
};

~favoriteKitRecipe = { |favorites, profileName|
    var counts, families, jobs;
    ~validateDrumLabFavorites.(favorites);
    jobs = Array.newClear(favorites.size);
    families = List.new;
    counts = IdentityDictionary.new;

    favorites.do { |favorite, index|
        var family, filename, job, parameters, prefix, spec;
        job = favorite[\job];
        family = job[\family];
        spec = ~generatorSpecs[family];
        prefix = if(spec.notNil) { spec[\prefix] } { "SOUND" };
        filename = "A" ++ ~zeroPadNumber.(index + 1, 2)
            ++ "_" ++ prefix ++ ".WAV";
        parameters = favorite[\effectiveParameters]
            ? favorite[\finalParameters]
            ? job[\parameters];
        jobs[index] = (
            family: family,
            engine: job[\engine],
            parameters: parameters.deepCopy,
            filename: filename,
            duration: job[\duration],
            custom: true,
            favoriteKit: true,
            variationOf: job[\variationOf],
            locks: job[\locks],
            mutationAmount: job[\mutationAmount]
        );
        if(families.includes(family).not) { families.add(family) };
        counts[family] = (counts[family] ? 0) + 1;
    };

    (
        kind: \jobs,
        recipeRole: \favoriteKit,
        jobs: jobs,
        options: (
            activeProfile: profileName ? ~activeProfile ? ~config[\activeProfile],
            randomSeed: ~runtimeConfig[\randomSeed] ? ~config[\randomSeed],
            samplesPerEngine: 1,
            engineCounts: counts,
            enabledEngines: families.asArray,
            macros: nil,
            masterAmp: 1.0,
            maxConcurrentRenders: ~runtimeConfig[\maxConcurrentRenders]
                ? ~config[\maxConcurrentRenders]
        )
    );
};

~renderSessionFavorites = { |session|
    var recipe;
    if(session[\kind] != \drumLabSession) {
        Error("Expected a Drum Lab session.").throw;
    };
    recipe = ~favoriteKitRecipe.(
        session[\favorites], session[\options][\activeProfile]
    );
    ~startJobs.(recipe[\jobs], recipe[\options]);
};
)
