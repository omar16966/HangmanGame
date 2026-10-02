-- Progress bar (not focusable). Fills from the start side of the interface
-- direction: right to left in Arabic.
--   ProgressBar.draw(x, y, w, h, value, color)

local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")

local ProgressBar = {}

function ProgressBar.draw(x, y, w, h, value, color)
    value = math.max(0, math.min(1, value or 0))
    x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
    love.graphics.setColor(Palette.panelBorder)
    love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
    love.graphics.setColor(Palette.panel)
    love.graphics.rectangle("fill", x, y, w, h)
    local fill = math.floor(w * value + 0.5)
    local fx = Localization.isRTL() and (x + w - fill) or x
    love.graphics.setColor(color or Palette.secondary)
    love.graphics.rectangle("fill", fx, y, fill, h)
    love.graphics.setColor(Palette.withAlpha(Palette.white, 0.25))
    love.graphics.rectangle("fill", fx, y, fill, 1)
    love.graphics.setColor(1, 1, 1, 1)
end

return ProgressBar
