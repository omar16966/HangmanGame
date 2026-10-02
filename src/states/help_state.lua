-- How to play: short sections with a title and a paragraph each.

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth

local HelpState = MenuBase.extend(S.HELP)

local SECTIONS = { "GOAL", "GUESS", "HINTS", "SCORE", "KEYS" }
local PANEL_X, PANEL_Y, PANEL_W, PANEL_H = 40, 8, VW - 80, 308

function HelpState:build()
    self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
end

function HelpState:back()
    StateManager.pop()
end

function HelpState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, { titleKey = "HOW_TO_PLAY" })

    local x, w = PANEL_X + 16, PANEL_W - 32
    local y = PANEL_Y + 40
    for _, id in ipairs(SECTIONS) do
        Localization.draw("HELP_" .. id .. "_TITLE", x, y, {
            font = Assets.fonts.bold, width = w, align = "start", color = Palette.primary })
        y = y + 14
        local _, h = Localization.draw("HELP_" .. id, x, y, { width = w, align = "start", color = Palette.text })
        y = y + h + 6
    end
end

return HelpState
