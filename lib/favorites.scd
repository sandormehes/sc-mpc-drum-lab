// Favorite-kit domain operations. These functions intentionally have no GUI
// dependencies so command workflows and tests can use them directly.

(
~mpcPadCoordinates = { |index|
    var column, row;
    if(index.isInteger.not or: { index < 0 or: { index > 15 } }) {
        Error("MPC pad indexes must be between 0 and 15.").throw;
    };
    column = (index % 4) + 1;
    row = (index / 4).floor + 1;
    (pad: "A" ++ ~zeroPadNumber.(index + 1, 2), row: row, column: column);
};

~writeMpcFavoriteMetadata = { |directory, favorites, filenames|
    var csv, map, mapPath, csvPath;
    mapPath = directory +/+ "MPC1000_PROGRAM_MAP.txt";
    csvPath = directory +/+ "MPC_KEYGROUP_MAP.csv";
    map = File(mapPath, "w");
    csv = File(csvPath, "w");
    if(map.isOpen.not or: { csv.isOpen.not }) {
        if(map.isOpen) { map.close };
        if(csv.isOpen) { csv.close };
        Error("Cannot create MPC metadata files.").throw;
    };
    protect {
        map.write("SC MPC DRUM LAB — MPC1000 PROGRAM MAP\n");
        map.write("Import the matching WAV files into an MPC program, assigning each file to the listed pad.\n");
        map.write("All samples are one-shot, mono 44.1 kHz / 16-bit WAV files.\n\n");
        csv.write("pad,row,column,wav,family,rating,tags\n");
        favorites.do { |favorite, index|
            var location, tags;
            location = ~mpcPadCoordinates.(index);
            tags = (favorite[\tags] ? []).collect(_.asString).join("|");
            map.write(location[\pad] ++ "  row " ++ location[\row]
                ++ ", column " ++ location[\column] ++ "  "
                ++ filenames[index] ++ "  " ++ favorite[\job][\family]
                ++ "\n");
            csv.write(location[\pad] ++ "," ++ location[\row] ++ ","
                ++ location[\column] ++ "," ++ filenames[index] ++ ","
                ++ favorite[\job][\family] ++ ","
                ++ (favorite[\rating] ? "") ++ "," ++ tags ++ "\n");
        };
    } {
        map.close;
        csv.close;
    };
    (programMap: mapPath, keygroupMap: csvPath);
};

// Reuse this options Event when preparing source WAVs for a sampler and no
// kit-level gain match is wanted.
~dryExportOptions = { (kitBalanceMode: \off) };

~exportDrumLabFavorites = { |favorites, options|
    var baseName, candidate, counter, file, filenames, metadata, missing;
    var outputRoot, recipe, writeMpcMetadata;
    if(favorites.isNil or: { favorites.isEmpty }) {
        Error("There are no favorite previews to export.").throw;
    };
    if(favorites.size > 16) {
        Error("A favorites kit can contain at most 16 samples.").throw;
    };
    missing = favorites.count { |favorite|
        favorite[\outputPath].isNil
            or: { File.exists(favorite[\outputPath]).not }
    };
    if(missing > 0) {
        Error(missing ++ " favorite source file(s) are unavailable. "
            ++ "Use Rebuild exact kit instead.").throw;
    };
    outputRoot = ~runtimeConfig[\outputDirectory] ? ~config[\outputDirectory];
    baseName = Date.getDate.asSortableString ++ "_favorites";
    candidate = outputRoot +/+ baseName;
    counter = 2;
    while({ File.exists(candidate) }, {
        candidate = outputRoot +/+ (baseName ++ "_" ++ counter);
        counter = counter + 1;
    });
    File.mkdir(candidate);
    filenames = List.new;
    writeMpcMetadata = if(options.notNil and: { options[\mpcMetadata].notNil }) {
        options[\mpcMetadata]
    } {
        (~runtimeConfig[\exportMpcMetadata] ? ~config[\exportMpcMetadata]) ? true
    };

    file = File(candidate +/+ "favorites_manifest.txt", "w");
    if(file.isOpen.not) {
        Error("Cannot create favorites manifest.").throw;
    };
    protect {
        file.write("SC MPC DRUM LAB FAVORITES\n");
        favorites.do { |favorite, index|
            var destination, filename, prefix;
            prefix = ~generatorSpecs[favorite[\job][\family]][\prefix]
                ? "SOUND";
            filename = "A" ++ ~zeroPadNumber.(index + 1, 2)
                ++ "_" ++ prefix ++ ".WAV";
            destination = candidate +/+ filename;
            File.copy(favorite[\outputPath], destination);
            if(File.exists(destination).not) {
                Error("Could not export favorite: " ++ filename).throw;
            };
            filenames.add(filename);
            file.write((
                pad: index + 1,
                filename: filename,
                family: favorite[\job][\family],
                source: favorite[\outputPath],
                parameters: favorite[\job][\parameters],
                variationOf: favorite[\job][\variationOf],
                locks: favorite[\job][\locks],
                mutationAmount: favorite[\job][\mutationAmount],
                rating: favorite[\rating],
                tags: favorite[\tags] ? []
            ).asCompileString ++ "\n");
        };
    } {
        file.close;
    };
    recipe = ~favoriteKitRecipe.(favorites, ~activeProfile);
    ~writeDrumLabDataFile.(candidate +/+ "favorites_recipe.json", recipe);
    if(writeMpcMetadata == true) {
        metadata = ~writeMpcFavoriteMetadata.(candidate, favorites, filenames);
    };
    candidate;
};

~drumLabFavoriteSourceAvailable = { |favorite|
    favorite.notNil
        and: { favorite[\outputPath].notNil }
        and: { File.exists(favorite[\outputPath]) };
};

// Curation metadata lives on a favorite rather than its source WAV: one sound
// can have a different role in each kit where it is kept.
~setDrumLabFavoriteRating = { |favorites, index, rating|
    var favorite;
    if(index.isInteger.not or: { index < 0 or: { index >= favorites.size } }
        or: { rating.isInteger.not } or: { rating < 1 or: { rating > 5 } }) {
        Error("Favorite ratings need a valid pad index and an integer from 1 to 5.").throw;
    };
    favorite = favorites[index];
    favorite[\rating] = rating;
    favorite;
};

~setDrumLabFavoriteTags = { |favorites, index, tags|
    var favorite, normalized;
    if(index.isInteger.not or: { index < 0 or: { index >= favorites.size } }
        or: { tags.isSequenceableCollection.not }) {
        Error("Favorite tags need a valid pad index and a collection of names.").throw;
    };
    normalized = tags.collect { |tag|
        if(tag.isKindOf(String).not and: { tag.isKindOf(Symbol).not }) {
            Error("Favorite tags must be strings or symbols.").throw;
        };
        tag.asString.toLower.replace(" ", "-")
    }.asSet.asArray.sort;
    favorite = favorites[index];
    favorite[\tags] = normalized;
    favorite;
};

~findDrumLabFavorites = { |favorites, criteria|
    var family, minimumRating, query, requiredTags;
    criteria = criteria ? ();
    family = criteria[\family];
    minimumRating = criteria[\minimumRating];
    query = criteria[\query];
    requiredTags = criteria[\tags] ? [];
    if(minimumRating.notNil and: {
        minimumRating.isInteger.not or: { minimumRating < 1 or: { minimumRating > 5 } }
    }) { Error("minimumRating must be an integer from 1 to 5.").throw };
    (favorites ? []).select { |favorite|
        var filename, missingTag, tags;
        tags = (favorite[\tags] ? []).collect { |tag| tag.asString.toLower };
        filename = (favorite[\job][\filename] ? "").asString.toLower;
        missingTag = requiredTags.detect { |tag|
            tags.includes(tag.asString.toLower).not
        };
        (family.isNil or: { favorite[\job][\family] == family })
        and: { minimumRating.isNil or: { (favorite[\rating] ? 0) >= minimumRating } }
        and: { missingTag.isNil }
        and: { query.isNil or: { filename.contains(query.asString.toLower) } }
    };
};

~drumLabFavoritePadLabel = { |favorite, index, selected = false|
    var padName, prefix, status;
    padName = "A" ++ ~zeroPadNumber.(index + 1, 2);
    if(favorite.isNil) {
        padName ++ "\nEmpty"
    } {
        prefix = ~generatorSpecs[favorite[\job][\family]][\prefix]
            ? favorite[\job][\family].asString.toUpper;
        status = if(~drumLabFavoriteSourceAvailable.(favorite)) {
            ""
        } {
            "  [REBUILD]"
        };
        (if(selected) { "> " } { "" }) ++ padName ++ "\n"
            ++ prefix ++ (if(favorite[\rating].notNil) {
                "  " ++ favorite[\rating] ++ "/5"
            } { "" }) ++ status;
    };
};

~moveDrumLabFavorite = { |favorites, index, offset|
    var result, target, temporary;
    result = nil;
    if(favorites.notNil
        and: { index.isInteger }
        and: { offset.isInteger }
        and: { index >= 0 }
        and: { index < favorites.size }) {
        target = index + offset;
        if(target >= 0 and: { target < favorites.size }) {
            temporary = favorites[index];
            favorites[index] = favorites[target];
            favorites[target] = temporary;
            result = target;
        };
    };
    result;
};
)
