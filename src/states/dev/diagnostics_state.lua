-- Developer diagnostics screen (debug builds only, F2).
-- Verifies the foundation: pixel-perfect scaling, letterboxing, mouse
-- coordinate conversion, input actions, fonts and screen shake.
-- Strings here are developer-facing and intentionally not localized.

local State = require("src.states.state")
local StateManager = require("src.core.state_manager")
local Config = require("src.core.config")
local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")
local Palette = require("src.graphics.palette")
local Renderer = require("src.graphics.renderer")

local DiagnosticsState = State.extend("diagnostics")

local MAX_EVENTS = 5
local MAX_CLICKS = 12

function DiagnosticsState:enter(params)
    self.isOverlay = params.overlay == true
    self.events = {}
    self.clicks = {}
    self.time = 0
    self.runnerX = 0
end

function DiagnosticsState:log(text)
    table.insert(self.events, 1, text)
    if #self.events > MAX_EVENTS then
        self.events[#self.events] = nil
    end
end

function DiagnosticsState:update(dt)
    self.time = self.time + dt
    -- A sub-pixel-speed mover: drawn snapped, so it must never look blurry.
    self.runnerX = (self.runnerX + dt * 23.7) % 96
end

function DiagnosticsState:action(action, isRepeat)
    self:log("action " .. action .. (isRepeat and " (repeat)" or ""))
    if action == Input.Actions.BACK and self.isOverlay then
        StateManager.pop()
        return true
    end
    return true
end

function DiagnosticsState:keypressed(key)
    local preset = Config.window.presets[tonumber(key) or 0]
    if preset then
        Renderer.setWindowSize(preset[1], preset[2])
        self:log(string.format("window %dx%d", preset[1], preset[2]))
        return true
    elseif key == "s" then
        Renderer.shake(2, 0.35)
        self:log("shake")
        return true
    end
    return false
end

function DiagnosticsState:textinput(text)
    self:log("text '" .. text .. "'")
    return true
end

function DiagnosticsState:mousepressed(x, y, button, inside)
    if inside then
        table.insert(self.clicks, { x = x, y = y })
        if #self.clicks > MAX_CLICKS then
            table.remove(self.clicks, 1)
        end
    end
    self:log(string.format("mouse %d at %d,%d%s", button, x, y, inside and "" or " (outside)"))
    return false -- let the right button still produce BACK
end

-- Drawing ----------------------------------------------------------------------

local function drawGrid(vw, vh)
    love.graphics.setColor(Palette.panel)
    for x = 0, vw, 16 do
        love.graphics.rectangle("fill", x, 0, 1, vh)
    end
    for y = 0, vh, 16 do
        love.graphics.rectangle("fill", 0, y, vw, 1)
    end
end

local function drawChecker(x, y, size)
    for cy = 0, size - 1 do
        for cx = 0, size - 1 do
            if (cx + cy) % 2 == 0 then
                love.graphics.setColor(Palette.white)
            else
                love.graphics.setColor(Palette.black)
            end
            love.graphics.rectangle("fill", x + cx, y + cy, 1, 1)
        end
    end
end

local function drawCrosshair(x, y)
    love.graphics.setColor(Palette.highlight)
    love.graphics.rectangle("fill", x - 4, y, 3, 1)
    love.graphics.rectangle("fill", x + 2, y, 3, 1)
    love.graphics.rectangle("fill", x, y - 4, 1, 3)
    love.graphics.rectangle("fill", x, y + 2, 1, 3)
end

function DiagnosticsState:draw()
    local vw, vh = Renderer.getVirtualSize()

    love.graphics.setColor(Palette.backgroundDeep)
    love.graphics.rectangle("fill", 0, 0, vw, vh)
    drawGrid(vw, vh)

    -- 1px border: every edge pixel must be visible at every window size.
    love.graphics.setColor(Palette.primary)
    love.graphics.rectangle("line", 0.5, 0.5, vw - 1, vh - 1)

    -- Corner markers.
    love.graphics.setColor(Palette.secondary)
    love.graphics.rectangle("fill", 0, 0, 3, 3)
    love.graphics.rectangle("fill", vw - 3, 0, 3, 3)
    love.graphics.rectangle("fill", 0, vh - 3, 3, 3)
    love.graphics.rectangle("fill", vw - 3, vh - 3, 3, 3)

    drawChecker(vw - 22, 6, 16)

    -- Fonts.
    love.graphics.setColor(Palette.primary)
    love.graphics.setFont(Assets.fonts.title)
    love.graphics.print("DIAGNOSTICS", 8, 4)

    love.graphics.setFont(Assets.fonts.regular)
    local mx, my, inside = Input.getMousePosition()
    local ww, wh = Renderer.getWindowSize()
    local lines = {
        string.format("Window %dx%d  Scale %s", ww, wh, tostring(Renderer.getScale())),
        string.format("Mouse %d,%d %s", mx, my, inside and "inside" or "outside"),
        "Keys 1-6 window size  S shake",
        "F11 fullscreen  F3 overlay",
    }
    for i, line in ipairs(lines) do
        love.graphics.setColor(Palette.text)
        love.graphics.print(line, 8, 26 + (i - 1) * 11)
    end

    love.graphics.setFont(Assets.fonts.bold)
    love.graphics.setColor(Palette.secondary)
    love.graphics.print("Bold: The quick brown fox 0123456789", 8, 74)

    -- Event log.
    love.graphics.setFont(Assets.fonts.regular)
    for i, text in ipairs(self.events) do
        love.graphics.setColor(i == 1 and Palette.highlight or Palette.textDim)
        love.graphics.print(text, 8, 92 + (i - 1) * 11)
    end

    -- Sub-pixel mover (must stay crisp).
    love.graphics.setColor(Palette.correct)
    love.graphics.rectangle("fill", 200 + Renderer.snap(self.runnerX), 150, 8, 8)
    love.graphics.setColor(Palette.text)
    love.graphics.rectangle("fill", 200, 160, 104, 1)

    -- Click markers and crosshair.
    love.graphics.setColor(Palette.incorrect)
    for _, click in ipairs(self.clicks) do
        love.graphics.rectangle("fill", click.x - 1, click.y - 1, 3, 3)
    end
    if inside then
        drawCrosshair(mx, my)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return DiagnosticsState
