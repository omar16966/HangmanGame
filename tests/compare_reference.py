#!/usr/bin/env python3
"""Compares the game's Arabic shaper and bidi implementation against
reference implementations:

  * shaping: HarfBuzz shaping the same text with the PixelAE font (glyph ids)
  * bidi:    python-bidi (full Unicode Bidi Algorithm)

Run from the project root:  python3 tests/compare_reference.py
Requires: luajit, pip install uharfbuzz python-bidi
"""
import subprocess
import sys

import uharfbuzz as hb
from bidi import get_display

FONT = "assets/PixelAE/PixelAE-Regular.ttf"

SHAPE_CASES = [
    "برمجة", "الذكاء الاصطناعي", "لا", "لأن", "سلام", "إسلام", "مستشفى",
    "ابدأ اللعب", "الإحصائيات", "الإعدادات", "طريقة اللعب", "خروج", "متابعة",
    "الرجل المشنوق", "اختر لغة الواجهة", "بيت", "ء", "شيء", "مسؤول", "سئل",
    "القاهرة", "الطائرة", "ظل", "غيم", "فيل", "قطة", "كتاب", "نهر", "هلال",
    "وردة", "يد", "ثعلب", "حصان", "خبز", "ضفدع", "عنكبوت", "ـبـ", "كلآ", "فلإ",
    "تُفَّاحَة", "مُبَرْمِج",
]

BIDI_CASES = [
    ("rtl", "لغة الألغاز: English"),
    ("rtl", "النتيجة 1250 نقطة"),
    ("rtl", "النتيجة ١٢٥٠ نقطة"),
    ("rtl", "الدقة 85% جيد"),
    ("rtl", "(مرحبا)"),
    ("rtl", "هل أنت مستعد؟"),
    ("rtl", "اللغة English والأرقام 3.14"),
    ("rtl", "Level 3 المستوى"),
    ("rtl", "مرحبا, World!"),
    ("rtl", "الوقت 10:30 صباحا"),
    ("ltr", "Puzzle language: العربية"),
    ("ltr", "Score: 1250 points"),
    ("ltr", "Arabic word: برمجة (programming)"),
    ("ltr", "العربية first"),
    ("ltr", "Level ١٢ done"),
    ("ltr", "a - b"),
    ("rtl", "كلمة - أخرى"),
    ("rtl", "سعر 5$ فقط"),
    ("rtl", "رقم -5 سالب"),
    ("ltr", "Hello"),
    ("rtl", "مرحبا   "),
    ("rtl", "اسم: Omar، العمر: 20"),
]


MIRROR = dict(zip("()[]{}<>«»", ")(][}{><»«"))


def only_mirrored(a, b):
    return len(a) == len(b) and all(x == y or MIRROR.get(x) == y for x, y in zip(a, b))


def run_lua(lines):
    data = "\n".join(lines) + "\n"
    out = subprocess.run(["luajit", "tests/dump_text.lua"], input=data.encode(),
                         capture_output=True, check=True).stdout.decode()
    return [[int(h, 16) for h in l.split()] for l in out.splitlines()]


def hb_glyphs(font, text):
    buf = hb.Buffer()
    buf.add_str(text)
    buf.direction = "rtl"
    buf.script = "Arab"
    buf.language = "ar"
    hb.shape(font, buf, {})
    return [info.codepoint for info in buf.glyph_infos]


def main():
    blob = hb.Blob.from_file_path(FONT)
    face = hb.Face(blob)
    font = hb.Font(face)
    from fontTools.ttLib import TTFont
    tt = TTFont(FONT)
    cmap = tt.getBestCmap()
    order = tt.getGlyphOrder()
    gid = {name: i for i, name in enumerate(order)}
    marks = set(range(0x064B, 0x0660)) | {0x0670}

    failures = 0

    # Shaping: our output reversed (RTL visual) mapped to glyph ids must match HarfBuzz.
    results = run_lua([f"shape\trtl\t{t}" for t in SHAPE_CASES])
    for text, cps in zip(SHAPE_CASES, results):
        ref_text = "".join(c for c in text if ord(c) not in marks)
        ref = [g for g in hb_glyphs(font, ref_text)]
        ours = [gid.get(cmap.get(cp, ".notdef"), 0) for cp in reversed(cps)]
        if ours != ref:
            failures += 1
            print(f"SHAPE MISMATCH {text!r}\n  ours {ours}\n  ref  {ref}")
    print(f"shaping: {len(SHAPE_CASES) - failures}/{len(SHAPE_CASES)} match HarfBuzz")

    bidi_fail = 0
    results = run_lua([f"bidi\t{d}\t{t}" for d, t in BIDI_CASES])
    for (d, text), cps in zip(BIDI_CASES, results):
        ref = get_display(text, base_dir="R" if d == "rtl" else "L")
        ours = "".join(chr(c) for c in cps)
        # python-bidi does not apply rule L4 (bracket mirroring); the game must,
        # because LÖVE draws codepoints as-is. Accept differences that are only
        # mirrored brackets.
        if ours != ref and not only_mirrored(ours, ref):
            bidi_fail += 1
            print(f"BIDI MISMATCH [{d}] {text!r}\n  ours {ours!r}\n  ref  {ref!r}")
    print(f"bidi: {len(BIDI_CASES) - bidi_fail}/{len(BIDI_CASES)} match python-bidi")
    return 1 if failures or bidi_fail else 0


if __name__ == "__main__":
    sys.exit(main())
