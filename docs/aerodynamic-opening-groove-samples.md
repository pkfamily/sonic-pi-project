# Aerodynamic opening-groove samples

This documents the local-only sample sources used by the opening-groove
multisample studies. The audio files are deliberately ignored by Git and are
not redistributed with this repository.

## Reproduce V11 from a fresh clone

The commands below are tested on macOS with Sonic Pi v5 installed in
`/Applications`. They require Git and the macOS-provided `curl`, `shasum`, and
`bsdtar` tools.

### 1. Clone the project

```sh
git clone https://github.com/pkfamily/sonic-pi-project.git
cd sonic-pi-project
sonic_pi_project_root="$PWD"
```

Keep this terminal open: the remaining commands use
`$sonic_pi_project_root` to locate the clone.

### 2. Download and install the guitar samples

The archive is downloaded into a temporary directory, verified, and extracted
into the ignored local-sample directory. It does not need to be copied into Git.

```sh
mkdir -p \
  "$sonic_pi_project_root/tracks/aerodynamic/references/local_samples/electric_guitar"

guitar_download_dir="$(mktemp -d /tmp/aerodynamic-guitar.XXXXXX)"
guitar_archive="$guitar_download_dir/EGuitarFSBS-clean-SFZ+FLAC-20260807.7z"

curl -fL \
  -o "$guitar_archive" \
  'https://github.com/freepats/electric-guitar-FSBS-clean/releases/download/2026-08-07/EGuitarFSBS-clean-SFZ%2BFLAC-20260807.7z'

printf '%s  %s\n' \
  'a929a3cbfc8289e325be56dab49f5fd560bbc3995c40b69f8f05caee380e8be3' \
  "$guitar_archive" | shasum -a 256 -c -

bsdtar -xf "$guitar_archive" \
  -C "$sonic_pi_project_root/tracks/aerodynamic/references/local_samples/electric_guitar"
```

A successful checksum reports `OK`. The arrangement expects this directory:

```text
tracks/aerodynamic/references/local_samples/electric_guitar/
  EGuitarFSBS-clean SFZ+FLAC-20260807/samples/bridge/
```

### 3. Run the complete arrangement in Sonic Pi

Quit Sonic Pi first if it is already open; macOS only applies `--env` when it
launches a new application process. Copy V11, launch Sonic Pi with the clone
path, paste into a buffer, and press **Run**:

```sh
pbcopy < \
  "$sonic_pi_project_root/tracks/aerodynamic/arrangements/aerodynamic_remix_v11_clean_guitar.rb"

open -a "Sonic Pi" \
  --env "SONIC_PI_PROJECT_ROOT=$sonic_pi_project_root"
```

V11 validates and preloads its sixteen required guitar recordings before the
arrangement begins. A `Missing clean-guitar sample` error means the project
root or extracted directory does not match the paths above.

### 4. Render the complete song from the command line

The optional headless workflow records the 3:28 arrangement plus a short engine
tail, producing a 48 kHz, 24-bit stereo WAV under the ignored `renders/`
directory:

```sh
mkdir -p "$sonic_pi_project_root/renders/aerodynamic_v11"

SONIC_PI_PROJECT_ROOT="$sonic_pi_project_root" \
ruby "$sonic_pi_project_root/tools/sonic_pi_headless_record.rb" \
  -o "$sonic_pi_project_root/renders/aerodynamic_v11/aerodynamic_remix_v11_clean_guitar.wav" \
  -d 212 \
  -f "$sonic_pi_project_root/tracks/aerodynamic/arrangements/aerodynamic_remix_v11_clean_guitar.rb"
```

If Sonic Pi is installed somewhere other than `/Applications`, set
`SONIC_PI_APP_ROOT` as described in the
[stem-rendering guide](aerodynamic-stem-rendering.md#requirements).

### Troubleshooting and other platforms

- If checksum verification fails, discard the temporary download and fetch it
  again before extracting anything.
- If the expected `samples/bridge/` directory is nested one level deeper or is
  absent, remove that extraction and rerun the exact `bsdtar` command above.
- If Sonic Pi was already running, quit it and rerun the `open --env` command so
  the application receives `SONIC_PI_PROJECT_ROOT`.
- Linux and Windows use the same `SONIC_PI_PROJECT_ROOT` value and extracted
  directory layout. Adapt the archive extraction and environment-variable
  syntax for the local shell; the commands above are verified only on macOS.

## Clean electric guitar study

The clavinet implementation proved that the multisample approach works, but
its source recording was not clean enough for the finished track. The next
candidate is a clean electric guitar: published reconstructions describe the
opening groove as bass slices interleaved with short chopped guitar hits, which
makes this a better instrumental fit than another synthesized pluck.

The selected source is FreePats Electric Guitar FSBS Clean #1:

- Study: `tracks/aerodynamic/studies/opening_groove_clean_guitar_multisample.rb`
- Full-groove excerpt: `tracks/aerodynamic/studies/opening_groove_clean_guitar_excerpt.rb`
- Main arrangement: `tracks/aerodynamic/arrangements/aerodynamic_remix_v11_clean_guitar.rb`
- Reconstruction reference: <https://reverbmachine.com/blog/daft-punk-aerodynamic-synth-solo-remake/>
- Project page: <https://freepats.zenvoid.org/ElectricGuitar/clean-electric-guitar.html>
- Full SFZ/FLAC download: <https://github.com/freepats/electric-guitar-FSBS-clean/releases/download/2026-08-07/EGuitarFSBS-clean-SFZ%2BFLAC-20260807.7z>
- Version: `2026-08-07`
- Download size: approximately 118 MiB
- Archive SHA-256: `a929a3cbfc8289e325be56dab49f5fd560bbc3995c40b69f8f05caee380e8be3`
- Format: processed clean electric guitar, stereo 48 kHz, 24-bit FLAC
- Mapping: two recorded velocity layers and four alternate takes per region
- License: Creative Commons CC0 1.0 public-domain dedication

### Selected guitar mappings

The study follows the supplied SFZ regions instead of inferring mappings from
filenames. It preloads only the sixteen recordings needed by the phrase.

| Target | SFZ source | Shift | Dynamics | Alternate takes |
|---|---|---:|---|---:|
| A3 | B3, string 5 | -2 semitones | soft/firm | 4 per layer |
| B3 | B3, string 5 | none | soft/firm | 4 per layer |
| D4 | C-sharp4, string 5 | +1 semitone | soft/firm | 4 per layer |

Phrase levels below `1.05` select the SFZ soft layer; the two D4 accents per
bar select the firm layer. Alternate takes cycle deterministically per target
pitch. The short Sonic Pi release envelopes create the chopped articulation;
no filter, distortion, reverb, or synthetic reinforcement is applied in this
first audition.

### Chord-stab A/B studies

Two matched studies isolate absolute opening-groove bars 9-20:

- `tracks/aerodynamic/studies/opening_groove_chord_stabs_synth.rb` retains the
  original `:dpulse` E-major and A-major stabs.
- `tracks/aerodynamic/studies/opening_groove_chord_stabs_guitar.rb` replaces
  only those stabs with low-to-high firm downstrokes and high-to-low soft
  responses from the FreePats pack.

Both studies retain identical main guitar, bass, drums, sub, accents, pads,
and the one-time synthetic micro-chop. They each run for twelve bars/48 beats,
making them suitable for direct level-matched comparison. Their stab gains are
raised approximately 8 dB over the subtle V10 layer and their releases are
extended from `0.12` to `0.18` beats so the chords remain audible against the
bass and offbeat hats. Listening showed that audible stabs interrupted the
core groove, so V11 removes the `:dpulse` layer instead of adopting the sampled
replacement. These files remain as rejected A/B studies.

## Clavinet study

### Selected source

The first candidate, the Hochschule für Musik Trossingen Hohner Clavinet
Sampler, could not be used because its published download returned HTTP 404.

The working fallback is the No Budget Orchestra clavinet:

- Download: <https://www.bandshed.net/sounds/sfz/clavinet.zip>
- SFZ maintenance fork and terms: <https://github.com/ssj71/No-Budget-Orchestra>
- Archive SHA-256: `9fd87e1a6d779db13f5b0f8fca812071147681d03783c334081c5284a6551ecd`
- Format: stereo 44.1 kHz, 16-bit WAV with an SFZ mapping and separate release
  samples

The stated terms permit using the samples as part of a personal or commercial
musical composition in combination with other sounds, but prohibit selling
them as a commercial sample library. Keep the raw files local and review the
upstream terms before publishing audio.

### Local installation

From the repository root:

```sh
mkdir -p tracks/aerodynamic/references/local_samples/clavinet
curl -fL \
  -o /tmp/no-budget-orchestra-clavinet.zip \
  https://www.bandshed.net/sounds/sfz/clavinet.zip
shasum -a 256 /tmp/no-budget-orchestra-clavinet.zip
unzip /tmp/no-budget-orchestra-clavinet.zip \
  -d tracks/aerodynamic/references/local_samples/clavinet
```

The study expects the resulting `Clavinet/` directory beneath that location.
It uses the same `SONIC_PI_PROJECT_ROOT` override as the guitar files.

### Selected mappings

The source SFZ has one velocity layer sampled every major third. The opening
groove uses only A3, B3, and D4, so the nearest recordings require small pitch
shifts:

| Target | Source file | Source pitch | Shift | SHA-256 |
|---|---|---:|---:|---|
| A3 | `4_Ab.wav` | G-sharp3 | +1 semitone | `611fb2481f0c106951e4dc67474635475be6eb4febb495e1c4fd89534119c986` |
| B3 | `5_C.wav` | C4 | -1 semitone | `100cc03be9f77e6aa397e36af56aecb3966d076c8e9ffc1a89191ab07721a10a` |
| D4 | `5_E.wav` | E4 | -2 semitones | `cb6a3db07e1ca09b7cffffc89badd58719f4103f1a2a307b85c31d4ae87c4adb` |

The clavinet study uses no filters, distortion, reverb, release-noise samples,
or synthetic reinforcement. Dynamics come only from the V10 event levels and
four-position phrase-gain pattern so the source timbre can be judged directly.
It remains available for A/B comparison even though its source quality was
rejected for the finished arrangement.
