-- English interface strings. Keys are shared by every language file.
-- Placeholders use {name} and are filled by Localization.get(key, params).

return {
    -- General
    GAME_TITLE = "Hangman",
    LOADING = "Loading",
    YES = "Yes",
    NO = "No",
    OK = "OK",
    CANCEL = "Cancel",
    BACK = "Back",
    NEXT = "Next",
    CONFIRM = "Confirm",
    ON = "On",
    OFF = "Off",

    -- Main menu
    PLAY = "Play",
    CONTINUE = "Continue",
    SCORES = "Scores",
    STATISTICS = "Statistics",
    SETTINGS = "Settings",
    HOW_TO_PLAY = "How to Play",
    CREDITS = "Credits",
    EXIT = "Exit",
    ADD_WORD = "Add a Word",
    MY_WORDS = "My Words",

    -- Languages
    CHOOSE_INTERFACE_LANGUAGE = "Choose Interface Language",
    CHOOSE_PUZZLE_LANGUAGE = "Choose Puzzle Language",
    INTERFACE_LANGUAGE = "Interface Language",
    PUZZLE_LANGUAGE = "Puzzle Language",
    LANGUAGE = "Language",
    LANGUAGE_ARABIC = "Arabic",
    LANGUAGE_ENGLISH = "English",

    -- Difficulty
    DIFFICULTY = "Difficulty",
    DIFFICULTY_EASY = "Easy",
    DIFFICULTY_NORMAL = "Normal",
    DIFFICULTY_HARD = "Hard",

    -- Pause
    PAUSED = "Paused",
    RESUME = "Resume",
    RESTART_ROUND = "Restart Round",
    MAIN_MENU = "Main Menu",
    CONFIRM_ABANDON = "Leave the current round? Its progress will be lost.",

    -- Gameplay
    SCORE = "Score",
    CATEGORY = "Category",
    ATTEMPTS_LEFT = "Attempts left: {count}",
    HINT = "Hint",
    HINT_TEXT = "Show Hint",
    HINT_REVEAL = "Reveal a Letter",
    HINT_COST = "-{points} points",
    NO_HINT = "This puzzle has no hint.",
    SCORE_VALUE = "Score: {value}",
    ALREADY_GUESSED = "You already tried this letter.",
    TYPE_ARABIC = "Use Arabic letters for this puzzle.",
    TYPE_ENGLISH = "Use English letters for this puzzle.",
    NOTHING_TO_REVEAL = "No letter can be revealed now.",
    NO_PUZZLES = "No puzzles available for this choice.",
    NEXT_ROUND_PROMPT = "Press Enter or click for the next puzzle",
    ROUND_POINTS = "+{points}",

    -- Results
    RESULT_WIN = "Well done!",
    RESULT_LOSS = "Better luck next time",
    ANSWER = "Answer",
    ACCURACY = "Accuracy",
    WRONG_GUESSES = "Wrong Guesses",
    TIME = "Time",
    BONUS = "Bonus",
    XP = "XP",
    STREAK = "Streak",
    TOTAL = "Total",
    NEXT_PUZZLE = "Next Puzzle",
    REPLAY = "Replay",

    -- Settings
    GRAPHICS = "Graphics",
    AUDIO = "Audio",
    GAMEPLAY = "Gameplay",
    MASTER_VOLUME = "Master Volume",
    MUSIC_VOLUME = "Music Volume",
    SFX_VOLUME = "Sound Volume",
    MUTE = "Mute",
    FULLSCREEN = "Fullscreen",
    WINDOW_SIZE = "Window Size",
    SHADERS = "Shaders",
    CRT_EFFECT = "CRT Effect",
    SCANLINES = "Scanlines",
    SCREEN_SHAKE = "Screen Shake",
    PARTICLES = "Particles",

    -- Statistics
    GAMES_PLAYED = "Games Played",
    ROUNDS_PLAYED = "Rounds Played",
    ROUNDS_WON = "Rounds Won",
    ROUNDS_LOST = "Rounds Lost",
    WIN_RATE = "Win Rate",
    CORRECT_GUESSES = "Correct Guesses",
    ARABIC_GAMES = "Arabic Puzzles",
    ENGLISH_GAMES = "English Puzzles",
    BEST_SCORE = "Best Score",
    TOTAL_SCORE = "Total Score",
    BEST_STREAK = "Best Streak",
    CURRENT_STREAK = "Current Streak",
    HINTS_USED = "Hints Used",
    PLAY_TIME = "Play Time",
    LEVEL = "Level {level}",

    -- Formats
    POINTS = "{value} points",
    PERCENT = "{value}%",
}
