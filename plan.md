# MASTER DEVELOPMENT PROMPT
## Professional Pixel-Art Hangman Game — LÖVE2D + Lua

You are a senior game developer specialized in:

- LÖVE2D
- Lua
- 2D pixel-art games
- Game architecture
- Localization
- Arabic RTL interfaces
- Shader programming
- UI/UX
- Save systems
- Game state machines
- Audio systems
- Performance optimization

Your task is to design and implement a complete, polished, professional **Hangman-style word puzzle game** using:

- **LÖVE2D**
- **Lua**
- Pixel-art visual style
- Internal resolution: **320×180**
- Target display resolutions up to **1920×1080**
- Arabic RTL user interface
- Arabic and English puzzle languages
- Local save/progression system
- Score system
- Audio and visual effects
- GPU shaders
- External assets stored inside `/assets`

The final project should be clean, modular, maintainable, expandable, and ready for adding final production assets.

---

# 1. CORE DEVELOPMENT RULES

Build the game as a real production-quality game project.

Do NOT create:

- one huge `main.lua`
- tightly coupled systems
- hard-coded puzzle lists inside gameplay code
- hard-coded screen coordinates scattered everywhere
- duplicated code
- temporary placeholder architecture that later requires rewriting

Instead, use:

- modular Lua files
- centralized configuration
- reusable UI components
- game states/scenes
- asset management
- localization manager
- save manager
- audio manager
- score manager
- puzzle manager
- shader manager
- input manager

The game must remain easy to expand.

---

# 2. TECHNOLOGY

Use:

```text
Engine: LÖVE2D
Language: Lua
Rendering: LÖVE Canvas
Base Resolution: 320x180
Default Aspect Ratio: 16:9
Maximum target: 1920x1080
Graphics Style: Pixel Art
UI Languages: Arabic / English
Puzzle Languages: Arabic / English
Save System: Local
Score System: Local
```

Use APIs compatible with a stable modern LÖVE2D release.

Avoid unnecessary external dependencies.

If a small library is genuinely useful, it may be included inside:

```text
/lib
```

But every third-party dependency must be clearly documented.

---

# 3. PROJECT STRUCTURE

Use a clean architecture similar to:

```text
project/
│
├── main.lua
├── conf.lua
│
├── assets/
│   ├── fonts/
│   ├── images/
│   ├── sprites/
│   ├── backgrounds/
│   ├── ui/
│   ├── icons/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── shaders/
│   └── particles/
│
├── src/
│   ├── core/
│   │   ├── constants.lua
│   │   ├── config.lua
│   │   ├── game.lua
│   │   ├── input.lua
│   │   ├── camera.lua
│   │   └── utils.lua
│   │
│   ├── managers/
│   │   ├── asset_manager.lua
│   │   ├── audio_manager.lua
│   │   ├── save_manager.lua
│   │   ├── score_manager.lua
│   │   ├── localization_manager.lua
│   │   ├── puzzle_manager.lua
│   │   └── shader_manager.lua
│   │
│   ├── states/
│   │   ├── boot_state.lua
│   │   ├── main_menu_state.lua
│   │   ├── language_state.lua
│   │   ├── category_state.lua
│   │   ├── gameplay_state.lua
│   │   ├── pause_state.lua
│   │   ├── result_state.lua
│   │   ├── scores_state.lua
│   │   ├── statistics_state.lua
│   │   ├── settings_state.lua
│   │   ├── help_state.lua
│   │   └── credits_state.lua
│   │
│   ├── gameplay/
│   │   ├── round.lua
│   │   ├── word_display.lua
│   │   ├── keyboard.lua
│   │   ├── attempts.lua
│   │   └── scoring.lua
│   │
│   ├── ui/
│   │   ├── ui_manager.lua
│   │   ├── button.lua
│   │   ├── panel.lua
│   │   ├── label.lua
│   │   ├── modal.lua
│   │   ├── progress_bar.lua
│   │   ├── tooltip.lua
│   │   └── virtual_keyboard.lua
│   │
│   ├── graphics/
│   │   ├── renderer.lua
│   │   ├── particles.lua
│   │   ├── transitions.lua
│   │   └── screen_effects.lua
│   │
│   └── localization/
│       ├── arabic.lua
│       ├── english.lua
│       ├── arabic_shaper.lua
│       └── bidi.lua
│
├── data/
│   ├── puzzles/
│   │   ├── arabic/
│   │   └── english/
│   ├── categories.lua
│   └── localization/
│
├── lib/
│
├── saves/
│
└── README.md
```

The exact structure may be improved if necessary, but maintain clear separation of responsibility.

---

# 4. PIXEL-PERFECT RENDERING

The game's logical/internal resolution must always be:

```text
320 × 180
```

Create a main internal canvas:

```lua
love.graphics.newCanvas(320, 180)
```

Render the entire game to this canvas.

Then scale the canvas to the actual window.

At:

```text
1920 × 1080
```

the scale should be:

```text
6×
```

because:

```text
320 × 6 = 1920
180 × 6 = 1080
```

Prefer integer scaling whenever possible.

Prevent:

- blurry pixel art
- fractional sprite positioning
- texture filtering artifacts
- uneven pixels

Use:

```lua
love.graphics.setDefaultFilter("nearest", "nearest")
```

Pixel-art objects should normally be drawn at integer coordinates.

---

# 5. WINDOW SCALING

Support:

```text
320x180
640x360
960x540
1280x720
1600x900
1920x1080
```

Also support arbitrary window sizes.

For non-perfect aspect ratios:

- preserve 16:9
- maintain integer scaling where possible
- center the game canvas
- use letterboxing/pillarboxing
- never stretch the game

Fullscreen must be supported.

---

# 6. ARABIC SUPPORT

Arabic support is a critical requirement.

The UI must support:

```text
Arabic RTL
English LTR
```

Arabic must NOT be implemented by simply reversing strings.

Arabic requires:

- correct Unicode handling
- correct right-to-left ordering
- Arabic letter shaping
- correct connected glyph forms
- proper handling of punctuation
- proper handling of numbers
- mixed Arabic/English strings when required

Create a dedicated text rendering/localization layer.

Example:

```lua
Localization.drawText(...)
```

The rest of the game should not manually handle RTL logic.

---

# 7. ARABIC FONT

The font must:

- support Arabic Unicode glyphs
- remain readable at low pixel-art resolutions
- work correctly at 320×180
- support Arabic shaping

Fonts will be placed under:

```text
assets/fonts/
```

Do not assume every font supports Arabic.

Create graceful fallback behavior when a font is missing.

---

# 8. UI LANGUAGE VS PUZZLE LANGUAGE

Treat these as two independent settings.

Example:

```text
Interface Language:
Arabic

Puzzle Language:
English
```

or:

```text
Interface Language:
Arabic

Puzzle Language:
Arabic
```

or:

```text
Interface Language:
English

Puzzle Language:
Arabic
```

The player must be able to choose both.

---

# 9. LANGUAGE SETTINGS

Store:

```lua
settings = {
    interfaceLanguage = "ar",
    puzzleLanguage = "ar"
}
```

Supported interface values:

```text
ar
en
```

Supported puzzle values:

```text
ar
en
```

Changing the interface language should update the UI immediately when practical.

---

# 10. ARABIC RTL LAYOUT

When UI language is Arabic:

- menu alignment should become RTL
- titles align appropriately
- labels align appropriately
- icon/text arrangement should be mirrored when necessary
- back/forward arrows should respect directionality
- lists should behave naturally in RTL
- panels should preserve good composition

Do NOT blindly mirror every graphic.

Decorative artwork normally stays unchanged.

Only directional UI elements should be mirrored where appropriate.

---

# 11. LOCALIZATION SYSTEM

Never scatter UI strings throughout code.

Create localization dictionaries.

Example:

```lua
local ar = {
    PLAY = "ابدأ اللعب",
    CONTINUE = "متابعة",
    SCORES = "النتائج",
    STATISTICS = "الإحصائيات",
    SETTINGS = "الإعدادات",
    EXIT = "خروج"
}
```

English example:

```lua
local en = {
    PLAY = "Play",
    CONTINUE = "Continue",
    SCORES = "Scores",
    STATISTICS = "Statistics",
    SETTINGS = "Settings",
    EXIT = "Exit"
}
```

Usage:

```lua
L("PLAY")
```

Never:

```lua
drawText("ابدأ اللعب")
```

inside random gameplay files.

---

# 12. GAMEPLAY CONCEPT

The game follows the classic Hangman word puzzle concept.

A hidden word or phrase is selected.

Example:

```text
PROGRAMMING
```

Initially:

```text
_ _ _ _ _ _ _ _ _ _ _
```

Correct guesses reveal characters.

Wrong guesses increase the failure/attempt stage.

Avoid graphic or disturbing imagery.

Represent the traditional Hangman stages with stylized, non-graphic pixel-art progression.

The visual presentation may use:

- silhouette
- abstract character
- wooden board
- puzzle meter
- rope/structure-inspired iconography
- progressive scene elements

Keep it suitable for a general audience.

---

# 13. ROUND FLOW

A typical round:

```text
Select puzzle
↓
Display category
↓
Display hidden letters
↓
Player selects letter
↓
Check letter
↓
Correct?
├── Yes → reveal matching letters
└── No → increase wrong-attempt counter
↓
Check victory
↓
Check round failure
↓
Calculate score
↓
Save statistics
↓
Result screen
↓
Next puzzle
```

---

# 14. PUZZLE TYPES

Support:

### Single Word

Example:

```text
COMPUTER
```

### Multi-word Phrase

Example:

```text
VIDEO GAME
```

Arabic example:

```text
الذكاء الاصطناعي
```

Spaces should automatically appear.

Non-letter punctuation should normally appear automatically.

---

# 15. ARABIC PUZZLES

Arabic puzzles must correctly handle:

```text
ا
ب
ت
ث
ج
ح
خ
...
```

Take normalization into account.

Design a normalization layer for puzzle comparison.

Possible configurable normalization rules:

```text
أ / إ / آ → ا
ى → ي
ة → ه or preserve depending on puzzle mode
```

However:

Do NOT automatically destroy linguistic correctness.

Make normalization rules configurable.

Recommended default:

Normalize:

```text
أ
إ
آ
```

to:

```text
ا
```

for input matching while preserving the original word for display.

---

# 16. DIACRITICS

Arabic diacritics should not normally be required to solve a puzzle.

Examples:

```text
َ
ُ
ِ
ّ
ْ
```

Normalize/remove optional Arabic diacritics during comparison.

Store and display the original phrase when appropriate.

---

# 17. ARABIC KEYBOARD

Create a virtual Arabic keyboard.

Possible layout:

```text
ض ص ث ق ف غ ع ه خ ح ج د
ش س ي ب ل ا ت ن م ك ط
ئ ء ؤ ر لا ى ة و ز ظ
```

The exact visual arrangement may be adjusted for the 320×180 interface.

Buttons must remain readable and accessible.

---

# 18. ENGLISH KEYBOARD

Support:

```text
A-Z
```

Create a responsive compact virtual keyboard.

Possible layout:

```text
Q W E R T Y U I O P
A S D F G H J K L
Z X C V B N M
```

---

# 19. PHYSICAL KEYBOARD SUPPORT

English puzzles:

```text
A-Z
```

Arabic puzzles:

support Arabic keyboard Unicode input where possible.

Use:

```lua
love.textinput
```

where appropriate.

Avoid depending only on:

```lua
love.keypressed
```

for international text.

---

# 20. INPUT METHODS

Support:

- Keyboard
- Mouse

Architecture should also allow future gamepad support.

Input management must be centralized.

Example actions:

```text
CONFIRM
BACK
LEFT
RIGHT
UP
DOWN
PAUSE
```

Do not hard-code input logic throughout UI code.

---

# 21. PUZZLE DATABASE

Puzzles must be external data.

Never hard-code puzzle lists in gameplay logic.

Example structure:

```text
data/puzzles/arabic/general.lua
data/puzzles/arabic/technology.lua
data/puzzles/arabic/animals.lua

data/puzzles/english/general.lua
data/puzzles/english/technology.lua
data/puzzles/english/animals.lua
```

Example record:

```lua
{
    id = "AR_TECH_001",
    answer = "برمجة",
    category = "technology",
    difficulty = "easy",
    hint = "عملية كتابة تعليمات للحاسوب"
}
```

English:

```lua
{
    id = "EN_TECH_001",
    answer = "PROGRAMMING",
    category = "technology",
    difficulty = "easy",
    hint = "Writing instructions for computers."
}
```

---

# 22. CATEGORIES

Create support for categories.

Examples:

```text
General
Technology
Science
Animals
Countries
Cities
History
Games
Sports
Movies
Food
Nature
```

Arabic translations should exist.

Categories must be data-driven.

---

# 23. DIFFICULTY SYSTEM

Support:

```text
Easy
Normal
Hard
```

Possible factors:

### Easy

- shorter words
- more attempts
- easier hints
- lower score multiplier

### Normal

- medium words
- standard attempts

### Hard

- longer phrases
- fewer attempts
- stronger score multiplier

Make these values configurable.

---

# 24. ATTEMPTS

Suggested base:

```text
6 wrong guesses
```

Do not hard-code this everywhere.

Use:

```lua
Config.gameplay.maxWrongAttempts
```

---

# 25. HINT SYSTEM

Support hints.

Possible hint types:

### Text Hint

Display the puzzle hint.

### Reveal Letter

Reveal one unrevealed letter.

Hints should cost score points.

Example:

```text
Text hint:
-50 points

Reveal letter:
-100 points
```

These values must be configurable.

---

# 26. SCORING SYSTEM

Create a meaningful scoring system.

Possible components:

```text
Base round score
+ correct guesses
+ unused attempts bonus
+ difficulty multiplier
+ speed bonus
- hint penalties
- incorrect guess penalties
```

Example conceptual formula:

```text
score =
baseScore
+ accuracyBonus
+ remainingAttemptsBonus
+ speedBonus
- hintPenalty
```

Then:

```text
score *= difficultyMultiplier
```

Do not allow negative round scores unless explicitly intended.

---

# 27. SCORE VALUES

Keep scoring values in configuration.

Example:

```lua
Config.score = {
    correctLetter = 10,
    completePuzzle = 100,
    remainingAttemptBonus = 20,
    wrongGuessPenalty = 5,
    textHintPenalty = 50,
    revealHintPenalty = 100
}
```

---

# 28. HIGH SCORES

Create a local high-score system.

Store at least:

```text
Player Name
Score
Puzzle Language
Difficulty
Date
Total Rounds
Correct Puzzles
```

Display:

```text
Top Scores
```

Optionally filter by:

```text
Arabic
English
Difficulty
```

---

# 29. PLAYER PROFILE

Allow a simple local player profile.

Example:

```text
Player Name
Total Score
Current Level
XP
Games Played
Games Won
Best Score
Current Streak
Best Streak
```

No online account is required.

---

# 30. PROGRESSION SYSTEM

Implement lightweight progression.

Example:

```text
XP
Level
Unlocked categories
Achievements
```

The architecture must support adding more progression later.

Do not make progression mandatory for basic gameplay.

---

# 31. LEVEL SYSTEM

Example:

```text
Level 1
Level 2
Level 3
...
```

XP can come from:

```text
Winning rounds
Difficulty bonuses
Perfect rounds
Streaks
Achievements
```

Store XP and level in the save file.

---

# 32. STATISTICS

Track:

```text
Games Played
Rounds Played
Rounds Won
Rounds Lost
Win Rate
Correct Guesses
Wrong Guesses
Accuracy
Arabic Games
English Games
Best Score
Total Score
Best Streak
Current Streak
Hints Used
Play Time
```

---

# 33. SAVE SYSTEM

Automatically save:

```text
Player profile
Progression
Scores
Statistics
Settings
Unlocked content
Current game if applicable
```

Use:

```lua
love.filesystem
```

Do not write directly into the game installation folder.

---

# 34. SAVE FILE DESIGN

Possible:

```text
save.lua
```

or:

```text
save.json
```

If JSON is used, include a lightweight JSON library locally.

Save format must include:

```text
version
```

Example:

```lua
{
    version = 1,
    player = {},
    settings = {},
    stats = {},
    scores = {},
    progress = {}
}
```

---

# 35. SAVE MIGRATION

Prepare the save architecture for future versions.

Example:

```lua
if save.version == 1 then
    migrateV1ToV2()
end
```

Do not assume save structures will never change.

---

# 36. SAVE SAFETY

Prevent corrupted saves from destroying player progress.

Use:

```text
validation
defaults
safe loading
backup strategy
```

If a save cannot be loaded:

- preserve the corrupted file if possible
- recover defaults
- avoid crashing

---

# 37. AUTOSAVE

Autosave after:

```text
Completing a puzzle
Changing settings
Unlocking progression
Updating major statistics
Exiting a session
```

Do not save unnecessarily every frame.

---

# 38. GAME STATES

Use a proper state/scene manager.

Required states:

```text
Boot
Main Menu
Language Selection
Category Selection
Gameplay
Pause
Result
High Scores
Statistics
Settings
Help
Credits
```

Each state should contain:

```lua
enter()
exit()
update(dt)
draw()
keypressed(...)
textinput(...)
mousepressed(...)
```

as appropriate.

---

# 39. MAIN MENU

Arabic example:

```text
الرجل المشنوق

ابدأ اللعب
متابعة
النتائج
الإحصائيات
الإعدادات
طريقة اللعب
خروج
```

English:

```text
HANGMAN

PLAY
CONTINUE
SCORES
STATISTICS
SETTINGS
HOW TO PLAY
EXIT
```

---

# 40. GAMEPLAY SCREEN

Design for 320×180.

Suggested layout:

```text
┌─────────────────────────────────────┐
│ Score                     Category  │
│                                     │
│            Scene                    │
│                                     │
│          _ _ _ _ _ _                │
│                                     │
│             Hint                    │
│                                     │
│       Virtual Keyboard              │
│                                     │
│ Attempts                       Menu │
└─────────────────────────────────────┘
```

For Arabic RTL, adapt composition appropriately.

---

# 41. RESPONSIVE UI

All UI must be authored relative to:

```text
320×180
```

Never design UI directly for 1920×1080.

Scaling occurs at the renderer level.

---

# 42. UI COMPONENTS

Build reusable UI components:

```text
Button
Icon Button
Label
Panel
Modal
Progress Bar
Toggle
Slider
Selector
Tabs
Tooltip
Virtual Keyboard Key
```

Buttons should support states:

```text
normal
hover
pressed
disabled
focused
```

---

# 43. PIXEL ART UI

Use pixel-art appropriate:

- borders
- panels
- shadows
- icons
- buttons
- background decoration

Avoid modern blurry vector-style UI unless intentionally pixelated.

---

# 44. UI ANIMATION

Use subtle animation.

Examples:

```text
Button hover offset
Button press animation
Panel slide
Menu fade
Letter reveal
Score popup
Incorrect guess shake
Correct guess bounce
Result screen entrance
```

Animations must feel responsive.

Do not over-animate every element.

---

# 45. TWEENING

Create a lightweight tweening system or include a small reliable Lua tween library.

Use for:

```text
position
scale
alpha
rotation
UI transitions
```

Respect pixel positioning where required.

---

# 46. SCREEN TRANSITIONS

Support transitions such as:

```text
Fade
Pixel dissolve
Slide
Iris
```

A default fade transition is sufficient initially.

Transition implementation must be reusable.

---

# 47. PARTICLE EFFECTS

Create lightweight particle effects.

Examples:

Correct answer:

```text
pixel sparkles
small stars
confetti
```

Wrong guess:

```text
small dust effect
brief particles
```

Level up:

```text
stronger celebration particles
```

Particles must remain appropriate for pixel art.

---

# 48. SHADER SYSTEM

Create a shader manager.

Shaders must be optional and configurable.

Possible shaders:

```text
CRT
Vignette
Color grading
Palette shift
Noise
Scanlines
Glow
Chromatic aberration
Pixel distortion
Transition shader
```

Use subtle values.

The game must remain visually clean.

---

# 49. DEFAULT SHADER STACK

Recommended subtle combination:

```text
Very light vignette
Very subtle CRT scanlines
Very subtle noise
Optional color grading
```

Do NOT destroy pixel clarity.

Avoid excessive blur.

---

# 50. SHADER SETTINGS

Settings menu:

```text
Shaders: On / Off
CRT Effect: On / Off
Scanlines: On / Off
Screen Shake: On / Off
Particles: On / Off
```

Allow weaker systems to disable expensive effects.

---

# 51. SCREEN SHAKE

Create reusable screen shake.

Use very subtle shake for:

```text
important incorrect guess
round completion
special event
```

Never make normal interaction uncomfortable.

Provide setting:

```text
Screen Shake:
On / Off
```

---

# 52. BACKGROUND

Support animated pixel-art backgrounds.

Examples:

```text
night room
old study
wooden puzzle room
mysterious chamber
retro arcade room
```

Background should contain subtle movement.

Examples:

```text
moving dust
flickering candle
floating particles
small light changes
```

Do not distract from the puzzle.

---

# 53. AUDIO SYSTEM

Support:

```text
Background Music
UI Sounds
Gameplay Sounds
Ambient Sounds
```

Centralize audio through:

```lua
AudioManager
```

---

# 54. SOUND EFFECTS

Prepare named sound events:

```text
ui_hover
ui_click
ui_back
letter_correct
letter_wrong
hint
round_win
round_loss
score_count
level_up
achievement
pause
resume
```

Missing audio assets must not crash the game.

---

# 55. MUSIC

Support looping background music.

Possible tracks:

```text
menu
gameplay
results
```

Add smooth music transitions where practical.

---

# 56. AUDIO SETTINGS

Settings:

```text
Master Volume
Music Volume
Sound Volume
Mute
```

Save settings.

---

# 57. ASSET MANAGEMENT

All game assets will be placed inside:

```text
/assets
```

The developer/user will provide production assets.

Do not assume filenames unless documented.

Create centralized asset definitions.

Example:

```lua
Assets.images.backgroundMenu
Assets.images.keyboardPanel
Assets.audio.correct
Assets.fonts.default
```

---

# 58. MISSING ASSETS

During development, missing assets should:

- produce a clear warning
- use a safe fallback where possible
- not crash unrelated game systems

For images, temporary fallback rectangles may be used.

For sound, simply skip playback.

For fonts, use safe fallback behavior.

---

# 59. ASSET DOCUMENTATION

Create:

```text
ASSETS.md
```

List every expected asset.

Example:

```text
assets/
├── backgrounds/
│   ├── menu.png
│   └── gameplay.png
│
├── sprites/
│   ├── stage_01.png
│   ├── stage_02.png
│   └── ...
```

Include:

```text
recommended dimensions
animation frames
expected format
purpose
```

This is important because the user will provide assets later.

---

# 60. SPRITE ANIMATION

Create a reusable sprite animation system.

Support:

```text
sprite sheets
frame duration
looping
one-shot animations
callbacks
```

Example states:

```text
idle
react_correct
react_wrong
win
loss
```

---

# 61. SETTINGS

Include:

```text
Interface Language
Puzzle Language
Difficulty
Master Volume
Music Volume
SFX Volume
Fullscreen
Shaders
CRT
Screen Shake
Particles
```

Save all settings.

---

# 62. PAUSE MENU

Pause menu:

Arabic:

```text
متابعة
إعادة الجولة
الإعدادات
القائمة الرئيسية
```

English:

```text
Resume
Restart Round
Settings
Main Menu
```

Require confirmation before abandoning active progress when appropriate.

---

# 63. RESULTS SCREEN

After each puzzle show:

```text
Correct / Incorrect
Answer
Score
Accuracy
Wrong Guesses
Time
Bonus
XP
Streak
```

Arabic translation required.

Allow:

```text
Next Puzzle
Replay
Main Menu
```

---

# 64. SCORE COUNT ANIMATION

Animate score increases instead of instantly replacing the number.

Example:

```text
850
→
860
→
870
→
...
→
1250
```

Use fast but readable counting animation.

---

# 65. ACHIEVEMENTS

Prepare optional local achievements.

Examples:

```text
First Victory
10 Correct Puzzles
Perfect Round
10-Round Streak
Arabic Expert
English Expert
100 Puzzles
No Hint Victory
```

Achievements should be data-driven.

---

# 66. DUPLICATE PUZZLES

Puzzle manager should remember recently used puzzle IDs.

Avoid showing the same puzzle repeatedly.

Implement:

```text
recentPuzzleHistory
```

When enough puzzles exist, rotate intelligently.

---

# 67. RANDOMIZATION

Use randomness responsibly.

Do not select puzzles completely blindly.

Selection can consider:

```text
Language
Category
Difficulty
Recent history
Unlocked content
```

---

# 68. SESSION SYSTEM

Track per-session information:

```text
Session Score
Current Streak
Rounds Played
Rounds Won
Hints Used
Session Time
```

Separate session data from lifetime statistics.

---

# 69. ERROR HANDLING

The game must not crash because of:

```text
missing sound
missing optional shader
invalid puzzle record
corrupted statistics
unknown localization key
missing optional image
```

Provide clear debug warnings.

---

# 70. DEBUG MODE

Provide configurable development mode:

```lua
Config.debug = true
```

When active, allow optional display of:

```text
FPS
Memory usage
Current state
Canvas size
Scale factor
Mouse coordinates
Selected puzzle ID
Wrong guesses
Shader status
```

Never display debug information in normal production mode.

---

# 71. LOGGING

Create simple logging:

```text
INFO
WARNING
ERROR
DEBUG
```

Example:

```lua
Logger.info("Loaded 240 Arabic puzzles")
Logger.warning("Missing sound: ui_hover")
```

Avoid excessive output every frame.

---

# 72. PERFORMANCE

Target stable performance on modest hardware.

Avoid:

```text
allocating large tables every frame
loading assets repeatedly
recompiling shaders every frame
creating fonts repeatedly
creating canvases repeatedly
```

Assets must normally load once.

---

# 73. MEMORY MANAGEMENT

Unload large optional resources when appropriate.

However, prioritize simplicity for this small game.

Do not prematurely optimize.

---

# 74. CODE QUALITY

Use consistent naming.

Example:

```text
camelCase
```

for functions and local variables.

Example:

```lua
loadPuzzle()
calculateScore()
currentPuzzle
wrongGuesses
```

Modules:

```text
PascalCase
```

when appropriate.

---

# 75. CONFIGURATION

Centralize tunable values.

Example:

```lua
Config = {
    virtualWidth = 320,
    virtualHeight = 180,

    gameplay = {
        maxWrongAttempts = 6
    },

    graphics = {
        pixelPerfect = true,
        shaders = true
    }
}
```

---

# 76. CONSTANTS

Avoid magic numbers.

Instead of:

```lua
if wrong == 6 then
```

use:

```lua
if wrong >= Config.gameplay.maxWrongAttempts then
```

---

# 77. GAME LOOP

Keep `main.lua` minimal.

Example responsibility:

```lua
love.load()
love.update(dt)
love.draw()
love.keypressed()
love.textinput()
love.mousepressed()
love.resize()
```

Delegate behavior to game systems.

---

# 78. RENDERER

Create a renderer responsible for:

```text
virtual canvas
scaling
letterboxing
pixel-perfect drawing
shader chain
fullscreen changes
window resize
screen shake
```

Gameplay states should not calculate display scaling themselves.

---

# 79. MOUSE COORDINATE CONVERSION

Mouse positions must convert from real window coordinates to virtual:

```text
320×180
```

Create:

```lua
Renderer.screenToVirtual(x, y)
```

Return:

```text
virtualX
virtualY
```

Handle letterboxing correctly.

---

# 80. TEXT RENDERING

Create a unified text API.

Example:

```lua
Text.draw(key, x, y, options)
```

or:

```lua
Localization.draw(key, x, y, options)
```

Options may support:

```text
alignment
direction
font
scale
color
maximum width
```

Arabic/English direction should be automatic.

---

# 81. TEXT MIXING

Support UI strings containing both Arabic and English.

Example:

```text
لغة الألغاز: English
```

Mixed-direction text must remain readable.

---

# 82. LONG TRANSLATIONS

Never assume translated text has the same width.

UI components should support:

```text
dynamic width
wrapping
smaller fallback font
scrolling if absolutely necessary
```

Avoid cutting Arabic text.

---

# 83. ACCESSIBILITY

Provide options when practical:

```text
Disable screen shake
Disable shaders
Adjust audio
Strong UI contrast
Keyboard navigation
```

Do not communicate correctness using color alone.

Use:

```text
icons
animation
text
shape
```

in addition to colors.

---

# 84. COLOR PALETTE

Keep palette configuration centralized.

Example:

```lua
Palette.background
Palette.panel
Palette.primary
Palette.secondary
Palette.text
Palette.correct
Palette.incorrect
Palette.highlight
```

This will allow the user to later replace the visual style.

---

# 85. CURSOR

Optional custom pixel-art cursor may be supported.

If no cursor asset exists, use the operating system cursor.

---

# 86. BOOT SCREEN

On startup:

```text
Initialize engine
Load config
Load save
Load settings
Load fonts
Load essential assets
Initialize renderer
Initialize localization
Go to main menu
```

An optional short logo/splash may be added later.

---

# 87. FIRST LAUNCH

If no save exists:

Show initial language setup:

```text
اختر لغة الواجهة
Choose Interface Language
```

Then:

```text
Arabic
English
```

Then puzzle-language choice.

Save choices.

---

# 88. CONTINUE SYSTEM

If a valid suspended game exists:

Enable:

```text
Continue
```

Otherwise disable/hide it.

When continuing, restore:

```text
Puzzle
Revealed letters
Wrong guesses
Score
Hints
Elapsed time
Session data
```

---

# 89. EXIT HANDLING

Before application exit:

```text
save profile
save statistics
save settings
save suspended game if appropriate
```

Use:

```lua
love.quit()
```

responsibly.

---

# 90. TESTING REQUIREMENTS

Test at:

```text
320×180
640×360
1280×720
1920×1080
```

Test:

```text
Arabic interface + Arabic puzzle
Arabic interface + English puzzle
English interface + Arabic puzzle
English interface + English puzzle
```

Also test:

```text
Window resize
Fullscreen
Mouse
Keyboard
Arabic text input
English text input
Save/reload
Corrupted save
Missing optional asset
Missing sound
Shader disabled
Shader enabled
```

---

# 91. GAMEPLAY EDGE CASES

Handle:

```text
Repeated guesses
Uppercase/lowercase English
Arabic normalized characters
Spaces
Punctuation
Hyphens
Multiple-word phrases
Numbers
Duplicate letters
Very long words
Missing hints
Empty puzzle lists
Invalid puzzle entries
```

Repeated guesses should not create extra penalties.

---

# 92. ENGLISH NORMALIZATION

English puzzle input should be case-insensitive.

Example:

```text
a == A
```

Internally normalize to uppercase or lowercase consistently.

Display original formatting if desired.

---

# 93. CONTENT VALIDATION

When puzzles load, validate:

```text
ID exists
answer exists
language valid
category valid
difficulty valid
duplicate IDs
```

Invalid entries should generate warnings.

---

# 94. PUZZLE IMPORT FRIENDLINESS

Design puzzle files so I can easily add hundreds or thousands of puzzles later.

Adding a puzzle should not require editing game logic.

---

# 95. README

Create a complete:

```text
README.md
```

Explain:

```text
Requirements
LÖVE2D version
How to run
Project structure
How to add assets
How to add puzzles
How localization works
How saves work
How scoring works
How shaders work
How to build/release
```

---

# 96. ASSETS.md

Create:

```text
ASSETS.md
```

This document is mandatory.

It should specify every art/audio asset I need to provide.

For each asset include:

```text
Filename
Folder
Recommended resolution
Animation frame dimensions
Purpose
Required / Optional
```

---

# 97. PUZZLES.md

Create:

```text
PUZZLES.md
```

Explain how to create:

```text
Arabic puzzles
English puzzles
Categories
Hints
Difficulty
Unique IDs
```

---

# 98. LOCALIZATION.md

Create:

```text
LOCALIZATION.md
```

Explain:

```text
Arabic RTL system
Arabic shaping
Bidi handling
Adding UI translations
Adding another language
Puzzle normalization
```

---

# 99. SAVE_FORMAT.md

Create:

```text
SAVE_FORMAT.md
```

Document:

```text
save schema
version field
migration approach
player stats
scores
progression
settings
suspended game
```

---

# 100. VISUAL QUALITY TARGET

The final game should feel like a small professional indie pixel-art game.

It should not feel like:

```text
a programming tutorial
a classroom example
a basic prototype
```

Visual quality should come from:

```text
good composition
animation
pixel-art UI
subtle shader effects
particles
transitions
audio feedback
responsive controls
consistent palette
```

---

# 101. DESIGN PRINCIPLE

Follow this rule:

```text
Polish through layering.
```

A normal interaction such as a correct answer may trigger:

```text
sound
+ small animation
+ letter reveal
+ tiny particle effect
+ score popup
```

But effects must remain subtle.

---

# 102. OPTIONAL ATMOSPHERIC EFFECTS

Prepare optional systems for:

```text
floating dust
light flicker
background parallax
subtle noise
ambient particles
occasional decorative animations
```

All must be inexpensive.

---

# 103. PIXEL PERFECT RULE

Never destroy pixel art using:

```text
linear filtering
non-integer sprite scaling
unnecessary rotations
blurred postprocessing
```

When a shader intentionally changes the image, preserve the visual identity of the pixel artwork.

---

# 104. GAME TITLE

Keep the game title configurable.

Example:

Arabic:

```text
الرجل المشنوق
```

English:

```text
Hangman
```

Do not embed the title permanently into source code or artwork assumptions.

---

# 105. CONFIGURABLE GAME IDENTITY

Create configuration for:

```text
Game title
Version
Developer name
Copyright
Website
```

Example:

```lua
Config.app = {
    name = "Hangman",
    version = "0.1.0",
    developer = ""
}
```

---

# 106. DEVELOPMENT PHASES

Do not attempt to build everything without checkpoints.

Implement in phases.

## Phase 1 — Foundation

Implement:

```text
Project architecture
Renderer
320×180 canvas
Integer scaling
State manager
Input manager
Asset manager
Configuration
Logging
```

Verify before continuing.

---

## Phase 2 — Localization

Implement:

```text
Arabic font
Arabic shaping
RTL/Bidi system
English support
Localization dictionary
Language switching
```

Test real Arabic text.

Do not continue until Arabic renders correctly.

---

## Phase 3 — Core Gameplay

Implement:

```text
Puzzle manager
Word display
Guess handling
Attempts
Win/loss conditions
Arabic normalization
English normalization
Virtual keyboard
```

---

## Phase 4 — Main UI

Implement:

```text
Main Menu
Language Selection
Category Selection
Gameplay Screen
Pause
Results
Settings
```

---

## Phase 5 — Persistence

Implement:

```text
Save system
Profiles
Statistics
Scores
Continue
Settings persistence
Save versioning
```

---

## Phase 6 — Progression

Implement:

```text
XP
Levels
Streaks
Achievements
Unlock architecture
```

---

## Phase 7 — Polish

Implement:

```text
Animations
Transitions
Particles
Screen shake
Sound effects
Music
Score animations
UI feedback
```

---

## Phase 8 — Shaders

Implement:

```text
Shader manager
Vignette
CRT
Scanlines
Noise
Optional palette/color grading
```

Test on/off behavior.

---

## Phase 9 — Content

Add:

```text
Arabic puzzle packs
English puzzle packs
Categories
Hints
Difficulty balancing
```

---

## Phase 10 — QA

Perform complete testing.

Check:

```text
Arabic
English
RTL
LTR
Scaling
Saves
Scores
Input
Shaders
Audio
Performance
Edge cases
```

---

# 107. DEVELOPMENT CHECKPOINT RULE

At the end of every phase:

1. Run the game.
2. Check for Lua errors.
3. Check console warnings.
4. Test implemented functionality.
5. Fix errors.
6. Clean/refactor code.
7. Verify no previously completed feature broke.
8. Only then continue.

Do NOT leave known errors for later phases.

---

# 108. PLACEHOLDER ASSETS

Because I will place final game assets inside:

```text
/assets
```

you may initially create temporary placeholders.

However:

- placeholders must be clearly isolated
- game logic must not depend on placeholder dimensions unnecessarily
- replacing placeholders later should require minimal or zero code changes

---

# 109. DO NOT GENERATE UNNECESSARY BINARY ASSETS

Focus primarily on:

```text
code
data
shader source
configuration
documentation
```

For artwork/audio, specify what is needed inside `ASSETS.md`.

I will provide the real assets.

---

# 110. SHADER SOURCE

Shader code should exist as external files when practical.

Example:

```text
assets/shaders/vignette.glsl
assets/shaders/crt.glsl
assets/shaders/noise.glsl
assets/shaders/transition.glsl
```

ShaderManager loads and manages them.

---

# 111. FALLBACK RENDERING

If shaders fail:

The game must continue rendering normally.

Example logic:

```text
Shader available?
    Yes → use shader
    No → normal rendering
```

---

# 112. NO INTERNET REQUIREMENT

The base game must run completely offline.

No network connection should be necessary for:

```text
Gameplay
Saving
Scores
Settings
Puzzle loading
Progression
```

Online services may be introduced only in a future version.

---

# 113. SECURITY / DATA SAFETY

Do not execute arbitrary Lua code from user-generated puzzle files.

If Lua tables are used for trusted bundled puzzle data, document that they are trusted game content.

For future user-generated content, prefer a safer structured format such as JSON.

---

# 114. FUTURE EXPANSION

The architecture should make future additions possible:

```text
Daily Challenge
Online Leaderboards
Steam achievements
More languages
Custom themes
Custom puzzle packs
User-generated puzzles
Gamepad support
Mobile adaptation
Additional shader presets
Challenge modes
Timed mode
Endless mode
```

Do not implement these unless required.

Just avoid architectures that make them difficult later.

---

# 115. FINAL REQUIRED DELIVERABLE

At the completion of development, the project must contain a working game plus:

```text
README.md
ASSETS.md
PUZZLES.md
LOCALIZATION.md
SAVE_FORMAT.md
```

And organized source code.

The game must successfully:

1. Start.
2. Display correctly at 320×180.
3. Scale cleanly to 1920×1080.
4. Display Arabic UI correctly.
5. Display English UI correctly.
6. Support Arabic puzzles.
7. Support English puzzles.
8. Accept guesses.
9. Determine wins/losses.
10. Calculate scores.
11. Save progress.
12. Load progress.
13. Store high scores.
14. Track statistics.
15. Play audio safely.
16. Render optional shader effects.
17. Handle fullscreen/window mode.
18. Survive missing optional assets.
19. Preserve player data between sessions.

---

# 116. INITIAL DEFAULT ASSUMPTIONS

Unless I explicitly override them, use:

```text
Game Type:
Single-player offline game

Base Resolution:
320×180

Aspect Ratio:
16:9

Primary Target:
Windows desktop

Maximum Target Resolution:
1920×1080

UI Languages:
Arabic
English

Puzzle Languages:
Arabic
English

Default UI Language:
Arabic

Default Puzzle Language:
Arabic

Default Wrong Attempts:
6

Input:
Keyboard + Mouse

Scores:
Local

Saves:
Local

Online Backend:
None

Art Style:
Pixel Art

Rendering:
Pixel Perfect

Arabic UI:
Full RTL

Final Assets:
Provided later inside /assets
```

---

# 117. IMPORTANT ARABIC REQUIREMENT

This requirement has the highest priority:

**Arabic text must render correctly.**

Do not consider Arabic support complete merely because Unicode Arabic characters appear on screen.

Verify:

- glyph connection
- letter shaping
- word direction
- sentence direction
- punctuation
- numbers
- Arabic/English mixed text
- button alignment
- paragraph alignment

If standard LÖVE2D text APIs are insufficient for proper shaping/Bidi behavior, create or integrate a lightweight Lua-compatible shaping/Bidi solution rather than implementing broken RTL by reversing strings.

---

# 118. IMPORTANT PIXEL ART REQUIREMENT

The second highest priority is pixel-perfect rendering.

Every graphical system should respect the internal:

```text
320×180
```

canvas.

The actual monitor resolution must never influence gameplay coordinates.

Conceptually:

```text
Game World / UI
        ↓
     320×180
        ↓
   Shader Pipeline
        ↓
Integer / Aspect-Preserved Scaling
        ↓
Physical Window
```

---

# 119. CODING AGENT BEHAVIOR

While implementing:

- inspect existing project files before modifying architecture
- avoid unnecessary rewrites
- keep files focused
- document important decisions
- test after significant changes
- fix warnings and errors as they appear
- never silently remove working functionality
- never claim a feature works without implementing it
- clearly mark any unfinished feature
- avoid fake/mock implementations in final production code

If a design choice is uncertain, prefer the architecture that is:

```text
simple
modular
data-driven
maintainable
easy to extend
```

---

# 120. FINAL QUALITY CHECK

Before declaring the project complete, perform a final review for:

```text
Architecture
Code duplication
Arabic rendering
RTL layout
Puzzle correctness
Scoring correctness
Save integrity
High-score integrity
Pixel-perfect scaling
Mouse coordinate scaling
Audio handling
Shader fallback
Missing assets
UI navigation
Performance
Error handling
Documentation
```

Fix discovered issues before considering the project finished.

The final result should be a polished foundation suitable for becoming a commercial-quality small pixel-art word puzzle game built with **LÖVE2D + Lua**.
