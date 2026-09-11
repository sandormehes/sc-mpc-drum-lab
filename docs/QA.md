# Quality gates

Every pull request must pass the language and offline-render suites on Linux and macOS.

The language suite verifies every profile and kit template can plan deterministic jobs, all
referenced engines are registered, and sessions/recipes remain valid. The render suite
renders representative WAVs, validates format, level, DC and tail measurements, then
checks replay, variation, sampler-map and Web Kit exports.

## Cross-project contract

`~exportDrumLabWebKit` is the handoff boundary to Drum Pattern Library. Its output must
contain `manifest.json` plus at least one WAV for each `kick`, `snare`, `hat`, and `perc`
role. A single role may be a string or an array of WAV filenames for round robin.

Before release, run the Drum Pattern Library validation against a newly exported kit and
audition a pattern with the Drum Lab sound set selected.

## Release checklist

1. All CI checks pass on the release commit.
2. Render reference kits for every shipped profile and inspect manifests, waveforms, and
   peak/tail measurements.
3. On macOS, verify Preview, queued Preview, and Restart audio using the intended output
   device.
4. Verify a Web Kit export in Drum Pattern Library and an MPC-map export on target hardware.
5. Update version and release notes, tag the commit, then publish.
