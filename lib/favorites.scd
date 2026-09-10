// Favorite-kit domain operations. These functions intentionally have no GUI
// dependencies so command workflows and tests can use them directly.

(
~exportDrumLabFavorites = { |favorites|
    var baseName, candidate, counter, file, missing, outputRoot, recipe;
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
        var filename, tags;
        tags = (favorite[\tags] ? []).collect { |tag| tag.asString.toLower };
        filename = (favorite[\job][\filename] ? "").asString.toLower;
        (family.isNil or: { favorite[\job][\family] == family })
        and: { minimumRating.isNil or: { (favorite[\rating] ? 0) >= minimumRating } }
        and: { requiredTags.every { |tag| tags.includes(tag.asString.toLower) } }
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
