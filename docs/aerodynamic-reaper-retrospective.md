# Aerodynamic REAPER retrospective

This document records the first attempt to take the Aerodynamic V10 Sonic Pi
arrangement into REAPER for production mixing. The project is paused while the
musical and sound-design direction is reconsidered. The files retained in
`renders/aerodynamic_v10/` are the reproducible handoff: the REAPER project,
seven aligned stems, and `manifest.json`.

## What we built

The V10 arrangement was copied into a dedicated stem-render arrangement. Each
render profile enables one component group while preserving the complete
timeline, producing these aligned stereo WAVs:

`full`, `drums`, `bass`, `lead`, `melody`, `harmony`, and `fx`.

The renderer uses Sonic Pi's headless recorder through the project-local TCP
adapter because the older `sonic-pi-tool` recording path did not match Sonic Pi
v5's engine transport. The capture is 120 BPM, 48 kHz, 24-bit stereo, and 210
seconds long, with the musical arrangement ending at approximately 208.5
seconds.

## Timing problem and resolution

The first summed stems were not aligned. The opening groove started late and
the transition bell appeared several seconds early in REAPER. The cause was a
timeline-ownership bug in the disabled `church_bell` helper: the caller already
waited four beats, while the disabled helper also returned `sleep 4`. That
doubled the opening-bell spacing in non-`fx` profiles and shifted later layers.

The fix was to make the disabled helper return immediately when called from the
timed bell loop, then regenerate every profile. A direct, sample-aligned sum of
the regenerated WAVs confirmed the expected placement: the opening groove near
16 seconds and the transition bell near 2:12. The investigation also showed
that stale summed files can make a corrected source appear to remain broken.

For future render profiles, identify which helper owns each wait before adding
any disabled branch. Regenerate all profiles after timing changes and verify a
direct sum before investigating DAW alignment.

## REAPER setup and automation

The REAPER MCP connection required several compatibility fixes and setup steps:

- REAPER's embedded Python had to use the Homebrew Python 3.12 framework.
- `reapy` had to be installed in the MCP virtual environment; that did not make
  it importable from REAPER's embedded Python.
- The external configuration command was more reliable than running
  `enable_reapy.py` as a ReaScript.
- Python 3.14 exposed a `configparser` incompatibility in the installed
  `python-reapy` release.
- The REAPER web interface used port 2307 and the reapy server used port 2306.
  Stale server processes caused `Address already in use` failures.
- The forked `reaper-mcp` compatibility branch fixed project time-signature,
  project-save, and native track volume/pan/mute/solo access issues.

The complete installation and troubleshooting commands are documented in
[`docs/reaper-mcp-setup.md`](reaper-mcp-setup.md). The forked repositories are
dependencies of the workflow, but the project remains usable without the MCP
connection once the stems and REAPER project have been created.

## Mix experiments

The REAPER project was used to test incremental production changes, including
gain staging, track panning, drum transient shaping, bass EQ, lead compression,
melody delay and saturation, ambience, and master limiting. These changes made
the mix cleaner and more controlled, and reduced masking between the layers.

The opening groove melody remained the limiting element. EQ, compression,
delay, saturation, filtering, and warmth adjustments changed its surface but
did not remove its underlying weak, metallic character. The result suggested
that the bottleneck is primarily the source timbre and articulation rather than
REAPER's ability to process the stem.

## Current conclusion

The REAPER workflow is reproducible and the stem timing issue is understood.
The first mix pass reached the point of diminishing returns because it was
processing a Sonic Pi built-in synth performance whose tone was not yet the
desired production sound.

The most promising next experiment is to redesign the opening melody at the
source level: try a substantially different synthesis approach, sampled or
external production-level instruments, and a new performance/articulation
layer. REAPER can then handle arrangement-level mixing, automation, spatial
effects, and mastering once the source sound is compelling.

No claim of a finished release mix is made. This pause preserves the working
pipeline while leaving the musical direction open for a later redesign.
