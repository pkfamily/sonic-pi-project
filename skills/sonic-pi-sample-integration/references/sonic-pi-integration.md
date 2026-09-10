# Sonic Pi sample integration reference

Use this reference after a source has passed provenance and license review and
its SFZ has been inspected.

## Local layout and loading

Keep third-party audio under the target track's ignored `references/local_samples/`
tree. Resolve the repository at runtime with a track-specific environment
variable such as `SONIC_PI_PROJECT_ROOT`, then construct paths with `File.join`.
If a fallback is useful for the repository owner, keep the environment override
authoritative and document the fallback.

Build a map containing only the source regions used by the phrase. Before the
timeline starts, verify each selected path with `File.exist?` and preload it
with `load_sample`. Raise a message that contains the missing absolute path.
Avoid variable names that shadow Sonic Pi functions, including `sample`,
`synth`, `chord`, and `scale`.

## Pitch and region mapping

Use the SFZ's `pitch_keycenter`, not the filename, as the source pitch. Sonic
Pi's playback rate for equal-tempered transposition is:

```ruby
rate_value = 2 ** ((target_midi - source_midi) / 12.0)
```

Prefer the region whose declared key range contains the target. Small shifts
usually retain realism better than large ones; audition boundary notes when two
recorded pitches could serve the same target.

Map the musical dynamics to declared `lovel`/`hivel` layers rather than making
every event equally loud. For `lorand`/`hirand` or `seq_length`/`seq_position`
alternates, create a deterministic order derived from stable values such as the
absolute bar and event index. Do not call an uncontrolled random selector in a
finite arrangement intended to render reproducibly.

## Study design

- Copy the immediate predecessor's event pitches, onsets, durations, and phrase
  boundaries exactly when the task is sound replacement.
- Keep ordinary bar helpers at exactly four beats and every thread finite.
- Pass sample roots and maps into helpers when Sonic Pi's method scope would
  otherwise hide top-level variables.
- Begin with the source recording and a short amplitude envelope. Add filters,
  saturation, ambience, doubling, or synthetic reinforcement one decision at a
  time after the dry source is judged.
- Suppress final-bar triggers and shorten releases when isolating a section or
  protecting a following silence.

An isolated study should make the replacement easy to hear without changing
the rest of the arrangement. Once approved, create a new standalone arrangement
derived from the immediate predecessor and preserve older versions.

## Reproducibility record

Document the provider page, exact release asset URL, release date/version,
download size, SHA-256, format and bit depth when known, license and license
URL, extraction destination, expected SFZ path, and every selected mapping.
Include a table with target pitch, source pitch, semitone shift, velocity layer,
and number or ordering of alternate takes.

Raw samples stay untracked by default. Documentation, scripts, and the Sonic Pi
mapping remain tracked so another user can reacquire the same release.
