(
~manifestPath = ~config[\outputDirectory] +/+ "sample_manifest.txt";

~resetManifest = {
    var file;
    file = File(~manifestPath, "w");
    if(file.isOpen.not) {
        Error("Cannot write manifest: " ++ ~manifestPath).throw;
    };
    file.write("SC MPC DRUM LAB\n");
    file.write("Generated: " ++ Date.getDate.asString ++ "\n");
    file.write("Seed: " ++ ~config[\randomSeed].asString ++ "\n\n");
    file.close;
};

~writeManifestEntry = {
    |filename, synthName, parameters|
    var file;
    file = File(~manifestPath, "a");
    file.write(
        filename ++ " | " ++ synthName.asString
        ++ " | " ++ parameters.asCompileString ++ "\n"
    );
    file.close;
};
)
