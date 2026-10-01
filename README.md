# Pixel Hangman

A pixel-art Hangman word puzzle game made with **LÖVE2D + Lua**, with an
Arabic (right-to-left) and English interface and Arabic and English puzzles.

> **Development status:** Phases 1 (Foundation), 2 (Localization) and 3 (Core gameplay) are complete. See
> [Development phases](#development-phases). This README grows with each phase.

## Requirements

- [LÖVE](https://love2d.org) **11.5** (11.4 also works)
- No other dependencies. Runs fully offline.

## How to run

```sh
love .
```

Run it from the project folder, or drag the folder onto `love.exe` on Windows.

## How to build / release

```sh
tools/build.sh
```

This produces:

- `build/PixelHangman.love`: runs on any system with LÖVE 11.5
  (`love PixelHangman.love`, or double-click it if LÖVE is installed)
- `build/PixelHangman-win64.zip`: a standalone Windows build. Unzip it and run
  `PixelHangman.exe`; nothing needs installing. The script downloads the
  official LÖVE 11.5 Windows files once and fuses the game into `love.exe`.

Before a public release, set `Config.debug = false` in `src/core/config.lua`
(this hides F2/F3 and the developer options).

## Controls (so far)

| Key | Action |
|---|---|
| Letters (keyboard) | Guess a letter. In Arabic puzzles, an English keyboard layout is mapped to the Arabic letter in the same position. |
| Mouse click | Press a key on the on-screen keyboard or a button |
| Arrow keys + Enter / Space | Move over the on-screen keyboard and press the focused key |
| Enter / click | Next puzzle (after a round) |
| F11 or Alt+Enter | Toggle fullscreen |
| F3 | Debug overlay *(debug builds only)*: shows the current puzzle and its answer |
| F2 | Diagnostics screen *(debug builds only)* |

The game currently starts directly in gameplay (`Config.startState`). The
main menu, pause menu (Esc), category selection and result screen come in
Phase 4.

All bindings are in `Config.input` (`src/core/config.lua`).

## Project structure

```text
main.lua                 entry point (only forwards LÖVE callbacks to Game)
conf.lua                 window / module configuration
assets/                  art, audio, fonts, shaders (see ASSETS.md)
src/core/                config, constants, logger, utils, input, settings,
                         state manager, game loop, debug overlay, CLI options
src/graphics/            renderer (virtual canvas + scaling), palette
src/managers/            asset manager + manifest, localization manager
src/localization/        text API, Arabic shaper, bidi, UTF-8 helpers
src/managers/puzzle_manager.lua  puzzle loading, validation, selection
src/gameplay/            round rules, normalizer, scoring, session, scene,
                         character physics, word display
src/ui/                  button, virtual keyboard, skin (9-slice), icons
src/graphics/            + rope physics, placeholders (code-drawn art), 9-slice
src/states/              game states (boot, gameplay, diagnostics, ...)
data/localization/       interface languages and dictionaries (ar, en)
data/puzzles/            puzzle packs (arabic/, english/), see PUZZLES.md
data/categories.lua      categories, data/keyboards.lua keyboard layouts
lib/                     third-party libraries (none yet)
tests/                   unit tests, reference comparison, test runner
tools/                   development scripts (headless display checks)
```

### Architecture in short

- **Renderer** (`src/graphics/renderer.lua`): the whole game is drawn on a
  **640×360** canvas, which is then scaled up by a whole number (2× at
  1280×720, 3× at 1920×1080, 4× at 2560×1440) and centered. Black bars fill
  any space left over. `Renderer.screenToVirtual(x, y)` converts mouse
  positions. Screen shake moves the image in whole virtual pixels only.
  The resolution is set in `Config.virtualWidth/virtualHeight`. (`plan.md`
  says 320×180; it was changed to 640×360 to give text and art more room.)
- **StateManager** (`src/core/state_manager.lua`): a stack of states.
  `switch` replaces the whole stack and `push`/`pop` add or remove overlays
  such as the pause menu. Each state implements only the callbacks it needs
  (`enter, exit, update, draw, action, keypressed, textinput, mousepressed, ...`).
- **Input** (`src/core/input.lua`): keys become actions (`CONFIRM`, `BACK`,
  `LEFT`, ...). States respond to actions, not to specific keys.
- **Assets** (`src/managers/asset_manager.lua`): loads everything listed in
  `asset_manifest.lua` once. A missing file is logged and replaced by a fallback.
- **Settings** (`src/core/settings.lua`): the player's live settings, with
  change listeners. Saved to disk in Phase 5.
- **Logger** (`src/core/logger.lua`): `Logger.info/warning/error/debug`, plus
  `warningOnce` for anything that could repeat every frame.
- **Gameplay** (`src/gameplay/`): `Round` holds the rules of one puzzle
  (guesses, attempts, hints, win/loss, save/restore) and has no drawing code.
  `Scoring` computes points from `Config.score`. `Scene` and `Character`
  animate the wooden frame and the character with spring and rope physics.
  `WordDisplay` draws the answer cells.
- **Localization** (`src/managers/localization_manager.lua` +
  `src/localization/`): `L("KEY")` for strings and `Text.draw` /
  `Localization.draw` for drawing. Arabic is shaped and reordered correctly;
  see [LOCALIZATION.md](LOCALIZATION.md).

## Configuration

Every tunable value is in `src/core/config.lua`. Set `Config.debug = false`
for release builds.

## How scoring works

All values are in `Config.score` and `Config.difficulty`
(`src/gameplay/scoring.lua`):

```text
round score = ( 100 for solving
              + 10 per letter you found
              + 20 per unused attempt          (solved only)
              + speed bonus up to 100          (solved only; falls to 0 after 6 s per letter)
              - 5 per wrong guess
              - 50 for the text hint, 100 per revealed letter )
              x difficulty multiplier (1.0 / 1.5 / 2.0), never below 0
```

Repeated guesses cost nothing. The score in the top bar is the session total
plus the points of the round in progress.

## Development tools

Command-line options (only when `Config.debug = true`):

```sh
love . --size 1920x1080          # start with this window size
love . --fullscreen
love . --state diagnostics       # first state after boot
love . --overlay                 # show the debug overlay
love . --lang en                 # force the interface language (ar / en)
love . --page 2                  # diagnostics: open the text test page
love . --set puzzleLanguage=en   # change any setting (repeatable)
love . --seed 42                 # fixed random seed
love . --screenshot shot.png --screenshot-after 1 --quit-after 1.5
```

Screenshots are saved in the LÖVE save folder
(`%APPDATA%\LOVE\pixel_hangman` on Windows,
`~/.local/share/love/pixel_hangman` on Linux).

In the diagnostics screen, **Tab** switches between the display page and the
text page, and **L** toggles the interface language.

### Tests

```sh
tests/run_all.sh          # everything below
luajit tests/unit_tests.lua
luajit tests/gameplay_tests.lua      # rules, normalization, scoring, puzzles
python3 tests/compare_reference.py   # Arabic shaping vs HarfBuzz, bidi vs python-bidi
tools/run_checks.sh       # pixel-perfect screenshots at 7 window sizes
```

Requirements: `luajit`, `xvfb-run`, Python 3 with `pillow uharfbuzz python-bidi fonttools`.

`tools/run_checks.sh [state]` starts the game headless (using xvfb) at
640×360, 1280×720, 1920×1080, 2560×1440, 1366×768, 1000×700 and 800×450. It
then uses `tools/verify_pixels.py` to check that every virtual pixel is a
sharp square block and that the black bars are clean.

## Development phases

| # | Phase | Status |
|---|---|---|
| 1 | Foundation: renderer, 640×360 canvas, integer scaling, states, input, assets, config, logging | ✅ Done |
| 2 | Localization: Arabic shaping, RTL/Bidi, dictionaries, language switching | ✅ Done |
| 3 | Core gameplay: puzzles, guesses, normalization, virtual keyboard, physics character | ✅ Done |
| 4 | Main UI: menus, gameplay screen, pause, results, settings | ⏳ Next |
| 5 | Persistence: saves, profile, statistics, scores, continue | |
| 6 | Progression: XP, levels, streaks, achievements | |
| 7 | Polish: animations, transitions, particles, audio | |
| 8 | Shaders: vignette, CRT, scanlines, noise | |
| 9 | Content: Arabic and English puzzle packs, add-your-own-words feature | |
| 10 | QA | |

## Documentation

- `ASSETS.md`: every art and audio file the game expects
- `LOCALIZATION.md`: Arabic shaping, RTL/bidi, adding translations and languages
- `PUZZLES.md`: puzzle file format, categories, hints, difficulty, validation
- `SAVE_FORMAT.md`: added in Phase 5
