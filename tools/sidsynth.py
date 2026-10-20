#!/usr/bin/env python3
"""A small software model of the MOS 6581 SID, used to render the game's sound effects and music.

What is modelled, as on the chip: three voices, each with a 24 bit style phase accumulator,
triangle / sawtooth / pulse (with pulse width) / noise (23 bit LFSR clocked by the oscillator)
and combined waveforms, an ADSR envelope, and a state variable filter (low / band / high pass
with resonance). Like a C64 music driver, pitch, pulse width, arpeggio and vibrato are updated
on a 50 Hz frame tick (PAL), which gives the typical stepped, "wobbly" SID sound.

Usage:  python3 tools/sidsynth.py <output folder>   (needs numpy and the sox command)
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 44100
FPS = 50.0
SPF = int(round(SR / FPS))      # samples per 50 Hz frame

# SID ADSR times in milliseconds (register values 0 to 15)
ATTACK_MS = [2, 8, 16, 24, 38, 56, 68, 80, 100, 250, 500, 800, 1000, 3000, 5000, 8000]
DECAY_MS = [6, 24, 48, 72, 114, 168, 204, 240, 300, 750, 1500, 2400, 3000, 9000, 15000, 24000]

NOTE_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name):
    """'D3', 'F#4', 'Bb2' -> MIDI number"""
    n = NOTE_NAMES[name[0]]
    i = 1
    while name[i] in "#b":
        n += 1 if name[i] == "#" else -1
        i += 1
    return 12 * (int(name[i:]) + 1) + n


def hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def _lfsr_table(length=400000):
    """The SID noise generator: 23 bit LFSR, 8 of its bits are the output"""
    reg = 0x7FFFF8
    out = np.empty(length, dtype=np.int32)
    for i in range(length):
        bit = ((reg >> 22) ^ (reg >> 17)) & 1
        reg = ((reg << 1) | bit) & 0x7FFFFF
        out[i] = (((reg >> 20) & 1) << 7 | ((reg >> 18) & 1) << 6 | ((reg >> 14) & 1) << 5 |
                  ((reg >> 11) & 1) << 4 | ((reg >> 9) & 1) << 3 | ((reg >> 5) & 1) << 2 |
                  ((reg >> 2) & 1) << 1 | (reg & 1)) << 4
    return out


NOISE = _lfsr_table()


class Inst:
    """One instrument: waveform, ADSR and what the driver does to it every frame"""

    def __init__(self, wave="pulse", adsr=(0, 4, 8, 4), pw=0.5, pw_lfo=(0.0, 0.0), vib=(0.0, 0.0, 0),
                 arp_rate=1, slide=0.0, vol=1.0):
        self.wave = wave                # any of "tri", "saw", "pulse", "noise" joined with "+"
        self.adsr = adsr                # attack, decay, sustain (0 to 15), release
        self.pw = pw                    # pulse width 0 to 1
        self.pw_lfo = pw_lfo            # (depth, frames per cycle) pulse width modulation
        self.vib = vib                  # (semitones depth, frames per cycle, delay frames)
        self.arp_rate = arp_rate        # frames per arpeggio step
        self.slide = slide              # semitones per second (glide)
        self.vol = vol


def render_note(inst, base_hz, gate, arp=None, vol=1.0):
    """One note on one voice: `gate` frames with the gate on, then the release"""
    a, d, s, r = inst.adsr
    release_frames = int(np.ceil(min(3.0, RELEASE_FACTOR * DECAY_MS[r] / 1000.0) * FPS)) + 1
    frames = gate + release_frames
    f = np.arange(frames, dtype=np.float64)
    semis = np.zeros(frames)
    if arp:
        steps = (f // inst.arp_rate).astype(int) % len(arp)
        semis += np.array(arp)[steps]
    semis += inst.slide * f / FPS
    depth, period, delay = inst.vib
    if depth:
        semis += depth * np.sin(2 * np.pi * f / period) * (f >= delay)
    freq = base_hz * 2.0 ** (semis / 12.0)
    pw = inst.pw + inst.pw_lfo[0] * np.sin(2 * np.pi * f / (inst.pw_lfo[1] or 1.0))
    pw = np.clip(pw, 0.02, 0.98)

    freq_s = np.repeat(freq, SPF)
    pw_s = np.repeat(pw, SPF)
    cycles = np.cumsum(freq_s / SR)
    phase = cycles % 1.0

    parts = []
    if "saw" in inst.wave:
        parts.append((phase * 4095).astype(np.int32))
    if "tri" in inst.wave:
        parts.append(((1.0 - np.abs(2.0 * phase - 1.0)) * 4095).astype(np.int32))
    if "pulse" in inst.wave:
        parts.append(np.where(phase < pw_s, 4095, 0).astype(np.int32))
    if "noise" in inst.wave:
        parts.append(NOISE[(cycles * 16).astype(np.int64) % len(NOISE)])
    out = parts[0]
    for p in parts[1:]:
        out = out & p                   # combined waveforms are a bitwise AND on the real chip
    wavef = (out - 2048) / 2048.0
    # Pulse and combined waveforms are not centered. The envelope would turn that offset into
    # a low thump on every note, so remove it per frame (the real chip has it, the speaker should not)
    wavef = wavef - np.repeat(wavef.reshape(frames, SPF).mean(axis=1), SPF)

    # ADSR (attack linear, decay and release exponential, like the chip's envelope counter)
    n = frames * SPF
    t = np.arange(n) / SR
    gate_n = gate * SPF
    atk = max(ATTACK_MS[a] / 1000.0, 0.001)
    env = np.minimum(t / atk, 1.0)
    sus = s / 15.0
    dec_tau = max(DECAY_MS[d] / 1000.0 * DECAY_FACTOR, 0.001)
    after = np.clip(t - atk, 0, None)
    env = np.where(t < atk, env, sus + (1.0 - sus) * np.exp(-after / dec_tau))
    rel_tau = max(DECAY_MS[r] / 1000.0 * DECAY_FACTOR, 0.001)
    level_at_gate = env[gate_n - 1] if gate_n > 0 else 0.0
    rel = level_at_gate * np.exp(-(t - gate_n / SR) / rel_tau)
    env = np.where(np.arange(n) < gate_n, env, rel)
    # a click free start and end (the real chip clicks, the player should not be hurt by it)
    ramp = int(0.0007 * SR)
    env[:ramp] *= np.linspace(0, 1, ramp)
    env[-ramp:] *= np.linspace(1, 0, ramp)
    return wavef * env * inst.vol * vol


RELEASE_FACTOR = 3.0
DECAY_FACTOR = 0.35


def render_voice(events, total_frames):
    """events: dicts with start, gate, hz, inst and optional arp and vol. One note at a time."""
    buf = np.zeros(total_frames * SPF + SR * 3)
    events = sorted(events, key=lambda e: e["start"])
    for i, e in enumerate(events):
        note = render_note(e["inst"], e["hz"], e["gate"], e.get("arp"), e.get("vol", 1.0))
        start = e["start"] * SPF
        if i + 1 < len(events):
            limit = events[i + 1]["start"] * SPF - start
            if limit < len(note):               # the next note cuts this one, with a short fade
                fade = min(int(0.002 * SR), max(limit, 1))
                note = note[:limit].copy()
                note[-fade:] *= np.linspace(1, 0, fade)
        buf[start:start + len(note)] += note
    return buf


def svf(x, cutoff_frames, res, mode="lp"):
    """State variable filter, cutoff (Hz) per 50 Hz frame, resonance 0 to 15"""
    q = 1.0 / (0.6 + res * 0.12)
    out = np.empty_like(x)
    lp = bp = 0.0
    cut = np.repeat(np.asarray(cutoff_frames, dtype=np.float64), SPF)
    if len(cut) < len(x):
        cut = np.concatenate([cut, np.full(len(x) - len(cut), cut[-1])])
    coef = 2.0 * np.sin(np.pi * np.clip(cut, 20, SR / 6) / SR)
    xs = x.tolist()
    cs = coef.tolist()
    o = [0.0] * len(xs)
    for i in range(len(xs)):
        hp = xs[i] - lp - q * bp
        bp += cs[i] * hp
        lp += cs[i] * bp
        o[i] = lp if mode == "lp" else (bp if mode == "bp" else hp)
    out[:] = o
    return out


def mix(voices, filt=None, master=1.0):
    """voices: list of (buffer, filtered?). filt: dict(cutoff=[Hz per frame], res, mode)"""
    n = max(len(v) for v, _ in voices)
    dry = np.zeros(n)
    wet = np.zeros(n)
    for v, f in voices:
        (wet if f else dry)[:len(v)] += v
    if filt is not None and np.any(wet):
        wet = svf(wet, filt["cutoff"], filt.get("res", 6), filt.get("mode", "lp"))
    return np.tanh((dry + wet) * master * 0.9)


def highpass(x, cutoff_hz):
    """One pole high pass, keeps small speakers from getting sub bass and DC"""
    a = np.exp(-2.0 * np.pi * cutoff_hz / SR)
    out = np.empty_like(x)
    prev_x = prev_y = 0.0
    xs = x.tolist()
    o = [0.0] * len(xs)
    for i, v in enumerate(xs):
        prev_y = a * (prev_y + v - prev_x)
        prev_x = v
        o[i] = prev_y
    out[:] = o
    return out


def finish(x, peak_db, trim_silence=True, hp_hz=40.0):
    x = highpass(x, hp_hz)
    if trim_silence:
        idx = np.nonzero(np.abs(x) > 0.002)[0]
        if len(idx):
            x = x[:idx[-1] + 1]
    # a 4 bit style master volume step, the typical hard SID output
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * 10.0 ** (peak_db / 20.0)
    return x


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def to_ogg(wav_path, ogg_path, quality=4):
    subprocess.run(["sox", wav_path, "-C", str(quality), ogg_path], check=True)
