-- Localization manager: interface language, translated strings, number
-- formatting and direction-aware drawing.
--
--   local L = Localization.L
--   L("PLAY")                          -> "ابدأ اللعب" / "Play"
--   L("ATTEMPTS_LEFT", { count = 3 })  -> "المحاولات المتبقية: ٣"
--   Localization.draw("PLAY", x, y, { align = "center", width = 100 })
--
-- The interface language and the puzzle language are independent settings;
-- this module only handles the interface language.

local Logger = require("src.core.logger")
local Settings = require("src.core.settings")
local Text = require("src.localization.text")
local languages = require("data.localization.languages")

local Localization = {}

local dictionaries = {}
local current = nil        -- language metadata table
local listeners = {}

local ARABIC_DIGITS = { "٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩" }

local function loadDictionary(code)
    local meta = languages[code]
    local ok, dict = pcall(require, meta.dictionary)
    if not ok or type(dict) ~= "table" then
        Logger.error("Could not load dictionary for '%s': %s", code, tostring(dict))
        return {}
    end
    return dict
end

-- Reports keys missing from any language compared with the fallback one.
local function validateDictionaries()
    local reference = dictionaries[languages.fallback]
    for _, code in ipairs(languages.order) do
        local dict = dictionaries[code]
        if dict ~= reference then
            local missing = {}
            for key in pairs(reference) do
                if dict[key] == nil then missing[#missing + 1] = key end
            end
            for key in pairs(dict) do
                if reference[key] == nil then
                    Logger.warning("Key '%s' exists in '%s' but not in '%s'", key, code, languages.fallback)
                end
            end
            if #missing > 0 then
                table.sort(missing)
                Logger.warning("Language '%s' is missing %d keys: %s", code, #missing, table.concat(missing, ", "))
            end
        end
    end
end

function Localization.init()
    for _, code in ipairs(languages.order) do
        dictionaries[code] = loadDictionary(code)
    end
    validateDictionaries()
    Localization.setLanguage(Settings.get("interfaceLanguage"))

    Settings.onChange(function(key, value)
        if key == "interfaceLanguage" then
            Localization.setLanguage(value)
        end
    end)
end

function Localization.setLanguage(code)
    if not languages[code] or not dictionaries[code] then
        Logger.warning("Unknown interface language '%s', using '%s'", tostring(code), languages.fallback)
        code = languages.fallback
    end
    if current and current.code == code then
        return
    end
    current = languages[code]
    Text.setDefaultDirection(current.direction)
    Logger.info("Interface language: %s (%s)", code, current.direction)
    for _, fn in ipairs(listeners) do
        fn(code)
    end
end

-- Registers fn(languageCode), called after the interface language changes.
function Localization.onChange(fn)
    listeners[#listeners + 1] = fn
end

function Localization.getLanguage()
    return current.code
end

function Localization.getDirection()
    return current.direction
end

function Localization.isRTL()
    return current.direction == "rtl"
end

function Localization.getLanguageCodes()
    return languages.order
end

function Localization.getNativeName(code)
    local meta = languages[code]
    return meta and meta.nativeName or tostring(code)
end

-- Numbers ---------------------------------------------------------------------------------

-- Formats a number with the digits of the interface language.
-- decimals: number of digits after the decimal point (default 0).
function Localization.formatNumber(value, decimals)
    local text
    if decimals and decimals > 0 then
        text = string.format("%." .. decimals .. "f", value)
    else
        text = string.format("%d", math.floor(value + 0.5))
    end
    if current.digits == "arabic" then
        text = text:gsub("%d", function(d) return ARABIC_DIGITS[tonumber(d) + 1] end)
        text = text:gsub("%.", current.decimalSeparator)
    end
    return text
end

-- Converts the digits inside a string (e.g. "05") to the interface digits.
function Localization.formatDigits(text)
    if current.digits == "arabic" then
        return (text:gsub("%d", function(d) return ARABIC_DIGITS[tonumber(d) + 1] end))
    end
    return text
end

-- Strings -----------------------------------------------------------------------------------

local function substitute(text, params)
    if not params then
        return text
    end
    return (text:gsub("{(%w+)}", function(name)
        local value = params[name]
        if value == nil then
            return "{" .. name .. "}"
        end
        if type(value) == "number" then
            return Localization.formatNumber(value)
        end
        return tostring(value)
    end))
end

-- Returns the translated string for key, with {placeholders} filled in.
-- Missing keys fall back to the fallback language, then to the key itself.
function Localization.get(key, params)
    local text = dictionaries[current.code][key]
    if text == nil then
        text = dictionaries[languages.fallback][key]
        if text == nil then
            Logger.warningOnce("loc:" .. tostring(key), "Unknown localization key: %s", tostring(key))
            return tostring(key)
        end
        Logger.warningOnce("loc:" .. current.code .. ":" .. key,
            "Key '%s' missing in '%s', using '%s'", key, current.code, languages.fallback)
    end
    return substitute(text, params)
end

Localization.L = Localization.get

-- A string in a specific language, whatever the interface language is
-- (used by the first-launch language screen, which shows both).
function Localization.getIn(code, key, params)
    local dict = dictionaries[code] or dictionaries[languages.fallback]
    local text = dict[key] or dictionaries[languages.fallback][key] or tostring(key)
    return substitute(text, params)
end

function Localization.getDirectionOf(code)
    local meta = languages[code]
    return meta and meta.direction or "ltr"
end

function Localization.has(key)
    return dictionaries[current.code][key] ~= nil
end

-- Drawing -------------------------------------------------------------------------------------

-- Fills in the interface direction so "start"/"end" alignment follows the UI.
-- Works on a reused scratch copy: the caller's table is never modified, so
-- option tables can be shared and still follow later language changes.
local scratch = {}
local function withUIDirection(opts)
    for k in pairs(scratch) do
        scratch[k] = nil
    end
    if opts then
        for k, v in pairs(opts) do
            scratch[k] = v
        end
    end
    if scratch.alignDirection == nil then
        scratch.alignDirection = current.direction
    end
    return scratch
end

-- Draws a localized string by key.
function Localization.draw(key, x, y, opts, params)
    return Text.draw(Localization.get(key, params), x, y, withUIDirection(opts))
end

-- Draws an already-translated or dynamic string (player names, puzzle text)
-- aligned according to the interface direction.
function Localization.drawText(str, x, y, opts)
    return Text.draw(str, x, y, withUIDirection(opts))
end

function Localization.measure(key, opts, params)
    return Text.measure(Localization.get(key, params), opts)
end

return Localization
