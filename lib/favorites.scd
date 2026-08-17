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
                mutationAmount: favorite[\job][\mutationAmount]
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
            ++ prefix ++ status;
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
