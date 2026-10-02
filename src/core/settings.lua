-- Live player settings (language, volume, graphics toggles ...).
-- Defaults come from Config; the SaveManager loads/stores the values.
-- Other systems read values with Settings.get() and may listen for changes
-- with Settings.onChange() so they can react immediately (e.g. language).

local Config = require("src.core.config")
local Utils = require("src.core.utils")
local Logger = require("src.core.logger")
local languages = require("data.localization.languages")

local Settings = {}

Settings.defaults = {
    interfaceLanguage = "ar",
    puzzleLanguage = "ar",
    difficulty = "normal",

    masterVolume = 1.0,
    musicVolume = 0.7,
    sfxVolume = 0.8,
    mute = false,

    fullscreen = Config.window.fullscreen,
    windowWidth = Config.window.width,
    windowHeight = Config.window.height,

    shaders = Config.graphics.shaders,
    crt = Config.graphics.crt,
    scanlines = Config.graphics.scanlines,
    screenShake = Config.graphics.screenShake,
    particles = Config.graphics.particles,
}

local values = Utils.deepCopy(Settings.defaults)
local listeners = {}

-- Value checks, used when loading a (possibly hand-edited or damaged) save
-- and when a setting is changed. A value that fails goes back to its default.
local function isLanguageCode(v)
    return type(v) == "string" and languages[v] ~= nil and v ~= "order" and v ~= "fallback"
end

local function isVolume(v)
    return type(v) == "number" and v >= 0 and v <= 1
end

local function isWindowSize(minimum, maximum)
    return function(v)
        return type(v) == "number" and v == math.floor(v) and v >= minimum and v <= maximum
    end
end

local validators = {
    interfaceLanguage = isLanguageCode,
    puzzleLanguage = function(v) return v == "ar" or v == "en" end,
    difficulty = function(v) return type(v) == "string" and Config.difficulty[v] ~= nil and v ~= "order" end,
    masterVolume = isVolume,
    musicVolume = isVolume,
    sfxVolume = isVolume,
    windowWidth = isWindowSize(Config.window.minWidth, 16384),
    windowHeight = isWindowSize(Config.window.minHeight, 16384),
}

function Settings.get(key)
    local value = values[key]
    if value == nil then
        Logger.warningOnce("settings:" .. tostring(key), "Unknown setting requested: %s", tostring(key))
    end
    return value
end

function Settings.set(key, value)
    if Settings.defaults[key] == nil then
        Logger.warning("Ignoring unknown setting: %s", tostring(key))
        return
    end
    if type(value) ~= type(Settings.defaults[key]) then
        Logger.warning("Setting %s expects %s, got %s", key, type(Settings.defaults[key]), type(value))
        return
    end
    if validators[key] and not validators[key](value) then
        Logger.warning("Setting %s rejected invalid value %s", key, tostring(value))
        return
    end
    local old = values[key]
    if old == value then
        return
    end
    values[key] = value
    for i = 1, #listeners do
        listeners[i](key, value, old)
    end
end

-- Registers fn(key, newValue, oldValue), called after any setting changes.
function Settings.onChange(fn)
    listeners[#listeners + 1] = fn
end

-- Replaces all values (used by the SaveManager when loading). Missing,
-- wrongly typed or out-of-range entries fall back to their defaults.
-- Change listeners are not called: loading happens during startup.
function Settings.load(data)
    values = Utils.applyDefaults(Utils.deepCopy(type(data) == "table" and data or {}), Settings.defaults)
    for key in pairs(values) do
        if Settings.defaults[key] == nil then
            values[key] = nil
        end
    end
    for key, isValid in pairs(validators) do
        if not isValid(values[key]) then
            Logger.warning("Saved setting %s has an invalid value, using the default", key)
            values[key] = Utils.deepCopy(Settings.defaults[key])
        end
    end
end

function Settings.reset()
    values = Utils.deepCopy(Settings.defaults)
end

-- Returns a copy of the values suitable for saving.
function Settings.export()
    return Utils.deepCopy(values)
end

return Settings
