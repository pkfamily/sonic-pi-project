# Aerodynamic distorted-guitar lead samples

This guide documents the local-only FreePats multisample used by the
distorted-guitar lead studies and the V12 guitar-pulse arrangement. The source
audio remains ignored by Git and is not redistributed with this repository.

## Selected source

The first lead candidate is FreePats FSBS Electric Guitar Distorted #2:

- Study: `tracks/aerodynamic/studies/lead_distorted_guitar_full_arc.rb`
- Selected study: `tracks/aerodynamic/studies/lead_distorted_guitar_zawa_layer.rb`
- Arrangement: `tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb`
- FreePats page: <https://freepats.zenvoid.org/ElectricGuitar/distorted-electric-guitar.html>
- GitHub repository: <https://github.com/freepats/electric-guitar-FSBS-dist2>
- Release: <https://github.com/freepats/electric-guitar-FSBS-dist2/releases/tag/2022-09-11>
- SFZ/FLAC asset: <https://github.com/freepats/electric-guitar-FSBS-dist2/releases/download/2022-09-11/EGuitarFSBS-dist2-SFZ%2BFLAC-20220911.7z>
- Instrument version: `2022-09-11`
- Release publication: `2026-08-08`
- Archive size: 135,646,700 bytes, approximately 129 MiB
- Archive SHA-256: `fee513712e10b31c78e45c7263c2860882c8e462d1733a7876a0d97d14303f4c`
- Format: processed distorted electric guitar, stereo 48 kHz, 24-bit FLAC
- License: Creative Commons CC0 1.0 public-domain dedication

The samples were made from direct recordings of a Fender electric guitar and
processed through an amplifier and effects rack. Distorted #2 was selected over
Distorted #1 for this first audition because its smaller archive and shorter
declared SFZ release suit the rapid sixteenth-note phrase.

## Local installation

From the repository root, use the sample-integration skill's safe downloader:

```sh
python3 skills/sonic-pi-sample-integration/scripts/acquire_sample_pack.py \
  --url 'https://github.com/freepats/electric-guitar-FSBS-dist2/releases/download/2022-09-11/EGuitarFSBS-dist2-SFZ%2BFLAC-20220911.7z' \
  --sha256 fee513712e10b31c78e45c7263c2860882c8e462d1733a7876a0d97d14303f4c \
  --destination tracks/aerodynamic/references/local_samples/electric_guitar_distorted
```

The downloader verifies the GitHub-published digest, checks the archive before
installing it, and discards the temporary archive after extraction. The study
expects this layout:

```text
tracks/aerodynamic/references/local_samples/electric_guitar_distorted/
  EGuitarFSBS-dist2 SFZ+FLAC-20220911/
    EGuitarFSBS-dist2 bridge 20220911.sfz
    samples/bridge/
```

Set `SONIC_PI_PROJECT_ROOT` to the checkout path when it differs from the
documented local fallback.

## Selected mappings

The source SFZ defines two velocity layers and four random alternate takes for
G3, B3, C-sharp4, and E4. Its G4 region has four takes and one velocity range.
The study preloads those 36 unique recordings and follows the SFZ boundaries.

| Target | SFZ source | Shift | Available layers |
|---|---|---:|---|
| F-sharp3 | G3 | -1 semitone | soft/firm, four takes each |
| G-sharp3 | G3 | +1 semitone | soft/firm, four takes each |
| A3 | B3 | -2 semitones | soft/firm, four takes each |
| B3 | B3 | none | soft/firm, four takes each |
| C-sharp4 | C-sharp4 | none | soft/firm, four takes each |
| D4 | C-sharp4 | +1 semitone | soft/firm, four takes each |
| E4 | E4 | none | soft/firm, four takes each |
| F-sharp4 | G4 | -1 semitone | single layer, four takes |
| G4 | G4 | none | single layer, four takes |
| G-sharp4 | G4 | +1 semitone | single layer, four takes |

The first note of every four-note cell uses the firm layer; the other notes use
the soft layer. G4-region notes use the sole available layer. Alternate takes
cycle in the fixed order 1, 3, 4, 2 from the absolute bar and event position.
No additional synth, filter, distortion, ambience, or stereo widening is used.

## Zawa-layer A/B study

`tracks/aerodynamic/studies/lead_distorted_guitar_zawa_layer.rb` preserves the
sample-only study's complete 34-bar sequence and layers `:zawa` at the same
pitches and onset times. The layer uses a 0.01-beat attack, no sustain, a
release scaled to 70 percent of each guitar envelope with a 0.025-beat minimum,
cutoff 96, phase 0.25, and amp 0.13 on cell accents or 0.11 elsewhere. This
keeps the multisample as the main voice while testing whether a compact
synthetic transient improves definition. The sample-only study remains
unchanged for direct comparison.

V12 promotes this exact guitar/zawa balance across the 1:04-2:12 lead arc. It
removes V11's blade double, retains the user-selected `:dsaw` accent bars, and
keeps the transition bar's secondary pluck phrase, bass, and drums. A scoped
`0.79` lead gain matches the isolated V11 lead level without changing the
approved guitar-to-zawa balance or lowering unaffected arrangement sections.

## Run and render the study

Open the study in Sonic Pi and run it. It outputs only the complete 34-bar lead
arc at 120 BPM, lasting 68 seconds.

To make a local audition render:

```sh
mkdir -p renders/aerodynamic_lead_distorted_guitar

SONIC_PI_PROJECT_ROOT="$PWD" \
ruby tools/sonic_pi_headless_record.rb \
  -o renders/aerodynamic_lead_distorted_guitar/lead_distorted_guitar_full_arc.wav \
  -d 72 \
  -f tracks/aerodynamic/studies/lead_distorted_guitar_full_arc.rb
```

Render the zawa-layer comparison separately so both versions remain available:

```sh
SONIC_PI_PROJECT_ROOT="$PWD" \
ruby tools/sonic_pi_headless_record.rb \
  -o renders/aerodynamic_lead_distorted_guitar/lead_distorted_guitar_zawa_layer.wav \
  -d 72 \
  -f tracks/aerodynamic/studies/lead_distorted_guitar_zawa_layer.rb
```

Listen for pitch accuracy, repeated-sample artifacts, excessive overlap, and
whether the shortened final stutter remains distinct.

## Reproduce and render V12

V12 requires both guitar libraries. First install the clean pack by following
the [V11 from-scratch walkthrough](aerodynamic-opening-groove-samples.md#reproduce-v11-from-a-fresh-clone),
then install the distorted pack at the path documented above. With both packs
present, render the complete 416-beat arrangement from the repository root:

```sh
mkdir -p renders/aerodynamic_v12

SONIC_PI_PROJECT_ROOT="$PWD" \
ruby tools/sonic_pi_headless_record.rb \
  -o renders/aerodynamic_v12/aerodynamic_remix_v12_guitar_pulse.wav \
  -d 212 \
  -f tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb
```

The full-resolution render includes recorder padding and a terminal engine
tail. The website copy removes the first 0.5 seconds, keeps exactly 208 seconds
of arrangement audio, and converts it to stereo 44.1 kHz/16-bit PCM. V11
remains unchanged as the immediate predecessor.
