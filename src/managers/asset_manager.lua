-- Asset manager: loads everything listed in asset_manifest.lua exactly once.
--
--   Assets.fonts.regular        -- always a usable font (falls back if missing)
--   Assets.images.panel         -- an Image, or nil when the file is missing
--   Assets.hasImage("panel")
--
-- A missing or broken file never crashes the game: it is reported once in
-- the log and the caller uses its fallback (placeholder art, OS cursor ...).

local Logger = require("src.core.logger")
local Utils = require("src.core.utils")
local manifest = require("src.managers.asset_manifest")

local Assets = {
    fonts = {},
    images = {},
    missing = {},   -- list of "kind:key (path)" strings, shown in the debug overlay
}

local missingOptional = {}

local function reportMissing(kind, key, def, reason)
    local text = string.format("%s:%s (%s)", kind, key, def.path)
    Assets.missing[#Assets.missing + 1] = text
    if def.required then
        Logger.error("Missing required %s '%s' at %s: %s", kind, key, def.path, reason)
    else
        -- Optional assets are expected to be missing during development:
        -- details at DEBUG level, one summary warning after loading.
        missingOptional[#missingOptional + 1] = key
        Logger.debug("Missing optional %s '%s' at %s: %s", kind, key, def.path, reason)
    end
end

-- Built-in LÖVE font used for glyphs PixelAE does not have (#, %, @ ...)
-- and as a full replacement if a font file is missing.
local fallbackFonts = {}
local function getFallbackFont(size)
    if not fallbackFonts[size] then
        fallbackFonts[size] = love.graphics.newFont(math.max(6, size - 1), "mono")
        fallbackFonts[size]:setFilter("nearest", "nearest")
    end
    return fallbackFonts[size]
end

local function loadFont(key, def)
    local fallback = getFallbackFont(def.size)
    if not Utils.fileExists(def.path) then
        reportMissing("font", key, def, "file not found")
        return fallback
    end
    local ok, font = pcall(love.graphics.newFont, def.path, def.size, "mono")
    if not ok then
        reportMissing("font", key, def, tostring(font))
        return fallback
    end
    font:setFilter("nearest", "nearest")
    font:setFallbacks(fallback)
    if def.lineHeight then
        font:setLineHeight(def.lineHeight / font:getHeight())
    end
    return font
end

local function loadImage(key, def)
    if not Utils.fileExists(def.path) then
        reportMissing("image", key, def, "file not found")
        return nil
    end
    local ok, image = pcall(love.graphics.newImage, def.path)
    if not ok then
        reportMissing("image", key, def, tostring(image))
        return nil
    end
    image:setFilter("nearest", "nearest")
    return image
end

function Assets.load()
    for key, def in pairs(manifest.fonts) do
        Assets.fonts[key] = loadFont(key, def)
    end
    for key, def in pairs(manifest.images) do
        Assets.images[key] = loadImage(key, def)
    end
    if #missingOptional > 0 then
        table.sort(missingOptional)
        Logger.warning("%d optional assets missing, using placeholders: %s",
            #missingOptional, table.concat(missingOptional, ", "))
    end
    Logger.info("Assets loaded (%d missing)", #Assets.missing)
end

function Assets.hasImage(key)
    return Assets.images[key] ~= nil
end

-- Returns a font by key, or the regular font when the key is unknown.
function Assets.font(key)
    local font = Assets.fonts[key]
    if not font then
        Logger.warningOnce("font:" .. tostring(key), "Unknown font key: %s", tostring(key))
        return Assets.fonts.regular or getFallbackFont(10)
    end
    return font
end

function Assets.getManifest()
    return manifest
end

return Assets
