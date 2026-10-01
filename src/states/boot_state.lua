-- Boot: runs the startup steps one per frame (so a progress bar can be
-- drawn), then moves to the first real state.

local State = require("src.states.state")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Renderer = require("src.graphics.renderer")
local Logger = require("src.core.logger")

local BootState = State.extend("boot")

-- Each step is { name, fn(params) }. Later phases add save loading,
-- audio and shaders here.
local steps = {
    { "assets", function() Assets.load() end },
    { "localization", function() Localization.init() end },
}

function BootState:enter(params)
    self.params = params
    self.stepIndex = 0
    self.startTime = love.timer.getTime()
end

function BootState:update(dt)
    self.stepIndex = self.stepIndex + 1
    local step = steps[self.stepIndex]
    if step then
        local ok, err = pcall(step[2], self.params)
        if not ok then
            Logger.error("Boot step '%s' failed: %s", step[1], tostring(err))
        end
        return
    end
    Logger.info("Boot finished in %.0f ms", (love.timer.getTime() - self.startTime) * 1000)
    StateManager.switch(self.params.nextState, self.params.nextParams)
end

function BootState:draw()
    local vw, vh = Renderer.getVirtualSize()
    local barW, barH = 120, 4
    local x = math.floor((vw - barW) / 2)
    local y = math.floor((vh - barH) / 2)
    local progress = math.min(1, self.stepIndex / math.max(1, #steps))

    love.graphics.setColor(Palette.panelBorder)
    love.graphics.rectangle("fill", x - 1, y - 1, barW + 2, barH + 2)
    love.graphics.setColor(Palette.panel)
    love.graphics.rectangle("fill", x, y, barW, barH)
    love.graphics.setColor(Palette.primary)
    love.graphics.rectangle("fill", x, y, math.floor(barW * progress), barH)
    love.graphics.setColor(1, 1, 1, 1)
end

return BootState
