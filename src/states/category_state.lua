-- Category selection: puzzle language and difficulty pickers, then a grid
-- of categories (with puzzle counts). Choosing one starts a new session.

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Settings = require("src.core.settings")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local PuzzleManager = require("src.managers.puzzle_manager")
local Palette = require("src.graphics.palette")
local GameFlow = require("src.managers.game_flow")
local SaveManager = require("src.managers.save_manager")
local Button = require("src.ui.button")
local Selector = require("src.ui.selector")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth

local CategoryState = MenuBase.extend(S.CATEGORY)

local COLUMNS = 4
local CELL_W, CELL_H, CELL_GAP = 140, 28, 8
local GRID_Y = 112
local ROW_W = 420

local LANGUAGE_OPTIONS = {
    { value = "ar", textKey = "LANGUAGE_ARABIC" },
    { value = "en", textKey = "LANGUAGE_ENGLISH" },
}

local function difficultyOptions()
    local options = {}
    for _, id in ipairs(Config.difficulty.order) do
        options[#options + 1] = { value = id, textKey = "DIFFICULTY_" .. id:upper() }
    end
    return options
end

function CategoryState:build()
    local rowX = math.floor((VW - ROW_W) / 2)
    self.languageSelector = self.ui:add(Selector.new({
        x = rowX, y = 50, w = ROW_W, h = 20, textKey = "PUZZLE_LANGUAGE", options = LANGUAGE_OPTIONS,
        get = function() return Settings.get("puzzleLanguage") end,
        set = function(v) Settings.set("puzzleLanguage", v) end,
    }))
    self.ui:add(Selector.new({
        x = rowX, y = 74, w = ROW_W, h = 20, textKey = "DIFFICULTY", options = difficultyOptions(),
        get = function() return Settings.get("difficulty") end,
        set = function(v) Settings.set("difficulty", v) end,
    }))

    -- "All categories" first, then every category from data/categories.lua.
    self.cells = {}
    local entries = { { id = "all" } }
    for _, category in ipairs(PuzzleManager.getCategories()) do
        entries[#entries + 1] = category
    end
    for i, entry in ipairs(entries) do
        local button = Button.new({ w = CELL_W, h = CELL_H, font = Assets.fonts.bold,
            onClick = function() self:start(entry.id) end })
        button.categoryId = entry.id
        button.index = i
        self.cells[i] = button
        self.ui:add(button)
    end
    self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
    self.ui:setFocus(self.cells[1], true)
end

function CategoryState:start(categoryId)
    local params = {
        language = Settings.get("puzzleLanguage"),
        category = categoryId,
        difficulty = Settings.get("difficulty"),
    }
    local function begin()
        GameFlow.startNewGame(params)
        StateManager.switch(S.GAMEPLAY, params)
    end
    -- A saved game would be replaced: ask first.
    if SaveManager.getSuspended() then
        StateManager.push(S.MODAL, {
            messageKey = "CONFIRM_REPLACE_SAVE",
            buttons = { { textKey = "YES", value = true }, { textKey = "NO", value = false } },
            cancelValue = false,
            onResult = function(yes) if yes then begin() end end,
        })
    else
        begin()
    end
end

function CategoryState:back()
    StateManager.switch(S.MAIN_MENU)
end

function CategoryState:onUpdate()
    local language = Settings.get("puzzleLanguage")
    local uiLanguage = Localization.getLanguage()
    local rtl = Localization.isRTL()
    local gridW = COLUMNS * CELL_W + (COLUMNS - 1) * CELL_GAP
    local x0 = math.floor((VW - gridW) / 2)

    for i, b in ipairs(self.cells) do
        local col = (i - 1) % COLUMNS
        local row = math.floor((i - 1) / COLUMNS)
        if rtl then
            col = COLUMNS - 1 - col
        end
        b:setPosition(x0 + col * (CELL_W + CELL_GAP), GRID_Y + row * (CELL_H + CELL_GAP))

        local count = PuzzleManager.count({ language = language, category = b.categoryId })
        local name = b.categoryId == "all" and Localization.get("ALL_CATEGORIES")
            or PuzzleManager.getCategoryName(b.categoryId, uiLanguage)
        b.text = name .. " (" .. Localization.formatNumber(count) .. ")"
        b:setEnabled(count > 0)
    end
end

function CategoryState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(16, 8, VW - 32, 286)
    Localization.draw("CHOOSE_CATEGORY", 16, 18, {
        font = Assets.fonts.title, width = VW - 32, align = "center",
        color = Palette.primary, shadowColor = Palette.black,
    })
end

return CategoryState
