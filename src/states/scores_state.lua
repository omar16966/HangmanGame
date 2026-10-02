-- High scores: the best finished games, filtered by puzzle language and
-- difficulty. The most recent entry is highlighted.

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Scores = require("src.managers.score_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Selector = require("src.ui.selector")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth

local ScoresState = MenuBase.extend(S.SCORES)

local PANEL_X, PANEL_Y, PANEL_W, PANEL_H = 24, 8, VW - 48, 306
local TABLE_X, TABLE_W = PANEL_X + 16, PANEL_W - 32
local HEADER_Y, ROWS_Y, ROW_H = 86, 104, 16

-- Table columns in reading order; mirrored for Arabic.
local COLUMNS = {
    { key = "rank", header = "COL_RANK", width = 36, align = "start" },
    { key = "name", header = "COL_NAME", width = 150, align = "start" },
    { key = "score", header = "COL_SCORE", width = 70, align = "start" },
    { key = "language", header = "COL_LANGUAGE", width = 76, align = "start" },
    { key = "difficulty", header = "COL_DIFFICULTY", width = 76, align = "start" },
    { key = "rounds", header = "COL_ROUNDS", width = 60, align = "start" },
    { key = "date", header = "COL_DATE", width = 84, align = "start" },
}

local function languageOptions()
    return {
        { value = "all", textKey = "FILTER_ALL" },
        { value = "ar", textKey = "LANGUAGE_ARABIC" },
        { value = "en", textKey = "LANGUAGE_ENGLISH" },
    }
end

local function difficultyOptions()
    local options = { { value = "all", textKey = "FILTER_ALL" } }
    for _, id in ipairs(Config.difficulty.order) do
        options[#options + 1] = { value = id, textKey = "DIFFICULTY_" .. id:upper() }
    end
    return options
end

function ScoresState:build()
    self.filter = self.filter or { language = "all", difficulty = "all" }
    local rowW = 276
    self.languageSelector = self.ui:add(Selector.new({
        x = 0, y = 52, w = rowW, h = 20, textKey = "PUZZLE_LANGUAGE", options = languageOptions(),
        get = function() return self.filter.language end,
        set = function(v) self.filter.language = v end,
    }))
    self.difficultySelector = self.ui:add(Selector.new({
        x = 0, y = 52, w = rowW, h = 20, textKey = "DIFFICULTY", options = difficultyOptions(),
        get = function() return self.filter.difficulty end,
        set = function(v) self.filter.difficulty = v end,
    }))
    self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
    self.ui:setFocus(self.languageSelector, true)
end

function ScoresState:back()
    StateManager.switch(S.MAIN_MENU)
end

function ScoresState:onUpdate()
    -- The two filters side by side, first one on the start side.
    local rtl = Localization.isRTL()
    local left = TABLE_X
    local right = TABLE_X + TABLE_W - self.languageSelector.w
    self.languageSelector:setPosition(rtl and right or left, 52)
    self.difficultySelector:setPosition(rtl and left or right, 52)
end

local function columnLayout()
    local rtl = Localization.isRTL()
    local x = rtl and (TABLE_X + TABLE_W) or TABLE_X
    local out = {}
    for _, col in ipairs(COLUMNS) do
        local cx = rtl and (x - col.width) or x
        out[#out + 1] = { def = col, x = cx }
        x = rtl and (x - col.width) or (x + col.width)
    end
    return out
end

local function formatDate(time)
    return Localization.formatDigits(os.date("%Y/%m/%d", time))
end

local function cellText(col, entry, rank)
    local key = col.def.key
    if key == "rank" then return Localization.formatNumber(rank) end
    if key == "name" then return entry.name ~= "" and entry.name or Localization.get("DEFAULT_PLAYER_NAME") end
    if key == "score" then return Localization.formatNumber(entry.score) end
    if key == "language" then return Localization.get(entry.language == "ar" and "LANGUAGE_ARABIC" or "LANGUAGE_ENGLISH") end
    if key == "difficulty" then return Localization.get("DIFFICULTY_" .. entry.difficulty:upper()) end
    if key == "rounds" then return Localization.formatNumber(entry.correct) .. "/" .. Localization.formatNumber(entry.rounds) end
    return formatDate(entry.time)
end

function ScoresState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, { titleKey = "TOP_SCORES" })

    local filter = {
        language = self.filter.language ~= "all" and self.filter.language or nil,
        difficulty = self.filter.difficulty ~= "all" and self.filter.difficulty or nil,
    }
    local entries = Scores.getTop(filter, Config.save.scoresShown)
    local columns = columnLayout()
    local font = Assets.fonts.regular

    -- Header and separator.
    for _, col in ipairs(columns) do
        Localization.draw(col.def.header, col.x, HEADER_Y, { font = font, width = col.def.width - 6,
            align = col.def.align, color = Palette.primary })
    end
    love.graphics.setColor(Palette.panelHighlight)
    love.graphics.rectangle("fill", TABLE_X, HEADER_Y + 15, TABLE_W, 1)

    if #entries == 0 then
        Localization.draw("NO_SCORES", PANEL_X, ROWS_Y + 60, { width = PANEL_W, align = "center",
            color = Palette.textDim })
        return
    end

    for i, entry in ipairs(entries) do
        local y = ROWS_Y + (i - 1) * ROW_H
        local isLatest = entry == Scores.lastEntry
        if isLatest then
            love.graphics.setColor(Palette.withAlpha(Palette.primary, 0.25))
            love.graphics.rectangle("fill", TABLE_X - 4, y - 2, TABLE_W + 8, ROW_H)
        end
        for _, col in ipairs(columns) do
            local color = Palette.text
            if col.def.key == "score" then
                color = Palette.highlight
            elseif col.def.key == "rank" and i <= 3 then
                color = Palette.primary
            end
            Localization.drawText(cellText(col, entry, i), col.x, y, { font = font, width = col.def.width - 6,
                align = col.def.align, color = color })
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return ScoresState
