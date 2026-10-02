-- Panel helpers: framed boxes with an optional localized title.
--   Panel.draw(x, y, w, h, { titleKey = "SETTINGS" })

local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Skin = require("src.ui.skin")

local Panel = {}

function Panel.draw(x, y, w, h, opts)
    opts = opts or {}
    Skin.drawFrame("panel", "normal", x, y, w, h)
    if opts.titleKey or opts.title then
        local text = opts.title or Localization.get(opts.titleKey)
        Localization.drawText(text, x, y + 6, {
            font = opts.font or Assets.fonts.title, width = w, align = "center",
            color = opts.titleColor or Palette.primary, shadowColor = Palette.black,
        })
    end
end

-- Darkens everything drawn so far (behind overlays such as pause or dialogs).
function Panel.dim(alpha)
    love.graphics.setColor(Palette.withAlpha(Palette.black, alpha or 0.6))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getCanvas():getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
end

return Panel
