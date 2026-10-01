# ASSETS

Every art and audio file the game can use. **All files are optional except
the font:** while a file is missing, the game draws placeholder art in code
or skips the sound, and logs one warning at startup.

Asset keys are defined in `src/managers/asset_manifest.lua`. Code never uses
file paths directly. To add a file, drop it into the right folder with the exact
name below and restart the game. No code change is needed.

> **Status.** Specs marked **Final** can be made now. Specs marked **Draft**
> depend on a later phase and may still change.

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
| `gameplay.png` | 640×360 | 1 | Gameplay background. The floor line the character stands on is at **y = 160**. Keep the area below y ≈ 176 dark and calm: the word, keyboard and buttons are drawn there. | Final |
| `results.png` | 640×360 | 1 | Results screen background | Final |
| `gameplay_far.png` | 640×360, transparent | 1 | Optional far layer that moves slowly behind the scene | Draft (Phase 7) |
| `gameplay_near.png` | 640×360, transparent | 1 | Optional near layer (dust, foreground frame) | Draft (Phase 7) |

Animated details (candle flicker, floating dust) are drawn with code and
particles, so the backgrounds can be static.

## Scene — `assets/sprites/hangman_stages.png` (Final)

**1120×144**: 7 frames of **160×144**, left to right. The frame is drawn
centered at the top of the screen (screen position x = 240, y = 22).

| Frame | Shows (wood only) |
|---|---|
| 0 | Empty (no mistakes yet; can contain ground decoration) |
| 1 | Base plank |
| 2 | + vertical post |
| 3 | + top beam |
| 4 | + diagonal brace |
| 5 | Same as 4 (the rope appears now, drawn by code) |
| 6 | Same as 5 (round lost) |

Fixed points inside each 160×144 frame (the code uses them):

- **Ground line: y = 136.** The character's feet touch it.
- **Rope anchor: pixel (112, 21).** The rope hangs from here, so the end of
  the top beam must be there. The rope is drawn by code with physics; don't
  draw it.
- **Character position: centered on x = 112** and standing on the ground. Leave
  the area from x = 92 to 132 and y = 96 to 136 free of wood.

## Character — `assets/sprites/character.png` (Final)

**320×32**: 10 frames of **32×32** in one row. The physics moves each part
separately, so draw each part centered in its frame (center pixel = 16,16).

| # | Frame | Notes |
|---|---|---|
| 1 | calm | Body with a neutral face. The body is about 28×24, round. |
| 2 | blink | calm with closed eyes |
| 3 | happy | correct guess / win |
| 4 | worried | after several mistakes |
| 5 | scared | right after a wrong guess |
| 6 | sad | round lost (it is lifted by the rope tied around its waist) |
| 7 | squash | body flattened (landing): about 32×20 |
| 8 | stretch | body stretched (jumping): about 24×28 |
| 9 | foot | one foot, about 10×6, drawn twice |
| 10 | leaf | the leaf on the head. Put the bottom of the stem at the frame center; it sways with physics. |

The rope belt around the waist is drawn by code over the body.

## UI — `assets/ui/`

| File | Size | Frames | Purpose | Status |
|---|---|---|---|---|
| `panel.png` | 24×24 | 1 | Stretchable panel frame (9-slice): the 8px corners stay fixed and the edges and middle stretch. | Final |
| `button.png` | 64×16 | 4 frames of 16×16 | Stretchable button (9-slice, 4px corners): normal, hover, pressed, disabled. Buttons are 18–20px tall. | Final |
| `key.png` | 64×16 | 4 frames of 16×16 | Keyboard key (9-slice, 5px corners): normal, pressed, correct, wrong. Keys are 32×30. Hover and focus are added by code. | Final |
| `cursor.png` | 16×16 | 1 | Optional mouse cursor. The tip is the top-left pixel. | Final |
| `logo_ar.png` | up to 400×80 | 1 | Optional Arabic title logo (otherwise the title is drawn as text) | Final |
| `logo_en.png` | up to 400×80 | 1 | Optional English title logo | Final |

## Icons — `assets/icons/icons.png` (Final)

**192×16**: 12 icons of 16×16 in one row, in this order:

1. heart (one attempt left) · 2. empty heart (used attempt) · 3. hint (light bulb) ·
4. reveal (eye) · 5. star · 6. pause · 7. back arrow (pointing **left**; mirrored
automatically for Arabic) · 8. sound · 9. check mark · 10. cross · 11. lock · 12. trophy

Icons from the sheet are drawn in their own colors. The placeholder icons
are white shapes tinted by the code.

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
