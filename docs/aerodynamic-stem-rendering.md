# Aerodynamic stem-rendering workflow

This is the reproducible path from the V10 Sonic Pi arrangement to aligned WAV
stems for REAPER.

## What is pinned

- Arrangement: `tracks/aerodynamic/arrangements/aerodynamic_remix_v10_stems.rb`
- Render profiles: `full`, `drums`, `bass`, `lead`, `melody`, `harmony`, `fx`
- Tempo: 120 BPM, 4/4
- Capture duration: 210 seconds
- Audio output: stereo, 48 kHz, 24-bit WAV
- Tested Sonic Pi: v5.0 on macOS
- Sonic Pi tool fork: <https://github.com/pkfamily/sonic-pi-tool>
- Fork revision recorded during setup: `b955369294b7669b2706b26d388ec2c2a9d0d3a2`

The fork is an optional CLI/control dependency. Sonic Pi v5 changed the engine
transport used by the older CLI recorder, so the actual stem export uses the
project-local `tools/sonic_pi_headless_record.rb` TCP adapter around Sonic Pi's
headless boot harness.

## Prerequisites

1. Install Sonic Pi and confirm its app path. The default expected path is:

   `/Applications/Sonic Pi.app`

2. Grant macOS audio permissions if Sonic Pi requests them.

3. Confirm the installed headless recorder and parser:

   ```sh
   ruby tools/sonic_pi_headless_record.rb --help
   ruby -c tracks/aerodynamic/arrangements/aerodynamic_remix_v10_stems.rb
   ```

If Sonic Pi is installed elsewhere, set its Ruby server root for the adapter:

```sh
export SONIC_PI_APP_ROOT="/path/to/Sonic Pi.app/Contents/Resources/app/server/ruby"
```

## Render stems

Render the complete set:

```sh
ruby tools/render_aerodynamic_stems.rb
```

Render selected profiles:

```sh
ruby tools/render_aerodynamic_stems.rb drums bass lead
```

The renderer creates full-length files under `renders/aerodynamic_v10/` and a
`manifest.json` containing the source hash, renderer hash, tool revision,
profile list, file sizes, and WAV SHA-256 hashes. Each run overwrites matching
profile files.

## Timing pitfall: disabled layers and `sleep`

Every render profile must preserve the master timeline. A disabled helper may
need to consume time when it is the only owner of a bar, but it must not add a
second wait when its caller already advances the bar or section.

For example, the opening-bell loop calls `church_bell` and then sleeps four
beats. The disabled-profile branch of `church_bell` therefore must return
immediately; using `return sleep 4` there doubled each opening-bell bar for
non-`fx` profiles and shifted the later layers in the summed REAPER mix. The
same rule applies to any helper called directly inside a timed loop.

When adding a profile guard, first identify who owns the timeline:

- A helper called directly by a loop that already sleeps: return immediately
  when disabled.
- A helper running as a complete bar/thread: consume the helper's full bar when
  disabled, as its caller expects that helper to advance time.
- A section helper with an explicit duration: preserve that duration exactly,
  without also adding a caller-level wait.

After changing a guard, regenerate all profiles rather than only the changed
layer. Compare cue timestamps in the Sonic Pi log and listen to a direct sum of
the regenerated WAVs before diagnosing REAPER timing. A stale summed render can
make an already-fixed source appear to remain out of alignment.

## Verify a render

Check that all stems have the same audio format and duration:

```sh
for f in renders/aerodynamic_v10/*.wav; do
  afinfo "$f" | rg "Data format:|estimated duration:"
done
```

Inspect the manifest:

```sh
ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(File.read("renders/aerodynamic_v10/manifest.json")))'
```

The expected duration is approximately 210 seconds. The musical arrangement
reaches `cue :arrangement_complete` at about 208.5 seconds; the extra capture
margin preserves final releases and keeps the headless engine alive until the
recorder stops it.

## Import into REAPER

1. Create a 120 BPM, 4/4 REAPER project.
2. Set the project timebase to time or otherwise disable tempo-stretching on
   import.
3. Import every WAV onto a separate track at exactly 0:00.
4. Keep the `full` stem muted as a reference while mixing the component stems.
5. Save the REAPER project beside the render directory, not inside the source
   arrangement directory.

## Updating the fork

Do not update the fork revision implicitly. When changing it:

```sh
git ls-remote https://github.com/pkfamily/sonic-pi-tool.git HEAD
```

Test the candidate revision against the installed Sonic Pi version, then update
the recorded commit in `tools/render_aerodynamic_stems.rb` and this document.
Keep the TCP adapter unless the fork gains verified Sonic Pi v5 recording
support; the fork's ordinary `record` command is not currently the render
engine used by this workflow.
