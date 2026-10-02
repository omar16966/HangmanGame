-- Results of a finished round: outcome, answer, score breakdown with a
-- counting total, round statistics, and what to do next.
-- Params: { round, scoreResult, gameplayParams }

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Session = require("src.gameplay.session")
local Button = require("src.ui.button")
local Panel = require("src.ui.panel")
local Icons = require("src.ui.icons")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth
local L = Localization.L

local ResultState = MenuBase.extend(S.RESULT)

local PANEL_X, PANEL_Y, PANEL_W, PANEL_H = 24, 26, VW - 48, 228
local BUTTONS_Y = PANEL_Y + PANEL_H + 14
local COUNT_TIME = 1.0
local ROW_H = 15

function ResultState:build(params)
    self.round = params.round
    self.score = params.scoreResult
    self.countTimer = 0

    local function playAgain(replay)
        local p = {}
        for k, v in pairs(params.gameplayParams or {}) do p[k] = v end
        p.replayPuzzleId = replay and self.round.puzzle.id or nil
        StateManager.switch(S.GAMEPLAY, p)
    end
    local items = {
        { "NEXT_PUZZLE", function() playAgain(false) end },
        { "REPLAY", function() playAgain(true) end },
        { "MAIN_MENU", function() StateManager.switch(S.MAIN_MENU) end },
    }
    self.buttons = {}
    for i, item in ipairs(items) do
        local b = Button.new({ w = 120, h = 22, autoWidth = true, textKey = item[1], font = Assets.fonts.bold,
            onClick = item[2] })
        self.buttons[i] = b
        self.ui:add(b)
    end
    self.ui:setFocus(self.buttons[1], true)
end

function ResultState:back()
    StateManager.switch(S.MAIN_MENU)
end

function ResultState:onUpdate(dt)
    self.countTimer = math.min(COUNT_TIME, self.countTimer + dt)

    -- Buttons centered in a row, in reading order.
    local gap, total = 10, -10
    for _, b in ipairs(self.buttons) do
        b:fit()
        total = total + b.w + gap
    end
    local rtl = Localization.isRTL()
    local x = rtl and math.floor((VW + total) / 2) or math.floor((VW - total) / 2)
    for _, b in ipairs(self.buttons) do
        if rtl then
            x = x - b.w
            b:setPosition(x, BUTTONS_Y)
            x = x - gap
        else
            b:setPosition(x, BUTTONS_Y)
            x = x + b.w + gap
        end
    end
end

local function signed(value)
    local n = Localization.formatNumber(math.abs(value))
    if value > 0 then return "+" .. n end
    if value < 0 then return "-" .. n end
    return n
end

-- One "label ........ value" line inside a column.
local function row(x, y, w, labelText, valueText, color)
    local font = Assets.fonts.regular
    Localization.drawText(labelText, x, y, { font = font, width = w, align = "start", color = Palette.textDim })
    Localization.drawText(valueText, x, y, { font = font, width = w, align = "end", color = color or Palette.text })
end

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return L("TIME_VALUE", {
        minutes = Localization.formatDigits(tostring(m)),
        seconds = Localization.formatDigits(string.format("%02d", s)),
    })
end

function ResultState:drawContent()
    MenuBase.drawBackground("backgroundResults")
    Panel.draw(PANEL_X, PANEL_Y, PANEL_W, PANEL_H)

    local round, score = self.round, self.score
    local won = round:isWon()

    -- Title with an icon (never color alone).
    local title = L(won and "RESULT_WIN" or "RESULT_LOSS")
    local font = Assets.fonts.title
    local tw = Text.measure(title, { font = font })
    local tx = math.floor((VW - tw) / 2)
    Text.draw(title, tx, PANEL_Y + 8, { font = font, align = "left",
        color = won and Palette.correct or Palette.incorrect, shadowColor = Palette.black })
    local iconX = Localization.isRTL() and (tx + tw + 6) or (tx - 22)
    Icons.draw(won and "check" or "cross", iconX, PANEL_Y + 12, won and Palette.correct or Palette.incorrect)

    -- The answer, in its own language and direction.
    Localization.drawText(L("ANSWER"), PANEL_X, PANEL_Y + 40, {
        width = PANEL_W, align = "center", color = Palette.textDim })
    Text.draw(round.puzzle.answer, PANEL_X + 10, PANEL_Y + 54, {
        font = font, width = PANEL_W - 20, align = "center", color = Palette.highlight, shadowColor = Palette.black })

    -- Two columns: score breakdown (start side) and statistics (end side).
    local colW = 250
    local rtl = Localization.isRTL()
    local leftX, rightX = PANEL_X + 22, PANEL_X + PANEL_W - 22 - colW
    local scoreX = rtl and rightX or leftX
    local statsX = rtl and leftX or rightX
    local y = PANEL_Y + 96

    local penalties = score.wrongPenalty + score.hintPenalty
    local lines = {
        { "SCORE_BASE", signed(score.base) },
        { "SCORE_LETTERS", signed(score.letters) },
        { "SCORE_ATTEMPTS", signed(score.remainingBonus) },
        { "SCORE_SPEED", signed(score.speedBonus) },
        { "SCORE_PENALTY", signed(-penalties), penalties > 0 and Palette.incorrect or nil },
        { "SCORE_MULTIPLIER", L("MULTIPLIER_VALUE", { value = Localization.formatNumber(score.multiplier, 1) }) },
    }
    for i, line in ipairs(lines) do
        row(scoreX, y + (i - 1) * ROW_H, colW, L(line[1]), line[2], line[3])
    end
    love.graphics.setColor(Palette.panelHighlight)
    love.graphics.rectangle("fill", scoreX, y + #lines * ROW_H + 2, colW, 1)
    local shown = math.floor(score.total * (self.countTimer / COUNT_TIME) + 0.5)
    local totalY = y + #lines * ROW_H + 6
    Localization.drawText(L("TOTAL"), scoreX, totalY, { font = Assets.fonts.bold, width = colW, align = "start",
        color = Palette.text })
    Localization.drawText(Localization.formatNumber(shown), scoreX, totalY - 6, { font = font, width = colW,
        align = "end", color = Palette.highlight, shadowColor = Palette.black })

    local session = Session.get()
    local stats = {
        { "ACCURACY", L("PERCENT", { value = math.floor(round:getAccuracy() * 100 + 0.5) }) },
        { "WRONG_GUESSES", Localization.formatNumber(round.wrong) .. " / " .. Localization.formatNumber(round.maxWrong) },
        { "TIME", formatTime(round.elapsed) },
        { "STREAK", Localization.formatNumber(session.streak) },
        { "SESSION_SCORE", Localization.formatNumber(session.score) },
    }
    for i, line in ipairs(stats) do
        row(statsX, y + (i - 1) * ROW_H, colW, L(line[1]), line[2])
    end
end

return ResultState
