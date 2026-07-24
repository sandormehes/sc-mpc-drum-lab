# SC MPC Drum Lab

A modular SuperCollider drum synthesizer and offline sample generator for the
Akai MPC1000 and other samplers.

It creates experimental kicks, snares, metallic percussion, digital glitches,
and resonator sounds as **mono, 44.1 kHz, 16-bit WAV** files.

## Requirements

- SuperCollider 3.12 or newer
- `scsynth` (included with SuperCollider)
- No Quarks or third-party extensions

## Quick start

1. Open `main.scd` in the SuperCollider IDE.
2. Evaluate the entire file:
   - macOS: `Cmd+A`, then `Cmd+Enter`
   - Windows/Linux: `Ctrl+A`, then `Ctrl+Enter`
3. Generate the complete pack:

```supercollider
~start.();
```

The default setup creates 60 samples in `output/`: 12 samples from each of the
five engines. Rendering is sequential, so the next job begins only after the
previous file has finished.

## Everyday configuration

Edit `config.scd` to change the common settings:

```supercollider
samplesPerEngine: 12,
randomSeed: 26071986,
masterAmp: 0.8,
autoStart: false,
enabledEngines: [\kick, \snare, \metal, \glitch, \resonator]
```

Examples:

```supercollider
// Generate 20 samples per enabled engine.
samplesPerEngine: 20,

// Generate only kicks and snares.
enabledEngines: [\kick, \snare]

// Start automatically whenever main.scd is evaluated.
autoStart: true
```

Keep the same `randomSeed` to reproduce the same parameter sequence. Change it
to generate a different pack.

## Edit the sound ranges

The random parameter ranges are in `lib/generator.scd`. Each engine has one
clearly named specification:

```supercollider
~generatorSpecs[\kick] = (
    synth: \experimentalKick,
    prefix: "XKICK",
    duration: 1.5,
    generator: {
        (
            frequency: exprand(38.0, 72.0),
            decay: exprand(0.22, 0.9),
            fmAmount: rrand(0.0, 0.8)
            // ...
        )
    }
);
```

- `rrand(min, max)` selects values evenly across the range.
- `exprand(min, max)` is better for frequency and time ranges.
- A fixed value, such as `drive: 1.5`, disables variation for that parameter.

## Presets

Hand-edited sounds live in `presets/presets.scd`. Export one after loading
`main.scd`:

```supercollider
~renderPreset.(\deepKick);
~renderPreset.(\industrialSnare);
~renderPreset.(\metalObject);
~renderPreset.(\extremeGlitch);
```

Supply a different output name if required:

```supercollider
~renderPreset.(\deepKick, "MY_KICK.wav");
```

Create a variation without changing the original preset:

```supercollider
(
var sound;

sound = ~presetVariation.(
    \deepKick,
    (
        frequency: 38,
        decay: 1.1,
        foldAmount: 0.25,
        bits: 9
    )
);

~renderSample.(
    sound[\engine],
    sound[\parameters],
    "DEEP_KICK_VARIATION.wav",
    sound[\duration]
);
)
```

## Output and manifest

Generated WAV files and `sample_manifest.txt` are written to `output/`.
The manifest records every filename, SynthDef, random seed, and parameter set.

The synthesis can internally use bit-depth and sample-rate reduction, while the
exported container remains a standard MPC-friendly WAV file.

To use another output folder, edit:

```supercollider
outputDirectory: ~projectRoot +/+ "output",
```

For example:

```supercollider
outputDirectory: Platform.userHomeDir +/+ "MPC1000_Drums",
```

## Project structure

```text
sc-mpc-drum-lab/
├── main.scd
├── config.scd
├── synthdefs/
│   ├── kick.scd
│   ├── snare.scd
│   ├── metal.scd
│   ├── glitch.scd
│   └── resonator.scd
├── lib/
│   ├── processing.scd
│   ├── renderer.scd
│   ├── manifest.scd
│   └── generator.scd
├── presets/
│   └── presets.scd
├── output/
│   └── .gitkeep
├── README.md
└── LICENSE
```

## Engine files

- `synthdefs/kick.scd` — pitch-envelope kick with FM, click, and comb layers
- `synthdefs/snare.scd` — tonal body, filtered noise, ring modulation
- `synthdefs/metal.scd` — inharmonic resonator bank and FM layer
- `synthdefs/glitch.scd` — pulse, chaos, ring modulation, heavy degradation
- `synthdefs/resonator.scd` — noise excitation and tunable modal resonances

All engines share the post-processing chain in `lib/processing.scd`:
wavefolding, sample-rate reduction, bit crushing, drive, high-pass filtering,
DC removal, and limiting.

## MPC1000 transfer

1. Generate the samples.
2. Copy the WAV files from `output/` to a CompactFlash card.
3. Load them on the MPC1000.
4. Assign them to pads in a drum program.
5. Save the program together with its samples.

The generated filenames are short and contain no spaces or accented characters.

## Troubleshooting

### `Unknown engine`

Evaluate the complete `main.scd` file again. It loads the SynthDefs before the
renderer and generator.

### No files appear

Check the SuperCollider post window for an `scsynth` error and confirm that the
configured output directory is writable.

### Samples are too extreme

Reduce `foldAmount`, `fmAmount`, `combAmount`, or `drive`. Increase `bits` and
`sampleRateReduction`.

### Samples are too quiet

Increase `masterAmp` in `config.scd`, or the preset's `amp`. The limiter leaves
headroom so layered MPC programs remain manageable.

## License

MIT. See `LICENSE`.

Akai and MPC are trademarks of their respective owners. This project is
independent and is not affiliated with or endorsed by Akai Professional.
