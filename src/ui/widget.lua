-- Base for UI widgets used with the UIManager.
--
-- A widget is a rectangle (x, y, w, h) that can be focused (keyboard
-- navigation / mouse hover), enabled or disabled, and receives:
--   update(dt), draw()
--   onAction(action) -> true if consumed (CONFIRM, LEFT, RIGHT ...)
--   mousepressed / mousereleased / mousemoved (virtual coordinates)
-- Optional `tooltipKey` shows a localized tooltip while focused.

local Utils = require("src.core.utils")
local Input = require("src.core.input")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Skin = require("src.ui.skin")

local Widget = {}
Widget.__index = Widget

function Widget.extend()
    local class = setmetatable({}, { __index = Widget })
    class.__index = class
    return class
end

-- Shared setup for every widget.
function Widget.init(self, opts)
    self.x, self.y = opts.x or 0, opts.y or 0
    self.w, self.h = opts.w or 100, opts.h or 20
    self.enabled = opts.enabled ~= false
    self.focusable = opts.focusable ~= false
    self.visible = opts.visible ~= false
    self.focused = false
    self.hovered = false
    self.tooltipKey = opts.tooltipKey
    self.id = opts.id
    return self
end

function Widget:contains(px, py)
    return Utils.pointInRect(px, py, self.x, self.y, self.w, self.h)
end

function Widget:setPosition(x, y)
    self.x, self.y = x, y
end

function Widget:setEnabled(enabled)
    self.enabled = enabled
end

function Widget:canFocus()
    return self.focusable and self.enabled and self.visible
end

-- Row layout for "label ... control" widgets: the label sits on the start
-- side of the interface direction and the control on the end side.
-- Returns labelX, labelW, controlX.
function Widget:rowLayout(controlW, padding)
    padding = padding or 6
    local rtl = Localization.isRTL()
    local labelW = self.w - controlW - padding * 3
    if rtl then
        return self.x + self.w - padding - labelW, labelW, self.x + padding
    end
    return self.x + padding, labelW, self.x + self.w - padding - controlW
end

-- Highlight behind a focused row, plus the keyboard focus outline.
function Widget:drawRowBackground()
    if self.focused or self.hovered then
        love.graphics.setColor(Palette.withAlpha(Palette.panelHighlight, 0.35))
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    end
    if self.focused and Input.lastDevice == "keyboard" then
        Skin.drawFocus(self.x, self.y, self.w, self.h)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Small pixel triangle pointing "left" or "right", centered on (cx, cy).
function Widget.drawArrow(cx, cy, direction, color)
    love.graphics.setColor(color)
    for i = 0, 3 do
        local h = 7 - i * 2
        -- The tallest column is the base, the 1px column is the tip.
        local x = direction == "left" and (cx + 1 - i) or (cx - 2 + i)
        love.graphics.rectangle("fill", math.floor(x), math.floor(cy - h / 2), 1, h)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Widget:update(dt) end
function Widget:draw() end
function Widget:onAction(action) return false end
function Widget:mousepressed(x, y, button) return false end
function Widget:mousereleased(x, y, button) return false end
function Widget:mousemoved(x, y) end

return Widget
