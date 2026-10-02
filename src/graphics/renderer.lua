-- Renderer: owns the virtual canvas (Config.virtualWidth x virtualHeight)
-- and everything about putting it on the physical window (scaling,
-- letterboxing, fullscreen, screen shake and the optional post-processing
-- step used by the ShaderManager).
--
--   Game world / UI  ->  640x360 canvas  ->  post-process  ->  scaled window
--
-- No other system should ever deal with window pixels directly.

local Config = require("src.core.config")
local Settings = require("src.core.settings")
local Palette = require("src.graphics.palette")
local Logger = require("src.core.logger")

local Renderer = {}

local VW, VH = Config.virtualWidth, Config.virtualHeight

local canvas
local scale = 1
local offsetX, offsetY = 0, 0
local windowW, windowH = VW, VH

local shake = { time = 0, duration = 0, intensity = 0, x = 0, y = 0 }

-- Optional function(canvas, x, y, scale) that draws the canvas to the screen
-- (installed by the ShaderManager). When nil the canvas is drawn directly.
local postProcessor = nil

local function computeScale(w, h)
    local fit = math.min(w / VW, h / VH)
    if Config.graphics.integerScaling and fit >= 1 then
        return math.floor(fit)
    end
    -- Window smaller than the virtual size, or integer scaling disabled:
    -- keep the aspect ratio and use the largest size that fits.
    return fit
end

function Renderer.init()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    love.graphics.setLineStyle("rough")

    canvas = love.graphics.newCanvas(VW, VH)
    canvas:setFilter("nearest", "nearest")

    Renderer.resize(love.graphics.getDimensions())
    Logger.info("Renderer ready: virtual %dx%d, window %dx%d, scale %.2f", VW, VH, windowW, windowH, scale)
end

function Renderer.resize(w, h)
    windowW, windowH = w, h
    scale = computeScale(w, h)
    offsetX = math.floor((w - VW * scale) / 2)
    offsetY = math.floor((h - VH * scale) / 2)
end

-- Frame -----------------------------------------------------------------------

function Renderer.update(dt)
    if shake.time > 0 then
        shake.time = math.max(0, shake.time - dt)
        local strength = shake.intensity * (shake.time / shake.duration)
        -- Whole virtual pixels only, so the pixel art never gets split.
        shake.x = math.floor(love.math.random() * (strength * 2 + 1) - strength)
        shake.y = math.floor(love.math.random() * (strength * 2 + 1) - strength)
    else
        shake.x, shake.y = 0, 0
    end
end

-- Everything drawn between beginFrame() and endFrame() is in virtual pixels.
function Renderer.beginFrame()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(Palette.background)
    love.graphics.origin()
    love.graphics.push()
    love.graphics.translate(shake.x, shake.y)
end

-- overlayFn (optional) draws on the canvas after the shake offset is removed
-- (used for the mouse cursor, which must not shake).
function Renderer.endFrame(overlayFn)
    love.graphics.pop()
    if overlayFn then
        overlayFn()
    end
    love.graphics.setCanvas()
end

-- Draws the finished canvas to the window.
function Renderer.present()
    love.graphics.origin()
    love.graphics.clear(Config.graphics.letterboxColor)
    love.graphics.setColor(1, 1, 1, 1)
    if postProcessor then
        postProcessor(canvas, offsetX, offsetY, scale)
    else
        love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
    end
end

function Renderer.setPostProcessor(fn)
    postProcessor = fn
end

-- Screen shake ------------------------------------------------------------------

-- intensity is in virtual pixels (1-3 is plenty), duration in seconds.
function Renderer.shake(intensity, duration)
    if not Settings.get("screenShake") then
        return
    end
    -- A weaker shake never cancels a stronger one already running.
    if shake.time > 0 and shake.intensity > intensity then
        return
    end
    shake.intensity = intensity
    shake.duration = duration
    shake.time = duration
end

-- Coordinates -------------------------------------------------------------------

-- Converts window coordinates to virtual (canvas) coordinates.
-- Returns virtualX, virtualY (whole pixels) and whether the point is inside
-- the game area (false when it is on the letterbox bars).
function Renderer.screenToVirtual(x, y)
    local vx = math.floor((x - offsetX) / scale)
    local vy = math.floor((y - offsetY) / scale)
    local inside = vx >= 0 and vy >= 0 and vx < VW and vy < VH
    return vx, vy, inside
end

function Renderer.virtualToScreen(vx, vy)
    return offsetX + vx * scale, offsetY + vy * scale
end

-- Window ---------------------------------------------------------------------------

function Renderer.setFullscreen(enabled)
    local ok, err = pcall(love.window.setFullscreen, enabled, Config.window.fullscreenType)
    if not ok then
        Logger.error("Could not change fullscreen mode: %s", tostring(err))
        return
    end
    Renderer.resize(love.graphics.getDimensions())
    Logger.info("Fullscreen %s (%dx%d, scale %.2f)", enabled and "on" or "off", windowW, windowH, scale)
end

function Renderer.isFullscreen()
    return (love.window.getFullscreen())
end

function Renderer.toggleFullscreen()
    local enabled = not Renderer.isFullscreen()
    Renderer.setFullscreen(enabled)
    Settings.set("fullscreen", enabled)
end

function Renderer.setWindowSize(w, h, centered)
    if Renderer.isFullscreen() then
        Renderer.setFullscreen(false)
    end
    local ok, err = pcall(love.window.updateMode, w, h, centered and { centered = true } or nil)
    if not ok then
        Logger.error("Could not resize window to %dx%d: %s", w, h, tostring(err))
        return
    end
    Renderer.resize(love.graphics.getDimensions())
end

-- Applies the window state saved by the player at startup. A saved window
-- larger than the desktop is reduced to the biggest preset that fits.
function Renderer.applySavedWindow(w, h, fullscreen)
    if fullscreen then
        Renderer.setFullscreen(true)
        return
    end
    local desktopW, desktopH = love.window.getDesktopDimensions()
    if w > desktopW or h > desktopH then
        local best = Config.window.presets[1]
        for _, size in ipairs(Config.window.presets) do
            if size[1] <= desktopW and size[2] <= desktopH then
                best = size
            end
        end
        w, h = best[1], best[2]
    end
    local currentW, currentH = love.window.getMode()
    if w ~= currentW or h ~= currentH then
        Renderer.setWindowSize(w, h, true)
    end
end

-- Info ------------------------------------------------------------------------------

function Renderer.getVirtualSize()
    return VW, VH
end

function Renderer.getScale()
    return scale
end

function Renderer.getWindowSize()
    return windowW, windowH
end

function Renderer.getCanvas()
    return canvas
end

-- Rounds a coordinate to a whole virtual pixel.
function Renderer.snap(value)
    return math.floor(value + 0.5)
end

return Renderer
