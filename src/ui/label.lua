-- Label: a non-focusable piece of localized text placed with the UIManager.
--   Label.new({ x, y, w, textKey = "PAUSED", font = Assets.fonts.title, align = "center" })

local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Widget = require("src.ui.widget")

local Label = Widget.extend()

function Label.new(opts)
    local self = setmetatable({}, Label)
    Widget.init(self, opts)
    self.focusable = false
    self.textKey, self.text, self.params = opts.textKey, opts.text, opts.params
    self.font = opts.font
    self.align = opts.align or "start"
    self.color = opts.color or Palette.text
    self.shadowColor = opts.shadowColor
    return self
end

function Label:draw()
    local text = self.text or Localization.get(self.textKey, self.params)
    Localization.drawText(text, self.x, self.y, {
        font = self.font or Assets.fonts.regular, width = self.w, align = self.align,
        color = self.color, shadowColor = self.shadowColor,
    })
end

return Label
