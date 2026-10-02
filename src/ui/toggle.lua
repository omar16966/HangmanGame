-- Toggle row: "Label ........ [switch] On".
--   Toggle.new({ textKey = "FULLSCREEN", get = fn() -> bool, set = fn(bool) })
-- CONFIRM, LEFT, RIGHT or a click switches it.

local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Widget = require("src.ui.widget")

local Toggle = Widget.extend()

local SWITCH_W, SWITCH_H = 26, 12
local CONTROL_W = 80

function Toggle.new(opts)
    local self = setmetatable({}, Toggle)
    Widget.init(self, opts)
    self.textKey = opts.textKey
    self.get, self.set = opts.get, opts.set
    return self
end

function Toggle:toggle()
    if self.enabled then
        self.set(not self.get())
    end
end

function Toggle:onAction(action)
    local A = Input.Actions
    if action == A.CONFIRM or action == A.LEFT or action == A.RIGHT then
        self:toggle()
        return true
    end
    return false
end

function Toggle:mousepressed(x, y, button)
    return button == 1 and self:contains(x, y)
end

function Toggle:mousereleased(x, y, button)
    if button == 1 and self:contains(x, y) then
        self:toggle()
        return true
    end
    return false
end

function Toggle:draw()
    self:drawRowBackground()
    local font = Assets.fonts.regular
    local labelX, labelW, controlX = self:rowLayout(CONTROL_W)
    local midY = self.y + math.floor(self.h / 2)
    local textColor = self.enabled and Palette.text or Palette.textDim
    local label = Localization.get(self.textKey)
    Localization.drawText(label, labelX, midY - Text.getCenterOffset(font, label),
        { font = font, width = labelW, align = "start", color = textColor })

    local on = self.get()
    local rtl = Localization.isRTL()
    -- Switch: the knob sits on the "end" side when on.
    local sx = rtl and (controlX + CONTROL_W - SWITCH_W) or controlX
    local sy = midY - SWITCH_H / 2
    love.graphics.setColor(Palette.panelBorder)
    love.graphics.rectangle("fill", sx, sy, SWITCH_W, SWITCH_H)
    love.graphics.setColor(on and Palette.correctDark or Palette.panel)
    love.graphics.rectangle("fill", sx + 1, sy + 1, SWITCH_W - 2, SWITCH_H - 2)
    local knobOnEnd = on
    local knobX
    if rtl then
        knobX = knobOnEnd and (sx + 2) or (sx + SWITCH_W - 10)
    else
        knobX = knobOnEnd and (sx + SWITCH_W - 10) or (sx + 2)
    end
    love.graphics.setColor(on and Palette.correct or Palette.textDim)
    love.graphics.rectangle("fill", knobX, sy + 2, 8, SWITCH_H - 4)

    local stateText = Localization.get(on and "ON" or "OFF")
    local textX = rtl and controlX or (sx + SWITCH_W + 6)
    local textW = CONTROL_W - SWITCH_W - 6
    Localization.drawText(stateText, textX, midY - Text.getCenterOffset(font, stateText), {
        font = font, width = textW, align = "start",
        color = on and Palette.correct or Palette.textDim,
    })
    love.graphics.setColor(1, 1, 1, 1)
end

return Toggle
