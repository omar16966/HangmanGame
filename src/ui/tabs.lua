-- Tabs: a row of tab labels; one is selected.
--   Tabs.new({ x, y, w, h, tabs = { "GAMEPLAY", "AUDIO", "GRAPHICS" }, onChange = fn(index) })
-- Laid out right-to-left in the Arabic UI. LEFT/RIGHT switch tabs while
-- the tab row is focused.

local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Skin = require("src.ui.skin")
local Widget = require("src.ui.widget")

local Tabs = Widget.extend()

function Tabs.new(opts)
    local self = setmetatable({}, Tabs)
    Widget.init(self, opts)
    self.tabs = opts.tabs
    self.selected = opts.selected or 1
    self.onChange = opts.onChange
    return self
end

function Tabs:select(index)
    index = (index - 1) % #self.tabs + 1
    if index ~= self.selected then
        self.selected = index
        if self.onChange then
            self.onChange(index)
        end
    end
end

-- Rectangle of tab i (visual order follows the interface direction).
function Tabs:tabRect(i)
    local n = #self.tabs
    local tw = math.floor(self.w / n)
    local slot = Localization.isRTL() and (n - i) or (i - 1)
    return self.x + slot * tw, self.y, tw, self.h
end

function Tabs:onAction(action)
    local A = Input.Actions
    local rtl = Localization.isRTL()
    if action == A.RIGHT then
        self:select(self.selected + (rtl and -1 or 1))
        return true
    elseif action == A.LEFT then
        self:select(self.selected + (rtl and 1 or -1))
        return true
    end
    return false
end

function Tabs:mousepressed(x, y, button)
    return button == 1 and self:contains(x, y)
end

function Tabs:mousereleased(x, y, button)
    if button ~= 1 or not self:contains(x, y) then
        return false
    end
    for i = 1, #self.tabs do
        local tx, ty, tw, th = self:tabRect(i)
        if x >= tx and x < tx + tw then
            self:select(i)
        end
    end
    return true
end

function Tabs:draw()
    local font = Assets.fonts.regular
    for i, key in ipairs(self.tabs) do
        local x, y, w, h = self:tabRect(i)
        local selected = i == self.selected
        Skin.drawFrame("button", selected and "hover" or "normal", x + 1, y, w - 2, h)
        local label = Localization.get(key)
        Text.draw(label, x, y + math.floor(h / 2) - Text.getCenterOffset(font, label), {
            font = font, width = w, align = "center",
            color = selected and Palette.highlight or Palette.textDim,
        })
        if selected then
            love.graphics.setColor(Palette.primary)
            love.graphics.rectangle("fill", x + 4, y + h - 3, w - 8, 2)
        end
    end
    if self.focused and Input.lastDevice == "keyboard" then
        Skin.drawFocus(self.x, self.y, self.w, self.h)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Tabs
