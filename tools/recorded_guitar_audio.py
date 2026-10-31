"""PCM24 I/O and windowed-sinc resampling for recorded guitar studies."""
import wave
import numpy as np

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

