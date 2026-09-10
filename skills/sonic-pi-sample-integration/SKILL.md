---
name: sonic-pi-sample-integration
description: Find, safely acquire, inspect, and integrate clearly licensed SFZ sample packs into Sonic Pi tracks. Use for FreePats or comparable sample-library research, local installation, SFZ mapping, sample-backed studies, or promotion of an approved study into an arrangement.
---

# Sonic Pi Sample Integration

Use a study-first workflow that keeps acquisition, sound design, transcription,
arrangement, and mixing as separate decisions.

## Find and assess a source

1. Search the provider's authoritative project and release pages. For FreePats,
   start with the `freepats` GitHub organization, open the instrument repository
   and its releases, then cross-check the matching FreePats instrument page and
   repository license. Consider another SFZ source when its provenance and
   license are clear.
2. Record the project URL, exact asset URL, release/version, archive format and
   size, license name, and license URL. Do not infer permission from a free
   download or a public repository.
3. Reject a pack when its license is unclear, its asset URL is unofficial, or
   it contains unauthorized copyrighted recordings.
4. Compare relevant musical qualities before downloading a large pack: pitch
   coverage, articulations, velocity layers, alternate takes, sample format,
   recording quality, and expected processing.

For a GitHub release, inspect its API metadata when available. Prefer the exact
`browser_download_url`, asset byte size, and published `digest` over values
inferred from a rendered release page or filename.

Internet research does not authorize a download. Obtain any approval required
by the active environment immediately before network or external filesystem
operations.

## Acquire and inspect

- Put local audio under
  `tracks/<track>/references/local_samples/<instrument-or-pack>/`. Confirm that
  location is ignored by Git unless the user explicitly asks to redistribute
  assets and the license permits it.
- Use `scripts/acquire_sample_pack.py` for deterministic downloading, hashing,
  archive validation, and collision-free extraction. Supply a published
  checksum with `--sha256`; otherwise use `--accept-unverified` only after
  explaining that authenticity is not independently verified, then retain the
  computed SHA-256 in tracked documentation.
- Do not retain the downloaded archive after successful extraction unless the
  user asks for it.
- Use `scripts/inspect_sfz.py` to inventory an SFZ or query target notes and
  velocities. Treat its mapping as source data; do not infer pitch centers from
  filenames when the SFZ specifies them.
- Stop on unsafe archives, destination collisions, unsupported SFZ include
  directives, missing referenced samples, or ambiguous licensing. Do not use a
  force-overwrite path.

## Integrate into Sonic Pi

Read [references/sonic-pi-integration.md](references/sonic-pi-integration.md)
before writing or modifying Sonic Pi code.

Create an isolated, finite study in the target track's `studies/` directory.
Preserve source-derived notes, order, timing, and section length unless the
user separately requests recomposition. Select the smallest useful sample
subset, retain meaningful velocity layers and alternate takes, and make sample
selection deterministic.

After static validation, ask the user to audition the study. Only promote an
approved result into a new arrangement version. Preserve stable arrangements
and their protected passages, update derivation headers and README paths, and
never commit or push unless explicitly requested.

## Document and validate

Track enough information for a fresh clone to reproduce the result:

- authoritative project and asset URLs;
- release/version, archive SHA-256, format, and license;
- ignored local installation path and expected extracted layout;
- selected files, SFZ pitch centers, semitone shifts, velocity splits, and
  alternate-take policy;
- study and arrangement paths plus run/render instructions.

For every changed `.rb` file, follow the repository's `AGENTS.md`: run
`ruby -c`, Sonic Pi's actual pre-parser, reserved-name scanning, beat and cue
checks, protected-passage checks, and a complete audible test. Parser success
does not establish sample quality or mix balance.
