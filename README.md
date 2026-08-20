# SC MPC Drum Lab

A modular SuperCollider drum synthesizer and offline sample generator for the
Akai MPC1000 and other samplers.

It creates kicks, snares, metallic percussion, digital glitches, and resonator
sounds as **mono, 44.1 kHz, 16-bit WAV** files. Every generated pack is kept in
its own run directory and includes a validation-aware manifest.

## Requirements

- SuperCollider 3.12 or newer
- `scsynth` (included with SuperCollider)
- No Quarks or third-party extensions

## Quick start: control panel

1. Open `gui.scd` in the SuperCollider IDE.
2. Evaluate the entire file:
   - macOS: `Cmd+A`, then `Cmd+Enter`
   - Windows/Linux: `Ctrl+A`, then `Ctrl+Enter`
   - If your editor does not provide the current document path to
     SuperCollider, select this project's `main.scd` in the file picker.
3. Choose a profile, enable the sound families you want, and set a quantity for
   each family.
4. Use **Preview** for one sound, **Explore** for an eight-candidate browser, or
   **Generate selected kit** to render the complete selection.

The control panel shows live progress and can open the finished output folder.
Preview files use the same validated offline renderer as final samples, so the
sound you audition is the sound that was exported. Each Preview click creates a
new reproducible candidate. Keep up to 16 favorites and export them with
pad-oriented names such as `A01_DHKICK.WAV`.

Five musical controls provide consistent direction across sound families:

- **Weight** adjusts body, level, and low-frequency emphasis.
- **Punch** shapes pitch impact, click, and transient emphasis.
- **Brightness** moves noise, click, and metallic tone.
- **Tail** changes decay, resonance, and comb sustain.
- **Dirt** coordinates drive, folding, bit depth, and sample-rate reduction.

Their center positions preserve the profile's original parameter ranges.

### Candidate browser and close variations

Select **Explore** beside any sound family to open the v0.4 candidate browser:

1. Generate eight candidates.
2. Click any pad to select and audition its rendered WAV.
3. Keep useful candidates, or reject them from the browser view.
4. Adjust **Variation distance** and create a close sibling.
5. Lock **Pitch**, **Envelope**, **Texture**, or **Dirt** to preserve those
   characteristics while the remaining parameters mutate.
6. Export up to 16 favorites as an MPC-oriented pad kit.

Rejecting a candidate never deletes its source run. A close variation records
its source filename, mutation distance, lock choices, complete parameters, and
synthesis seed. Its `recipe.json` therefore replays the exact custom job rather
than generating an approximation.

### Sessions and reopening work

v0.5 adds persistent lab sessions to the bottom of the main control panel:

- **Save session** stores the profile, seed, macros, enabled families,
  per-family quantities, and up to 16 favorites.
- **Load session** restores those controls and favorites into the GUI.
- **Replay recipe** selects any generated `recipe.json` and renders it again.
- **Rebuild favorite kit** regenerates the current favorites from their exact
  effective parameters, even when their original preview WAVs are unavailable.

Sessions are stored under `sessions/` by default and are ignored by Git. The
loader reports missing favorite source files while preserving their jobs for
rebuilding. New sessions and recipes use schema-validated JSON rather than
executable SuperCollider source. Legacy `.scd` data files remain loadable for
backward compatibility and should only be opened when trusted.

### Visual 16-pad kit builder

v0.6 adds **Edit 16-pad kit** to the main control panel. It opens an MPC-style
four-by-four view of the current favorites where you can:

- click any filled pad to select and audition it;
- move the selected sound earlier or later in the exported pad order;
- remove sounds without deleting their rendered WAV files;
- export all available source WAVs with `A01` through `A16` names; or
- rebuild the exact kit when previews have moved or been deleted.

Pads whose original audio is unavailable show `[REBUILD]`. Rebuilding uses the
stored effective synthesis parameters, updates the favorite sources to the new
WAV files, and makes the rebuilt kit immediately exportable again. Pad order is
preserved when saving and loading v0.6 sessions.

## Command workflow

Open `main.scd`, evaluate the entire file, then inspect the next pack without
rendering:

```supercollider
~dryRun.();
```

Generate the complete pack:

```supercollider
~start.();
```

Loading `main.scd` does not render or overwrite audio unless `autoStart` is
explicitly enabled. The default `thickClub` profile plans 60 samples: six from
each of ten focused dancehall, grime, and gqom families. Half of the pack is
kick/snare material; the other half is metallic percussion, low toms, wooden
rims, closed hats, and grainy shakers.

Generate one family only:

```supercollider
~generateEngine.(\dancehallKick);
```

Stop scheduling new jobs while allowing active renders to finish:

```supercollider
~cancelGeneration.();
```

Useful discovery and status commands:

```supercollider
~help.();
~listProfiles.();
~listFamilies.();
~status.();
~openDrumLab.();
~openFavoriteKitBuilder.(~drumLabFavorites);
```

## Configuration

Edit `config.scd` for normal use:

```supercollider
activeProfile: \thickClub,
randomSeed: 26071986,
samplesPerEngine: nil,
engineCounts: nil,
macros: nil,
masterAmp: nil,
enabledEngines: nil,
maxConcurrentRenders: 2,
autoStart: false
```

`nil` means “use the selected profile's default.” Set an explicit value to
override that default without editing the profile:

```supercollider
samplesPerEngine: 20,
masterAmp: 0.85,
enabledEngines: [\dancehallKick, \grimeSnare]
```

Use `engineCounts` when each family should contribute a different number of
sounds:

```supercollider
samplesPerEngine: 4,
engineCounts: (
    dancehallKick: 8,
    grimeSnare: 4,
    dancehallRim: 2
)
```

Families omitted from `engineCounts` use `samplesPerEngine`. The control panel
constructs these settings for you; editing `config.scd` remains optional.

Macros can also be supplied from code, with values from `0` to `1`:

```supercollider
macros: (
    weight: 0.8,
    punch: 0.65,
    brightness: 0.35,
    tail: 0.5,
    dirt: 0.7
)
```

Keep the same `randomSeed` to reproduce the same parameter sequence. Every
generated sound also receives a deterministic synthesis seed, including its
server-side noise generators.

### Profiles

Two profiles are available:

- `\thickClub` — 60 balanced dancehall, grime, and gqom samples by default
- `\original` — 60 broad experimental samples by default

Select one in `config.scd`:

```supercollider
activeProfile: \original
```

Profiles register their own engines and defaults. They do not overwrite the
original SynthDefs or the shared job planner, so multiple profiles can coexist.

## Output and safety

Each generation creates a directory such as:

```text
output/20260810214530_thickClub/
```

The directory contains completed WAV files, `sample_manifest.txt`, and a
reusable `recipe.json`. Previous runs are not overwritten. Each render is first
written to a temporary file and is promoted only after these checks pass:

- mono channel layout
- configured sample rate and sample format
- expected duration
- non-silent signal
- peak within the configured limits
- DC offset and RMS level
- a quiet final tail, preventing abruptly truncated samples

The manifest records the profile, seed, project and SuperCollider versions, Git
revision and dirty state, export settings, raw parameters, effective amplitude,
audio metrics, failures, cancellation state, and final totals.

Regenerate a saved pack or close variation from its exact profile, family
counts, parameter locks, seed, and level settings:

```supercollider
~replayRecipe.("/full/path/to/recipe.json");
```

Favorite exports also include `favorites_recipe.json`. It uses pad-oriented
filenames and the already-scaled effective parameters, preventing master level
from being applied twice when the kit is rebuilt.

Generated output is ignored by Git. Publish selected packs as release downloads
or copy them directly to removable media rather than committing each run.

> Packs rendered before version 0.2.0 should be regenerated. The previous
> full-rate `Latch` path could create silent files when
> `sampleRateReduction` was exactly 44100.

## Presets

Hand-edited sounds live in `presets/presets.scd`. Export one after loading
`main.scd`:

```supercollider
~renderPreset.(\deepKick);
~renderPreset.(\industrialSnare);
~renderPreset.(\metalObject);
~renderPreset.(\extremeGlitch);
```

Supply another filename if required:

```supercollider
~renderPreset.(\deepKick, "MY_KICK.wav");
```

Preset renders receive their own run directory and manifest.

Create a variation without changing the original preset:

```supercollider
(
var sound;

sound = ~presetVariation.(
    \deepKick,
    (frequency: 38, decay: 1.1, foldAmount: 0.25, bits: 9)
);

~renderSound.(sound, "DEEP_KICK_VARIATION.wav");
)
```

## Sound design

The original random ranges are in `lib/generator.scd`. The focused club ranges
are in `profiles/thick_2000s_club_profile.scd`. Each family specifies a SynthDef,
an MPC-safe prefix, a render duration, and a parameter generator.

The original engines share the post-processing chain in `lib/processing.scd`:
wavefolding, sample-rate reduction, signed bit-depth quantization, drive,
high-pass filtering, DC removal, and limiting. The club engines use their own
EQ and parallel saturation while sharing the quantizer implementation.

## Tests

The language-level smoke test loads every engine and profile, switches profiles,
plans both packs, and verifies filename safety and uniqueness without rendering
audio:

```sh
./scripts/test.sh
```

If SuperCollider is installed somewhere unusual:

```sh
SCLANG_BIN=/full/path/to/sclang ./scripts/test.sh
```

On Apple Silicon, the test launcher checks whether the native `sclang` process
can start and automatically uses the universal binary's x86_64 slice when the
arm64 Qt runtime is incompatible. An architecture can still be selected
explicitly, for example `SCLANG_ARCH=x86_64 ./scripts/test.sh`.

GitHub Actions runs the same smoke test on pushes and pull requests. Full audio
validation happens automatically during every local render. To exercise the
entire offline-rendering path with the four focused percussion voices (using
two concurrent workers):

```sh
./scripts/test.sh tests/render_smoke.scd
```

In a graphical desktop session, verify that the native control panel builds:

```sh
./scripts/test.sh tests/gui_smoke.scd
```

## Project structure

```text
sc-mpc-drum-lab/
├── main.scd
├── gui.scd
├── config.scd
├── synthdefs/
├── profiles/
├── lib/
│   ├── processing.scd
│   ├── renderer.scd
│   ├── manifest.scd
│   ├── generator.scd
│   ├── session.scd
│   ├── favorites.scd
│   └── gui.scd
├── presets/
├── sessions/
├── tests/
├── scripts/
├── output/
├── .github/workflows/
├── README.md
└── LICENSE
```

## MPC1000 transfer

1. Generate a pack, or audition and export up to 16 favorites from the control
   panel.
2. Open the newest run directory under `output/`.
3. Copy its WAV files to a CompactFlash card.
4. Load them on the MPC1000 and assign them to pads.
5. Save the program together with its samples.

Generated filenames are uppercase, zero-padded, short, and contain no spaces or
accented characters.

## Troubleshooting

### `Unknown profile` or `Missing generator specification`

Evaluate the complete `main.scd` file again. It loads all engine and profile
files before activating the configured profile.

### No files appear

Check the SuperCollider post window for a render failure and inspect the current
run's manifest. Confirm that the configured output directory is writable.

### A generation job is already running

Wait for active renders to finish or run `~cancelGeneration.()`. Cancellation
does not terminate an `scsynth` process mid-file; it prevents new jobs from
starting and finalizes the manifest after active jobs return.

### Samples are too extreme

Reduce distortion, FM, comb, or drive parameters. Increase `bits` and
`sampleRateReduction`.

### Samples are too quiet

Set an explicit `masterAmp` in `config.scd`, or adjust the family's `amp`. The
limiter intentionally leaves headroom for layered MPC programs.

## License

MIT. See `LICENSE`.

Akai and MPC are trademarks of their respective owners. This project is
independent and is not affiliated with or endorsed by Akai Professional.
