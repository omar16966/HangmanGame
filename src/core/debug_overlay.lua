-- Development overlay (F3). Only available when Config.debug is true.
-- Drawn at window resolution on top of the scaled game, so it never
-- disturbs the 320x180 pixel art.

local Config = require("src.core.config")
local Renderer = require("src.graphics.renderer")
local Input = require("src.core.input")
local Logger = require("src.core.logger")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")

local DebugOverlay = {}

local visible = false
local font
-- Extra info providers: functions returning a list of strings.
local providers = {}

function DebugOverlay.init()
    font = love.graphics.newFont(12)
end

function DebugOverlay.isEnabled()
    return Config.debug
end

function DebugOverlay.toggle()
    if not Config.debug then
        return
    end
    visible = not visible
end

function DebugOverlay.setVisible(value)
    visible = Config.debug and value
end

-- Registers fn() -> { "line", ... } shown under the built-in lines
-- (used later by e.g. the ShaderManager to show its status).
function DebugOverlay.addProvider(fn)
    providers[#providers + 1] = fn
end

local function collectLines()
    local vw, vh = Renderer.getVirtualSize()
    local ww, wh = Renderer.getWindowSize()
    local mx, my, inside = Input.getMousePosition()
    local counts = Logger.getCounts()

    local lines = {
        string.format("FPS %d   Memory %.1f MB", love.timer.getFPS(), collectgarbage("count") / 1024),
        string.format("State %s   Stack [%s]", StateManager.currentName(), table.concat(StateManager.getStackNames(), " > ")),
        string.format("Canvas %dx%d   Window %dx%d   Scale %.2f%s", vw, vh, ww, wh, Renderer.getScale(),
            Renderer.isFullscreen() and "   Fullscreen" or ""),
        string.format("Mouse %d,%d %s   Device %s", mx, my, inside and "" or "(outside)", Input.lastDevice),
        string.format("Log  warnings %d  errors %d   Missing assets %d", counts.WARNING, counts.ERROR, #Assets.missing),
    }

    for _, provider in ipairs(providers) do
        for _, line in ipairs(provider() or {}) do
            lines[#lines + 1] = line
        end
    end

    local top = StateManager.current()
    local extra = top and top:debugInfo()
    if extra then
        for _, line in ipairs(extra) do
            lines[#lines + 1] = line
        end
    end
    return lines
end

function DebugOverlay.draw()
    if not visible then
        return
    end
    local lines = collectLines()
    local lineHeight = font:getHeight() + 2
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, font:getWidth(line))
    end

    love.graphics.origin()
    love.graphics.setFont(font)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 4, 4, width + 12, #lines * lineHeight + 8)
    love.graphics.setColor(0.6, 1, 0.6, 1)
    for i, line in ipairs(lines) do
        love.graphics.print(line, 10, 8 + (i - 1) * lineHeight)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return DebugOverlay
