# Release checklist

Run these checks from a clean checkout before a release:

1. Run `./scripts/test.sh tests/smoke.scd`.
2. Run `./scripts/test.sh tests/render_smoke.scd` on a machine with `scsynth`.
3. In the SuperCollider IDE, evaluate `gui.scd`, generate a preview, save and
   reload a session, then rebuild and export a favorite kit.
4. Confirm that exported WAV files are mono, 44.1 kHz, 16-bit and that the
   generated manifest has no validation failures.
5. Plan each reference pack below with its stated seed and compare its ordered
   filenames and parameter recipes against the release candidate.

## Reproducible reference packs

| Name | Command | Expected pads |
| --- | --- | ---: |
| Dancehall foundation | `~dryRunKitTemplate.(\dancehall16, (randomSeed: 101));` | 16 |
| Grime foundation | `~dryRunKitTemplate.(\grime16, (randomSeed: 202));` | 16 |
| Gqom foundation | `~dryRunKitTemplate.(\gqom16, (randomSeed: 303));` | 16 |

Reference packs are recipes rather than checked-in audio so the repository
stays small. A fixed seed makes their planned parameters and render jobs
repeatable across releases.
