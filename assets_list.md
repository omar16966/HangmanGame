# Assets I can add

Every art and audio file the game uses, with its exact name, folder, size and
frame layout.

**All of these files already exist as dummy placeholders.** The images were
exported from the art the game draws in code, and the sounds are simple
synthesized beeps and loops. To use your own art or sound, **overwrite the
file with the same name**. No code change is needed.

> The dummy images also work as templates: open one in your pixel-art
> editor to see the exact frame layout, then paint over it.

**General rules**

- **Images:** PNG with transparency (RGBA), drawn at **1:1** for the
  **640×360** game screen. Never pre-scale art; the game scales it to
  1280×720 (2×), 1920×1080 (3×) and 2560×1440 (4×).
- **File names:** keep them exactly as listed, in lowercase. Packaged games
  are case-sensitive.
- **Sprite sheets:** frames go left to right in one row, with no gaps between
  them.
- **Colors:** try to stay close to the palette in `src/graphics/palette.lua`,
  a warm wooden room at night with amber and teal accents.
- **Audio:** OGG Vorbis at 44.1 kHz. Sound effects in mono, music in stereo.
  Music must loop seamlessly.
- **Already provided:** the PixelAE fonts in `assets/PixelAE/`.
- **Made by code (nothing to draw):** shaders, particles and the rope.

---

## A. Used by the game now

### 1. `assets/backgrounds/gameplay.png`: 640×360, 1 frame

The room behind the game.

- The floor line the character stands on is at **y = 160**.
- Keep everything below **y ≈ 176** dark and plain. The word, keyboard and
  buttons are drawn there.

### 2. `assets/sprites/hangman_stages.png`: 1120×144, 7 frames of 160×144

The wooden frame built in 7 steps. Draw **wood only**: no rope and no
character.

| Frame | Content |
|---|---|
| 0 | Empty (no mistakes yet; can contain ground decoration) |
| 1 | Base plank |
| 2 | + vertical post |
| 3 | + top beam |
| 4 | + diagonal brace |
| 5 | Same as 4 (the rope appears now, drawn by code) |
| 6 | Same as 5 (round lost) |

Fixed points inside **each** 160×144 frame (the code uses them):

- **Ground line:** y = 136.
- **Rope anchor:** pixel **(112, 21)**. The end of the top beam must be here.
- **Character area:** keep **x = 92–132, y = 96–136** free of wood. The
  character stands there.

The frame is drawn at screen position x = 240, y = 22.

### 3. `assets/sprites/character.png`: 320×32, 10 frames of 32×32

Draw each part **centered in its frame** (center pixel = 16,16). The physics
moves the parts separately.

| # | Frame | Notes |
|---|---|---|
| 1 | calm | Body with a neutral face. The body is round, about 28×24. |
| 2 | blink | Calm, with eyes closed |
| 3 | happy | Correct guess / win |
| 4 | worried | After several mistakes |
| 5 | scared | Right after a wrong guess |
| 6 | sad | Round lost |
| 7 | squash | Body flattened when landing, about 32×20 |
| 8 | stretch | Body stretched when jumping, about 24×28 |
| 9 | foot | One foot, about 10×6, drawn twice |
| 10 | leaf | The leaf on the head. Put the **bottom of the stem at the frame center**. |

The code draws the rope belt and the sweat drop on top.

### 4. `assets/ui/key.png`: 64×16, 4 frames of 16×16

Keyboard key, **9-slice with 5px corners**. On screen, keys are 32×30.

| Frame | State |
|---|---|
| 1 | normal |
| 2 | pressed |
| 3 | correct |
| 4 | wrong |

The code adds the hover and focus effects.

### 5. `assets/ui/button.png`: 64×16, 4 frames of 16×16

Button, **9-slice with 4px corners**. On screen, buttons are 18–20px tall.

| Frame | State |
|---|---|
| 1 | normal |
| 2 | hover |
| 3 | pressed |
| 4 | disabled |

### 6. `assets/ui/panel.png`: 24×24, 1 frame

Panel / window frame, **9-slice with 8px corners**.

### 7. `assets/icons/icons.png`: 192×16, 12 icons of 16×16

In this order:

| # | Icon | # | Icon |
|---|---|---|---|
| 1 | heart (attempt left) | 7 | back arrow (pointing **left**; mirrored automatically for Arabic) |
| 2 | empty heart (attempt used) | 8 | sound |
| 3 | hint (light bulb) | 9 | check mark |
| 4 | reveal (eye) | 10 | cross |
| 5 | star | 11 | lock |
| 6 | pause | 12 | trophy |

Icons are drawn in their own colors and darkened automatically on disabled
buttons.

> **9-slice:** the corners stay exactly as drawn, and the edges and middle
> stretch. One small image can make a frame of any size.

---

## B. Used by the menus (Phase 4)

| # | File | Size | Content |
|---|---|---|---|
| 8 | `assets/backgrounds/menu.png` | 640×360 | Main menu background |
| 9 | `assets/backgrounds/results.png` | 640×360 | Results screen background |
| 10 | `assets/ui/logo_ar.png` | up to 400×80 | Arabic title logo "الرجل المشنوق" |
| 11 | `assets/ui/logo_en.png` | up to 400×80 | English title logo "Hangman" |
| 12 | `assets/ui/cursor.png` | 16×16 | Mouse cursor. **The tip is the top-left pixel.** |

---

## C. Used from Phase 7 (sound and effects)

### Sound effects: `assets/audio/sfx/` (OGG, mono)

| # | File | When it plays |
|---|---|---|
| 13 | `ui_hover.ogg` | The mouse moves onto a button |
| 14 | `ui_click.ogg` | A button is pressed |
| 15 | `ui_back.ogg` | Back / cancel |
| 16 | `letter_correct.ogg` | Correct letter |
| 17 | `letter_wrong.ogg` | Wrong letter |
| 18 | `hint.ogg` | A hint is used |
| 19 | `round_win.ogg` | Puzzle solved |
| 20 | `round_loss.ogg` | Puzzle lost |
| 21 | `score_count.ogg` | One short tick, repeated while the score counts up |
| 22 | `level_up.ogg` | The player levels up |
| 23 | `achievement.ogg` | An achievement is unlocked |
| 24 | `pause.ogg` | The pause menu opens |
| 25 | `resume.ogg` | The pause menu closes |

### Music: `assets/audio/music/` (OGG, stereo, must loop with no gap)

| # | File | Use |
|---|---|---|
| 26 | `menu.ogg` | Menu music |
| 27 | `gameplay.ogg` | Calm music while playing |
| 28 | `results.ogg` | Results screen (a loop or a short tune) |
| 29 | `ambient_room.ogg` | Room ambience, such as wind or a ticking clock |

### Extra background layers (optional)

| # | File | Size | Use |
|---|---|---|---|
| 30 | `assets/backgrounds/gameplay_far.png` | 640×360, transparent | Far layer that moves slightly (parallax) |
| 31 | `assets/backgrounds/gameplay_near.png` | 640×360, transparent | Near layer, such as a foreground frame or dust |

The dummy versions of 30 and 31 are fully transparent.

---

## Tips

- **Where to start:** numbers 2, 3 and 4 change the game's look the most.
- **Checking your files:** after adding files, start the game. The log lists
  any image the game could not load. You can also tell me, and I'll check
  every file.
- **Restoring the dummy files** (only fills in missing files, never
  overwrites yours):
  ```sh
  tools/export_placeholders.sh                # images
  python3 tools/generate_placeholder_audio.py # sounds
  ```
  Add `--force` to either command to overwrite **all** files with the dummies.
- **Full technical details** are in `ASSETS.md`.
