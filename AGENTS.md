# Repository instructions

These instructions apply to the entire repository.

## Layout and versioning

- Put complete Sonic Pi tracks in a track's `arrangements/` directory,
  isolated experiments in `studies/`, and source material in `references/`.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v2_filter_house.rb` is
  the stable Aerodynamic remix.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v3_timing.rb` is the
  experimental timing version.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v4_cleanup.rb` is the
  cleanup reference.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v5_refined.rb` is the
  refined reference.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v6_polished_arc.rb` is
  the polished-arc reference.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v7_lead_drop.rb` is the
  experimental lead-drop arrangement.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v8_simple_lead_entry.rb`
  is the simple-lead-entry reference.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v9_structural_rework.rb`
  is the structural re-edit reference.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v10_mix_polish.rb` is the
  mix-polished reference and latest fully built-in arrangement.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v11_clean_guitar.rb` is
  the clean-guitar reference; it uses the local FreePats clean-guitar multisample
  for the recurring funk melody and removes the supplemental `:dpulse` stabs.
- `tracks/aerodynamic/arrangements/aerodynamic_remix_v12_guitar_pulse.rb` is
  the latest arrangement; it uses the local FreePats Distorted #2 multisample
  with restrained `:zawa` reinforcement for the main lead.
- Preserve approved arrangements. Create a new standalone version for a
  substantial remix, timing experiment, or alternate mix.
- Inspect both the target and its immediate predecessor before editing. Update
  derivation headers and README paths when files move or are renamed.

## Sonic Pi conventions

- Write for Sonic Pi's Ruby dialect and use lowercase `snake_case` names.
- Never use built-in Sonic Pi function names such as `chord`, `sample`,
  `scale`, or `synth` as variables.
- Prefer explicit finite loops and deterministic scheduling. Do not introduce
  unrestricted `live_loop`s unless the task explicitly requires them.
- Ordinary bar helpers must consume exactly four beats. A partial-bar effect
  must still preserve the master timeline.
- Use `cue` for major section boundaries and keep every spawned thread finite.
- Suppress final-bar events and shorten releases when a following section must
  be isolated or silent.
- Use built-in synths, samples, and effects unless the user supplies or
  authorizes external assets.

## Musical invariants

- Preserve GP4-derived pitches, note order, and intervals unless recomposition
  is explicitly requested.
- Preserve the corrected mixed-register lead and compare lead changes against
  `tracks/aerodynamic/studies/lead_only.rb`.
- When an arrangement specifies a lead-only entrance, no bass, percussion,
  pad, stab, delayed sample, or unrelated synth may remain audible.
- Keep four opening bells, one transition bell, and one final bell unless the
  task explicitly changes that structure.
- Treat transcription, sound design, arrangement timing, and mix balance as
  separate concerns; avoid changing several at once without a clear reason.

## Known timing history

- Earlier arrangements repeatedly leaked bass, percussion, or synth tails into
  the protected lead passage. Dedicated finite helpers and final-bar
  suppression proved more reliable than attempts to stop uncontrolled loops.
- V3 corrected a post-bell harmonic bar that could schedule notes beyond its
  four-beat boundary. Do not restore the overflowing timing logic.
- V4 removes duplicate sixteenth-note hat layers and uses a dedicated,
  lower-level final bell instead of the oversized opening-bell patch.
- V5 strengthens the remix arc through staged layer handoffs and keeps the
  last beat before the ending decay free of sounding events.
- V6 applies timing swing only to supplemental percussion; GP4-derived notes
  and percussion remain on their exact timing grid.
- V7 reserves the final beat before the lead for silence. Do not add a crash,
  bass note, percussion hit, or effect tail on the lead downbeat.
- V8 replaces V7's EDM-style lead buildup with a four-bar subtraction. Preserve
  at least one full beat of silence before the isolated lead, and do not add a
  riser, accelerating drum roll, fake drop, or lead-downbeat impact there.
- V9 moves that protected lead entrance to beat 128, shortens the first layered
  lead stage to six bars, and reprises the four-bar subtraction before the
  ending decay. Keep its shortened transition bed clear of the post-bell cue.
- V10 preserves V9's structure while lowering cumulative gain, tightening drum
  sample envelopes, and reducing masking from doubles and support layers. Keep
  the scoped output trim and avoid restoring per-bar melody compression. Its
  final bell was deliberately removed; the A-D decay is now the ending.
- V11 preserves V10's 416-beat structure and protected silences. Keep its
  sampled lead-entry releases short, retain deterministic sample selection,
  and do not restore the rejected `:dpulse` chord-stab layer.
- V12 preserves V11's cue map and uses the approved guitar/zawa lead from
  1:04-2:12. Keep its deterministic takes and short final-stutter releases,
  retain the selected `:dsaw` accents, and do not restore the blade double.

## Editing and Git safety

- Preserve unrelated user changes and do not delete reference files merely
  because runtime code does not load them.
- Keep large experiments in new files so stable versions remain available for
  A/B listening.
- Do not commit or push unless the user explicitly requests it.

## Validation

For every changed `.rb` file:

1. Run `ruby -c path/to/file.rb`.
2. Run Sonic Pi's actual pre-parser using the command documented in
   `README.md`.
3. Search for assignments that use reserved Sonic Pi function names.
4. Recalculate cumulative beat totals and section cue timestamps.
5. Compare protected lead passages and predecessor checksums when creating a
   new version.
6. Confirm deliberate silent passages contain no sounding threads or long
   releases.
7. Listen to the complete result in Sonic Pi. Parser success does not validate
   musical balance or audible transitions.
