-- Slider row: "Label ........ [=====-----] 80%".
--   Slider.new({ textKey = "MUSIC_VOLUME", get = fn() -> 0..1, set = fn(v), step = 0.1 })
-- LEFT/RIGHT change the value (mirrored in the Arabic UI, where the bar
-- fills from the right); click or drag on the bar sets it directly.

local Input = require("src.core.input")
local Utils = require("src.core.utils")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Widget = require("src.ui.widget")

local Slider = Widget.extend()

local BAR_W, BAR_H = 96, 8
local CONTROL_W = 136

function Slider.new(opts)
    local self = setmetatable({}, Slider)
    Widget.init(self, opts)
    self.textKey = opts.textKey
    self.get, self.set = opts.get, opts.set
    self.step = opts.step or 0.1
    self.dragging = false
    return self
end

local function barRect(self)
    local _, _, controlX = self:rowLayout(CONTROL_W)
    local rtl = Localization.isRTL()
    local bx = rtl and (controlX + CONTROL_W - BAR_W) or controlX
    return bx, self.y + math.floor((self.h - BAR_H) / 2), controlX, rtl
end

function Slider:change(delta)
    local value = Utils.clamp(self.get() + delta, 0, 1)
    self.set(math.floor(value / self.step + 0.5) * self.step)
end

function Slider:onAction(action)
    if not self.enabled then
        return false
    end
    local A = Input.Actions
    local rtl = Localization.isRTL()
    if action == A.RIGHT then
        self:change(rtl and -self.step or self.step)
        return true
    elseif action == A.LEFT then
        self:change(rtl and self.step or -self.step)
        return true
    end
    return false
end

local function setFromMouse(self, x)
    local bx, _, _, rtl = barRect(self)
    local t = Utils.clamp((x - bx) / BAR_W, 0, 1)
    if rtl then t = 1 - t end
    self.set(math.floor(t / self.step + 0.5) * self.step)
end

function Slider:mousepressed(x, y, button)
    if button ~= 1 or not self:contains(x, y) then
        return false
    end
    local bx = barRect(self)
    if x >= bx - 4 and x <= bx + BAR_W + 4 then
        self.dragging = true
        setFromMouse(self, x)
    end
    return true
end

function Slider:mousemoved(x)
    if self.dragging then
        setFromMouse(self, x)
    end
end

function Slider:mousereleased(x, y, button)
    if button == 1 and self.dragging then
        self.dragging = false
        return true
    end
    return false
end

function Slider:draw()
    self:drawRowBackground()
    local font = Assets.fonts.regular
    local labelX, labelW = self:rowLayout(CONTROL_W)
    local midY = self.y + math.floor(self.h / 2)
    local label = Localization.get(self.textKey)
    Localization.drawText(label, labelX, midY - Text.getCenterOffset(font, label),
        { font = font, width = labelW, align = "start", color = self.enabled and Palette.text or Palette.textDim })

    local value = self.get()
    local bx, by, controlX, rtl = barRect(self)
    love.graphics.setColor(Palette.panelBorder)
    love.graphics.rectangle("fill", bx - 1, by - 1, BAR_W + 2, BAR_H + 2)
    love.graphics.setColor(Palette.panel)
    love.graphics.rectangle("fill", bx, by, BAR_W, BAR_H)
    local fill = math.floor(BAR_W * value + 0.5)
    love.graphics.setColor(Palette.primary)
    if rtl then
        love.graphics.rectangle("fill", bx + BAR_W - fill, by, fill, BAR_H)
    else
        love.graphics.rectangle("fill", bx, by, fill, BAR_H)
    end
    love.graphics.setColor(Palette.highlight)
    love.graphics.rectangle("fill", rtl and (bx + BAR_W - fill) or bx, by, fill, 1)

    local valueText = Localization.get("PERCENT", { value = math.floor(value * 100 + 0.5) })
    local textW = CONTROL_W - BAR_W - 6
    local tx = rtl and controlX or (bx + BAR_W + 6)
    Localization.drawText(valueText, tx, midY - Text.getCenterOffset(font, valueText),
        { font = font, width = textW, align = "start", color = Palette.text })
    love.graphics.setColor(1, 1, 1, 1)
end

return Slider
