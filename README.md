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
- Latest experiment: [timing-focused V3](tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb)
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

The files in `studies/` are intentionally smaller. `lead_only.rb` is the
approved lead reference, while `il_macquillage_fixed.rb` documents an earlier
melodic and harmonic reconstruction experiment.

## V3 timeline

At 120 BPM, the current experimental arrangement uses this cue map:

| Time | Section |
|---|---|
| 0:00–0:16 | Four opening bells |
| 0:16–1:12 | Extended opening groove |
| 1:12–1:36 | Isolated lead |
| 1:36–1:52 | Lead plus light groove |
| 1:52–2:24 | Experimental full groove |
| 2:24 | Transition bell |
| 2:32–2:56 | Post-bell melody |
| 2:56–3:36 | Post-bell rhythm |
| 3:36–3:38 | Silent final bar |
| 3:38 | Final bell |

## Development and validation

Check ordinary Ruby syntax first:

```sh
ruby -c tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb
```

On macOS with Sonic Pi installed in `/Applications`, run its actual pre-parser:

```sh
SP_ROOT='/Applications/Sonic Pi.app/Contents/Resources/app/server/ruby'
'/Applications/Sonic Pi.app/Contents/Resources/app/server/native/ruby/bin/ruby' \
  -I"$SP_ROOT/lib" \
  -I"$SP_ROOT/vendor/kramdown-2.1.0/lib" \
  -e "require '$SP_ROOT/core'; require 'sonicpi/lang/core'; require 'sonicpi/preparser'; SonicPi::PreParser.preparse(File.read(ARGV.fetch(0)), SonicPi::Lang::Core.vec_fns); puts 'Sonic Pi pre-parser OK'" \
  tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb
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
