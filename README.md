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
- Latest remix: [structural re-edit V9](tracks/aerodynamic/arrangements/aerodynamic_remix_v9_structural_rework.rb)
- Simple-transition reference: [simple-lead-entry V8](tracks/aerodynamic/arrangements/aerodynamic_remix_v8_simple_lead_entry.rb)
- Lead-drop experiment: [lead-drop V7](tracks/aerodynamic/arrangements/aerodynamic_remix_v7_lead_drop.rb)
- Polished-arc reference: [polished-arc V6](tracks/aerodynamic/arrangements/aerodynamic_remix_v6_polished_arc.rb)
- Refined reference: [refined V5](tracks/aerodynamic/arrangements/aerodynamic_remix_v5_refined.rb)
- Cleanup reference: [cleanup V4](tracks/aerodynamic/arrangements/aerodynamic_remix_v4_cleanup.rb)
- Timing experiment: [timing-focused V3](tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb)
- Isolated comparison: [lead-only study](tracks/aerodynamic/studies/lead_only.rb)

## Project structure

```text
tracks/
├── aerodynamic/
│   ├── arrangements/  # Complete tracks and historical iterations
│   ├── studies/       # Isolated phrases and comparison experiments
│   └── references/    # GP4, MIDI, and saved research material
└── midnight_club/     # Separate Sonic Pi track
```

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

The files in `studies/` are intentionally smaller. `lead_only.rb` is the
approved lead reference, while `il_macquillage_fixed.rb` documents an earlier
melodic and harmonic reconstruction experiment.

## Latest V9 timeline

At 120 BPM, the current structural re-edit uses this cue map:

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
| 3:26–3:28 | Controlled A–D decay and one-second breath |
| 3:28 | Final bell |

## Development and validation

Check ordinary Ruby syntax first:

```sh
ruby -c tracks/aerodynamic/arrangements/aerodynamic_remix_v9_structural_rework.rb
```

On macOS with Sonic Pi installed in `/Applications`, run its actual pre-parser:

```sh
SP_ROOT='/Applications/Sonic Pi.app/Contents/Resources/app/server/ruby'
'/Applications/Sonic Pi.app/Contents/Resources/app/server/native/ruby/bin/ruby' \
  -I"$SP_ROOT/lib" \
  -I"$SP_ROOT/vendor/kramdown-2.1.0/lib" \
  -e "require '$SP_ROOT/core'; require 'sonicpi/lang/core'; require 'sonicpi/preparser'; SonicPi::PreParser.preparse(File.read(ARGV.fetch(0)), SonicPi::Lang::Core.vec_fns); puts 'Sonic Pi pre-parser OK'" \
  tracks/aerodynamic/arrangements/aerodynamic_remix_v9_structural_rework.rb
```

In a restricted shell, Sonic Pi may warn that it cannot open its user debug
log. The validation succeeds when the command still prints
`Sonic Pi pre-parser OK` and exits successfully.

For arrangement changes, also calculate cumulative beats and cue timestamps.
Static checks cannot reveal balance, timbre, or audible tail leakage, so every
changed arrangement still needs a complete listening test inside Sonic Pi.

## Attribution and status

This is an educational fan project. "Aerodynamic" was written and released by
Daft Punk. Referenced compositions and source materials remain the property of
their respective owners.

This repository does not currently include an explicit software or content
license. Do not assume that third-party reference files are freely
redistributable merely because they are present here.
