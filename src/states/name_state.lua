-- Player name entry. Used at first launch (after the language setup) and
-- from the statistics screen.
-- Params: { returnTo = "pop" | stateName, firstLaunch = bool }

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local SaveManager = require("src.managers.save_manager")
local Profile = require("src.managers.profile_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Button = require("src.ui.button")
local Panel = require("src.ui.panel")
local TextInput = require("src.ui.text_input")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth

local NameState = MenuBase.extend(S.NAME)

local PANEL_W, PANEL_H = 380, 170
local PANEL_X, PANEL_Y = math.floor((VW - PANEL_W) / 2), 70

function NameState:build(params)
    self.draft = Profile.getName()
    self.field = self.ui:add(TextInput.new({
        x = PANEL_X + 40, y = PANEL_Y + 62, w = PANEL_W - 80, h = 26,
        maxLength = Config.save.nameMaxLength,
        filter = Profile.filterTyping,
        placeholderKey = "DEFAULT_PLAYER_NAME",
        get = function() return self.draft end,
        set = function(text) self.draft = text end,
        onSubmit = function() self:accept() end,
    }))
    self.okButton = self.ui:add(Button.new({ w = 90, h = 22, autoWidth = true, textKey = "OK",
        font = Assets.fonts.bold, onClick = function() self:accept() end }))
    -- First launch: skipping keeps the default name. Otherwise: cancel.
    self.cancelButton = self.ui:add(Button.new({ w = 90, h = 22, autoWidth = true,
        textKey = params.firstLaunch and "SKIP" or "CANCEL", font = Assets.fonts.bold,
        onClick = function() self:finish() end }))
    self.ui:setFocus(self.field, true)
end

function NameState:accept()
    Profile.setName(self.draft)
    SaveManager.markDirty()
    self:finish()
end

function NameState:finish()
    SaveManager.save("name")
    local target = self.params.returnTo or S.MAIN_MENU
    if target == "pop" then
        StateManager.pop()
    else
        StateManager.switch(target)
    end
end

function NameState:back()
    self:finish()
end

function NameState:onUpdate()
    local rtl = Localization.isRTL()
    local buttons = { self.okButton, self.cancelButton }
    local gap, total = 12, -12
    for _, b in ipairs(buttons) do
        b:fit()
        total = total + b.w + gap
    end
    local x = rtl and math.floor(PANEL_X + (PANEL_W + total) / 2) or math.floor(PANEL_X + (PANEL_W - total) / 2)
    for _, b in ipairs(buttons) do
        if rtl then
            x = x - b.w
            b:setPosition(x, PANEL_Y + PANEL_H - 40)
            x = x - gap
        else
            b:setPosition(x, PANEL_Y + PANEL_H - 40)
            x = x + b.w + gap
        end
    end
end

function NameState:keypressed(key)
    -- Typed characters arrive through textinput. Stop single keys and space
    -- from also being used as shortcuts (P = pause, Space = confirm).
    if self.ui:keypressed(key) then
        return true
    end
    return #key == 1 or key == "space"
end

function NameState:textinput(text)
    return self.ui:textinput(text)
end

function NameState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, { titleKey = "ENTER_NAME" })
    Localization.draw("NAME_HINT", PANEL_X, PANEL_Y + 94, {
        width = PANEL_W, align = "center", color = Palette.textDim }, { count = Config.save.nameMaxLength })
end

return NameState
