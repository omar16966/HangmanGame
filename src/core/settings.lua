-- Live player settings (language, volume, graphics toggles ...).
-- Defaults come from Config; the SaveManager loads/stores the values.
-- Other systems read values with Settings.get() and may listen for changes
-- with Settings.onChange() so they can react immediately (e.g. language).

local Config = require("src.core.config")
local Utils = require("src.core.utils")
local Logger = require("src.core.logger")

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

-- Replaces all values (used by the SaveManager when loading).
-- Missing or invalid entries fall back to defaults.
function Settings.load(data)
    values = Utils.applyDefaults(Utils.deepCopy(data or {}), Settings.defaults)
    for key in pairs(values) do
        if Settings.defaults[key] == nil then
            values[key] = nil
        end
    end
end

-- Returns a copy of the values suitable for saving.
function Settings.export()
    return Utils.deepCopy(values)
end

return Settings
