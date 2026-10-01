# ASSETS

Every art and audio file the game can use. **All files are optional except
the font:** while a file is missing, the game draws placeholder art in code
or skips the sound, and logs one warning at startup.

Asset keys are defined in `src/managers/asset_manifest.lua`. Code never uses
file paths directly. To add a file, drop it into the right folder with the exact
name below and restart the game. No code change is needed.

> **Status.** Specs marked **Final** can be made now. Specs marked **Draft**
> depend on the gameplay screen layout and the physics-driven character
> (Phases 3–4). Please wait for the final version before drawing those.

## General rules

| Topic | Rule |
|---|---|
| Image format | PNG, RGBA, no color profile. |
| Pixel scale | Draw at **1:1** for the **640×360** screen. Never pre-scale art; the game scales by whole numbers (2× = 1280×720, 3× = 1920×1080, 4× = 2560×1440). |
| Colors | Try to stay close to `src/graphics/palette.lua`, the shared color palette. |
| Sprite sheets | Frames are laid out left → right in one row, with no spacing between them, unless stated otherwise. |
| Audio format | OGG Vorbis, 44.1 kHz. Sound effects in mono, music in stereo. |
| Music loops | Must loop seamlessly (no silence at the start or end). |
| File names | Lower case, exactly as listed (the packaged game is case-sensitive). |

---

## Fonts — `assets/PixelAE/` (provided)

| File | Status | Notes |
|---|---|---|
| `PixelAE-Regular.ttf` | ✅ Provided — **required** | Main UI font. Its pixel grid is 10px: size 10 (1×) for normal text, size 20 (2×) for titles. |
| `PixelAE-Bold.ttf` | ✅ Provided — **required** | Titles and emphasis. |

Font analysis (done with fontTools):
- Has all Arabic letters plus the initial, medial and final connected forms
  (U+FE70–FEFC) and the lam-alef ligatures. The Arabic shaping layer needs
  these.
- Has no separate isolated forms. The shaper uses the base letters (U+0621–064A)
  instead, which works the same way.
- Has no Arabic diacritics (harakat). They are removed before drawing.
- Missing Latin symbols: `# $ % & * + < = > @ [ ] ^ \` { | } ~`. These are
  drawn with LÖVE's built-in font as a fallback. If you update the font,
  adding them would make the text look more consistent.

---

## Backgrounds — `assets/backgrounds/`

| File | Size | Frames | Purpose | Status |
|---|---|---|---|---|
| `menu.png` | 640×360 | 1 | Main menu background | Final |
| `gameplay.png` | 640×360 | 1 | Gameplay background (keep the center calm: the puzzle is drawn on top) | Draft |
| `results.png` | 640×360 | 1 | Results screen background | Final |
| `gameplay_far.png` | 640×360, transparent | 1 | Optional far layer that moves slowly behind the scene | Draft |
| `gameplay_near.png` | 640×360, transparent | 1 | Optional near layer (dust, foreground frame) | Draft |

Animated details (candle flicker, floating dust) are drawn with code and
particles, so the backgrounds can be static.

## Scene and character — `assets/sprites/`

| File | Size | Frames | Purpose | Status |
|---|---|---|---|---|
| `hangman_stages.png` | 1120×144 | 7 frames of 160×144 | The wooden frame built in 7 steps: frame 0 = no mistakes, frame 6 = last mistake. Wood only; the rope and character are separate. | Draft |
| `character_parts.png` | TBD | TBD | The cute character, split into parts (body, face expressions, hat, hands) so the physics system can animate it (idle bobbing, surprised jump and wobble on a wrong guess). | **Draft — wait for Phase 3** |

## UI — `assets/ui/`

| File | Size | Frames | Purpose | Status |
|---|---|---|---|---|
| `panel.png` | 24×24 | 1 | Stretchable panel frame (9-slice): the 8px corners stay fixed and the edges and middle stretch. | Final |
| `button.png` | 64×16 | 4 frames of 16×16 | Stretchable button (9-slice, 4px corners): normal, hover, pressed, disabled | Draft |
| `key.png` | 64×16 | 4 frames of 16×16 | Virtual keyboard key (9-slice, 5px corners): normal, pressed, correct, wrong | Draft |
| `cursor.png` | 16×16 | 1 | Optional mouse cursor. The tip is the top-left pixel. | Final |
| `logo_ar.png` | up to 400×80 | 1 | Optional Arabic title logo (otherwise the title is drawn as text) | Final |
| `logo_en.png` | up to 400×80 | 1 | Optional English title logo | Final |

## Icons — `assets/icons/`

| File | Size | Frames | Purpose | Status |
|---|---|---|---|---|
| `icons.png` | 160×16 (16×16 per icon, one row) | 10 | In this order: attempt/heart, hint, star, pause, back arrow (pointing **left**; mirrored automatically for Arabic), sound, check mark, cross, lock, trophy | Draft |

## Audio — `assets/audio/` (Phase 7)

| File | Purpose | Status |
|---|---|---|
| `sfx/ui_hover.ogg` | Cursor moves onto a button | Final |
| `sfx/ui_click.ogg` | Button pressed | Final |
| `sfx/ui_back.ogg` | Back / cancel | Final |
| `sfx/letter_correct.ogg` | Correct letter | Final |
| `sfx/letter_wrong.ogg` | Wrong letter | Final |
| `sfx/hint.ogg` | Hint used | Final |
| `sfx/round_win.ogg` | Puzzle solved | Final |
| `sfx/round_loss.ogg` | Puzzle failed | Final |
| `sfx/score_count.ogg` | One short tick, repeated while the score counts up | Final |
| `sfx/level_up.ogg` | Player level up | Final |
| `sfx/achievement.ogg` | Achievement unlocked | Final |
| `sfx/pause.ogg` | Pause menu opened | Final |
| `sfx/resume.ogg` | Pause menu closed | Final |
| `music/menu.ogg` | Menu music (loop) | Final |
| `music/gameplay.ogg` | Gameplay music (loop, calm) | Final |
| `music/results.ogg` | Results music (loop or short sting) | Final |
| `music/ambient_room.ogg` | Optional room ambience (loop) | Final |

## Shaders — `assets/shaders/` (Phase 8)

Written by the developer as GLSL source files. No art needed.
