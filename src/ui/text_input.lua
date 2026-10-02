-- Text field: one line of typed text (names).
--   TextInput.new({ x, y, w, h, get = fn() -> string, set = fn(string),
--                   maxLength = 16, filter = fn(string) -> string, onSubmit = fn() })
--
-- Text is typed with the keyboard (love.textinput, so any OS keyboard layout
-- works, Arabic included), Backspace deletes the last character, Enter
-- submits. The text is shaped and ordered like all other text, and aligned
-- to the start side of its direction. The caret is drawn at the logical end
-- of the text (for text that mixes both directions this is approximate).

local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Utf8 = require("src.localization.utf8_util")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Widget = require("src.ui.widget")

local TextInput = Widget.extend()

local PADDING = 6
local BLINK = 0.5

function TextInput.new(opts)
    local self = setmetatable({}, TextInput)
    Widget.init(self, opts)
    self.get, self.set = opts.get, opts.set
    self.maxLength = opts.maxLength or 16
    self.filter = opts.filter
    self.onSubmit = opts.onSubmit
    self.placeholderKey = opts.placeholderKey
    self.time = 0
    return self
end

function TextInput:update(dt)
    self.time = self.time + dt
end

function TextInput:onTextInput(text)
    if not self.enabled then
        return false
    end
    local current = self.get()
    local room = self.maxLength - #Utf8.decode(current)
    if room <= 0 then
        return true
    end
    local cps = Utf8.decode(text)
    local add = {}
    for i = 1, math.min(room, #cps) do
        add[i] = cps[i]
    end
    local combined = current .. Utf8.encode(add)
    if self.filter then
        combined = self.filter(combined)
    end
    self.set(combined)
    self.time = 0 -- the caret stays visible while typing
    return true
end

function TextInput:onKey(key)
    if key == "backspace" then
        local cps = Utf8.decode(self.get())
        if #cps > 0 then
            cps[#cps] = nil
            self.set(Utf8.encode(cps))
        end
        self.time = 0
        return true
    end
    return false
end

function TextInput:onAction(action)
    if action == Input.Actions.CONFIRM and self.onSubmit then
        self.onSubmit()
        return true
    end
    return false
end

function TextInput:mousepressed(x, y, button)
    return button == 1 and self:contains(x, y)
end

function TextInput:draw()
    local font = Assets.fonts.bold
    -- Box: dark inset with a highlighted border while it has the focus.
    love.graphics.setColor(self.focused and Palette.highlight or Palette.panelBorder)
    love.graphics.rectangle("fill", self.x - 1, self.y - 1, self.w + 2, self.h + 2)
    love.graphics.setColor(Palette.backgroundDeep)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    local text = self.get()
    local innerX, innerW = self.x + PADDING, self.w - PADDING * 2
    local midY = self.y + math.floor(self.h / 2)
    local rtl = Localization.isRTL()
    local textWidth, direction = 0, rtl and "rtl" or "ltr"

    if text ~= "" then
        local _, _, layout = Text.measure(text, { font = font })
        textWidth, direction = layout.width, layout.direction
        Text.draw(text, innerX, midY - Text.getCenterOffset(font, text), {
            font = font, width = innerW, align = "start", alignDirection = direction, color = Palette.text,
        })
    elseif self.placeholderKey then
        Localization.drawText(Localization.get(self.placeholderKey), innerX,
            midY - Text.getCenterOffset(font), { font = font, width = innerW, align = "start",
            color = Palette.textDim })
    end

    -- Caret on the end side of the text.
    if self.focused and (self.time % (BLINK * 2)) < BLINK then
        local caretX
        if direction == "rtl" then
            caretX = innerX + innerW - textWidth - 3
        else
            caretX = innerX + textWidth + 1
        end
        love.graphics.setColor(Palette.highlight)
        love.graphics.rectangle("fill", math.floor(caretX), self.y + 4, 2, self.h - 8)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return TextInput
