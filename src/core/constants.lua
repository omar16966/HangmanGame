-- Fixed identifiers shared across modules (no tunable values here: those
-- belong in config.lua).

local Constants = {}

-- Registered state names.
Constants.States = {
    BOOT = "boot",
    DIAGNOSTICS = "diagnostics",
    MAIN_MENU = "main_menu",
    LANGUAGE = "language",
    CATEGORY = "category",
    GAMEPLAY = "gameplay",
    PAUSE = "pause",
    RESULT = "result",
    SCORES = "scores",
    STATISTICS = "statistics",
    SETTINGS = "settings",
    HELP = "help",
    CREDITS = "credits",
    MODAL = "modal",
    NAME = "name",
}

Constants.Languages = {
    ARABIC = "ar",
    ENGLISH = "en",
}

Constants.Direction = {
    LTR = "ltr",
    RTL = "rtl",
}

Constants.Align = {
    LEFT = "left",
    CENTER = "center",
    RIGHT = "right",
    -- Logical alignments: resolved to left/right from the text direction.
    START = "start",
    ENDING = "end",
}

Constants.Difficulty = {
    EASY = "easy",
    NORMAL = "normal",
    HARD = "hard",
}

return Constants
