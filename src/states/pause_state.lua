-- Pause menu, drawn over the frozen gameplay.
-- Params: { gameplayParams = {...}, puzzleId = "..." }

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Input = require("src.core.input")
local SaveManager = require("src.managers.save_manager")
local Assets = require("src.managers.asset_manager")
local Button = require("src.ui.button")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW, VH = Config.virtualWidth, Config.virtualHeight

local PauseState = MenuBase.extend(S.PAUSE)
PauseState.isOverlay = true

local PANEL_W, PANEL_H = 240, 168
local BUTTON_W, BUTTON_H, GAP = 180, 20, 6

local function confirm(messageKey, onYes)
    StateManager.push(S.MODAL, {
        messageKey = messageKey,
        buttons = { { textKey = "YES", value = true }, { textKey = "NO", value = false } },
        cancelValue = false,
        onResult = function(yes) if yes then onYes() end end,
    })
end

function PauseState:build(params)
    local items = {
        { "RESUME", function() self:back() end },
        { "RESTART_ROUND", function()
            confirm("CONFIRM_RESTART", function()
                local p = {}
                for k, v in pairs(params.gameplayParams or {}) do p[k] = v end
                p.replayPuzzleId = params.puzzleId
                StateManager.switch(S.GAMEPLAY, p)
            end)
        end },
        { "SETTINGS", function() StateManager.push(S.SETTINGS, { overlay = true }) end },
        { "MAIN_MENU", function()
            -- The round was stored when the pause menu opened: Continue picks it up.
            confirm("CONFIRM_LEAVE_SAVE", function()
                SaveManager.save("leave game")
                StateManager.switch(S.MAIN_MENU)
            end)
        end },
    }
    local x = math.floor((VW - BUTTON_W) / 2)
    local y0 = math.floor((VH - PANEL_H) / 2) + 46
    for i, item in ipairs(items) do
        self.ui:add(Button.new({ x = x, y = y0 + (i - 1) * (BUTTON_H + GAP), w = BUTTON_W, h = BUTTON_H,
            textKey = item[1], font = Assets.fonts.bold, onClick = item[2] }))
    end
end

function PauseState:back()
    StateManager.pop()
end

-- Esc / P close the pause menu as well.
function PauseState:action(action)
    if action == Input.Actions.PAUSE then
        self:back()
        return true
    end
    if self.ui:action(action) then
        return true
    end
    if action == Input.Actions.BACK then
        self:back()
        return true
    end
    return false
end

function PauseState:drawContent()
    Panel.dim(0.6)
    Panel.draw(math.floor((VW - PANEL_W) / 2), math.floor((VH - PANEL_H) / 2), PANEL_W, PANEL_H,
        { titleKey = "PAUSED" })
end

return PauseState
