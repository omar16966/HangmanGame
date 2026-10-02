# SAVE_FORMAT

How the game stores the player's data. The code is in
`src/managers/save_manager.lua` (reading/writing), `src/core/json.lua` (the
file format) and one module per section (see [Sections](#sections)).

## Where the files are

Saves are written to the LÖVE **save folder**, never to the game's own folder.

| System | Folder |
|---|---|
| Windows | `%APPDATA%\LOVE\pixel_hangman\` |
| Linux | `~/.local/share/love/pixel_hangman/` |
| macOS | `~/Library/Application Support/LOVE/pixel_hangman/` |

(The folder name comes from `Config.app.identity`.)

| File | Purpose |
|---|---|
| `save.json` | The save. |
| `save.bak` | The save as it was before the last write. |
| `save.start.bak` | The save as it was when the game started. |
| `save.tmp` | Exists only for a moment while writing (see below). |
| `save.corrupt-<date>-<time>.json` | A damaged `save.json`, kept for inspection (the newest 3 are kept). |
| `save.future.bak` | A copy of a save written by a *newer* version of the game. |

For development, `love . --profile test` keeps everything in
`profiles/test/` instead.

The file is plain, readable JSON (UTF-8). Players can inspect it; hand editing
is safe because every value is checked when loading.

## Schema (version 1)

```json
{
  "version": 1,
  "savedAt": 1790946302,
  "gameVersion": "0.1.0",

  "player":   { "name": "Omar", "createdAt": 1790946299 },

  "settings": {
    "interfaceLanguage": "ar", "puzzleLanguage": "en", "difficulty": "normal",
    "masterVolume": 1, "musicVolume": 0.7, "sfxVolume": 0.8, "mute": false,
    "fullscreen": false, "windowWidth": 1280, "windowHeight": 720,
    "shaders": true, "crt": true, "scanlines": true, "screenShake": true, "particles": true
  },

  "stats": {
    "gamesPlayed": 14, "roundsPlayed": 87, "roundsWon": 61, "roundsLost": 26,
    "correctGuesses": 520, "wrongGuesses": 215, "arabicGames": 8, "englishGames": 6,
    "bestScore": 1850, "bestRoundScore": 410, "totalScore": 15230,
    "bestStreak": 9, "currentStreak": 3, "hintsUsed": 22, "perfectRounds": 12,
    "playTime": 8420.5
  },

  "scores": [
    { "name": "Omar", "score": 1850, "language": "ar", "difficulty": "hard",
      "time": 1790946000, "rounds": 11, "correct": 9 }
  ],

  "progress": {
    "xp": 0, "level": 1,
    "unlockedCategories": [], "achievements": {},
    "recentPuzzles": ["EN_ANI_003", "AR_FOOD_004"]
  },

  "suspended": {
    "round":   { "puzzleId": "AR_FOOD_004", "maxWrong": 6, "guessOrder": [1575, 1604, 1578],
                 "hintKeys": [], "textHintUsed": false, "elapsed": 3.1 },
    "params":  { "language": "ar", "difficulty": "normal", "category": "all" },
    "session": { "score": 40, "streak": 1, "roundsPlayed": 1, "roundsWon": 1, "hintsUsed": 0,
                 "time": 95.2, "language": "ar", "difficulty": "normal", "category": "all",
                 "submitted": false },
    "savedAt": 1790946300
  }
}
```

### The `version` field

Every save has an integer `version` (the **format** version, not the game
version; the game version is stored in `gameVersion` for information only).
A file without a valid `version` is treated as damaged.

### Sections

Each top-level key is owned by one module with `load(data)`, `export()` and
`reset()`. Each module checks its own data: a missing or wrong value is
replaced by its default, so one bad value never spoils the rest. A section
that raises an error while loading is reset to defaults.

| Key | Module | Contents |
|---|---|---|
| `player` | `profile_manager` | Name (max 16 characters; control and bidi-override characters removed), creation time. An empty name shows the localized default ("Player" / "لاعب"). |
| `settings` | `core/settings` | Everything on the settings screen, plus the window size. Values are range-checked: unknown languages, volumes outside 0–1 and impossible window sizes fall back to defaults. |
| `stats` | `stats_manager` | Lifetime statistics. All counters are non-negative whole numbers (`playTime` is seconds). |
| `scores` | `score_manager` | High scores, best first, at most `Config.save.maxScores` (200). Invalid entries are dropped. |
| `progress` | `progress_manager` | Level/XP and unlocks (filled in by the progression phase), and the ids of recently played puzzles (so the same puzzle does not come straight back). |
| `suspended` | `save_manager` | The round in progress (for **Continue**), or absent. |

### Statistics

| Field | Meaning |
|---|---|
| `gamesPlayed` | Games (sessions) with at least one finished round |
| `roundsPlayed`, `roundsWon`, `roundsLost` | Finished rounds |
| `correctGuesses` | Different correct letters the player guessed |
| `wrongGuesses` | Wrong guesses |
| `arabicGames`, `englishGames` | Games by puzzle language |
| `bestScore` | Best score of a whole game (also shown in Scores) |
| `bestRoundScore`, `totalScore` | Best single round; sum of all round scores |
| `bestStreak`, `currentStreak` | Rounds won in a row, across games |
| `hintsUsed`, `perfectRounds` | Hints used; rounds won with no wrong guess and no hint |
| `playTime` | Seconds spent in finished rounds |

The win rate and accuracy shown on screen are calculated from these.

### Scores

A high-score entry is created when a **game** ends (not after each round):

- when the player leaves the results screen for the main menu,
- when a new game replaces an old one,
- when the application closes (unless a round is waiting to be continued).

A game with no points, or with no finished round, is not recorded. Entries are
ordered by score, then by time (earlier first).

### Suspended game

While a round is being played, its state is written to `suspended`
(after every guess and hint, when pausing, and when the game closes).
`guessOrder` lists the guessed letters (as Unicode code points, in order) and
`hintKeys` the ones revealed by hints; the round is rebuilt by replaying them.
It is removed when the round ends or a new game starts. When the player picks
**Continue** the saved `session` becomes the current game again.

A suspended game that refers to a puzzle that no longer exists (for example
after a content update) is discarded.

## Writing safely

`SaveManager.save()` never writes straight over the real file:

1. The new data is encoded, **decoded again** to prove it is valid, and written
   to `save.tmp`.
2. `save.tmp` is read back and compared with what was written.
3. The current `save.json` is copied to `save.bak` (only if it is itself valid).
4. `save.json` is written, then `save.tmp` is removed.

If a step fails (disk full, no permission), the old files are untouched, the
player is told once, and the write is retried a few seconds later. If step 4
fails, the verified `save.tmp` remains.

**When it saves**

- Immediately: a round finished, a game ended, the application closed, a
  name changed, leaving a round to the menu.
- A moment later (1 s after the last change, at most 5 s of waiting): settings
  changes, window resizing, and the round in progress. This keeps a slider
  being dragged from writing the file on every frame.

## Loading and damaged files

1. `save.json` is read. If it is missing it is treated as a first launch,
   unless a backup exists.
2. If it cannot be parsed, or has no valid `version`, it is copied to
   `save.corrupt-<time>.json` and `save.bak`, then `save.start.bak`, are tried.
3. If a backup is used, the player sees **"Your save file was damaged. Your
   progress was restored from a backup."** and the file is rewritten.
4. If nothing is usable, defaults are used, the damaged file is kept, and the
   player sees **"Your save file could not be read, so a new one was
   started."** The first-launch setup runs again.

The game never crashes because of a save file.

## Changing the format (migrations)

Old saves must keep working. To change the layout:

1. Increase `CURRENT_VERSION` in `save_manager.lua`.
2. Add a function that upgrades **from the previous version**:

   ```lua
   -- version 1 -> 2: scores get a "mode" field
   migrations[1] = function(data)
       for _, entry in ipairs(data.scores or {}) do
           entry.mode = "classic"
       end
       return data
   end
   ```

3. Update this document and add a test in `tests/save_tests.lua`.

On load, a save from version *n* is upgraded step by step
(`migrations[n]`, `migrations[n+1]`, ...) up to the current version; the
upgraded data is written at the next save. If a step is missing or fails, the
file counts as unusable and the backups are tried.

A save from a **newer** version of the game (it has a higher `version`) is
copied to `save.future.bak` and still read: values the game knows are used,
the rest is ignored. Run an older game version only on a copy of the save
folder if you want to keep the newer file intact.

## Tests

`luajit tests/save_tests.lua` (part of `tests/run_all.sh`) runs against an
in-memory filesystem (`tests/fake_love.lua`) and covers: JSON, round trips,
damaged and partly invalid files, backups, migration, failed writes, autosave
timing, statistics, high scores, the suspended game and game flow.
