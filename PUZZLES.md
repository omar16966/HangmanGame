# PUZZLES

How to add Arabic and English puzzles, categories, hints and difficulty.
Adding puzzles never requires changing game code.

## Where puzzles live

```text
data/puzzles/arabic/<category>.lua     Arabic puzzle packs
data/puzzles/english/<category>.lua    English puzzle packs
data/categories.lua                    the category list
```

Every `.lua` file in those folders is loaded at startup, in alphabetical
order. You can split puzzles across as many files as you like, for example
`animals.lua`, `animals_2.lua` or `my_pack.lua`. The folders are listed in
`Config.puzzles.folders`.

> These files are **trusted game content**: they are Lua code shipped with
> the game. Puzzles added by players are stored as data (JSON) and never run
> as code. That feature arrives in Phase 9.

## Pack format

```lua
return {
    language = "en",          -- "ar" or "en" (falls back to the folder name)
    category = "technology",  -- default category for the records below
    puzzles = {
        { id = "EN_TECH_001", answer = "PROGRAMMING", difficulty = "easy",
          hint = "Writing instructions for computers." },
        { id = "EN_TECH_002", answer = "VIDEO GAME", difficulty = "normal",
          hint = "An electronic game played on a screen.",
          category = "games" },   -- a record can override the pack category
    },
}
```

### Record fields

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Unique across **all** packs. Convention: `LANG_CATEGORY_NUMBER`, e.g. `AR_ANI_007`. Never reuse an id: saves and the recent-history list refer to puzzles by id. |
| `answer` | yes | A word or phrase. Spaces separate words. Extra spaces are cleaned up. |
| `difficulty` | no | `easy`, `normal` (default) or `hard` |
| `category` | no* | *Required if the pack has no `category`. Must be an id from `data/categories.lua`. |
| `hint` | no | A string, or a table with one string per interface language: `{ ar = "...", en = "..." }`. A plain string is shown as it is, whatever the interface language. |

### Answers: what is guessed and what is shown

- **English:** only the letters A–Z are guessed. Guesses ignore case
  (`a` = `A`), and the answer is shown as written.
- **Arabic:** Arabic letters are guessed.
  - Diacritics (harakat) and tatweel (ـ) may be in the answer, but they are
    ignored, never need guessing, and don't take up a cell.
  - With the default rules, أ إ آ are matched by ا. More matching rules are
    in `Config.normalization.arabic`: ى = ي, ة = ه, and ؤ / ئ treated as و / ي.
  - The original spelling is always the one displayed.
- **Spaces, digits, punctuation and hyphens** (`- ' ! ? 3`) are revealed from
  the start and never need to be guessed.
- An answer containing a letter the puzzle's keyboard can't type is rejected
  with a warning. Examples: an Arabic letter in an English puzzle, `é`, or
  Persian letters such as پ چ گ.

## Difficulty

The difficulty is a property of each puzzle. The player also chooses a
difficulty, and the game **prefers** puzzles that match it. If no puzzle in
the chosen category matches, it picks from all difficulties.

The player's difficulty also sets the rules (`Config.difficulty`):

| Difficulty | Wrong guesses allowed | Score multiplier |
|---|---|---|
| Easy | 8 | ×1.0 |
| Normal | 6 | ×1.5 |
| Hard | 5 | ×2.0 |

Suggested guidelines for each level:

- **Easy:** short, common words (3–5 letters) with a clear hint.
- **Normal:** longer words (6–8 letters) or common two-word phrases.
- **Hard:** long words, or phrases of two or more words, with a vaguer hint.

## Categories

`data/categories.lua`:

```lua
{ id = "animals", name = { ar = "الحيوانات", en = "Animals" }, unlockLevel = 1 },
```

- `id` is the name used in puzzle files.
- `name` is the display name in each interface language.
- `unlockLevel` sets the player level needed to play the category. Unlocking
  arrives in Phase 6; 1 means always open.

To add a category: add a line to this file, then create puzzle files that use
its id.

## Validation

At startup every record is checked. A bad record is skipped with a warning
in the log, and the game still starts. Records are rejected for:

- a missing or duplicate `id`
- a missing or empty `answer`
- an unknown `language` or `category`
- an invalid `difficulty`
- a hint that is neither a string nor a table
- an answer with no letters to guess, or with letters the keyboard can't type

The log shows how many puzzles were loaded, for example
`Loaded 144 puzzles (Arabic 72, English 72)`.

## Selection

`PuzzleManager.pick` chooses a random puzzle that matches the language and
category (and the unlocked categories). It prefers the chosen difficulty and
skips the last `Config.puzzles.recentHistorySize` (30) puzzles played. A puzzle
can only repeat once every other puzzle in the choice has been played.

## Testing a new pack

1. Start the game and check the log for `Puzzle ... skipped:` warnings.
2. In debug builds, press **F3**. The overlay shows the current puzzle's id,
   category, difficulty and answer.
3. `luajit tests/gameplay_tests.lua` runs the validation and selection tests.

## Current content

There are 12 categories with 6 starter puzzles each in both languages
(144 puzzles). More are added in Phase 9.
