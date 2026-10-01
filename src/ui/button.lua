-- Button: a clickable frame with an optional icon and a localized label.
--
--   local b = Button.new({ x = 10, y = 10, w = 80, h = 20, textKey = "HINT",
--                          icon = "hint", onClick = function() ... end })
--
-- States: normal, hover, pressed, disabled, focused (keyboard navigation).
-- In the Arabic UI the icon goes on the right of the label, and directional
-- icons (iconDirectional = true) are mirrored.

local Input = require("src.core.input")
local Utils = require("src.core.utils")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Skin = require("src.ui.skin")
local Icons = require("src.ui.icons")

local Button = {}
Button.__index = Button

function Button.new(opts)
    local self = setmetatable({}, Button)
    self.x, self.y, self.w, self.h = opts.x or 0, opts.y or 0, opts.w or 60, opts.h or 20
    -- autoWidth: the button grows to fit its (translated) label.
    self.autoWidth = opts.autoWidth
    self.minW = opts.w or 0
    self.padding = opts.padding or 8
    self.textKey = opts.textKey
    self.text = opts.text
    self.params = opts.params
    self.icon = opts.icon
    self.iconColor = opts.iconColor
    self.iconDirectional = opts.iconDirectional
    self.font = opts.font
    self.onClick = opts.onClick
    self.enabled = opts.enabled ~= false
    self.focused = false
    self.hovered = false
    self.pressed = false
    return self
end

function Button:setPosition(x, y)
    self.x, self.y = x, y
end

function Button:setEnabled(enabled)
    self.enabled = enabled
    if not enabled then
        self.pressed = false
    end
end

function Button:contains(px, py)
    return Utils.pointInRect(px, py, self.x, self.y, self.w, self.h)
end

function Button:getLabel()
    if self.textKey then
        return Localization.get(self.textKey, self.params)
    end
    return self.text
end

-- Width of icon + label, without padding.
function Button:getContentWidth()
    local label = self:getLabel()
    local font = self.font or Assets.fonts.regular
    local textW = label and Text.measure(label, { font = font }) or 0
    local iconW = self.icon and Icons.SIZE or 0
    local spacing = (self.icon and label) and 4 or 0
    return textW + iconW + spacing, textW, iconW, spacing
end

-- Resizes an autoWidth button to its current label (call after a language change).
function Button:fit()
    if self.autoWidth then
        self.w = math.max(self.minW, self:getContentWidth() + 2 * self.padding)
    end
end

function Button:getState()
    if not self.enabled then return "disabled" end
    if self.pressed then return "pressed" end
    if self.hovered then return "hover" end
    if self.focused then return "focused" end
    return "normal"
end

function Button:update(dt)
    local mx, my, inside = Input.getMousePosition()
    self.hovered = inside and self.enabled and self:contains(mx, my)
end

function Button:activate()
    if self.enabled and self.onClick then
        self.onClick(self)
    end
end

function Button:mousepressed(x, y, button)
    if button == 1 and self.enabled and self:contains(x, y) then
        self.pressed = true
        return true
    end
    return false
end

function Button:mousereleased(x, y, button)
    if button ~= 1 or not self.pressed then
        return false
    end
    self.pressed = false
    if self:contains(x, y) then
        self:activate()
        return true
    end
    return false
end

function Button:draw()
    local state = self:getState()
    Skin.drawFrame("button", state, self.x, self.y, self.w, self.h)
    if self.focused and Input.lastDevice == "keyboard" then
        Skin.drawFocus(self.x, self.y, self.w, self.h)
    end

    local dy = Skin.contentOffset(state)
    local color = self.enabled and Palette.text or Palette.textDim
    local label = self:getLabel()
    local font = self.font or Assets.fonts.regular
    local rtl = Localization.isRTL()

    local contentW, textW, iconW, spacing = self:getContentWidth()
    local startX = math.floor(self.x + (self.w - contentW) / 2)
    local midY = self.y + math.floor(self.h / 2) + dy

    local iconX, textX
    if rtl then
        textX, iconX = startX, startX + textW + spacing
    else
        iconX, textX = startX, startX + iconW + spacing
    end

    if self.icon then
        Icons.draw(self.icon, iconX, midY - Icons.SIZE / 2 - 1,
            self.iconColor or color, self.iconDirectional and rtl)
    end
    if label then
        Text.draw(label, textX, midY - Text.getCenterOffset(font, label),
            { font = font, align = "left", color = color })
    end
end

return Button
