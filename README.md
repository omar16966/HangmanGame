# Pixel Hangman

A pixel-art Hangman word puzzle game made with **LÖVE2D + Lua**, with an
Arabic (right-to-left) and English interface and Arabic and English puzzles.

> **Development status:** Phase 1 (Foundation) is complete. See
> [Development phases](#development-phases). This README grows with each phase.

## Requirements

- [LÖVE](https://love2d.org) **11.5** (11.4 also works)
- No other dependencies. Runs fully offline.

## How to run

```sh
love .
```

Run it from the project folder, or drag the folder onto `love.exe` on Windows.

## Controls (so far)

| Key | Action |
|---|---|
| Enter / Space | Confirm |
| Esc / Backspace / right mouse button | Back |
| Arrow keys | Navigate |
| Esc / P | Pause (in gameplay) |
| F11 or Alt+Enter | Toggle fullscreen |
| F3 | Debug overlay *(debug builds only)* |
| F2 | Diagnostics screen *(debug builds only)* |

All bindings are in `Config.input` (`src/core/config.lua`).

## Project structure

```text
main.lua                 entry point (only forwards LÖVE callbacks to Game)
conf.lua                 window / module configuration
assets/                  art, audio, fonts, shaders (see ASSETS.md)
src/core/                config, constants, logger, utils, input, settings,
                         state manager, game loop, debug overlay, CLI options
src/graphics/            renderer (virtual canvas + scaling), palette
src/managers/            asset manager + asset manifest
src/states/              game states (boot, diagnostics, ... more per phase)
src/ui/ gameplay/ localization/   filled in by the next phases
data/                    puzzle and category data (Phase 3 / 9)
lib/                     third-party libraries (none yet)
tools/                   development scripts (headless checks)
```

### Architecture in short

- **Renderer** (`src/graphics/renderer.lua`): the whole game is drawn on a
  **320×180** canvas, which is then scaled up by a whole number (3× at
  960×540, 6× at 1920×1080) and centered. Black bars fill any space left
  over. `Renderer.screenToVirtual(x, y)` converts mouse positions. Screen shake
  moves the image in whole virtual pixels only.
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

## Configuration

Every tunable value is in `src/core/config.lua`. Set `Config.debug = false`
for release builds.

## Development tools

Command-line options (only when `Config.debug = true`):

```sh
love . --size 1920x1080          # start with this window size
love . --fullscreen
love . --state diagnostics       # first state after boot
love . --overlay                 # show the debug overlay
love . --screenshot shot.png --screenshot-after 1 --quit-after 1.5
```

Screenshots are saved in the LÖVE save folder
(`%APPDATA%\LOVE\pixel_hangman` on Windows,
`~/.local/share/love/pixel_hangman` on Linux).

`tools/run_checks.sh [state]` starts the game headless (using xvfb) at
320×180, 640×360, 960×540, 1280×720, 1920×1080, 1366×768 and 1000×700. It
then uses `tools/verify_pixels.py` to check that every virtual pixel is a
sharp square block and that the black bars are clean.

## Development phases

| # | Phase | Status |
|---|---|---|
| 1 | Foundation: renderer, 320×180 canvas, integer scaling, states, input, assets, config, logging | ✅ Done |
| 2 | Localization: Arabic shaping, RTL/Bidi, dictionaries, language switching | ⏳ Next |
| 3 | Core gameplay: puzzles, guesses, normalization, virtual keyboard, physics character | |
| 4 | Main UI: menus, gameplay screen, pause, results, settings | |
| 5 | Persistence: saves, profile, statistics, scores, continue | |
| 6 | Progression: XP, levels, streaks, achievements | |
| 7 | Polish: animations, transitions, particles, audio | |
| 8 | Shaders: vignette, CRT, scanlines, noise | |
| 9 | Content: Arabic and English puzzle packs, add-your-own-words feature | |
| 10 | QA | |

## Documentation

- `ASSETS.md`: every art and audio file the game expects
- `PUZZLES.md`, `LOCALIZATION.md`, `SAVE_FORMAT.md`: added in later phases
