# SC MPC Drum Lab

A modular experimental drum synthesizer and sample generator built with SuperCollider.

SC MPC Drum Lab creates synthesized drum one-shots and exports them as mono WAV files suitable for use with the Akai MPC1000 and other hardware or software samplers.

The project includes multiple drum synthesis engines, controlled randomization, digital degradation, resonators, FM synthesis, wavefolding, and automatic offline sample rendering.

## Features

- Experimental kick generator
- Experimental snare generator
- Metallic percussion generator
- Glitch and digital percussion generator
- Resonator-based percussion generator
- FM synthesis
- Ring modulation
- Wavefolding
- Bit-depth reduction
- Sample-rate reduction
- Comb filtering
- Controlled randomization
- Reproducible random sample generation
- Parameter manifest generation
- Offline WAV rendering
- MPC1000-friendly file naming

## Output Format

Generated samples use the following format:

- WAV
- Mono
- 44.1 kHz sample rate
- 16-bit integer encoding

The synthesis process may internally use bit crushing and sample-rate reduction, but the final exported file remains a standard 44.1 kHz, 16-bit WAV file.

## Requirements

- SuperCollider
- `scsynth`, included with SuperCollider
- A writable user home directory

No external SuperCollider extensions are required.

## Installation

Clone or download the repository:

```bash
git clone https://github.com/your-username/sc-mpc-drum-lab.git
cd sc-mpc-drum-lab
```

Open the main file in SuperCollider:

```text
experimental_mpc_drum_lab.scd
```

## Project Structure

```text
sc-mpc-drum-lab/
├── README.md
├── experimental_mpc_drum_lab.scd
├── presets/
│   └── example_presets.scd
├── examples/
│   └── custom_samples.scd
├── output/
│   └── .gitkeep
└── LICENSE
```

## Quick Start

Open `experimental_mpc_drum_lab.scd` in the SuperCollider IDE.

Run the code blocks in the following order:

1. Setup
2. SynthDefs
3. Export engine
4. Parameter manifest
5. Randomization helpers
6. Sample pack generator

To evaluate a block in SuperCollider:

- Place the cursor inside the parentheses.
- Press `Ctrl+Enter` on Windows or Linux.
- Press `Cmd+Enter` on macOS.

The full sample pack generator creates:

- 12 experimental kicks
- 12 experimental snares
- 12 metallic percussion samples
- 12 glitch percussion samples
- 12 resonator percussion samples

A complete run produces 60 WAV files.

## Output Directory

By default, generated samples are written to:

```text
~/MPC1000_Experimental_Drums
```

The output directory can be changed near the beginning of the main file:

```supercollider
~outputDirectory = Platform.userHomeDir +/+ "MPC1000_Experimental_Drums";
```

For example:

```supercollider
~outputDirectory = "/Users/yourname/Desktop/MPC_Drums";
```

On Windows, use a valid SuperCollider path:

```supercollider
~outputDirectory = "C:/Users/yourname/Desktop/MPC_Drums";
```

## Generating the Full Sample Pack

Run the block named:

```text
GENERATE BALANCED EXPERIMENTAL SAMPLE PACK
```

The generator uses controlled parameter ranges rather than unrestricted randomness. This helps produce unusual sounds that remain useful as drum samples.

The generated file names follow a simple format:

```text
XKICK_001.wav
XSNARE_001.wav
METAL_001.wav
GLITCH_001.wav
RESON_001.wav
```

Short names without spaces or accented characters are used for better compatibility with hardware samplers.

## Reproducible Randomization

The generator uses a fixed random seed:

```supercollider
thisThread.randSeed = 26071986;
```

Using the same seed produces the same parameter sequence.

Change the value to generate a different sample pack:

```supercollider
thisThread.randSeed = 12345678;
```

Keep the seed unchanged when you want to recreate the same sounds.

## Parameter Manifest

Each generation run creates:

```text
sample_manifest.txt
```

The manifest contains:

- File name
- SynthDef name
- Parameter values used for generation

Example:

```text
XKICK_001.wav | experimentalKick | [frequency, 48.2, decay, 0.51, bits, 12, ...]
```

The manifest makes it possible to identify and manually recreate useful sounds.

## Generating a Single Sample

Use the `~renderDrum` function to render one sound.

Example:

```supercollider
~renderDrum.(
    \experimentalKick,
    [
        \amp, 0.72,
        \frequency, 43,
        \decay, 0.75,
        \pitchAmount, 6.5,
        \pitchBounce, 0.18,
        \clickAmount, 0.08,
        \fmAmount, 0.3,
        \foldAmount, 0.12,
        \drive, 2.0,
        \bits, 12,
        \sampleRateReduction, 18000,
        \combAmount, 0.08
    ],
    "CUSTOM_DEEP_KICK.wav",
    1.7
);
```

The final argument controls the rendered file duration in seconds.

## Mutation Workflow

The project includes a controlled mutation example that creates three versions of one sound:

```text
MUTATION_KICK_CLEAN.wav
MUTATION_KICK_MEDIUM.wav
MUTATION_KICK_DESTROYED.wav
```

This workflow is useful when building layered MPC programs.

A practical sample set may include:

- A clean version for the main hit
- A moderately processed version for variation
- An extreme version for fills and accents

## Main Parameters

### Kick

Common kick parameters include:

```text
frequency
decay
pitchAmount
pitchBounce
clickAmount
clickTone
fmAmount
fmRatio
foldAmount
drive
bits
sampleRateReduction
combAmount
combTime
combDecay
```

### Snare

Common snare parameters include:

```text
frequency
decay
bodyAmount
noiseAmount
noiseTone
noiseWidth
fmAmount
ringAmount
ringRatio
foldAmount
drive
bits
sampleRateReduction
combAmount
```

### Metallic Percussion

Common metallic percussion parameters include:

```text
frequency
decay
exciterAmount
resonance
inharmonicity
fmAmount
foldAmount
drive
bits
sampleRateReduction
combAmount
combDecay
```

### Glitch Percussion

Common glitch parameters include:

```text
frequency
decay
pulseWidth
chaosAmount
noiseAmount
ringRatio
foldAmount
drive
bits
sampleRateReduction
combAmount
combTime
```

### Resonator Percussion

Common resonator parameters include:

```text
frequency
decay
brightness
resonance
spread
noiseAmount
foldAmount
drive
bits
sampleRateReduction
combAmount
```

## Sound Design Guidelines

Avoid maximizing every processing parameter at the same time.

Combining extreme FM, heavy wavefolding, low bit depth, low sample rate, high drive, and strong comb filtering often produces noise with little rhythmic usefulness.

A more effective approach is to emphasize one or two processing stages per sound.

For example:

```text
Metallic sound:
high resonance
moderate inharmonicity
low wavefolding
clean sample rate

Digital sound:
low bit depth
low sample rate
moderate FM
short decay

Industrial sound:
moderate ring modulation
moderate comb filtering
high drive
controlled noise
```

## Recommended Mutation Levels

### Clean

```supercollider
\fmAmount, 0.1,
\foldAmount, 0.0,
\bits, 16,
\sampleRateReduction, 44100,
\drive, 1.2
```

### Mutated

```supercollider
\fmAmount, 0.5,
\foldAmount, 0.2,
\bits, 9,
\sampleRateReduction, 11000,
\drive, 2.0
```

### Destroyed

```supercollider
\fmAmount, 1.2,
\foldAmount, 0.7,
\bits, 4,
\sampleRateReduction, 2200,
\drive, 4.0
```

## Loading Samples into the MPC1000

1. Generate the WAV files.
2. Copy the samples to a CompactFlash card.
3. Insert the card into the MPC1000.
4. Open the MPC file browser.
5. Load the WAV files.
6. Create or open a drum program.
7. Assign samples to pads.
8. Adjust tuning, filter, envelope, and level on the MPC.
9. Save the program and its associated samples.

For consistent transfers, keep file names short and avoid:

- Spaces
- Accented characters
- Special symbols
- Very long file names

## MPC Program Suggestions

A useful 16-pad layout might be:

```text
A01 Clean kick
A02 Mutated kick
A03 Destroyed kick
A04 Sub kick

A05 Clean snare
A06 Metallic snare
A07 Glitch snare
A08 Noise snare

A09 Closed metallic percussion
A10 Open metallic percussion
A11 Short resonator
A12 Long resonator

A13 High glitch
A14 Mid glitch
A15 Low glitch
A16 Texture
```

Related samples can also be assigned to velocity layers when using an operating system that supports layered programs.

## Rendering Performance

Offline rendering starts separate synthesis processes.

On slower systems, files may be created too quickly for consecutive render jobs. Increase the delay between render calls:

```supercollider
0.35.wait;
```

For example:

```supercollider
0.8.wait;
```

This does not change the sound. It only increases the time between render jobs.

## Troubleshooting

### No Files Are Generated

Check that:

- SuperCollider is installed correctly.
- `scsynth` is available.
- The output directory is writable.
- The setup block was evaluated.
- The SynthDef block was evaluated.
- The export engine was evaluated.

### Unknown SynthDef Error

The SynthDef section must be evaluated before rendering samples.

Run the complete SynthDef block again.

### Output Is Silent

Check:

- The `amp` parameter
- The render duration
- The decay value
- Whether the selected SynthDef exists
- Whether extreme processing values reduced the signal

Start with conservative values:

```supercollider
\amp, 0.7,
\drive, 1.2,
\bits, 16,
\sampleRateReduction, 44100,
\foldAmount, 0.0
```

### Samples Are Too Distorted

Reduce:

```text
drive
foldAmount
fmAmount
ringAmount
combAmount
```

Increase:

```text
bits
sampleRateReduction
```

### Samples Are Clipping

The SynthDefs include limiting, but multiple aggressive processing stages may still produce overly dense sounds.

Reduce the output amplitude:

```supercollider
\amp, 0.5
```

Do not normalize every sample to maximum digital level. Leaving headroom makes layering easier inside the MPC.

### Some Rendered Files Are Missing

Increase the wait time between render operations.

Change:

```supercollider
0.35.wait;
```

to:

```supercollider
1.0.wait;
```

## Extending the Project

Possible future additions include:

- Hi-hat synthesis
- Clap synthesis
- Cymbal synthesis
- Physical modeling
- Karplus–Strong percussion
- Granular drum generation
- Sample slicing
- Automatic silence trimming
- Automatic peak normalization
- CSV or JSON parameter manifests
- MIDI-controlled sound preview
- Graphical user interface
- Automatic MPC program generation

## Design Philosophy

The project is designed around controlled experimentation.

Pure randomization often generates a large number of unusable sounds. SC MPC Drum Lab instead uses bounded parameter ranges and separate synthesis engines.

The goal is not to make every sound extreme. The goal is to create coherent families of samples with different levels of mutation.

A balanced pack may contain:

```text
30% clean or stable sounds
40% moderately processed sounds
20% strongly processed sounds
10% extreme glitches and textures
```

This produces a sample library that remains playable while still having a distinctive experimental character.

## License

Choose a license before publishing the repository.

For an open-source project, the MIT License is a simple permissive option.

For code sharing with attribution and fewer restrictions, consider:

```text
MIT License
```

For stronger copyleft requirements, consider:

```text
GNU General Public License v3.0
```

## Disclaimer

The Akai and MPC names are trademarks of their respective owners.

This project is independent and is not affiliated with or endorsed by Akai Professional.
