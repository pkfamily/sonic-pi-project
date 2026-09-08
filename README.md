<p align="center">
  <img src="assets/sonic-pi-project-banner.svg" alt="Sonic Pi Projects — arrangements, reconstruction studies, and remixes" width="100%">
</p>

# Sonic Pi Projects

Sonic Pi arrangements, reconstruction studies, and remixes. The main project
is a fan-made study of Daft Punk's "Aerodynamic," developed from a Guitar Pro
reference and refined through several standalone versions.

The arrangements synthesize approximations with Sonic Pi's built-in synths,
samples, and effects. They are not official transcriptions or releases.

## Quick start

1. Install [Sonic Pi](https://sonic-pi.net/).
2. Clone this repository:

   ```sh
   git clone git@github.com:pkfamily/sonic-pi-project.git
   cd sonic-pi-project
   ```

3. Open a `.rb` file in Sonic Pi, paste its contents into a buffer, and press
   **Run**.

Recommended entry points:

- Stable remix: [filter-house V2](tracks/aerodynamic/arrangements/aerodynamic_remix_v2_filter_house.rb)
- Latest remix: [mix-polish V10](tracks/aerodynamic/arrangements/aerodynamic_remix_v10_mix_polish.rb)
- Stem-render reference: [V10 stems](tracks/aerodynamic/arrangements/aerodynamic_remix_v10_stems.rb)
- Structural reference: [structural re-edit V9](tracks/aerodynamic/arrangements/aerodynamic_remix_v9_structural_rework.rb)
- Simple-transition reference: [simple-lead-entry V8](tracks/aerodynamic/arrangements/aerodynamic_remix_v8_simple_lead_entry.rb)
- Lead-drop experiment: [lead-drop V7](tracks/aerodynamic/arrangements/aerodynamic_remix_v7_lead_drop.rb)
- Polished-arc reference: [polished-arc V6](tracks/aerodynamic/arrangements/aerodynamic_remix_v6_polished_arc.rb)
- Refined reference: [refined V5](tracks/aerodynamic/arrangements/aerodynamic_remix_v5_refined.rb)
- Cleanup reference: [cleanup V4](tracks/aerodynamic/arrangements/aerodynamic_remix_v4_cleanup.rb)
- Timing experiment: [timing-focused V3](tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb)
- Isolated comparison: [lead-only study](tracks/aerodynamic/studies/lead_only.rb)

## GitHub Pages listening site

The repository includes a static music player in [`docs/`](docs/). To publish
it from GitHub, open **Settings → Pages**, choose **Deploy from a branch**, then
select the default branch and the `/docs` folder. The first player track uses a
small 44.1 kHz mono WAV in [`docs/audio/`](docs/audio/); the full-resolution
stereo render remains in the local `renders/` workflow.

When adding a finished render, place its web-sized audio file in `docs/audio/`
and add a track row in `docs/index.html`. A browser-friendly WAV can be made
with macOS `afconvert`, for example:

```sh
afconvert renders/aerodynamic_v10/aerodynamic_v10_full.wav \
  -o docs/audio/aerodynamic_v10_web.wav -f WAVE -d LEI16@44100 -c 1
```

## Project structure

```text
tracks/
├── aerodynamic/
│   ├── arrangements/  # Complete tracks and historical iterations
│   ├── studies/       # Isolated phrases and comparison experiments
│   └── references/    # GP4, MIDI, and saved research material
└── midnight_club/     # Separate Sonic Pi track
```

The repository also contains a GP4-based reconstruction of Daft Punk's
“Something About Us” in [`tracks/something_about_us/`](tracks/something_about_us/).
The longer GP5-based comparison arrangement is
[`something_about_us_gp5_master.rb`](tracks/something_about_us/arrangements/something_about_us_gp5_master.rb).

The website includes a compact browser render of the complete GP5 arrangement:
[`something_about_us_gp5_web.wav`](docs/audio/something_about_us_gp5_web.wav).
The archival 24-bit stereo render is kept in the ignored local
`renders/something_about_us_gp5/` directory.

## Aerodynamic arrangement history

| Version | File | Purpose |
|---|---|---|
| Hand-built master | [`aerodynamic_master.rb`](tracks/aerodynamic/arrangements/aerodynamic_master.rb) | Early arrangement with explicit musical phases. |
| GP4 reconstruction | [`aerodynamic_gp4_master.rb`](tracks/aerodynamic/arrangements/aerodynamic_gp4_master.rb) | Arrangement rebuilt from the Guitar Pro reference. |
| Timed master | [`aerodynamic_timed_master.rb`](tracks/aerodynamic/arrangements/aerodynamic_timed_master.rb) | Aligns major entrances with the source track's approximate timestamps. |
| Funk-polished | [`aerodynamic_funk_polished.rb`](tracks/aerodynamic/arrangements/aerodynamic_funk_polished.rb) | Brings the opening melody forward with a tighter picked articulation. |
| Progressive remix V1 | [`aerodynamic_remix_v1.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v1.rb) | Adds deterministic French-house layers to the timed foundation. |
| Filter-house remix V2 | [`aerodynamic_remix_v2_filter_house.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v2_filter_house.rb) | Stable remix with progressive filtering, four-on-the-floor drums, and a protected lead solo. |
| Timing remix V3 | [`aerodynamic_remix_v3_timing.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb) | Experimental arrangement with delayed, half-time, double-time, and silent transitions. |
| Cleanup remix V4 | [`aerodynamic_remix_v4_cleanup.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v4_cleanup.rb) | Cleans percussion density, alternates tonal support layers, and tailors the final decay and bell. |
| Refined remix V5 | [`aerodynamic_remix_v5_refined.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v5_refined.rb) | Strengthens the remix arc with staged layer handoffs, internal breakdowns, and a cleaner post-bell deconstruction. |
| Polished-arc remix V6 | [`aerodynamic_remix_v6_polished_arc.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v6_polished_arc.rb) | Adds deterministic pocket, phrase filtering, and restrained stereo movement to V5's arrangement. |
| Lead-drop remix V7 | [`aerodynamic_remix_v7_lead_drop.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v7_lead_drop.rb) | Rebuilds the final eight opening bars into a rising transition with a protected silent beat before the defining lead. |
| Simple-lead-entry remix V8 | [`aerodynamic_remix_v8_simple_lead_entry.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v8_simple_lead_entry.rb) | Replaces V7's EDM-style buildup with a four-bar subtraction, a dry truncated funk phrase, and over one beat of silence before the isolated lead. |
| Structural re-edit V9 | [`aerodynamic_remix_v9_structural_rework.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v9_structural_rework.rb) | Moves the lead forward, shortens symmetrical passages, tightens the bell transition, and reprises the opening groove before the final decay. |
| Mix-polish V10 | [`aerodynamic_remix_v10_mix_polish.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v10_mix_polish.rb) | Preserves V9's structure while adding headroom, consistent drum envelopes, clearer low-end roles, softer supporting layers, and restrained stereo depth. |
| V10 stem renderer | [`aerodynamic_remix_v10_stems.rb`](tracks/aerodynamic/arrangements/aerodynamic_remix_v10_stems.rb) | Separate render-profile copy of V10 for aligned WAV export into a DAW; the approved V10 arrangement is unchanged. |

| Something About Us GP4 reconstruction | [`something_about_us_gp4_master.rb`](tracks/something_about_us/arrangements/something_about_us_gp4_master.rb) | Finite five-track transcription generated from the Guitar Pro 4 reference. |
| Something About Us GP5 reconstruction | [`something_about_us_gp5_master.rb`](tracks/something_about_us/arrangements/something_about_us_gp5_master.rb) | Finite seven-track, 104-measure transcription generated from the Guitar Pro 5 reference. |
| Something About Us GP5 audition | [`something_about_us_gp5_audition.rb`](tracks/something_about_us/arrangements/something_about_us_gp5_audition.rb) | GP5 reference copy with per-layer mute switches and entry messages for auditioning. |
| Something About Us GP5 compact audition | [`something_about_us_gp5_audition_compact.rb`](tracks/something_about_us/arrangements/something_about_us_gp5_audition_compact.rb) | Pattern-compacted audition copy with finite repeated-bar expansion and unchanged GP5 note data. |
| Something About Us GP5 pattern audition | [`something_about_us_gp5_audition_compact_v2.rb`](tracks/something_about_us/arrangements/something_about_us_gp5_audition_compact_v2.rb) | Sequence-based audition copy that stores each unique bar once and reconstructs all 104 measures by index. |
| Something About Us no-repeat comparison | [`something_about_us_gp5_no_repeat_melody.rb`](tracks/something_about_us/arrangements/something_about_us_gp5_no_repeat_melody.rb) | Experimental GP5 copy that suppresses short adjacent same-pitch re-attacks in the Piano Melodia layer. |

The files in `studies/` are intentionally smaller. `lead_only.rb` is the
approved lead reference, while `il_macquillage_fixed.rb` documents an earlier
melodic and harmonic reconstruction experiment.

## Latest V10 timeline

At 120 BPM, the current polished mix preserves V9's cue map:

| Time | Section |
|---|---|
| 0:00–0:16 | Four opening bells |
| 0:16–1:04 | Opening groove and four-bar subtraction |
| 1:04–1:28 | Isolated lead |
| 1:28–1:40 | Lead plus light groove |
| 1:40–2:12 | Full lead groove |
| 2:12 | Transition bell |
| 2:18–2:42 | Post-bell melody |
| 2:42–3:18 | Post-bell rhythm and sparse exit |
| 3:18–3:26 | Opening-groove callback |
| 3:26–3:28 | Controlled A–D decay and silent ending |

## Development and validation

Check ordinary Ruby syntax first:

```sh
ruby -c tracks/aerodynamic/arrangements/aerodynamic_remix_v10_mix_polish.rb
```

On macOS with Sonic Pi installed in `/Applications`, run its actual pre-parser:

```sh
SP_ROOT='/Applications/Sonic Pi.app/Contents/Resources/app/server/ruby'
'/Applications/Sonic Pi.app/Contents/Resources/app/server/native/ruby/bin/ruby' \
  -I"$SP_ROOT/lib" \
  -I"$SP_ROOT/vendor/kramdown-2.1.0/lib" \
  -e "require '$SP_ROOT/core'; require 'sonicpi/lang/core'; require 'sonicpi/preparser'; SonicPi::PreParser.preparse(File.read(ARGV.fetch(0)), SonicPi::Lang::Core.vec_fns); puts 'Sonic Pi pre-parser OK'" \
  tracks/aerodynamic/arrangements/aerodynamic_remix_v10_mix_polish.rb
```

In a restricted shell, Sonic Pi may warn that it cannot open its user debug
log. The validation succeeds when the command still prints
`Sonic Pi pre-parser OK` and exits successfully.

For arrangement changes, also calculate cumulative beats and cue timestamps.
Static checks cannot reveal balance, timbre, or audible tail leakage, so every
changed arrangement still needs a complete listening test inside Sonic Pi.

### Automated V10 stem export

See [the complete reproducible stem-rendering workflow](docs/aerodynamic-stem-rendering.md)
for pinned versions, verification, REAPER import, and fork maintenance. See
[the REAPER MCP setup and troubleshooting guide](docs/reaper-mcp-setup.md) for
the Codex connection, Python configuration, and issues solved during setup.

The stem copy keeps every disabled layer's timeline intact and selects one
render group at a time. With Sonic Pi installed:

```sh
ruby tools/render_aerodynamic_stems.rb
```

The aligned WAV files are written to `renders/aerodynamic_v10/`. To render
only selected profiles, pass them as arguments, for example:

```sh
ruby tools/render_aerodynamic_stems.rb drums bass lead
```

The resulting WAV files are ready for REAPER: create a project at 120 BPM,
import the files from `renders/aerodynamic_v10/`, and place them all at the
same start position. The included manifest records the source and render
hashes so the stem set can be verified or regenerated later.

The exporter uses Sonic Pi's bundled `headless-record.rb` harness, which
starts a matching headless daemon and writes the SuperSonic recording directly.
It waits through the complete 3:28 arrangement plus a short safety margin
before saving each WAV. Set `SONIC_PI_HEADLESS_RECORD` if Sonic Pi is installed
somewhere other than `/Applications/Sonic Pi.app`.

See the [Aerodynamic REAPER retrospective](docs/aerodynamic-reaper-retrospective.md)
for the experiments, timing investigation, mix attempts, and conclusions from
the first production workflow. The [REAPER MCP setup and troubleshooting
guide](docs/reaper-mcp-setup.md) documents the Codex connection and Python
configuration.

## Attribution and status

This is an educational fan project. "Aerodynamic" was written and released by
Daft Punk. Referenced compositions and source materials remain the property of
their respective owners.

This repository does not currently include an explicit software or content
license. Do not assume that third-party reference files are freely
redistributable merely because they are present here.
