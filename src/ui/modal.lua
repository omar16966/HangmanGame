-- Modal dialog: a centered panel with a message and a row of buttons.
-- Used through the "modal" overlay state:
--
--   StateManager.push("modal", {
--       messageKey = "CONFIRM_ABANDON",
--       buttons = { { textKey = "YES", value = true }, { textKey = "NO", value = false } },
--       cancelValue = false,          -- result of BACK / Esc
--       onResult = function(value) ... end,
--   })

local Config = require("src.core.config")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Panel = require("src.ui.panel")
local Button = require("src.ui.button")
local UIManager = require("src.ui.ui_manager")

local Modal = {}
Modal.__index = Modal

local WIDTH = 360
local PADDING = 14
local BUTTON_H = 20

function Modal.new(opts, onChoose)
    local self = setmetatable({}, Modal)
    self.opts = opts
    self.ui = UIManager.new()
    self.font = Assets.fonts.regular
    self.message = opts.message or Localization.get(opts.messageKey, opts.params)

    local _, textH = Text.measure(self.message, { font = self.font, width = WIDTH - PADDING * 2 })
    self.w = WIDTH
    self.h = PADDING * 2 + textH + 12 + BUTTON_H + (opts.titleKey and 30 or 0)
    self.x = math.floor((Config.virtualWidth - self.w) / 2)
    self.y = math.floor((Config.virtualHeight - self.h) / 2)

    -- Buttons, laid out in reading order of the interface direction.
    local buttons = {}
    for _, def in ipairs(opts.buttons) do
        local b = Button.new({ w = 80, h = BUTTON_H, autoWidth = true, textKey = def.textKey,
            onClick = function() onChoose(def.value) end })
        b:fit()
        buttons[#buttons + 1] = b
    end
    local gap = 10
    local total = -gap
    for _, b in ipairs(buttons) do total = total + b.w + gap end
    local rtl = Localization.isRTL()
    local cursor = rtl and math.floor(self.x + (self.w + total) / 2) or math.floor(self.x + (self.w - total) / 2)
    local by = self.y + self.h - PADDING - BUTTON_H
    for _, b in ipairs(buttons) do
        if rtl then
            cursor = cursor - b.w
            b:setPosition(cursor, by)
            cursor = cursor - gap
        else
            b:setPosition(cursor, by)
            cursor = cursor + b.w + gap
        end
        self.ui:add(b)
    end
    -- Focus the safe choice (the cancel button) by default.
    local focusIndex = opts.defaultIndex or #buttons
    self.ui:setFocus(buttons[focusIndex], true)
    return self
end

function Modal:draw()
    Panel.dim(0.6)
    local titleOffset = 0
    Panel.draw(self.x, self.y, self.w, self.h, { titleKey = self.opts.titleKey })
    if self.opts.titleKey then
        titleOffset = 30
    end
    Localization.drawText(self.message, self.x + PADDING, self.y + PADDING + titleOffset, {
        font = self.font, width = self.w - PADDING * 2, align = "center", color = Palette.text,
    })
    self.ui:draw()
end

return Modal
