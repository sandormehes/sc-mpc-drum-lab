// Native, dependency-free control panel for profile selection, family counts,
// previews, and generation progress.

(
~playRenderedFile = { |path|
    var server;
    if(path.isNil or: { File.exists(path).not }) {
        "Cannot preview: rendered file was not found.".warn;
    } {
        server = Server.default;
        server.waitForBoot {
            Buffer.read(server, path, action: { |buffer|
                {
                    if(~drumLabPreviewBuffer.notNil) {
                        ~drumLabPreviewBuffer.free;
                    };
                    ~drumLabPreviewBuffer = buffer;
                    buffer.play(
                        loop: false,
                        action: {
                            buffer.free;
                            if(~drumLabPreviewBuffer === buffer) {
                                ~drumLabPreviewBuffer = nil;
                            };
                        }
                    );
                }.defer;
            });
        };
        if(server.serverRunning.not) {
            "Booting the audio server for preview...".postln;
            server.boot;
        };
    };
};

~openFavoriteKitBuilder = { |favorites, profileName, onFavoritesChanged|
    var activeRebuild, builderListener, exportButton, leftButton;
    var missingCount, moveSelection, padButtons, playButton, rebuildButton;
    var rebuildJobs;
    var refresh, removeButton, rightButton, selectedIndex, selectionText;
    var setBusy, setStatus, statusText, window;

    favorites = favorites ? ~drumLabFavorites ? List.new;
    ~drumLabFavorites = favorites;
    if(~favoriteKitBuilderWindow.notNil) {
        try { ~favoriteKitBuilderWindow.close } { };
    };
    activeRebuild = false;
    padButtons = Array.newClear(16);
    selectedIndex = if(favorites.notEmpty) { 0 } { nil };

    window = Window(
        "Favorite Kit Builder",
        Rect(130, 70, 860, 650),
        resizable: false
    );
    ~favoriteKitBuilderWindow = window;

    StaticText(window, Rect(20, 14, 500, 30))
        .string_("Favorite Kit Builder")
        .font_(Font.default.boldVariant.size_(20));
    StaticText(window, Rect(20, 46, 810, 24))
        .string_("Arrange favorites in MPC pad order. Click a pad to select and audition it.");

    setStatus = { |message|
        { statusText.string = message }.defer;
    };
    setBusy = { |busy|
        {
            padButtons.do { |button| button.enabled = busy.not };
            playButton.enabled = busy.not and: { selectedIndex.notNil };
            leftButton.enabled = busy.not and: { selectedIndex.notNil }
                and: { selectedIndex > 0 };
            rightButton.enabled = busy.not and: { selectedIndex.notNil }
                and: { selectedIndex < (favorites.size - 1) };
            removeButton.enabled = busy.not and: { selectedIndex.notNil };
            exportButton.enabled = busy.not and: { favorites.notEmpty }
                and: { missingCount == 0 };
            rebuildButton.enabled = busy.not and: { favorites.notEmpty };
        }.defer;
    };

    refresh = {
        {
            var favorite, sourceState;
            if(selectedIndex.notNil and: { selectedIndex >= favorites.size }) {
                selectedIndex = if(favorites.notEmpty) {
                    favorites.size - 1
                } { nil };
            };
            missingCount = favorites.count { |item|
                ~drumLabFavoriteSourceAvailable.(item).not
            };
            padButtons.do { |button, index|
                favorite = if(index < favorites.size) { favorites[index] };
                button.states = [[~drumLabFavoritePadLabel.(
                    favorite, index, selectedIndex == index
                )]];
                button.toolTip = if(favorite.isNil) {
                    "Empty pad"
                } {
                    favorite[\job][\filename] ? "Favorite sound"
                };
            };
            favorite = if(selectedIndex.notNil) { favorites[selectedIndex] };
            sourceState = if(favorite.notNil) {
                if(~drumLabFavoriteSourceAvailable.(favorite)) {
                    "Source WAV ready"
                } {
                    "Source WAV missing — this pad can still be rebuilt exactly"
                }
            } {
                "Select a filled pad."
            };
            selectionText.string = if(favorite.notNil) {
                "A" ++ ~zeroPadNumber.(selectedIndex + 1, 2) ++ "  •  "
                    ++ (~generatorSpecs[favorite[\job][\family]][\label]
                        ? favorite[\job][\family].asString)
                    ++ "  •  " ++ sourceState
            } {
                sourceState
            };
            playButton.enabled = favorite.notNil
                and: { ~drumLabFavoriteSourceAvailable.(favorite) }
                and: { ~generationRunning != true };
            leftButton.enabled = selectedIndex.notNil
                and: { selectedIndex > 0 }
                and: { ~generationRunning != true };
            rightButton.enabled = selectedIndex.notNil
                and: { selectedIndex < (favorites.size - 1) }
                and: { ~generationRunning != true };
            removeButton.enabled = favorite.notNil
                and: { ~generationRunning != true };
            exportButton.enabled = favorites.notEmpty
                and: { missingCount == 0 }
                and: { ~generationRunning != true };
            rebuildButton.enabled = favorites.notEmpty
                and: { ~generationRunning != true };
        }.defer;
    };

    16.do { |index|
        var column, left, row, top;
        column = index % 4;
        row = (index / 4).floor;
        left = 20 + (column * 205);
        top = 82 + (row * 78);
        padButtons[index] = Button(window, Rect(left, top, 190, 64))
            .states_([[~drumLabFavoritePadLabel.(nil, index)]])
            .action_({
                var favorite;
                favorite = if(index < favorites.size) { favorites[index] };
                if(favorite.notNil) {
                    selectedIndex = index;
                    refresh.();
                    if(~drumLabFavoriteSourceAvailable.(favorite)) {
                        ~playRenderedFile.(favorite[\outputPath]);
                        setStatus.("Playing pad A"
                            ++ ~zeroPadNumber.(index + 1, 2) ++ ".");
                    } {
                        setStatus.("This source WAV is missing. Use Rebuild exact kit.");
                    };
                };
            });
    };

    StaticText(window, Rect(20, 402, 820, 20))
        .string_("Selected pad")
        .font_(Font.default.boldVariant);
    selectionText = StaticText(window, Rect(20, 426, 820, 42))
        .string_("Select a filled pad.");

    playButton = Button(window, Rect(20, 480, 130, 34))
        .states_([["Play selected"]])
        .action_({
            if(selectedIndex.notNil) {
                ~playRenderedFile.(favorites[selectedIndex][\outputPath]);
            };
        });

    moveSelection = { |offset|
        var newIndex;
        newIndex = ~moveDrumLabFavorite.(favorites, selectedIndex, offset);
        if(newIndex.notNil) {
            selectedIndex = newIndex;
            if(onFavoritesChanged.notNil) { onFavoritesChanged.value };
            refresh.();
            setStatus.("Moved selection to pad A"
                ++ ~zeroPadNumber.(selectedIndex + 1, 2) ++ ".");
        };
    };
    leftButton = Button(window, Rect(160, 480, 130, 34))
        .states_([["Move earlier"]])
        .action_({ moveSelection.(-1) });
    rightButton = Button(window, Rect(300, 480, 130, 34))
        .states_([["Move later"]])
        .action_({ moveSelection.(1) });
    removeButton = Button(window, Rect(440, 480, 130, 34))
        .states_([["Remove pad"]])
        .action_({
            var removed;
            if(selectedIndex.notNil) {
                removed = favorites.removeAt(selectedIndex);
                if(onFavoritesChanged.notNil) { onFavoritesChanged.value };
                refresh.();
                setStatus.("Removed " ++ removed[\job][\filename]
                    ++ " from the kit.");
            };
        });

    exportButton = Button(window, Rect(580, 480, 130, 34))
        .states_([["Export WAVs"]])
        .action_({
            try {
                var path;
                path = ~exportDrumLabFavorites.(favorites);
                setStatus.("Favorite kit exported to " ++ path);
                path.openOS;
            } { |error| setStatus.(error.errorString) };
        });
    rebuildButton = Button(window, Rect(720, 480, 120, 34))
        .states_([["Rebuild exact"]])
        .action_({
            try {
                var recipe;
                recipe = ~favoriteKitRecipe.(
                    favorites, profileName ? ~activeProfile
                );
                rebuildJobs = recipe[\jobs];
                activeRebuild = true;
                setStatus.("Rebuilding " ++ favorites.size
                    ++ " favorite pad(s)...");
                ~startJobs.(recipe[\jobs], recipe[\options]);
            } { |error| setStatus.(error.errorString) };
        });

    statusText = StaticText(window, Rect(20, 536, 820, 54))
        .string_("Ready. Empty pads remain available for future favorites.");
    StaticText(window, Rect(20, 600, 820, 24))
        .string_("[REBUILD] means the original preview WAV moved or was deleted; its synthesis recipe is preserved.")
        .font_(Font.default.size_(11));

    builderListener = { |event, data|
        {
            if(activeRebuild) {
                switch(event,
                    \started, { setBusy.(true) },
                    \rendering, {
                        setStatus.("Rebuilding " ++ data[\job][\filename] ++ "...")
                    },
                    \rendered, {
                        var favoriteIndex;
                        favoriteIndex = rebuildJobs.detectIndex { |job|
                            job[\filename] == data[\job][\filename]
                        };
                        if(favoriteIndex.notNil
                            and: { favoriteIndex < favorites.size }) {
                            favorites[favoriteIndex][\outputPath] = data[\outputPath];
                            favorites[favoriteIndex][\effectiveParameters] =
                                data[\effectiveParameters].deepCopy;
                        };
                        refresh.();
                    },
                    \finished, {
                        activeRebuild = false;
                        setBusy.(false);
                        if(onFavoritesChanged.notNil) {
                            onFavoritesChanged.value;
                        };
                        setStatus.(if(data[\failed] > 0) {
                            "Rebuild finished with " ++ data[\failed] ++ " failure(s)."
                        } {
                            "Exact favorite kit rebuilt in " ++ data[\outputDirectory]
                        });
                    }
                );
            };
        }.defer;
    };
    ~addGenerationListener.(builderListener);

    ~refreshFavoriteKitBuilder = { refresh.() };
    window.onClose = {
        ~removeGenerationListener.(builderListener);
        ~refreshFavoriteKitBuilder = nil;
        ~favoriteKitBuilderWindow = nil;
    };
    refresh.();
    window.front;
    window;
};

~candidateSummary = { |job|
    var keys, parameters, parts, result;
    result = if(job.isNil) {
        "No candidate selected."
    } {
        parameters = job[\parameters];
        keys = [
            \frequency, \decay, \bodyAmount, \noiseAmount,
            \brightness, \drive, \bits, \sampleRateReduction
        ];
        parts = List.new;
        keys.do { |key|
            var value;
            value = parameters[key];
            if(value.notNil) {
                if(value.isFloat) { value = value.round(0.001) };
                parts.add(key.asString ++ ": " ++ value);
            };
        };
        parts.join("   ");
    };
    result;
};

~openCandidateBrowser = { |engineName, options, onFavoritesChanged|
    var activeMode, amountSlider, batchCounter, browserListener, candidates;
    var cancelButton, exportButton, favorites, generateButton, keepButton;
    var lockBoxes, padButtons, progress, refresh, rejectButton, selectedIndex;
    var selectionText;
    var setBusy, setStatus, spec, statusText, variationButton;
    var variationCounter, window;

    spec = ~generatorSpecs[engineName];
    if(spec.isNil) { Error("Unknown family: " ++ engineName).throw };
    if(~candidateBrowserWindow.notNil) {
        try { ~candidateBrowserWindow.close } { };
    };

    candidates = Array.newClear(8);
    padButtons = Array.newClear(8);
    favorites = ~drumLabFavorites ? List.new;
    ~drumLabFavorites = favorites;
    lockBoxes = IdentityDictionary.new;
    selectedIndex = nil;
    activeMode = nil;
    batchCounter = 0;
    variationCounter = 0;

    window = Window(
        "Explore " ++ (spec[\label] ? engineName.asString),
        Rect(150, 90, 840, 600),
        resizable: false
    );
    ~candidateBrowserWindow = window;

    StaticText(window, Rect(20, 15, 500, 28))
        .string_("Explore " ++ (spec[\label] ? engineName.asString))
        .font_(Font.default.boldVariant.size_(20));
    StaticText(window, Rect(20, 45, 790, 24))
        .string_(spec[\description] ? "");

    setStatus = { |message|
        { statusText.string = message }.defer;
    };
    setBusy = { |busy|
        {
            generateButton.enabled = busy.not;
            cancelButton.enabled = busy;
            variationButton.enabled = busy.not and: { selectedIndex.notNil };
            rejectButton.enabled = busy.not and: { selectedIndex.notNil };
            keepButton.enabled = busy.not
                and: { selectedIndex.notNil }
                and: { favorites.size < 16 };
            lockBoxes.values.do { |box| box.enabled = busy.not };
            amountSlider.enabled = busy.not;
        }.defer;
    };

    refresh = {
        {
            var favoriteIndex, selectedCandidate;
            padButtons.do { |button, index|
                var candidate, isFavorite, label;
                candidate = candidates[index];
                label = if(candidate.isNil) {
                    (index + 1).asString ++ "\nEmpty"
                } {
                    isFavorite = favorites.detect { |favorite|
                        favorite[\outputPath] == candidate[\outputPath]
                    }.notNil;
                    (if(selectedIndex == index) { "> " } { "" })
                        ++ (index + 1).asString ++ "  "
                        ++ candidate[\job][\filename]
                        ++ (if(isFavorite) { "  [KEPT]" } { "" })
                };
                button.states = [[label]];
            };
            selectionText.string = if(selectedIndex.notNil
                and: { candidates[selectedIndex].notNil }) {
                ~candidateSummary.(candidates[selectedIndex][\job])
            } {
                "Select a rendered candidate to inspect it."
            };
            selectedCandidate = if(selectedIndex.notNil) {
                candidates[selectedIndex]
            };
            favoriteIndex = if(selectedCandidate.notNil) {
                favorites.detectIndex { |favorite|
                    favorite[\outputPath] == selectedCandidate[\outputPath]
                }
            };
            keepButton.states = [[
                (if(favoriteIndex.notNil) { "Unkeep" } { "Keep" })
                ++ " (" ++ favorites.size ++ "/16)"
            ]];
            keepButton.enabled = selectedCandidate.notNil
                and: {
                    favoriteIndex.notNil or: { favorites.size < 16 }
                }
                and: { ~generationRunning != true };
            rejectButton.enabled = selectedIndex.notNil
                and: { ~generationRunning != true };
            variationButton.enabled = selectedIndex.notNil
                and: { ~generationRunning != true };
            exportButton.enabled = favorites.notEmpty;
        }.defer;
    };

    generateButton = Button(window, Rect(20, 76, 160, 32))
        .states_([["Generate 8 candidates"]])
        .action_({
            var batchOptions, counts;
            if(~generationRunning == true) {
                setStatus.("Another render is already running.");
            } {
                batchCounter = batchCounter + 1;
                candidates = Array.newClear(8);
                selectedIndex = nil;
                refresh.();
                counts = IdentityDictionary.new;
                counts[engineName] = 8;
                batchOptions = options.deepCopy;
                batchOptions[\enabledEngines] = [engineName];
                batchOptions[\engineCounts] = counts;
                batchOptions[\samplesPerEngine] = 8;
                batchOptions[\randomSeed] = options[\randomSeed]
                    + ((batchCounter - 1) * 1000);
                activeMode = \batch;
                setStatus.("Rendering eight candidates...");
                ~start.([engineName], batchOptions);
            };
        });

    cancelButton = Button(window, Rect(190, 76, 100, 32))
        .states_([["Cancel"]])
        .enabled_(false)
        .action_({ ~cancelGeneration.() });

    StaticText(window, Rect(310, 81, 360, 20))
        .string_("Click a pad to select and audition it.");

    8.do { |index|
        var column, left, row, top;
        column = index % 4;
        row = (index / 4).floor;
        left = 20 + (column * 200);
        top = 122 + (row * 82);
        padButtons[index] = Button(window, Rect(left, top, 185, 66))
            .states_([[(index + 1).asString ++ "\nEmpty"]])
            .action_({
                var candidate;
                candidate = candidates[index];
                if(candidate.notNil) {
                    selectedIndex = index;
                    refresh.();
                    ~playRenderedFile.(candidate[\outputPath]);
                    setStatus.("Playing " ++ candidate[\job][\filename]);
                };
            });
    };

    StaticText(window, Rect(20, 294, 800, 20))
        .string_("Selected sound")
        .font_(Font.default.boldVariant);
    selectionText = StaticText(window, Rect(20, 316, 800, 42))
        .string_("Select a rendered candidate to inspect it.");

    StaticText(window, Rect(20, 366, 190, 20))
        .string_("Lock while creating variations")
        .font_(Font.default.boldVariant);
    [
        [\pitch, "Pitch"],
        [\envelope, "Envelope"],
        [\texture, "Texture"],
        [\dirt, "Dirt"]
    ].do { |pair, index|
        lockBoxes[pair[0]] = CheckBox(
            window, Rect(220 + (index * 120), 364, 110, 24)
        ).string_(pair[1]).value_(0);
    };

    StaticText(window, Rect(20, 402, 125, 20)).string_("Variation distance");
    amountSlider = Slider(window, Rect(148, 402, 230, 20)).value_(0.25);
    StaticText(window, Rect(390, 402, 380, 20))
        .string_("Small = close sibling; large = stronger mutation.");

    variationButton = Button(window, Rect(20, 438, 170, 34))
        .states_([["Create close variation"]])
        .enabled_(false)
        .action_({
            var candidate, locks, mutationSeed, variationJob;
            if(selectedIndex.notNil and: { ~generationRunning != true }) {
                candidate = candidates[selectedIndex];
                locks = IdentityDictionary.new;
                lockBoxes.keysValuesDo { |name, box|
                    locks[name] = box.value;
                };
                variationCounter = variationCounter + 1;
                mutationSeed = options[\randomSeed]
                    + 100000 + (variationCounter * 7919);
                variationJob = ~makeVariationJob.(
                    candidate[\job], locks, amountSlider.value,
                    mutationSeed, variationCounter, options
                );
                activeMode = \variation;
                setStatus.("Rendering a close variation...");
                ~startJobs.([variationJob], options);
            };
        });

    keepButton = Button(window, Rect(202, 438, 125, 34))
        .states_([["Keep (0/16)"]])
        .enabled_(false)
        .action_({
            var candidate, favoriteIndex;
            candidate = if(selectedIndex.notNil) { candidates[selectedIndex] };
            if(candidate.notNil) {
                favoriteIndex = favorites.detectIndex { |favorite|
                    favorite[\outputPath] == candidate[\outputPath]
                };
                if(favoriteIndex.notNil) {
                    favorites.removeAt(favoriteIndex);
                    setStatus.("Removed from favorites: "
                        ++ candidate[\job][\filename]);
                } {
                    if(favorites.size < 16) {
                        favorites.add(candidate.copy);
                        setStatus.("Added to favorites: "
                            ++ candidate[\job][\filename]);
                    };
                };
                if(onFavoritesChanged.notNil) {
                    onFavoritesChanged.value;
                };
                refresh.();
            };
        });

    rejectButton = Button(window, Rect(339, 438, 110, 34))
        .states_([["Reject"]])
        .enabled_(false)
        .action_({
            if(selectedIndex.notNil) {
                var candidate, favoriteIndex;
                candidate = candidates[selectedIndex];
                favoriteIndex = favorites.detectIndex { |favorite|
                    favorite[\outputPath] == candidate[\outputPath]
                };
                if(favoriteIndex.notNil) {
                    favorites.removeAt(favoriteIndex);
                    if(onFavoritesChanged.notNil) {
                        onFavoritesChanged.value;
                    };
                };
                candidates[selectedIndex] = nil;
                selectedIndex = nil;
                refresh.();
                setStatus.("Candidate removed from this browser view.");
            };
        });

    exportButton = Button(window, Rect(461, 438, 165, 34))
        .states_([["Export favorites"]])
        .enabled_(favorites.isEmpty.not)
        .action_({
            try {
                var path;
                path = ~exportDrumLabFavorites.(favorites);
                setStatus.("Favorites exported to " ++ path);
                path.openOS;
            } { |error| setStatus.(error.errorString) };
        });

    Button(window, Rect(638, 438, 170, 34))
        .states_([["Play selected"]])
        .action_({
            if(selectedIndex.notNil) {
                ~playRenderedFile.(candidates[selectedIndex][\outputPath]);
            };
        });

    statusText = StaticText(window, Rect(20, 494, 800, 54))
        .string_("Ready to generate candidates.");
    progress = Slider(window, Rect(20, 558, 800, 16))
        .enabled_(false);

    browserListener = { |event, data|
        {
            if(activeMode.notNil) {
                switch(event,
                    \started, {
                        progress.value = 0;
                        setBusy.(true);
                    },
                    \rendered, {
                        var targetIndex;
                        if(data[\job][\family] == engineName) {
                            targetIndex = candidates.detectIndex { |item|
                                item.isNil
                            };
                            if(targetIndex.isNil) {
                                targetIndex = selectedIndex ? 0;
                            };
                            candidates[targetIndex] = data.copy;
                            selectedIndex = targetIndex;
                            progress.value = data[\completed] / data[\total];
                            refresh.();
                            if(activeMode == \variation) {
                                ~playRenderedFile.(data[\outputPath]);
                            };
                            setStatus.("Rendered " ++ data[\completed]
                                ++ " of " ++ data[\total] ++ ".");
                        };
                    },
                    \failed, {
                        setStatus.("Render failed: " ++ data[\message]);
                    },
                    \finished, {
                        progress.value = if(data[\total] > 0) {
                            data[\completed] / data[\total]
                        } { 0 };
                        activeMode = nil;
                        setBusy.(false);
                        refresh.();
                        setStatus.(if(data[\cancelled]) {
                            "Candidate rendering cancelled."
                        } {
                            "Candidates ready. Select a pad to audition it."
                        });
                    }
                );
            };
        }.defer;
    };
    ~addGenerationListener.(browserListener);

    window.onClose = {
        ~removeGenerationListener.(browserListener);
        ~candidateBrowserWindow = nil;
    };
    refresh.();
    window.front;
    window;
};

~openDrumLab = {
    var applySession, buildFamilyRows, buildOptions, cancelButton, countLabel;
    var descriptionText, dryRunButton, familyRows, familyScroll;
    var exportButton, favorites, generateButton, keepButton, lastPreview;
    var kitBuilderButton, listener, loadSessionButton, macroSliders, openButton;
    var previewCounter, previewRequested, renderFavoritesButton;
    var profileMenu, profileNames, profileSymbols, progress, randomizeButton;
    var replayRecipeButton, saveSessionButton, seedBox, setBusy;
    var setFavoriteButtons, setStatus, statusText, window;

    if(~drumLabWindow.notNil) {
        try { ~drumLabWindow.close } { };
    };

    familyRows = IdentityDictionary.new;
    favorites = ~drumLabFavorites ? List.new;
    ~drumLabFavorites = favorites;
    lastPreview = nil;
    macroSliders = IdentityDictionary.new;
    previewCounter = 0;
    previewRequested = false;
    profileSymbols = ~profiles.keys.asArray.sort;
    profileNames = profileSymbols.collect { |name|
        ~profiles[name][\displayName]
    };

    window = Window(
        "SC MPC Drum Lab",
        Rect(80, 40, 760, 850),
        resizable: false
    );
    ~drumLabWindow = window;

    StaticText(window, Rect(20, 16, 400, 30))
        .string_("SC MPC Drum Lab")
        .font_(Font.default.boldVariant.size_(22));
    StaticText(window, Rect(20, 48, 710, 22))
        .string_("Choose a sound world, audition a family, then render your kit.");

    StaticText(window, Rect(20, 82, 60, 22)).string_("Profile");
    profileMenu = PopUpMenu(window, Rect(82, 80, 220, 26))
        .items_(profileNames);

    StaticText(window, Rect(325, 82, 42, 22)).string_("Seed");
    seedBox = NumberBox(window, Rect(368, 80, 145, 26))
        .value_(~config[\randomSeed])
        .decimals_(0);
    randomizeButton = Button(window, Rect(522, 80, 110, 26))
        .states_([["New seed"]])
        .action_({ seedBox.value = 2147483646.rand + 1 });

    descriptionText = StaticText(window, Rect(20, 114, 710, 32));
    StaticText(window, Rect(20, 148, 710, 20))
        .string_("Musical character (center leaves the profile unchanged)")
        .font_(Font.default.boldVariant);
    [
        [\weight, "Weight"],
        [\punch, "Punch"],
        [\brightness, "Brightness"],
        [\tail, "Tail"],
        [\dirt, "Dirt"]
    ].do { |pair, index|
        var left, name;
        name = pair[0];
        left = 20 + (index * 142);
        StaticText(window, Rect(left, 170, 125, 18))
            .string_(pair[1]);
        macroSliders[name] = Slider(window, Rect(left, 190, 125, 20))
            .value_(0.5);
    };

    StaticText(window, Rect(20, 220, 470, 22))
        .string_("Sound families")
        .font_(Font.default.boldVariant);
    countLabel = StaticText(window, Rect(420, 220, 70, 22))
        .string_("Quantity");

    setStatus = { |message|
        { statusText.string = message }.defer;
    };

    setBusy = { |busy|
        {
            generateButton.enabled = busy.not;
            dryRunButton.enabled = busy.not;
            cancelButton.enabled = busy;
            profileMenu.enabled = busy.not;
            randomizeButton.enabled = busy.not;
            seedBox.enabled = busy.not;
            saveSessionButton.enabled = busy.not;
            loadSessionButton.enabled = busy.not;
            replayRecipeButton.enabled = busy.not;
            renderFavoritesButton.enabled = busy.not
                and: { favorites.notEmpty };
            kitBuilderButton.enabled = busy.not;
            familyRows.values.do { |row|
                row[\enabled].enabled = busy.not;
                row[\count].enabled = busy.not;
                row[\preview].enabled = busy.not;
                row[\explore].enabled = busy.not;
            };
            macroSliders.values.do { |slider| slider.enabled = busy.not };
        }.defer;
    };

    setFavoriteButtons = {
        {
            keepButton.enabled = lastPreview.notNil
                and: { favorites.size < 16 };
            keepButton.states = [["Keep preview ("
                ++ favorites.size ++ "/16)"]];
            exportButton.enabled = favorites.notEmpty;
            if(renderFavoritesButton.notNil) {
                renderFavoritesButton.enabled = favorites.notEmpty
                    and: { ~generationRunning != true };
            };
            if(~refreshFavoriteKitBuilder.notNil) {
                ~refreshFavoriteKitBuilder.value;
            };
        }.defer;
    };

    buildFamilyRows = {
        var defaults, engines, profile, rowHeight;
        if(familyScroll.notNil) { familyScroll.remove };
        familyRows = IdentityDictionary.new;
        profile = ~profiles[profileSymbols[profileMenu.value]];
        defaults = profile[\defaults];
        engines = defaults[\enabledEngines];
        rowHeight = 54;

        descriptionText.string = profile[\description] ? "";
        familyScroll = ScrollView(window, Rect(20, 246, 720, 320));
        familyScroll.hasBorder = true;

        engines.do { |engineName, index|
            var check, count, explore, preview, spec, top;
            spec = ~generatorSpecs[engineName];
            top = 6 + (index * rowHeight);
            check = CheckBox(familyScroll, Rect(8, top + 7, 165, 22))
                .string_(spec[\label] ? engineName.asString)
                .value_(1);
            StaticText(familyScroll, Rect(30, top + 28, 375, 18))
                .string_(spec[\description] ? "")
                .font_(Font.default.size_(11));
            count = NumberBox(familyScroll, Rect(420, top + 7, 58, 24))
                .value_(defaults[\samplesPerEngine])
                .decimals_(0)
                .action_({ |box| box.value = box.value.asInteger.clip(1, 128) });
            preview = Button(familyScroll, Rect(490, top + 7, 88, 24))
                .states_([["Preview"]])
                .action_({
                    var counts, macros, options;
                    if(~generationRunning == true) {
                        setStatus.("A render is already running.");
                    } {
                        counts = IdentityDictionary.new;
                        counts[engineName] = 1;
                        macros = IdentityDictionary.new;
                        macroSliders.keysValuesDo { |name, slider|
                            macros[name] = slider.value;
                        };
                        options = (
                            activeProfile: profileSymbols[profileMenu.value],
                            randomSeed: seedBox.value.asInteger,
                            samplesPerEngine: 1,
                            engineCounts: counts,
                            enabledEngines: [engineName],
                            macros: macros
                        );
                        previewCounter = previewCounter + 1;
                        options[\randomSeed] = seedBox.value.asInteger
                            + previewCounter;
                        previewRequested = true;
                        setStatus.("Rendering a preview of "
                            ++ (spec[\label] ? engineName.asString) ++ "...");
                        ~generateEngine.(engineName, options);
                    };
                });
            explore = Button(familyScroll, Rect(590, top + 7, 88, 24))
                .states_([["Explore..."]])
                .action_({
                    var counts, macros, options;
                    counts = IdentityDictionary.new;
                    counts[engineName] = 8;
                    macros = IdentityDictionary.new;
                    macroSliders.keysValuesDo { |name, slider|
                        macros[name] = slider.value;
                    };
                    options = (
                        activeProfile: profileSymbols[profileMenu.value],
                        randomSeed: seedBox.value.asInteger,
                        samplesPerEngine: 8,
                        engineCounts: counts,
                        enabledEngines: [engineName],
                        macros: macros
                    );
                    ~openCandidateBrowser.(
                        engineName, options, { setFavoriteButtons.() }
                    );
                });
            familyRows[engineName] = (
                enabled: check,
                count: count,
                preview: preview,
                explore: explore
            );
        };
    };

    buildOptions = {
        var counts, enabled, macros, result;
        counts = IdentityDictionary.new;
        enabled = List.new;
        macros = IdentityDictionary.new;
        familyRows.keysValuesDo { |engineName, row|
            if(row[\enabled].value) {
                enabled.add(engineName);
                counts[engineName] = row[\count].value.asInteger.clip(1, 128);
            };
        };
        macroSliders.keysValuesDo { |name, slider|
            macros[name] = slider.value;
        };
        result = if(enabled.isEmpty) {
            setStatus.("Select at least one sound family.");
            nil
        } {
            (
                activeProfile: profileSymbols[profileMenu.value],
                randomSeed: seedBox.value.asInteger,
                samplesPerEngine: 1,
                engineCounts: counts,
                enabledEngines: enabled.asArray,
                macros: macros,
                masterAmp: ~config[\masterAmp]
                    ? ~profiles[profileSymbols[profileMenu.value]][\defaults][\masterAmp],
                maxConcurrentRenders: ~config[\maxConcurrentRenders]
            )
        };
        result;
    };

    applySession = { |session|
        var counts, enabled, macros, missing, options, profileIndex;
        options = session[\options];
        profileIndex = profileSymbols.indexOf(options[\activeProfile]);
        if(profileIndex.isNil) {
            Error("Session profile is not currently available.").throw;
        };
        profileMenu.value = profileIndex;
        buildFamilyRows.();
        seedBox.value = options[\randomSeed] ? ~config[\randomSeed];
        macros = options[\macros] ? ();
        macroSliders.keysValuesDo { |name, slider|
            slider.value = macros[name] ? 0.5;
        };
        enabled = options[\enabledEngines];
        counts = options[\engineCounts] ? ();
        familyRows.keysValuesDo { |engineName, row|
            row[\enabled].value = enabled.includes(engineName);
            row[\count].value = counts[engineName]
                ? options[\samplesPerEngine]
                ? 1;
        };
        favorites.clear;
        session[\favorites].do { |favorite|
            favorites.add(favorite.deepCopy);
        };
        ~loadedDrumLabSession = session.deepCopy;
        lastPreview = nil;
        missing = favorites.count { |favorite|
            favorite[\outputPath].isNil
                or: { File.exists(favorite[\outputPath]).not }
        };
        setFavoriteButtons.();
        setStatus.("Loaded session '" ++ (session[\name] ? "Untitled") ++ "' with "
            ++ favorites.size ++ " favorite(s)"
            ++ if(missing > 0) {
                "; " ++ missing ++ " source file(s) need rebuilding."
            } {
                "."
            });
    };

    // Small public hooks make session restoration scriptable and testable
    // without exposing individual GUI widgets.
    ~applyDrumLabSessionToGui = { |session| applySession.(session) };
    ~currentDrumLabGuiOptions = { buildOptions.() };

    profileMenu.value = profileSymbols.indexOf(~config[\activeProfile]) ? 0;
    profileMenu.action = { buildFamilyRows.() };

    progress = Slider(window, Rect(20, 586, 720, 18))
        .enabled_(false);
    statusText = StaticText(window, Rect(20, 612, 720, 42))
        .string_("Ready. Preview one family or generate the selected kit.");

    dryRunButton = Button(window, Rect(20, 662, 120, 34))
        .states_([["Plan pack"]])
        .action_({
            var options;
            options = buildOptions.();
            if(options.notNil) {
                try {
                    var jobs;
                    jobs = ~dryRun.(nil, options);
                    setStatus.("Plan ready: " ++ jobs.size
                        ++ " samples. Details are in the Post window.");
                } { |error| setStatus.(error.errorString) };
            };
        });

    generateButton = Button(window, Rect(150, 662, 175, 34))
        .states_([["Generate selected kit"]])
        .action_({
            var options;
            options = buildOptions.();
            if(options.notNil) {
                previewRequested = false;
                ~start.(nil, options);
            };
        });

    cancelButton = Button(window, Rect(335, 662, 100, 34))
        .states_([["Cancel"]])
        .enabled_(false)
        .action_({ ~cancelGeneration.() });

    openButton = Button(window, Rect(445, 662, 160, 34))
        .states_([["Open output folder"]])
        .action_({
            var path;
            path = ~currentRunDirectory ? ~runtimeConfig[\outputDirectory];
            if(path.notNil and: { File.exists(path) }) {
                path.openOS;
            } {
                setStatus.("No output folder is available yet.");
            };
        });

    Button(window, Rect(615, 662, 125, 34))
        .states_([["Help"]])
        .action_({
            ~help.();
            setStatus.("Command reference printed in the Post window.");
        });

    keepButton = Button(window, Rect(20, 714, 180, 34))
        .states_([["Keep preview (0/16)"]])
        .enabled_(false)
        .action_({
            if(lastPreview.notNil and: { favorites.size < 16 }) {
                if(favorites.detect { |favorite|
                    favorite[\outputPath] == lastPreview[\outputPath]
                }.isNil) {
                    favorites.add(lastPreview.copy);
                    setStatus.("Kept " ++ lastPreview[\job][\filename]
                        ++ ". " ++ favorites.size ++ " favorite(s).");
                };
                setFavoriteButtons.();
            };
        });

    exportButton = Button(window, Rect(210, 714, 180, 34))
        .states_([["Export favorites"]])
        .enabled_(false)
        .action_({
            try {
                var path;
                path = ~exportDrumLabFavorites.(favorites);
                setStatus.("Favorites exported to " ++ path);
                path.openOS;
            } { |error| setStatus.(error.errorString) };
        });

    Button(window, Rect(400, 714, 140, 34))
        .states_([["Clear favorites"]])
        .action_({
            favorites.clear;
            lastPreview = nil;
            setFavoriteButtons.();
            setStatus.("Favorites cleared; rendered source files were kept.");
        });

    kitBuilderButton = Button(window, Rect(550, 714, 190, 34))
        .states_([["Edit 16-pad kit"]])
        .action_({
            ~openFavoriteKitBuilder.(
                favorites,
                profileSymbols[profileMenu.value],
                {
                    setFavoriteButtons.();
                }
            );
        });

    saveSessionButton = Button(window, Rect(20, 766, 165, 34))
        .states_([["Save session"]])
        .action_({
            var options;
            options = buildOptions.();
            if(options.notNil) {
                Dialog.savePanel({ |selectedPath|
                    {
                        try {
                            var name, path, session;
                            path = ~drumLabSessionPath.(selectedPath);
                            name = PathName(path).fileNameWithoutExtension;
                            session = ~saveDrumLabSession.(
                                path, options, favorites, name
                            );
                            ~loadedDrumLabSession = session.deepCopy;
                            setStatus.("Session saved to " ++ path);
                        } { |error| setStatus.(error.errorString) };
                    }.defer;
                }, {
                    setStatus.("Session save cancelled.");
                }, path: ~config[\sessionDirectory]);
            };
        });

    loadSessionButton = Button(window, Rect(195, 766, 165, 34))
        .states_([["Load session"]])
        .action_({
            Dialog.openPanel({ |path|
                {
                    try {
                        applySession.(~loadDrumLabSession.(path));
                    } { |error| setStatus.(error.errorString) };
                }.defer;
            }, {
                setStatus.("Session load cancelled.");
            }, path: ~config[\sessionDirectory]);
        });

    replayRecipeButton = Button(window, Rect(370, 766, 165, 34))
        .states_([["Replay recipe"]])
        .action_({
            Dialog.openPanel({ |path|
                {
                    try {
                        setStatus.("Replaying recipe: "
                            ++ PathName(path).fileName);
                        ~replayRecipe.(path);
                    } { |error| setStatus.(error.errorString) };
                }.defer;
            }, {
                setStatus.("Recipe selection cancelled.");
            }, path: ~config[\outputDirectory]);
        });

    renderFavoritesButton = Button(window, Rect(545, 766, 195, 34))
        .states_([["Rebuild favorite kit"]])
        .enabled_(favorites.notEmpty)
        .action_({
            try {
                var options, recipe;
                options = buildOptions.();
                if(options.notNil and: { favorites.notEmpty }) {
                    recipe = ~favoriteKitRecipe.(
                        favorites, options[\activeProfile]
                    );
                    ~startJobs.(recipe[\jobs], recipe[\options]);
                };
            } { |error| setStatus.(error.errorString) };
        });

    listener = { |event, data|
        {
            switch(event,
                \started, {
                    progress.value = 0;
                    setBusy.(true);
                    statusText.string = "Starting " ++ data[\total]
                        ++ " render(s)...";
                },
                \rendering, {
                    statusText.string = "Rendering "
                        ++ data[\job][\filename] ++ "...";
                },
                \rendered, {
                    progress.value = data[\completed] / data[\total];
                    statusText.string = "Rendered " ++ data[\completed]
                        ++ " of " ++ data[\total] ++ ": "
                        ++ data[\job][\filename];
                    if(previewRequested) {
                        previewRequested = false;
                        lastPreview = data.copy;
                        setFavoriteButtons.();
                        ~playRenderedFile.(data[\outputPath]);
                    };
                },
                \failed, {
                    previewRequested = false;
                    statusText.string = "Render failed: " ++ data[\message];
                },
                \finished, {
                    previewRequested = false;
                    progress.value = if(data[\total] > 0) {
                        data[\completed] / data[\total]
                    } { 0 };
                    setBusy.(false);
                    statusText.string = if(data[\cancelled]) {
                        "Cancelled after " ++ data[\completed] ++ " render(s)."
                    } {
                        "Finished " ++ data[\completed] ++ " render(s); "
                            ++ data[\failed] ++ " failed."
                    };
                }
            );
        }.defer;
    };
    ~addGenerationListener.(listener);

    window.onClose = {
        ~removeGenerationListener.(listener);
        if(~drumLabPreviewBuffer.notNil) {
            ~drumLabPreviewBuffer.free;
            ~drumLabPreviewBuffer = nil;
        };
        ~applyDrumLabSessionToGui = nil;
        ~currentDrumLabGuiOptions = nil;
        if(~favoriteKitBuilderWindow.notNil) {
            try { ~favoriteKitBuilderWindow.close } { };
        };
        ~drumLabWindow = nil;
    };

    buildFamilyRows.();
    setFavoriteButtons.();
    window.front;
    window;
};
)
