#!/usr/bin/env python3
"""Renders every sound effect and music track of the game with the SID model in sidsynth.py.

    python3 tools/sid_audio.py sounds        # writes sounds/sfx/*.ogg and sounds/music/sid/*.ogg
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sidsynth as sid
from sidsynth import Inst, hz, midi, render_voice, mix, finish, SPF

# ---------------------------------------------------------------- sound effects

def ev(start, gate, note_hz, inst, arp=None, vol=1.0):
    return dict(start=start, gate=gate, hz=note_hz, inst=inst, arp=arp, vol=vol)


def N(name):
    return hz(midi(name))


def sweep(a, b, frames):
    return np.linspace(a, b, frames)


def sfx_sword_hit():
    v1 = [ev(0, 3, 5000, Inst("noise", (0, 3, 0, 3)))]
    v2 = [ev(0, 4, 330, Inst("tri", (0, 2, 0, 3), slide=-160))]
    return [(render_voice(v1, 12), False), (render_voice(v2, 12), False)], None, -11, 200


def sfx_swing_miss():
    v1 = [ev(0, 7, 2500, Inst("noise", (3, 4, 0, 4)))]
    filt = dict(cutoff=sweep(600, 5000, 14), res=4, mode="hp")
    return [(render_voice(v1, 14), True)], filt, -15


def sfx_player_hurt():
    v1 = [ev(0, 6, 420, Inst("pulse", (0, 3, 3, 3), pw=0.3, slide=-130))]
    v2 = [ev(0, 3, 2800, Inst("noise", (0, 3, 0, 3)), vol=0.5)]
    return [(render_voice(v1, 14), False), (render_voice(v2, 14), False)], None, -14, 220


def sfx_monster_hurt():
    v1 = [ev(0, 5, 330, Inst("saw", (0, 2, 3, 2), slide=-120))]
    return [(render_voice(v1, 12), False)], None, -14


def sfx_monster_death():
    v1 = [ev(0, 14, 1500, Inst("noise", (0, 6, 5, 6)))]
    v2 = [ev(0, 25, 160, Inst("tri", (0, 6, 8, 6), slide=-70))]
    filt = dict(cutoff=sweep(6000, 300, 50), res=5, mode="lp")
    return [(render_voice(v1, 50), True), (render_voice(v2, 50), False)], filt, -10


def sfx_pickup():
    i = Inst("pulse", (0, 3, 6, 3), pw=0.25)
    v1 = [ev(0, 3, N("C6"), i), ev(3, 4, N("G6"), i)]
    return [(render_voice(v1, 14), False)], None, -14


def sfx_unlock():
    i = Inst("pulse", (0, 2, 4, 2), pw=0.5)
    v1 = [ev(0, 1, N("A5"), i), ev(5, 1, N("A5"), i), ev(9, 3, N("C6"), i)]
    v2 = [ev(0, 1, 3000, Inst("noise", (0, 1, 0, 1))), ev(5, 1, 3000, Inst("noise", (0, 1, 0, 1)))]
    return [(render_voice(v1, 16), False), (render_voice(v2, 16), False)], None, -13


def sfx_lockpick_fail():
    v1 = [ev(0, 8, 150, Inst("saw", (0, 4, 6, 3), vib=(1.0, 2, 0)))]
    v2 = [ev(0, 4, 2000, Inst("noise", (0, 3, 0, 3)), vol=0.6)]
    return [(render_voice(v1, 18), False), (render_voice(v2, 18), False)], None, -11


def sfx_trap():
    v1 = [ev(0, 6, 4000, Inst("noise", (0, 5, 3, 5)))]
    v2 = [ev(0, 10, 400, Inst("pulse", (0, 4, 5, 4), pw=0.125, slide=-150))]
    return [(render_voice(v1, 24), False), (render_voice(v2, 24), False)], None, -9


def sfx_discover():
    v1 = [ev(0, 12, N("E5"), Inst("pulse", (0, 5, 6, 5), pw=0.125), arp=[0, 4, 7, 12])]
    return [(render_voice(v1, 24), False)], None, -13


def sfx_spell_cast():
    v1 = [ev(0, 18, N("A3"), Inst("pulse", (2, 5, 8, 5), pw=0.5, pw_lfo=(0.4, 8), slide=40))]
    v2 = [ev(0, 18, N("A4"), Inst("saw", (0, 5, 5, 5)), arp=[0, 7, 12], vol=0.4)]
    return [(render_voice(v1, 40), False), (render_voice(v2, 40), False)], None, -11


def sfx_quaff():
    v1 = [ev(0, 14, 220, Inst("pulse", (0, 6, 6, 4), pw=0.5, pw_lfo=(0.3, 5), vib=(2.0, 4, 0), slide=-10))]
    return [(render_voice(v1, 30), False)], None, -14


def sfx_heal():
    v1 = [ev(0, 20, N("C5"), Inst("tri", (0, 6, 9, 6)), arp=[0, 4, 7, 12, 16], vol=1.0)]
    v1[0]["inst"].arp_rate = 2
    return [(render_voice(v1, 36), False)], None, -12


def sfx_level_up():
    i = Inst("pulse", (0, 4, 9, 6), pw=0.25, vib=(0.2, 6, 6))
    notes = ["C5", "E5", "G5", "C6"]
    v1 = [ev(k * 4, 4 if k < 3 else 14, N(n), i) for k, n in enumerate(notes)]
    j = Inst("tri", (0, 4, 10, 6))
    v2 = [ev(k * 4, 4 if k < 3 else 14, N(n) / 2, j) for k, n in enumerate(notes)]
    return [(render_voice(v1, 40), False), (render_voice(v2, 40), False)], None, -10


def sfx_throw():
    v1 = [ev(0, 6, 3000, Inst("noise", (4, 3, 0, 3)))]
    filt = dict(cutoff=sweep(800, 6000, 12), res=5, mode="hp")
    return [(render_voice(v1, 12), True)], filt, -15


def sfx_door_open():
    v1 = [ev(0, 22, 90, Inst("saw", (3, 6, 8, 6), vib=(0.6, 3, 0), slide=14))]
    v2 = [ev(0, 22, 180, Inst("pulse", (3, 6, 8, 6), pw=0.1, slide=20), vol=0.3)]
    filt = dict(cutoff=np.full(50, 900.0), res=6, mode="lp")
    return [(render_voice(v1, 50), True), (render_voice(v2, 50), True)], filt, -12


def sfx_chest_open():
    v1 = [ev(0, 14, 120, Inst("saw", (3, 5, 7, 5), vib=(0.5, 4, 0), slide=30))]
    i = Inst("pulse", (0, 3, 5, 4), pw=0.25)
    v2 = [ev(14, 2, N("B5"), i), ev(17, 6, N("E6"), i)]
    return [(render_voice(v1, 40), False), (render_voice(v2, 40), False)], None, -11


def sfx_descend():
    i = Inst("pulse", (0, 3, 4, 3), pw=0.5)
    v1 = [ev(k * 5, 3, N(n), i) for k, n in enumerate(["A4", "F4", "D4", "A3"])]
    v2 = [ev(k * 5, 1, 1500, Inst("noise", (0, 2, 0, 2)), vol=0.5) for k in range(4)]
    return [(render_voice(v1, 30), False), (render_voice(v2, 30), False)], None, -12


def sfx_player_death():
    v1 = [ev(0, 50, 220, Inst("tri", (0, 9, 10, 8), slide=-18))]
    v2 = [ev(0, 50, 110, Inst("pulse", (0, 9, 8, 8), pw=0.5, slide=-14, vib=(0.8, 6, 0)), vol=0.7)]
    v3 = [ev(0, 20, 400, Inst("noise", (0, 8, 5, 8)))]
    return [(render_voice(v1, 90), False), (render_voice(v2, 90), False), (render_voice(v3, 90), False)], None, -9


def sfx_low_hp():
    # Two soft falling notes, a nudge and not an alarm
    i = Inst("tri", (2, 6, 6, 7))
    v1 = [ev(0, 6, N("A4"), i), ev(8, 10, N("E4"), i)]
    return [(render_voice(v1, 32), False)], None, -15


def sfx_bump():
    # A very quiet dry tick for walking into a wall, not a thud
    return [(render_voice([ev(0, 1, N("D6"), Inst("pulse", (0, 2, 0, 2), pw=0.5))], 4), False)], None, -24, 300


def sfx_ui_move():
    return [(render_voice([ev(0, 1, N("A5"), Inst("pulse", (0, 2, 0, 2), pw=0.5))], 4), False)], None, -17


def sfx_ui_accept():
    i = Inst("pulse", (0, 2, 3, 2), pw=0.25)
    return [(render_voice([ev(0, 2, N("E5"), i), ev(3, 3, N("B5"), i)], 9), False)], None, -14


def sfx_ui_back():
    i = Inst("pulse", (0, 2, 3, 2), pw=0.25)
    return [(render_voice([ev(0, 2, N("B5"), i), ev(3, 3, N("E5"), i)], 9), False)], None, -14


SFX = {name[4:]: fn for name, fn in globals().items() if name.startswith("sfx_")}

# ---------------------------------------------------------------- music

CHORDS = {   # root, arpeggio offsets
    "Dm": ("D", [0, 3, 7]), "Gm": ("G", [0, 3, 7]), "Am": ("A", [0, 3, 7]), "Em": ("E", [0, 3, 7]),
    "Bb": ("Bb", [0, 4, 7]), "F": ("F", [0, 4, 7]), "C": ("C", [0, 4, 7]), "A": ("A", [0, 4, 7]),
    "E": ("E", [0, 4, 7]), "D": ("D", [0, 4, 7]), "B": ("B", [0, 4, 7]), "G": ("G", [0, 4, 7]),
}

KICK = Inst("tri", (0, 3, 0, 2), slide=-260)
SNARE = Inst("noise", (0, 4, 0, 3))
HAT = Inst("noise", (0, 2, 0, 1), vol=0.7)


def melody_events(bars, speed, inst):
    events, step = [], 0
    for bar in bars:
        assert sum(ln for _, ln in bar) == 16, bar
        for name, ln in bar:
            if name:
                events.append(ev(step * speed, max(1, ln * speed - 1), N(name), inst))
            step += ln
    return events


def bass_events(chords, speed, pattern, inst, octave=2):
    events = []
    for b, chord in enumerate(chords):
        root = CHORDS[chord][0]
        for step, interval, ln in pattern:
            m = midi(root + str(octave)) + interval
            events.append(ev((b * 16 + step) * speed, max(1, int(ln * speed) - 1), hz(m), inst))
    return events


def drum_arp_events(chords, speed, pattern, arp_inst):
    """Voice 3 plays the arpeggio and, like on the real chip, also steals itself for the drums"""
    events = []
    for b, chord in enumerate(chords):
        arp = CHORDS[chord][1]
        root = midi(CHORDS[chord][0] + "4")
        for step, what, ln in pattern:
            start = (b * 16 + step) * speed
            if what == "kick":
                events.append(ev(start, 3, 120, KICK))
            elif what == "snare":
                events.append(ev(start, 3, 3500, SNARE))
            elif what == "hat":
                events.append(ev(start, 1, 9000, HAT))
            else:
                events.append(ev(start, max(1, int(ln * speed) - 1), hz(root + (12 if what == "arp_hi" else 0)),
                                 arp_inst, arp=arp))
    return events


def render_track(t):
    speed = t["speed"]
    total = 16 * 16 * speed
    lead = melody_events(t["melody"], speed, t["lead"])
    bass = bass_events(t["chords"], speed, t["bass_pattern"], t["bass"], t.get("bass_octave", 2))
    drum = drum_arp_events(t["chords"], speed, t["drum_pattern"], t["arp"])
    g = t.get("gains", (0.8, 0.9, 0.65))
    voices = [render_voice(lead, total) * g[0], render_voice(bass, total) * g[1], render_voice(drum, total) * g[2]]
    n = total * SPF
    for k, v in enumerate(voices):         # wrap the release tails so the loop has no gap
        tail = v[n:]
        v[:len(tail)] += tail
        voices[k] = v[:n]
    period = total // t.get("filter_cycles", 4)
    f = np.arange(total)
    cutoff = t["cutoff"][0] + t["cutoff"][1] * np.sin(2 * np.pi * f / period)
    mixed = mix([(voices[0], False), (voices[1], False), (voices[2], True)],
                dict(cutoff=cutoff, res=t.get("res", 6), mode="lp"), master=1.0)
    return finish(mixed, t.get("peak", -13), trim_silence=False)


L = lambda name, ln: (name, ln)

DUNGEON = dict(
    speed=10,
    chords=["Dm", "Dm", "Bb", "Bb", "Gm", "Gm", "A", "A", "Dm", "F", "C", "A", "Bb", "Gm", "A", "A"],
    melody=[
        [("A4", 4), ("D5", 2), ("F5", 2), ("E5", 4), ("D5", 2), ("C5", 2)],
        [("D5", 6), ("A4", 2), ("C5", 4), ("D5", 4)],
        [("F5", 4), ("D5", 4), ("Bb4", 4), ("D5", 4)],
        [("C5", 6), ("Bb4", 2), ("A4", 4), (None, 4)],
        [("G4", 4), ("Bb4", 4), ("D5", 4), ("G5", 4)],
        [("F5", 6), ("D5", 2), ("Bb4", 4), ("A4", 4)],
        [("E5", 4), ("A4", 4), ("C#5", 4), ("E5", 4)],
        [("E5", 6), ("C#5", 2), ("A4", 8)],
        [("D5", 2), ("F5", 2), ("A5", 4), ("G5", 2), ("F5", 2), ("E5", 4)],
        [("F5", 4), ("C5", 4), ("A4", 4), ("C5", 4)],
        [("E5", 4), ("G5", 4), ("E5", 4), ("C5", 4)],
        [("C#5", 4), ("E5", 4), ("A5", 4), ("E5", 4)],
        [("D5", 4), ("F5", 4), ("Bb5", 4), ("A5", 4)],
        [("G5", 4), ("D5", 4), ("Bb4", 4), ("D5", 4)],
        [("E5", 2), ("F5", 2), ("E5", 2), ("D5", 2), ("C#5", 4), ("A4", 4)],
        [("A4", 12), (None, 4)],
    ],
    # Calm: a slow tempo, a soft triangle lead, a long bass and a slow arpeggio, no drums
    lead=Inst("tri", (3, 9, 8, 8), vib=(0.12, 9, 14)),
    bass=Inst("tri", (3, 9, 9, 8)),
    arp=Inst("pulse", (4, 9, 5, 8), pw=0.5, arp_rate=6),
    bass_pattern=[(0, 0, 7), (8, 7, 7)],
    drum_pattern=[(0, "arp", 8), (8, "arp", 8)],
    cutoff=(850, 250), res=2, filter_cycles=2, gains=(0.7, 0.8, 0.35),
)

CAVERN = dict(
    speed=10,
    chords=["Am", "Am", "F", "F", "Dm", "Dm", "E", "E", "Am", "G", "F", "E", "Dm", "F", "E", "E"],
    melody=[
        [("E5", 8), ("C5", 4), ("B4", 4)], [("A4", 8), (None, 8)],
        [("C5", 8), ("A4", 4), ("F4", 4)], [("G4", 8), (None, 8)],
        [("D5", 8), ("A4", 4), ("F4", 4)], [("E4", 16)],
        [("G#4", 8), ("B4", 4), ("E5", 4)], [("D5", 4), ("B4", 4), ("G#4", 8)],
        [("A4", 4), ("C5", 4), ("E5", 8)], [("D5", 8), ("B4", 4), ("G4", 4)],
        [("A4", 8), ("C5", 4), ("F5", 4)], [("E5", 8), ("B4", 8)],
        [("F5", 8), ("D5", 4), ("A4", 4)], [("C5", 16)],
        [("B4", 8), ("G#4", 4), ("B4", 4)], [("E4", 12), (None, 4)],
    ],
    lead=Inst("tri", (4, 10, 8, 9), vib=(0.15, 10, 16)),
    bass=Inst("tri", (3, 9, 9, 8)),
    arp=Inst("pulse", (5, 9, 4, 9), pw=0.4, arp_rate=6),
    bass_octave=2,
    bass_pattern=[(0, 0, 7), (8, 7, 7)],
    drum_pattern=[(0, "arp", 8), (8, "arp_hi", 8)],
    cutoff=(750, 200), res=3, filter_cycles=2, gains=(0.7, 0.8, 0.3),
)

BOSS = dict(
    speed=9,
    chords=["Em", "Em", "C", "D", "Em", "Em", "F", "B", "Em", "C", "D", "B", "Em", "F", "Em", "B"],
    melody=[
        [("B4", 2), ("B4", 2), ("E5", 2), ("B4", 2), ("G5", 4), ("F#5", 2), ("E5", 2)],
        [("E5", 2), ("D5", 2), ("B4", 2), ("D5", 2), ("E5", 8)],
        [("C5", 2), ("C5", 2), ("G5", 2), ("E5", 2), ("C5", 4), ("B4", 4)],
        [("D5", 2), ("D5", 2), ("A5", 2), ("F#5", 2), ("D5", 4), ("C#5", 4)],
        [("B4", 2), ("B4", 2), ("E5", 2), ("B4", 2), ("G5", 4), ("F#5", 2), ("E5", 2)],
        [("G5", 4), ("E5", 4), ("B4", 4), ("E5", 4)],
        [("F5", 2), ("F5", 2), ("C6", 2), ("A5", 2), ("F5", 4), ("E5", 4)],
        [("B4", 2), ("D#5", 2), ("F#5", 2), ("B5", 2), ("A#5", 4), (None, 4)],
        [("E5", 4), ("G5", 4), ("B5", 4), ("G5", 4)],
        [("E5", 4), ("G5", 4), ("C6", 4), ("G5", 4)],
        [("F#5", 4), ("A5", 4), ("D6", 4), ("A5", 4)],
        [("F#5", 4), ("D#5", 4), ("B4", 8)],
        [("B4", 2), ("E5", 2), ("G5", 2), ("B5", 2), ("A5", 4), ("G5", 4)],
        [("A5", 4), ("F5", 4), ("C5", 4), ("F5", 4)],
        [("G5", 2), ("F#5", 2), ("E5", 2), ("D#5", 2), ("E5", 8)],
        [("D#5", 4), ("F#5", 4), ("A#5", 4), (None, 4)],
    ],
    lead=Inst("tri", (2, 8, 8, 7), vib=(0.2, 8, 10)),
    bass=Inst("tri", (2, 8, 8, 7)),
    arp=Inst("pulse", (3, 8, 5, 7), pw=0.5, arp_rate=5),
    bass_octave=2,
    bass_pattern=[(0, 0, 3), (4, 0, 3), (8, 7, 3), (12, 5, 3)],
    drum_pattern=[(0, "arp", 4), (4, "arp", 4), (8, "arp", 4), (12, "arp", 4)],
    cutoff=(1000, 300), res=2, filter_cycles=2, gains=(0.7, 0.8, 0.35),
)

# The newer areas reuse the melodic ideas above with other timbres and tempos (placeholders until they get
# songs of their own, see sounds/music/README.md)
CRYPT = dict(CAVERN, speed=12, lead=Inst("tri", (5, 10, 7, 9), vib=(0.2, 11, 18)),
             arp=Inst("pulse", (6, 10, 3, 10), pw=0.3, arp_rate=8), cutoff=(600, 150), res=4, gains=(0.65, 0.8, 0.28))
MINE = dict(DUNGEON, speed=12, lead=Inst("pulse", (3, 9, 6, 8), pw=0.3, vib=(0.1, 9, 20)),
            bass=Inst("tri", (4, 9, 8, 8)), cutoff=(700, 200), res=3, gains=(0.6, 0.8, 0.3))
VOLCANO = dict(BOSS, speed=11, lead=Inst("saw", (3, 9, 5, 8), vib=(0.15, 7, 14)),
               bass=Inst("tri", (3, 9, 9, 8)), cutoff=(900, 250), res=3, gains=(0.55, 0.85, 0.3))

TRACKS = {"dungeon": DUNGEON, "cavern": CAVERN, "boss": BOSS, "crypt": CRYPT, "mine": MINE, "volcano": VOLCANO}


def main(out):
    os.makedirs(os.path.join(out, "sfx"), exist_ok=True)
    # The SID tracks are the built-in fallback, songs placed in music/ itself take their place
    os.makedirs(os.path.join(out, "music", "sid"), exist_ok=True)
    tmp = os.path.join(out, "_tmp.wav")
    for name, fn in SFX.items():
        result = fn()
        voices, filt, peak = result[:3]
        hp = result[3] if len(result) > 3 else (40.0 if name in ("player_death", "door_open", "monster_death") else 120.0)
        x = finish(mix(voices, filt), peak, hp_hz=hp)
        sid.write_wav(tmp, x)
        sid.to_ogg(tmp, os.path.join(out, "sfx", name + ".ogg"))
        print("sfx", name, "%.2fs" % (len(x) / sid.SR))
    for name, t in TRACKS.items():
        x = render_track(t)
        sid.write_wav(tmp, x)
        sid.to_ogg(tmp, os.path.join(out, "music", "sid", name + ".ogg"), quality=3)
        print("music", name, "%.1fs" % (len(x) / sid.SR))
    os.remove(tmp)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "sounds")
