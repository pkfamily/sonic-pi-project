# Recorded-guitar session wrap — 2026-10-31

This complete 120 BPM session mix derives from the V10 stems. It preserves
V10's 416-beat structure and prints the selected recorded-guitar sounds to
six aligned REAPER tracks. It is a separate offline mix; V12 remains the
latest Sonic Pi arrangement and is unchanged.

## Selected sounds

- Lead A: the user's E4 sample, 32 dB drive, Marshall JCM800 / Stock 70
  convolution response, and short delay. Retain the corrected mixed-register
  motifs and lower effect notes. Harder, brighter, body, and octave alternatives
  were auditioned and rejected.
- Funk melody: the user's B3/E4 recordings, mild note-level balancing,
  smoother endings, quiet room reflections, and a note-triggered wah.
  The extra-snap and synth-pluck alternatives were rejected.
- Bass: a same-pitch fundamental with restrained harmonics, mild saturation,
  short attack, and controlled release. Original pitches, chord dynamics,
  note order, and same-pitch reinforcement remain.
- Mix: lead reduced 2 dB; wah raised 10 dB under the lead. The wah remains
  subtle, and that balance was accepted provisionally. The foreground opening
  wah is matched to the original opening melody rather than boosted 10 dB.

The source-derived bells, drums, post-bell synths, composite 2:10 transition
stutter, truncated pre-lead/callback bars, and final A–D decay remain. The
0.438-second stem-recording start offset is removed. The arrangement is 3:28;
the delivered stereo file is 3:30 including the ending tail and silence.

## Local audio inputs

Raw recordings, rendered samples, full-resolution WAVs, and ZIP bundles stay
local, consistent with `.gitignore`. They are not included in this commit.
The selected asset hashes are in
[aerodynamic-recorded-session.json](aerodynamic-recorded-session.json).

Place the user-recorded assets under this ignored folder:

```text
tracks/aerodynamic/references/local_samples/recorded_session/
  samples/guitar_E4.wav
  wah-melody.wav
```

`guitar_E4.wav` is the tuned, dry PCM24 mono sample. `wah-melody.wav` is the
approved eight-second, four-bar stereo melody phrase. Its four bars carry the
source phrase gains, with the A3 fill in bar four. Retaining this approved
render freezes the exact polish and wah performance selected by listening.
The JSON also records hashes for the other five prepared guitar notes.

The six-note preparation tool accepts the original 65-second mono PCM24 take
and writes trimmed/tuned open-string samples plus a sampler map and review
project:

```sh
python3 tools/prepare_recorded_guitar_samples.py /path/to/original-take.wav \
  tracks/aerodynamic/references/local_samples/recorded_session/samples
```

This tool's trim positions belong specifically to that recorded take; they
are not a general-purpose note detector. It preserves the original recording.
The final mix renderer needs only the selected E4 and approved wah phrase.

## Rebuild the session mix

Requirements: Python 3 with NumPy, existing V10 stem exports under
`renders/aerodynamic_v10`, the two private audio inputs above, and REAPER's
bundled `Marshall JCM800 - Marshall Stock 70.wav` response under the default
macOS REAPER data directory. No network downloads occur during rendering.

```sh
python3 -m venv .venv-recorded-session
.venv-recorded-session/bin/python -m pip install -r tools/requirements-recorded-session.txt
.venv-recorded-session/bin/python tools/render_aerodynamic_recorded_session.py
```

Optional `--repo-root`, `--assets-dir`, and `--output-dir` arguments allow
alternate local locations. Outputs default to ignored
`renders/aerodynamic_recorded_session/`:

- `Aerodynamic-session-mix.wav`: 48 kHz, 24-bit stereo, 210 seconds.
- `Aerodynamic Session Wrap.rpp`: six aligned rendered tracks with independent
  faders and section markers; processing is printed, not a live FX chain.
- Six stems, a manifest, and a self-contained ZIP project bundle.

The renderer checks finite audio, peak headroom, pre-lead silence, the
isolated lead passage, the half-time melody omission, the transition composite,
ending preservation, the final silence, and the sum of quantized stems.
The checked session export peaked at approximately −1.94 dBFS. These checks
are structural and signal checks, not perceptual mastering or a true-peak
measurement. The 58-second integration and bass/wah choices were auditioned;
the final complete render was exported and technically verified.
