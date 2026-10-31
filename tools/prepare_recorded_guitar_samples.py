from pathlib import Path
import json
import wave
import numpy as np

import argparse
parser=argparse.ArgumentParser(description="Trim and tune the six user-recorded open guitar strings.")
parser.add_argument('source',type=Path,help="Original 65-second mono PCM24 take")
parser.add_argument('output_dir',type=Path)
args=parser.parse_args()
SOURCE=args.source.resolve()
OUT=args.output_dir.resolve()
OUT.mkdir(parents=True,exist_ok=True)

def read_wav(path):
    with wave.open(str(path)) as w:
        sr = w.getframerate()
        assert w.getnchannels() == 1 and w.getsampwidth() == 3
        b = np.frombuffer(w.readframes(w.getnframes()), dtype=np.uint8).reshape(-1, 3)
    v = b[:, 0].astype(np.int32) | b[:, 1].astype(np.int32) << 8 | b[:, 2].astype(np.int32) << 16
    return ((v ^ 8388608) - 8388608) / 8388608, sr

def frequency(x, sr, expected):
    estimates = []
    for offset in [0.25, 0.45, 0.65, 0.85]:
        a = x[int(offset * sr):int((offset + .5) * sr)]
        n = 262144
        spec = abs(np.fft.rfft((a - a.mean()) * np.hanning(len(a)), n))
        lo, hi = int(expected * .96 * n / sr), int(expected * 1.04 * n / sr)
        k = lo + np.argmax(spec[lo:hi])
        y = np.log(spec[k-1:k+2] + 1e-30)
        delta = .5 * (y[0] - y[2]) / (y[0] - 2*y[1] + y[2])
        estimates.append((k + delta) * sr / n)
    return float(np.median(estimates))

def resample_pitch(x, rate):
    # Windowed-sinc interpolation, 96 taps; preserve the source attack and decay.
    length = int(len(x) / rate)
    result = np.empty(length)
    offsets = np.arange(-47, 49)
    cutoff = min(1., 1. / rate) * .97
    for start in range(0, length, 8192):
        pos = np.arange(start, min(length, start + 8192)) * rate
        idx = np.floor(pos).astype(int)[:, None] + offsets
        distance = pos[:, None] - idx
        weights = cutoff * np.sinc(cutoff * distance) * np.where(abs(distance) < 48, .5 + .5*np.cos(np.pi*distance/48), 0)
        weights /= weights.sum(axis=1)[:, None]
        valid = (idx >= 0) & (idx < len(x))
        result[start:start+len(pos)] = np.sum(x[np.clip(idx, 0, len(x)-1)] * weights * valid, axis=1)
    return result

def write_wav(path, x, sr):
    v = np.clip(np.rint(x * 8388608), -8388608, 8388607).astype(np.int32)
    b = np.stack([v & 255, (v >> 8) & 255, (v >> 16) & 255], axis=1).astype(np.uint8)
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(3); w.setframerate(sr); w.writeframes(b.tobytes())

def main():
    x, sr = read_wav(SOURCE)
    # Start just before the pick transient; stop before the following note.
    regions = [('E2',40,3.043,8.9), ('A2',45,16.013,25.55),
               ('D3',50,25.627,36.20), ('G3',55,36.268,43.96),
               ('B3',59,44.035,52.35), ('E4',64,54.993,61.90)]
    records = []
    for note, midi, start, end in regions:
        a = x[int(start*sr):int(end*sr)].copy()
        target = 440 * 2**((midi-69)/12)
        measured = frequency(a, sr, target)
        rate = target / measured
        y = resample_pitch(a, rate)
        y -= np.mean(y)
        attack, release = int(.0005*sr), int(.12*sr)
        y[:attack] *= np.linspace(0,1,attack)
        y[-release:] *= .5 + .5*np.cos(np.linspace(0,np.pi,release))
        # Keep the relative recorded dynamics; no normalization or amp effects.
        name = f'guitar_{note}.wav'
        write_wav(OUT/name, y, sr)
        check, _ = read_wav(OUT/name)
        verified = frequency(check, sr, target)
        cents = 1200*np.log2(verified/target)
        assert abs(cents) < 4, (note, cents)
        assert len(check) > sr and abs(check).max() < 1
        records.append(dict(file=name,note=note,midi=midi,source_start_seconds=start,
            source_end_seconds=end,source_frequency_hz=measured,
            tuning_correction_cents=float(1200*np.log2(rate)),
            duration_seconds=len(y)/sr,verified_tuning_error_cents=float(cents),
            peak_dbfs=float(20*np.log10(abs(y).max()))))
    bounds = [(40,42),(43,47),(48,52),(53,56),(57,61),(62,76)]
    sfz = ['// Dry guitar, C4 = MIDI 60. Tuned mono samples; one-shot decay, no loops.',
           '<group> amp_veltrack=100 ampeg_release=0.15']
    for r,(low,high) in zip(records,bounds):
        sfz.append(f'<region> sample={r["file"]} pitch_keycenter={r["midi"]} lokey={low} hikey={high}')
    (OUT/'guitar.sfz').write_text('\n'.join(sfz)+'\n')
    manifest = dict(source_file=str(SOURCE),sample_rate=sr,bit_depth=24,channels=1,
        processing='Dry source; constant pitch correction; 0.5 ms fade-in, 120 ms fade-out; no normalization, noise gate, amp or cabinet effects.',
        limitations=['One picking strength per note; residual sympathetic string resonance retained.',
                     'Low E shortened to exclude a later swell in the recording.',
                     'Sampler range E2–E5; widest transposition is the top octave.'],samples=records)
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    # A separate review project leaves the existing arrangement intact.
    rpp=['<REAPER_PROJECT 0.1 7.79 1','  SAMPLERATE 44100','  TEMPO 120','  <TRACK',
         '    NAME "Guitar samples - tuned dry"','    VOLPAN 1 0','    MAINSEND 1 0','    REC 0 0 0 0']
    pos=0.
    for r in records:
        rpp += ['    <ITEM',f'      POSITION {pos:.8f}',f'      LENGTH {r["duration_seconds"]:.8f}',
                '      VOLPAN 1 0 1 -1','      SOFFS 0',f'      NAME "{r["note"]} - tuned dry"',
                '      <SOURCE WAVE',f'        FILE "{r["file"]}"','      >','    >']
        pos += r['duration_seconds']+1
    rpp += ['  >','>']
    (OUT/'Guitar Samples.rpp').write_text('\n'.join(rpp)+'\n')
    print(json.dumps(records,indent=2))

if __name__ == '__main__':
    main()
