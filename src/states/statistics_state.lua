-- Statistics: the player's name and lifetime numbers.

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Profile = require("src.managers.profile_manager")
local Stats = require("src.managers.stats_manager")
local Palette = require("src.graphics.palette")
local Button = require("src.ui.button")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth
local L = Localization.L

local StatisticsState = MenuBase.extend(S.STATISTICS)

local PANEL_X, PANEL_Y, PANEL_W, PANEL_H = 24, 8, VW - 48, 306
local COLUMN_W, ROW_H = 270, 20
local ROWS_Y = 112

function StatisticsState:build()
    self.nameButton = self.ui:add(Button.new({ w = 100, h = 20, autoWidth = true, textKey = "CHANGE_NAME",
        onClick = function() StateManager.push(S.NAME, { returnTo = "pop" }) end }))
    self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
    self.ui:setFocus(self.nameButton, true)
end

function StatisticsState:back()
    StateManager.switch(S.MAIN_MENU)
end

function StatisticsState:onUpdate()
    self.nameButton:fit()
    local rtl = Localization.isRTL()
    self.nameButton:setPosition(rtl and (PANEL_X + 16) or (PANEL_X + PANEL_W - 16 - self.nameButton.w), 56)
end

local function formatDuration(seconds)
    seconds = math.floor(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return L("TIME_HMS", {
        hours = Localization.formatDigits(tostring(h)),
        minutes = Localization.formatDigits(string.format("%02d", m)),
        seconds = Localization.formatDigits(string.format("%02d", s)),
    })
end

local function percent(fraction)
    return L("PERCENT", { value = math.floor(fraction * 100 + 0.5) })
end

function StatisticsState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, { titleKey = "STATISTICS" })

    local data = Stats.get()
    local n = Localization.formatNumber

    -- Player.
    local font = Assets.fonts.bold
    Localization.draw("PLAYER_NAME", PANEL_X + 16, 52, { width = PANEL_W - 32 - 140, align = "start",
        color = Palette.textDim })
    Localization.drawText(Profile.getDisplayName(), PANEL_X + 16, 66, { font = Assets.fonts.title,
        width = PANEL_W - 32 - 140, align = "start", color = Palette.highlight, shadowColor = Palette.black })
    love.graphics.setColor(Palette.panelHighlight)
    love.graphics.rectangle("fill", PANEL_X + 16, 100, PANEL_W - 32, 1)

    -- Two columns of numbers (first column on the start side).
    local rtl = Localization.isRTL()
    local firstX = rtl and (PANEL_X + PANEL_W - 16 - COLUMN_W) or (PANEL_X + 16)
    local secondX = rtl and (PANEL_X + 16) or (PANEL_X + PANEL_W - 16 - COLUMN_W)
    local first = {
        { "GAMES_PLAYED", n(data.gamesPlayed) },
        { "ROUNDS_PLAYED", n(data.roundsPlayed) },
        { "ROUNDS_WON", n(data.roundsWon) },
        { "ROUNDS_LOST", n(data.roundsLost) },
        { "WIN_RATE", percent(Stats.getWinRate()) },
        { "CORRECT_GUESSES", n(data.correctGuesses) },
        { "WRONG_GUESSES", n(data.wrongGuesses) },
        { "ACCURACY", percent(Stats.getAccuracy()) },
    }
    local second = {
        { "ARABIC_GAMES", n(data.arabicGames) },
        { "ENGLISH_GAMES", n(data.englishGames) },
        { "BEST_SCORE", n(data.bestScore) },
        { "TOTAL_SCORE", n(data.totalScore) },
        { "BEST_STREAK", n(data.bestStreak) },
        { "CURRENT_STREAK", n(data.currentStreak) },
        { "HINTS_USED", n(data.hintsUsed) },
        { "PLAY_TIME", formatDuration(data.playTime) },
    }
    for _, group in ipairs({ { first, firstX }, { second, secondX } }) do
        for i, line in ipairs(group[1]) do
            local y = ROWS_Y + (i - 1) * ROW_H
            Localization.draw(line[1], group[2], y, { width = COLUMN_W, align = "start", color = Palette.textDim })
            Localization.drawText(line[2], group[2], y, { font = font, width = COLUMN_W, align = "end",
                color = Palette.text })
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return StatisticsState
