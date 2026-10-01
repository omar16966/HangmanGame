# LOCALIZATION

How the game handles Arabic (right-to-left) and English (left-to-right) text.

## Overview

```text
data/localization/languages.lua   language list: direction, digits, dictionary
data/localization/ar.lua          Arabic interface strings
data/localization/en.lua          English interface strings
src/managers/localization_manager.lua   L(key), language switching, number formatting
src/localization/text.lua         the one text drawing API (shaping + bidi + wrapping + alignment)
src/localization/arabic_shaper.lua    contextual letter forms + lam-alef ligatures
src/localization/bidi.lua         Unicode bidirectional algorithm (logical -> visual order)
src/localization/utf8_util.lua    UTF-8 decode/encode
```

The **interface language** (`Settings.interfaceLanguage`) and the **puzzle
language** (`Settings.puzzleLanguage`) are separate settings. The player can
choose any combination of the two.

## Using text in code

Never write user-visible strings in game code. Add a key to the dictionaries
and use it:

```lua
local Localization = require("src.managers.localization_manager")
local L = Localization.L

L("PLAY")                              --> "ابدأ اللعب" or "Play"
L("ATTEMPTS_LEFT", { count = 3 })      --> "المحاولات المتبقية: ٣"
Localization.draw("PLAY", x, y, { width = 100, align = "start" })
Localization.drawText(playerName, x, y, { width = 100, align = "start" })
```

Never pass strings straight to `love.graphics.print`. Always draw through
`Text.draw` / `Localization.draw`; they are the only functions that shape
Arabic.

### Text options

| Option | Meaning |
|---|---|
| `font` | LÖVE font (default `Assets.fonts.regular`) |
| `width` | Box width: turns on word wrapping and box alignment |
| `wrap` | `false` keeps a single line even when `width` is set |
| `align` | `left`, `center`, `right`, `start`, `end` (default `start`) |
| `alignDirection` | Direction used to resolve `start`/`end`. `Localization.draw` sets it to the interface direction, so `start` means *right* in the Arabic UI and *left* in the English UI. |
| `direction` | Paragraph direction `rtl`/`ltr`/`auto` (default `auto` = first strong letter) |
| `height`, `valign` | Vertical alignment in a box: `top`, `middle`, `bottom` |
| `color`, `shadowColor`, `outlineColor` | Colors (1px shadow / outline for pixel-art text) |
| `lineHeight` | Line spacing override in pixels |

`Text.measure(str, opts)` returns the width and height without drawing, so
UI components can size themselves around translations of any length.

## Arabic shaping

LÖVE draws every character exactly as it is stored. It does not use the
font's OpenType shaping tables, so plain Arabic text would show as separate,
unconnected letters. `arabic_shaper.lua` fixes this:

1. Each letter gets a **joining type**:
   - dual-joining (ب ت ث …): connects to the letters on both sides
   - right-joining (ا د ذ ر ز و ة ى أ إ آ ؤ): never connects to the next letter
   - non-joining (ء)
   - join-causing (tatweel ـ)
   - transparent (diacritics): ignored when deciding how letters connect
2. Based on its neighbours, each letter becomes its **isolated**, **final**,
   **initial** or **medial** form from the Unicode Arabic Presentation Forms
   (U+FE70–FEFC, U+FB50–FBFF).
3. **Lam + alef** (لا لأ لإ لآ) become their required ligature.
4. **Fallbacks:** if the font lacks a form, the plain letter is drawn
   instead of an empty box. If the font has no diacritics (PixelAE has none),
   they are removed before drawing.

Shaping works on the text in *logical* order (the order it was typed).
Word direction is handled afterwards by the bidi step.

## Bidi (right-to-left and mixed text)

The text is never simply reversed. `bidi.lua` implements the Unicode Bidi
Algorithm (UAX #9), leaving out explicit embedding control characters:

- The **paragraph direction** comes from the first strong letter: Arabic → RTL,
  Latin → LTR. A string with no letters, such as `"123"`, follows the
  interface direction.
- **Arabic runs** are drawn right to left.
- **English words and numbers** inside Arabic stay left to right
  (`لغة الألغاز: English`, `النتيجة 1250 نقطة`, `٨٥٪`).
- **Punctuation and spaces** take the direction of the surrounding text.
  Brackets are mirrored in RTL runs, so `(مرحبا)` displays correctly.
- **Wrapping** happens on the logical text. Each line is then reordered on
  its own, as the standard requires.

Layouts are cached per string, font, width and direction, so text costs
almost nothing per frame.

### Verification

- `luajit tests/unit_tests.lua`: unit tests (UTF-8, shaping, fallbacks, bidi).
- `python3 tests/compare_reference.py`: shapes 41 Arabic words and phrases and
  compares the resulting glyphs with **HarfBuzz** using the PixelAE font. It also
  compares 22 mixed Arabic/English/number lines with **python-bidi**. Every case
  matches.
- `love . --page 2` (or F2 then Tab in debug builds): the text test page,
  where L switches the interface language live.

## Numbers

`Localization.formatNumber(value, decimals)` uses the digits set for each
language in `languages.lua`:

- Arabic: `digits = "arabic"` gives ٠١٢٣٤٥٦٧٨٩ with ٫ as the decimal separator.
  Set it to `"western"` for 0123456789.
- Numbers passed as placeholder values are formatted automatically:
  `L("POINTS", { value = 1250 })` → `١٢٥٠ نقطة`.

## Adding or changing UI translations

1. Add the key to **both** `data/localization/en.lua` and `ar.lua`.
2. Use `{name}` for values filled in at runtime.
3. At startup the game logs a warning for any key that is missing from a
   language. A missing key falls back to English, then to the key name, and
   never crashes the game.

## Adding another language

1. Copy `data/localization/en.lua` to `data/localization/<code>.lua` and translate it.
2. Add the language to `data/localization/languages.lua` (code, native name,
   direction, digits) and to its `order` list.
3. If the language needs glyphs PixelAE lacks, add a font to
   `asset_manifest.lua`.

The dictionaries are trusted Lua files bundled with the game. Content made by
players, such as words they add themselves, is stored as data and never run as
code.

## Puzzle normalization

Guesses are compared with the answer through `src/gameplay/normalizer.lua`.
The answer is always **displayed** exactly as written; normalization only
affects matching.

- English: guesses ignore case (`a` == `A`). Only A–Z are letters to guess.
- Arabic:
  - Diacritics (fatha, damma, kasra, shadda, sukun, tanween …) and tatweel
    are ignored completely.
  - The rules in `Config.normalization.arabic` can be switched on or off:

    | Rule | Default | Effect |
    |---|---|---|
    | `alefVariants` | on | أ إ آ ٱ match ا |
    | `alefMaqsura` | off | ى matches ي |
    | `taMarbuta` | off | ة matches ه |
    | `hamzaCarriers` | off | ؤ matches و, ئ matches ي |

  - The on-screen keyboard follows the rules automatically. A letter merged
    into another one gets no key, and when `alefVariants` is off, the
    أ إ آ keys appear.
- Physical keyboard: letters arrive through `love.textinput`, so an Arabic
  OS keyboard layout works directly. If the OS layout is still English during
  an Arabic puzzle, each key is mapped to the Arabic letter in the same
  position on a standard Arabic keyboard (`data/keyboards.lua`, `latinToArabic`).

### Arabic letters in the puzzle display

Each letter of an Arabic answer has its own cell, from right to left. A
revealed letter is drawn in the connected form it has in the word, and when
two neighbouring letters are both revealed, the joining stroke between their
cells is drawn too. Lam-alef is shown as two cells (two letters to guess),
not as the ligature.
