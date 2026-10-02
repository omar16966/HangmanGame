#!/usr/bin/env python3
"""Generates simple synthesized placeholder sounds and music (OGG Vorbis)
at the paths listed in assets_list.md. They are dummies to be replaced by
real audio; existing files are NEVER overwritten unless --force is given.

Usage:  python3 tools/generate_placeholder_audio.py [--force]
Needs:  ffmpeg with libvorbis (pure Python otherwise, no numpy needed).
"""
import math
import os
import random
import struct
import subprocess
import sys
import tempfile
import wave

RATE = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
FORCE = "--force" in sys.argv


def note(name):
    """'C5' -> frequency in Hz."""
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3,
             "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + (octave - 4) * 12) / 12)


def osc(kind, phase):
    p = phase % 1.0
    if kind == "sine":
        return math.sin(2 * math.pi * p)
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "triangle":
        return 4 * p - 1 if p < 0.5 else 3 - 4 * p
    return random.uniform(-1, 1)  # noise


def tone(buf, start, dur, f0, f1=None, kind="square", vol=0.3, attack=0.005, release=0.05):
    """Adds a tone (optionally sliding from f0 to f1) into buf (list of floats)."""
    f1 = f1 or f0
    n0, n = int(start * RATE), int(dur * RATE)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = f0 + (f1 - f0) * (i / max(1, n - 1))
        phase += f / RATE
        env = min(1.0, t / attack) if attack > 0 else 1.0
        tail = dur - t
        if tail < release:
            env *= max(0.0, tail / release)
        idx = n0 + i
        if idx < len(buf):
            buf[idx] += osc(kind, phase) * vol * env


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def write(path, channels, frames):
    """channels: list of sample lists (1 = mono, 2 = stereo)."""
    full = os.path.normpath(os.path.join(ROOT, path))
    if os.path.exists(full) and not FORCE:
        print(f"kept     assets/audio/{path} (already exists)")
        return
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(len(channels))
        w.setsampwidth(2)
        w.setframerate(RATE)
        data = bytearray()
        for i in range(frames):
            for ch in channels:
                v = max(-1.0, min(1.0, ch[i]))
                data += struct.pack("<h", int(v * 32000))
        w.writeframes(bytes(data))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis",
                    "-q:a", "4", full], check=True)
    os.remove(wav_path)
    print(f"written  assets/audio/{path}")


def sfx(path, seconds, build):
    buf = silence(seconds)
    build(buf)
    write(os.path.join("sfx", path), [buf], len(buf))


# Sound effects ------------------------------------------------------------------------------------

def make_sfx():
    sfx("ui_hover.ogg", 0.06, lambda b: tone(b, 0, 0.05, 1200, kind="sine", vol=0.25, release=0.04))
    sfx("ui_click.ogg", 0.09, lambda b: tone(b, 0, 0.08, 660, 990, vol=0.2, release=0.04))
    sfx("ui_back.ogg", 0.12, lambda b: tone(b, 0, 0.11, 660, 420, vol=0.2, release=0.05))

    def correct(b):
        tone(b, 0.00, 0.07, note("C6"), vol=0.18)
        tone(b, 0.07, 0.10, note("E6"), vol=0.18, release=0.06)
    sfx("letter_correct.ogg", 0.2, correct)

    def wrong(b):
        tone(b, 0, 0.22, 220, 140, kind="square", vol=0.2, release=0.08)
        tone(b, 0, 0.12, 0, kind="noise", vol=0.06, release=0.1)
    sfx("letter_wrong.ogg", 0.25, wrong)

    def hint(b):
        for i, n in enumerate(["E6", "G6", "B6"]):
            tone(b, i * 0.06, 0.12, note(n), kind="sine", vol=0.25, release=0.08)
    sfx("hint.ogg", 0.32, hint)

    def win(b):
        for i, n in enumerate(["C5", "E5", "G5", "C6"]):
            tone(b, i * 0.1, 0.18 if i < 3 else 0.4, note(n), vol=0.16, release=0.12)
    sfx("round_win.ogg", 0.75, win)

    def loss(b):
        for i, n in enumerate(["G4", "E4", "C4"]):
            tone(b, i * 0.18, 0.2 if i < 2 else 0.45, note(n), kind="triangle", vol=0.35, release=0.15)
    sfx("round_loss.ogg", 0.85, loss)

    sfx("score_count.ogg", 0.04, lambda b: tone(b, 0, 0.03, 1500, kind="square", vol=0.12, release=0.02))

    def level_up(b):
        for i, n in enumerate(["C5", "E5", "G5", "C6", "E6", "G6", "C7"]):
            tone(b, i * 0.07, 0.12 if i < 6 else 0.35, note(n), vol=0.14, release=0.08)
    sfx("level_up.ogg", 0.85, level_up)

    def achievement(b):
        tone(b, 0.0, 0.15, note("G5"), kind="sine", vol=0.3)
        tone(b, 0.12, 0.45, note("D6"), kind="sine", vol=0.3, release=0.3)
        tone(b, 0.12, 0.45, note("G6"), kind="sine", vol=0.12, release=0.3)
    sfx("achievement.ogg", 0.65, achievement)

    def pause(b):
        tone(b, 0.0, 0.06, note("G5"), vol=0.15)
        tone(b, 0.06, 0.08, note("C5"), vol=0.15, release=0.05)
    sfx("pause.ogg", 0.16, pause)

    def resume(b):
        tone(b, 0.0, 0.06, note("C5"), vol=0.15)
        tone(b, 0.06, 0.08, note("G5"), vol=0.15, release=0.05)
    sfx("resume.ogg", 0.16, resume)


# Music (seamless loops) ---------------------------------------------------------------------------

def music(path, bpm, chords, melody_kind="square", melody_vol=0.08, bass_vol=0.22, arpeggio=True):
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * len(chords)
    left, right = silence(total), silence(total)
    for i, chord in enumerate(chords):
        start = i * bar
        root = note(chord[0])
        # Bass: root on beats 1 and 3.
        for b in (0, 2):
            for ch in (left, right):
                tone(ch, start + b * beat, beat * 1.8, root / 2, kind="triangle", vol=bass_vol, release=0.2)
        # Arpeggio or held chord, slightly panned.
        if arpeggio:
            for step in range(8):
                n = note(chord[step % len(chord)])
                t = start + step * beat / 2
                tone(left, t, beat * 0.45, n * 2, kind=melody_kind, vol=melody_vol, release=0.08)
                tone(right, t, beat * 0.45, n * 2, kind=melody_kind, vol=melody_vol * 0.7, release=0.08)
        else:
            for k, name in enumerate(chord):
                ch = left if k % 2 == 0 else right
                tone(ch, start, bar * 0.95, note(name), kind="sine", vol=melody_vol, attack=0.3, release=0.4)
    write(os.path.join("music", path), [left, right], len(left))


def ambient(path, seconds=12.0):
    # Soft filtered noise (wind in an old room) with a slow swell; loops cleanly.
    random.seed(4)
    n = int(seconds * RATE)
    left, right = [0.0] * n, [0.0] * n
    lp_l = lp_r = 0.0
    for i in range(n):
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * i / n)
        lp_l += (random.uniform(-1, 1) - lp_l) * 0.02
        lp_r += (random.uniform(-1, 1) - lp_r) * 0.02
        left[i] = lp_l * 0.9 * swell
        right[i] = lp_r * 0.9 * swell
    write(os.path.join("music", path), [left, right], n)


def make_music():
    music("menu.ogg", 96, [["C4", "E4", "G4"], ["A3", "C4", "E4"], ["F3", "A3", "C4"], ["G3", "B3", "D4"]] * 2)
    music("gameplay.ogg", 80, [["D4", "F4", "A4"], ["A#3", "D4", "F4"], ["F3", "A3", "C4"], ["C4", "E4", "G4"]] * 2,
          melody_kind="triangle", melody_vol=0.12, bass_vol=0.18)
    music("results.ogg", 100, [["F4", "A4", "C5"], ["G4", "B4", "D5"], ["E4", "G4", "B4"], ["A4", "C5", "E5"]],
          arpeggio=False, melody_vol=0.12)
    ambient("ambient_room.ogg")


if __name__ == "__main__":
    random.seed(1)
    make_sfx()
    make_music()
