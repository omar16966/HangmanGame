-- UIManager: a group of widgets with shared focus handling.
--
--   local ui = UIManager.new()
--   ui:add(Button.new({...}))
--   -- in the state: ui:update(dt), ui:draw(), ui:action(a), ui:mousepressed(...)
--
-- Keyboard: arrow keys move the focus to the nearest widget in that
-- direction (wrapping around at the edges); the focused widget gets the
-- action first, so sliders and selectors can use LEFT/RIGHT themselves.
-- Mouse: hovering focuses a widget. Tooltips (widget.tooltipKey) appear for
-- the focused or hovered widget after a short delay, also for disabled ones.

local Input = require("src.core.input")
local Config = require("src.core.config")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Skin = require("src.ui.skin")

local UIManager = {}
UIManager.__index = UIManager

local TOOLTIP_DELAY = 0.45
local DIRECTIONS = {
    [Input.Actions.UP] = { 0, -1 },
    [Input.Actions.DOWN] = { 0, 1 },
    [Input.Actions.LEFT] = { -1, 0 },
    [Input.Actions.RIGHT] = { 1, 0 },
}

-- Optional global hooks (the AudioManager plugs UI sounds in here).
UIManager.onFocusChanged = nil   -- function(widget)
UIManager.onActivated = nil      -- function(widget)

function UIManager.new()
    return setmetatable({ widgets = {}, focused = nil, hoverWidget = nil, tooltipTimer = 0 }, UIManager)
end

function UIManager:add(widget)
    self.widgets[#self.widgets + 1] = widget
    return widget
end

function UIManager:clear()
    self.widgets = {}
    self.focused = nil
    self.hoverWidget = nil
end

function UIManager:getFocused()
    return self.focused
end

function UIManager:setFocus(widget, silent)
    if self.focused == widget then
        return
    end
    if self.focused then
        self.focused.focused = false
    end
    self.focused = widget
    self.tooltipTimer = 0
    if widget then
        widget.focused = true
        if not silent and UIManager.onFocusChanged then
            UIManager.onFocusChanged(widget)
        end
    end
end

function UIManager:focusFirst()
    for _, w in ipairs(self.widgets) do
        if w:canFocus() then
            self:setFocus(w, true)
            return w
        end
    end
end

-- Keeps the focus valid when widgets get disabled or hidden.
local function validateFocus(self)
    if self.focused and not self.focused:canFocus() then
        self.focused.focused = false
        self.focused = nil
    end
end

local function center(w)
    return w.x + w.w / 2, w.y + w.h / 2
end

-- Finds the best widget in direction (dx, dy) from the focused one.
local function findInDirection(self, dx, dy)
    local from = self.focused
    if not from then
        return nil
    end
    local fx, fy = center(from)
    local best, bestScore = nil, math.huge
    for _, w in ipairs(self.widgets) do
        if w ~= from and w:canFocus() then
            local cx, cy = center(w)
            local along = (cx - fx) * dx + (cy - fy) * dy
            local across = math.abs((cx - fx) * dy) + math.abs((cy - fy) * dx)
            if along > 1 then
                local score = along + across * 2
                if score < bestScore then
                    best, bestScore = w, score
                end
            end
        end
    end
    if best then
        return best
    end
    -- Wrap around: the farthest widget on the opposite side, closest in line.
    for _, w in ipairs(self.widgets) do
        if w ~= from and w:canFocus() then
            local cx, cy = center(w)
            local along = (cx - fx) * dx + (cy - fy) * dy
            local across = math.abs((cx - fx) * dy) + math.abs((cy - fy) * dx)
            if along < -1 then
                local score = along + across * 2
                if score < bestScore then
                    best, bestScore = w, score
                end
            end
        end
    end
    return best
end

-- Returns true when the action was used.
function UIManager:action(action)
    validateFocus(self)
    local focused = self.focused
    if focused and focused:onAction(action) then
        if action == Input.Actions.CONFIRM and UIManager.onActivated then
            UIManager.onActivated(focused)
        end
        return true
    end
    local dir = DIRECTIONS[action]
    if dir then
        if not focused then
            self:focusFirst()
        else
            local target = findInDirection(self, dir[1], dir[2])
            if target then
                self:setFocus(target)
            end
        end
        return true
    end
    return false
end

function UIManager:update(dt)
    validateFocus(self)
    local mx, my, inside = Input.getMousePosition()
    local hover = nil
    for _, w in ipairs(self.widgets) do
        w.hovered = false
        if w.visible and inside and w:contains(mx, my) then
            hover = w
        end
    end
    if hover then
        hover.hovered = hover.enabled
    end
    -- Mouse hover moves the keyboard focus too (only when the mouse is in use).
    if hover ~= self.hoverWidget then
        self.hoverWidget = hover
        self.tooltipTimer = 0
        if hover and Input.lastDevice == "mouse" and hover:canFocus() then
            self:setFocus(hover)
        end
    end
    self.tooltipTimer = self.tooltipTimer + dt
    for _, w in ipairs(self.widgets) do
        w:update(dt)
    end
end

function UIManager:mousepressed(x, y, button)
    for i = #self.widgets, 1, -1 do
        local w = self.widgets[i]
        if w.visible and w.enabled and w:mousepressed(x, y, button) then
            if w:canFocus() then self:setFocus(w, true) end
            return true
        end
    end
    return false
end

function UIManager:mousereleased(x, y, button)
    for i = #self.widgets, 1, -1 do
        local w = self.widgets[i]
        if w.visible and w:mousereleased(x, y, button) then
            if UIManager.onActivated then UIManager.onActivated(w) end
            return true
        end
    end
    return false
end

function UIManager:mousemoved(x, y)
    for _, w in ipairs(self.widgets) do
        if w.visible then w:mousemoved(x, y) end
    end
end

function UIManager:draw()
    for _, w in ipairs(self.widgets) do
        if w.visible then
            w:draw()
        end
    end
    self:drawTooltip()
end

-- Tooltip for the hovered widget (mouse) or the focused one (keyboard).
function UIManager:drawTooltip()
    if self.tooltipTimer < TOOLTIP_DELAY then
        return
    end
    local w = (Input.lastDevice == "mouse") and self.hoverWidget or self.focused
    if not w or not w.tooltipKey then
        return
    end
    local font = Assets.fonts.regular
    local text = Localization.get(w.tooltipKey)
    local tw, th = Text.measure(text, { font = font, width = 220 })
    local pw, ph = tw + 12, th + 8
    local x = math.floor(w.x + w.w / 2 - pw / 2)
    local y = w.y - ph - 4
    if y < 2 then
        y = w.y + w.h + 4
    end
    x = math.max(2, math.min(Config.virtualWidth - pw - 2, x))
    Skin.drawFrame("panel", "normal", x, y, pw, ph)
    Localization.drawText(text, x + 6, y + 3, { font = font, width = tw, align = "center", color = Palette.text })
end

return UIManager
