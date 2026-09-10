<p align="center">
  <img src="assets/sonic-pi-project-banner.svg" alt="Sonic Pi Projects — arrangements, reconstruction studies, and remixes" width="100%">
</p>

# Sonic Pi Projects

An archive of Sonic Pi arrangements, reconstruction studies, and remixes by
PK Family. The project contains a long-running fan-made study of Daft Punk's
“Aerodynamic,” Guitar Pro reconstructions of “Something About Us,” and smaller
original sketches such as *Midnight Club*.

These works are approximations made with Sonic Pi's built-in synths, samples,
and effects. They are educational fan projects, not official transcriptions or
releases.

## Listen online

<a href="https://brucewayneisbatman.org/sonic-pi-project/">
  <img src="assets/sonic-pi-media-player.png" alt="Historical V10 concept for the Sonic Pi media player" width="100%">
</a>

The image above is an earlier V10 player concept; the live player reflects the
current published mixes.

Listen to the published [Sonic Pi media player](https://brucewayneisbatman.org/sonic-pi-project/).
The repository also includes the player source as a static [GitHub Pages
listening site](docs/), currently featuring compact browser renders of the
latest Aerodynamic mix and the Something About Us GP5 reconstruction.

To publish it, open **Settings → Pages** on GitHub, choose **Deploy from a
branch**, then select the default branch and the `/docs` folder.

## Quick start

1. Install [Sonic Pi](https://sonic-pi.net/).
2. Clone the repository:

   ```sh
   git clone git@github.com:pkfamily/sonic-pi-project.git
   cd sonic-pi-project
   ```

3. Open a `.rb` file in Sonic Pi, paste it into a buffer, and press **Run**.

Recommended entry points:

- [Aerodynamic V12 guitar pulse](tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb)
- [Aerodynamic clean-guitar opening groove](tracks/aerodynamic/studies/opening_groove_clean_guitar_excerpt.rb)
- [Something About Us GP5 master](tracks/something_about_us/arrangements/something_about_us_gp5_master.rb)
- [Something About Us GP5 audition](tracks/something_about_us/arrangements/something_about_us_gp5_audition.rb)
- [Aerodynamic lead-only study](tracks/aerodynamic/studies/lead_only.rb)
- [Aerodynamic distorted-guitar lead study](tracks/aerodynamic/studies/lead_distorted_guitar_full_arc.rb)
- [Aerodynamic guitar/zawa lead study](tracks/aerodynamic/studies/lead_distorted_guitar_zawa_layer.rb)
- [Midnight Club sketch](tracks/midnight_club/midnight_club.rb)

## Project structure

```text
tracks/
├── aerodynamic/
│   ├── arrangements/  # Complete tracks and historical iterations
│   ├── studies/       # Isolated phrases and comparison experiments
│   └── references/    # GP4, MIDI, and saved research material
├── midnight_club/     # Standalone Sonic Pi sketch
└── something_about_us/
    ├── arrangements/  # GP4/GP5 reconstructions and audition variants
    └── references/    # Guitar Pro source files
docs/                  # GitHub Pages player and web-sized audio
renders/               # Ignored local full-resolution exports
tools/                 # Reproducible render and manifest scripts
skills/                # Reusable Codex workflows and deterministic helpers
```

Complete tracks belong in `arrangements/`, isolated experiments in `studies/`,
and source material in `references/`. Rendered audio for the website belongs in
`docs/audio/`; full-resolution local renders remain under the ignored
`renders/` directory. Only finished, web-sized listening copies belong in
`docs/audio/`; stems, full-resolution masters, and A/B renders must remain in
`renders/` so they do not enter Git history.

The [Aerodynamic studies index](tracks/aerodynamic/studies/README.md) records
which isolated experiments were selected, retained for comparison, or rejected.

## Reusable sample integration skill

The repository includes a
[Sonic Pi sample integration skill](skills/sonic-pi-sample-integration/SKILL.md)
for finding clearly licensed FreePats or SFZ libraries, safely downloading and
inspecting them, and turning selected regions into reproducible Sonic Pi
studies. It keeps raw audio in each track's ignored `references/local_samples/`
directory and records source URLs, checksums, licensing, and pitch mappings in
tracked documentation.

Install the repository copy for personal Codex use with a symlink:

```sh
ln -s "$PWD/skills/sonic-pi-sample-integration" \
  "$HOME/.codex/skills/sonic-pi-sample-integration"
```

Then invoke it explicitly, for example:

```text
$sonic-pi-sample-integration find a licensed clean bass sample pack and build an isolated study for this track
```

The workflow creates and validates an isolated study before modifying an
arrangement. Promotion into a newly versioned arrangement remains a separate,
user-approved step.

## Aerodynamic arrangements

The [V12 guitar-pulse mix](tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb)
is the latest arrangement at 120 BPM. It preserves V11's clean-guitar groove
and structure while replacing the main lead stack with the FreePats Distorted
#2 multisample plus a restrained `:zawa` transient. The occasional `:dsaw`
lead accents remain. A fresh checkout needs both the clean pack documented in
the [V11 walkthrough](docs/aerodynamic-opening-groove-samples.md#reproduce-v11-from-a-fresh-clone)
and the distorted pack documented in the
[lead-sample guide](docs/aerodynamic-lead-samples.md).
See the complete [Aerodynamic arrangement history](docs/aerodynamic-arrangement-history.md)
for the version table, derivation notes, and timeline.

V10 remains the latest fully built-in and stem-rendered version. Its aligned
stems were imported into REAPER and mixed there as part of the REAPER MCP
production workflow; see the [Aerodynamic REAPER retrospective](docs/aerodynamic-reaper-retrospective.md)
for the mix experiments and conclusions.

The [clean-guitar opening-groove excerpt](tracks/aerodynamic/studies/opening_groove_clean_guitar_excerpt.rb)
outputs only V10's twenty active groove bars, replacing the synthesized main
funk line with the local FreePats multisample documented in
`docs/aerodynamic-opening-groove-samples.md`.

The [guitar/zawa lead study](tracks/aerodynamic/studies/lead_distorted_guitar_zawa_layer.rb)
isolates the complete 1:04-2:12 lead arc using the V12 lead voice. Its
sample-only predecessor remains available for A/B comparison. Download and
mapping details are in the
[Aerodynamic lead-sample guide](docs/aerodynamic-lead-samples.md).

## Something About Us reconstructions

The [GP4 master](tracks/something_about_us/arrangements/something_about_us_gp4_master.rb)
is a finite five-track reconstruction at 95 BPM. The [GP5 master](tracks/something_about_us/arrangements/something_about_us_gp5_master.rb)
is a finite seven-track, 104-measure reconstruction at 100 BPM. The GP5 folder
also contains audition variants with per-layer mute switches and increasingly
compact pattern storage; their GP5 note data is unchanged.

## Validation and rendering

Check ordinary Ruby syntax first:

```sh
ruby -c tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb
```

With Sonic Pi installed in `/Applications`, run the actual pre-parser:

```sh
SP_ROOT='/Applications/Sonic Pi.app/Contents/Resources/app/server/ruby'
'/Applications/Sonic Pi.app/Contents/Resources/app/server/native/ruby/bin/ruby' \
  -I"$SP_ROOT/lib" \
  -I"$SP_ROOT/vendor/kramdown-2.1.0/lib" \
  -e "require '$SP_ROOT/core'; require 'sonicpi/lang/core'; require 'sonicpi/preparser'; SonicPi::PreParser.preparse(File.read(ARGV.fetch(0)), SonicPi::Lang::Core.vec_fns); puts 'Sonic Pi pre-parser OK'" \
  tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb
```

Static checks cannot reveal balance, timbre, or audible tail leakage. Listen to
the complete arrangement in Sonic Pi after changing a track, and recalculate
beat totals and cue timestamps for timing edits.

### Aerodynamic stem export

The [stem-rendering workflow](docs/aerodynamic-stem-rendering.md) documents
pinned versions, verification, REAPER import, and fork maintenance. The
[REAPER MCP setup guide](docs/reaper-mcp-setup.md) covers the Codex connection
and troubleshooting.

With Sonic Pi installed, render all V10 profiles with:

```sh
ruby tools/render_aerodynamic_stems.rb
```

Pass profile names to render only selected stems, for example:

```sh
ruby tools/render_aerodynamic_stems.rb drums bass lead
```

Aligned WAV files are written to `renders/aerodynamic_v10/` and can be imported
at the same start position into a REAPER project set to 120 BPM. Set
`SONIC_PI_HEADLESS_RECORD` when Sonic Pi is installed somewhere other than
`/Applications`. The [Aerodynamic REAPER retrospective](docs/aerodynamic-reaper-retrospective.md)
records the production experiments and conclusions.

## Attribution and status

This is an educational fan project. “Aerodynamic” and “Something About Us”
were written and released by Daft Punk. Referenced compositions and source
materials remain the property of their respective owners.

This repository does not currently include an explicit software or content
license. Do not assume that third-party reference files are freely
redistributable merely because they are present here.
