-- On-screen keyboard for the puzzle language (layouts in data/keyboards.lua).
--
--   local kb = VirtualKeyboard.new({ language = "ar", centerX = 320, y = 230, onPress = fn })
--   kb:setStateProvider(function(key) return round:getKeyState(key) end)
--
-- Keys are pressed with the mouse, or with the arrow keys + Enter (a focus
-- cursor appears when the keyboard is used). Letters merged by the
-- normalization rules are hidden. Used keys stay visible and show their
-- result with a color AND a mark (check / cross), never color alone.

local Input = require("src.core.input")
local Utils = require("src.core.utils")
local Assets = require("src.managers.asset_manager")
local Utf8 = require("src.localization.utf8_util")
local Text = require("src.localization.text")
local Normalizer = require("src.gameplay.normalizer")
local Palette = require("src.graphics.palette")
local Skin = require("src.ui.skin")
local layouts = require("data.keyboards")

local VirtualKeyboard = {}
VirtualKeyboard.__index = VirtualKeyboard

local DEFAULTS = { keyW = 32, keyH = 30, gap = 4 }
local PRESS_FLASH = 0.12

function VirtualKeyboard.new(opts)
    local self = setmetatable({}, VirtualKeyboard)
    self.language = opts.language
    self.centerX = opts.centerX
    self.y = opts.y
    self.keyW = opts.keyW or DEFAULTS.keyW
    self.keyH = opts.keyH or DEFAULTS.keyH
    self.gap = opts.gap or DEFAULTS.gap
    self.font = opts.font or Assets.fonts.title
    self.onPress = opts.onPress
    self.stateProvider = function() return nil end
    self.enabled = true
    self:build()
    return self
end

function VirtualKeyboard:setStateProvider(fn)
    self.stateProvider = fn
end

function VirtualKeyboard:setEnabled(enabled)
    self.enabled = enabled
end

-- Builds key rectangles from the layout of the current language.
function VirtualKeyboard:build()
    local layout = layouts[self.language] or layouts.en
    local rows = {}
    for r, row in ipairs(layout.rows) do
        local keys = {}
        for _, label in ipairs(row) do
            keys[#keys + 1] = label
        end
        -- Optional variant keys join the last row when the rules keep them separate.
        if r == #layout.rows and layout.extra then
            for _, label in ipairs(layout.extra) do
                keys[#keys + 1] = label
            end
        end
        rows[r] = keys
    end

    self.keys = {}
    self.rows = {}
    self.byKey = {}
    for r, labels in ipairs(rows) do
        local visible = {}
        for _, label in ipairs(labels) do
            local cp = Utf8.decode(label)[1]
            if Normalizer.isCanonical(cp, self.language) then
                visible[#visible + 1] = { label = label, cp = cp, key = cp }
            end
        end
        local rowW = #visible * self.keyW + (#visible - 1) * self.gap
        local x = math.floor(self.centerX - rowW / 2)
        local y = self.y + (r - 1) * (self.keyH + self.gap)
        self.rows[r] = {}
        for c, key in ipairs(visible) do
            key.x = x + (c - 1) * (self.keyW + self.gap)
            key.y = y
            key.row, key.col = r, c
            key.flash = 0
            self.keys[#self.keys + 1] = key
            self.rows[r][c] = key
            self.byKey[key.key] = key
        end
    end
    self.height = #self.rows * self.keyH + (#self.rows - 1) * self.gap
    self.focusRow, self.focusCol = 1, 1
end

function VirtualKeyboard:getHeight()
    return self.height
end

local function keyAt(self, px, py)
    for _, key in ipairs(self.keys) do
        if Utils.pointInRect(px, py, key.x, key.y, self.keyW, self.keyH) then
            return key
        end
    end
    return nil
end

local function isUsable(self, key)
    return self.enabled and self.stateProvider(key.key) == nil
end

function VirtualKeyboard:press(key)
    key.flash = PRESS_FLASH
    if isUsable(self, key) and self.onPress then
        self.onPress(key.key, key)
    end
end

-- Visual feedback when a letter is typed on the physical keyboard.
function VirtualKeyboard:flashKey(keyCode)
    local key = self.byKey[keyCode]
    if key then
        key.flash = PRESS_FLASH
    end
end

-- Returns the key under the mouse (for the character to look at), or nil.
function VirtualKeyboard:getHoveredKey()
    return self.hovered
end

function VirtualKeyboard:getFocusedKey()
    local row = self.rows[self.focusRow]
    return row and row[self.focusCol]
end

function VirtualKeyboard:update(dt)
    for _, key in ipairs(self.keys) do
        if key.flash > 0 then
            key.flash = math.max(0, key.flash - dt)
        end
    end
    local mx, my, inside = Input.getMousePosition()
    self.hovered = inside and keyAt(self, mx, my) or nil
end

-- Mouse ------------------------------------------------------------------------------------------

function VirtualKeyboard:mousepressed(x, y, button)
    if button ~= 1 then
        return false
    end
    local key = keyAt(self, x, y)
    if key then
        self.pressedKey = key
        return true
    end
    return false
end

function VirtualKeyboard:mousereleased(x, y, button)
    if button ~= 1 or not self.pressedKey then
        return false
    end
    local key = keyAt(self, x, y)
    local pressed = self.pressedKey
    self.pressedKey = nil
    if key == pressed then
        self.focusRow, self.focusCol = key.row, key.col
        self:press(key)
        return true
    end
    return false
end

-- Keyboard navigation ------------------------------------------------------------------------------

-- Moves the focus cursor. Moving between rows keeps the horizontal position.
function VirtualKeyboard:moveFocus(dx, dy)
    local current = self:getFocusedKey()
    if dy ~= 0 then
        local newRow = Utils.clamp(self.focusRow + dy, 1, #self.rows)
        if newRow ~= self.focusRow and current then
            local best, bestDist = 1, math.huge
            for c, key in ipairs(self.rows[newRow]) do
                local dist = math.abs(key.x - current.x)
                if dist < bestDist then best, bestDist = c, dist end
            end
            self.focusRow, self.focusCol = newRow, best
        end
    end
    if dx ~= 0 then
        local count = #self.rows[self.focusRow]
        self.focusCol = (self.focusCol - 1 + dx) % count + 1
    end
end

function VirtualKeyboard:pressFocused()
    local key = self:getFocusedKey()
    if key then
        self:press(key)
    end
end

-- Drawing ---------------------------------------------------------------------------------------------

local function stateFor(self, key)
    local result = self.stateProvider(key.key)
    if result then
        return result
    end
    if not self.enabled then return "disabled" end
    if key.flash > 0 or self.pressedKey == key then return "pressed" end
    if self.hovered == key then return "hover" end
    return "normal"
end

local function drawMark(state, x, y, w)
    -- Small corner mark so used keys are not told apart by color alone.
    if state == "correct" or state == "hint" then
        love.graphics.setColor(state == "hint" and Palette.secondary or Palette.correct)
        love.graphics.rectangle("fill", x + w - 7, y + 5, 2, 2)
        love.graphics.rectangle("fill", x + w - 5, y + 3, 2, 2)
        love.graphics.rectangle("fill", x + w - 9, y + 3, 2, 2)
    elseif state == "wrong" then
        love.graphics.setColor(Palette.incorrect)
        for i = 0, 3 do
            love.graphics.rectangle("fill", x + w - 9 + i * 2, y + 3 + i, 2, 1)
            love.graphics.rectangle("fill", x + w - 3 - i * 2, y + 3 + i, 2, 1)
        end
    end
end

function VirtualKeyboard:draw()
    local font = self.font
    local midY = math.floor(self.keyH / 2)
    local focused = Input.lastDevice == "keyboard" and self.enabled and self:getFocusedKey() or nil

    for _, key in ipairs(self.keys) do
        local state = stateFor(self, key)
        Skin.drawFrame("key", state, key.x, key.y, self.keyW, self.keyH)
        local dy = Skin.contentOffset(state)
        local color = Palette.text
        if state == "wrong" or state == "disabled" then
            color = Palette.textDim
        end
        Text.draw(key.label, key.x, key.y + midY - Text.getCenterOffset(font, key.label) + dy, {
            font = font, width = self.keyW, align = "center", color = color,
        })
        drawMark(state, key.x, key.y + dy, self.keyW)
        if focused == key then
            Skin.drawFocus(key.x, key.y, self.keyW, self.keyH)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return VirtualKeyboard
