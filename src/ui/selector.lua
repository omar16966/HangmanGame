-- Selector row: "Label ........ ‹ value ›".
--   Selector.new({ textKey = "DIFFICULTY",
--                  options = { { value = "easy", textKey = "DIFFICULTY_EASY" }, ... },
--                  get = fn() -> value, set = fn(value) })
-- Options may use `text` instead of `textKey` (e.g. language names).
-- LEFT/RIGHT step through the options; in the Arabic UI the arrows are
-- mirrored (the "next" arrow points left). CONFIRM or a click on the value
-- moves to the next option.

local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Widget = require("src.ui.widget")

local Selector = Widget.extend()

local CONTROL_W = 136
local ARROW_ZONE = 16

function Selector.new(opts)
    local self = setmetatable({}, Selector)
    Widget.init(self, opts)
    self.textKey = opts.textKey
    self.options = opts.options
    self.get, self.set = opts.get, opts.set
    self.controlW = opts.controlW or CONTROL_W
    return self
end

function Selector:currentIndex()
    local value = self.get()
    for i, option in ipairs(self.options) do
        if option.value == value then
            return i
        end
    end
    return 1
end

function Selector:step(delta)
    if not self.enabled or #self.options == 0 then
        return
    end
    local i = (self:currentIndex() - 1 + delta) % #self.options + 1
    self.set(self.options[i].value)
end

local function optionLabel(option)
    if option.textKey then
        return Localization.get(option.textKey)
    end
    return option.text or tostring(option.value)
end

function Selector:onAction(action)
    local A = Input.Actions
    local rtl = Localization.isRTL()
    if action == A.RIGHT then
        self:step(rtl and -1 or 1)
        return true
    elseif action == A.LEFT then
        self:step(rtl and 1 or -1)
        return true
    elseif action == A.CONFIRM then
        self:step(1)
        return true
    end
    return false
end

function Selector:mousepressed(x, y, button)
    return button == 1 and self:contains(x, y)
end

function Selector:mousereleased(x, y, button)
    if button ~= 1 or not self:contains(x, y) then
        return false
    end
    local _, _, controlX = self:rowLayout(self.controlW)
    local rtl = Localization.isRTL()
    local controlEnd = controlX + self.controlW
    if x >= controlX and x < controlX + ARROW_ZONE then
        self:step(rtl and 1 or -1)          -- left arrow
    elseif x >= controlEnd - ARROW_ZONE and x < controlEnd then
        self:step(rtl and -1 or 1)          -- right arrow
    else
        self:step(1)                        -- label or value: next option
    end
    return true
end

function Selector:draw()
    self:drawRowBackground()
    local font = Assets.fonts.regular
    local labelX, labelW, controlX = self:rowLayout(self.controlW)
    local midY = self.y + math.floor(self.h / 2)
    local color = self.enabled and Palette.text or Palette.textDim
    if self.textKey then
        local label = Localization.get(self.textKey)
        Localization.drawText(label, labelX, midY - Text.getCenterOffset(font, label),
            { font = font, width = labelW, align = "start", color = color })
    end

    local arrowColor = (self.focused or self.hovered) and Palette.highlight or Palette.textDim
    Widget.drawArrow(controlX + 5, midY, "left", arrowColor)
    Widget.drawArrow(controlX + self.controlW - 6, midY, "right", arrowColor)
    local value = optionLabel(self.options[self:currentIndex()] or {})
    Text.draw(value, controlX + ARROW_ZONE, midY - Text.getCenterOffset(font, value), {
        font = font, width = self.controlW - ARROW_ZONE * 2, align = "center",
        color = self.enabled and Palette.primary or Palette.textDim,
    })
end

return Selector
