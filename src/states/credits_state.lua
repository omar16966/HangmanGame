-- Credits: game title, version, developer and the tools/fonts used.
-- The developer name comes from Config.app.developer.

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth

local CreditsState = MenuBase.extend(S.CREDITS)

function CreditsState:build()
    self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
end

function CreditsState:back()
    StateManager.pop()
end

function CreditsState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(100, 30, VW - 200, 250, { titleKey = "CREDITS" })

    local opts = { width = VW, align = "center", color = Palette.text }
    local y = 80
    Localization.draw("GAME_TITLE", 0, y, { font = Assets.fonts.title, width = VW, align = "center",
        color = Palette.primary, shadowColor = Palette.black })
    y = y + 34
    Localization.draw("VERSION", 0, y, { width = VW, align = "center", color = Palette.textDim },
        { version = Config.app.version })
    y = y + 26
    if Config.app.developer ~= "" then
        Localization.draw("CREDITS_DEVELOPER", 0, y, opts, { name = Config.app.developer })
        y = y + 18
    end
    for _, key in ipairs({ "CREDITS_ENGINE", "CREDITS_FONT" }) do
        Localization.draw(key, 0, y, opts)
        y = y + 18
    end
    if Config.app.copyright ~= "" then
        Localization.drawText(Config.app.copyright, 0, y, { width = VW, align = "center", color = Palette.textDim })
        y = y + 18
    end
    Localization.draw("CREDITS_THANKS", 0, y + 14, { font = Assets.fonts.bold, width = VW, align = "center",
        color = Palette.secondary })
end

return CreditsState
