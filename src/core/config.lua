-- Central configuration. Every tunable value of the game lives here.
-- Player-changeable values (language, volume, ...) are only *defaults* here;
-- the live values are stored in the save file by the SaveManager.

local Config = {}

Config.app = {
    name = "Hangman",            -- fallback title; the localized title comes from the GAME_TITLE key
    version = "0.1.0",
    developer = "",
    copyright = "",
    website = "",
    identity = "pixel_hangman",  -- save folder name inside the LÖVE save directory
}

-- Development mode: debug overlay (F3), diagnostics screen (F2), extra logging.
-- Must be false for release builds.
Config.debug = true

-- Internal (virtual) resolution. Everything is drawn at this size and then
-- scaled by a whole number: 2x = 1280x720, 3x = 1920x1080, 4x = 2560x1440.
Config.virtualWidth = 640
Config.virtualHeight = 360

Config.window = {
    width = 1280,
    height = 720,
    minWidth = 640,
    minHeight = 360,
    resizable = true,
    fullscreen = false,
    fullscreenType = "desktop",
    vsync = 1,
    -- Window sizes offered in the settings menu (exact multiples of 640x360).
    presets = {
        { 640, 360 },
        { 1280, 720 },
        { 1920, 1080 },
        { 2560, 1440 },
    },
}

Config.graphics = {
    pixelPerfect = true,
    -- true  -> scale only by whole numbers (1x, 2x, 3x ...) and letterbox the rest.
    -- false -> fit the window as large as possible while keeping 16:9.
    integerScaling = true,
    letterboxColor = { 0, 0, 0, 1 },
    shaders = true,
    crt = true,
    scanlines = true,
    screenShake = true,
    particles = true,
}

Config.input = {
    -- Action -> list of keyboard keys (LÖVE KeyConstant names).
    bindings = {
        CONFIRM = { "return", "kpenter", "space" },
        BACK = { "escape", "backspace" },
        LEFT = { "left" },
        RIGHT = { "right" },
        UP = { "up" },
        DOWN = { "down" },
        PAUSE = { "escape", "p" },
        TOGGLE_FULLSCREEN = { "f11" },
    },
    -- Mouse button -> action. 1 = left, 2 = right.
    mouseBindings = {
        [2] = "BACK",
    },
    debugBindings = {
        TOGGLE_DEBUG_OVERLAY = { "f3" },
        OPEN_DIAGNOSTICS = { "f2" },
    },
}

Config.logging = {
    level = "INFO",         -- minimum level printed: DEBUG, INFO, WARNING, ERROR
    historySize = 200,      -- lines kept in memory for the debug overlay
}

-- First state entered after the boot state finishes loading.
Config.startState = "diagnostics"

return Config
