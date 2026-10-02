-- Main menu: title, the main buttons, a language shortcut and the
-- character idling on the side (it watches the cursor).

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Input = require("src.core.input")
local Button = require("src.ui.button")
local Character = require("src.gameplay.character")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW, VH = Config.virtualWidth, Config.virtualHeight
local MARGIN = MenuBase.MARGIN

local MainMenuState = MenuBase.extend(S.MAIN_MENU)

local BUTTON_W, BUTTON_H, BUTTON_GAP = 200, 20, 5
local MENU_Y = 104

-- Menu entries. `soon` marks features of later phases (shown disabled).
local ITEMS = {
    { key = "PLAY", run = function() StateManager.switch(S.CATEGORY) end },
    { key = "CONTINUE", soon = true },      -- Phase 5 (saves)
    { key = "SCORES", soon = true },        -- Phase 5
    { key = "STATISTICS", soon = true },    -- Phase 5
    { key = "SETTINGS", run = function() StateManager.push(S.SETTINGS) end },
    { key = "HOW_TO_PLAY", run = function() StateManager.push(S.HELP) end },
    { key = "CREDITS", run = function() StateManager.push(S.CREDITS) end },
    { key = "EXIT", run = function()
        StateManager.push(S.MODAL, {
            messageKey = "CONFIRM_EXIT",
            buttons = { { textKey = "YES", value = true }, { textKey = "NO", value = false } },
            cancelValue = false,
            onResult = function(yes) if yes then love.event.quit() end end,
        })
    end },
}

function MainMenuState:build()
    local x = math.floor((VW - BUTTON_W) / 2)
    for i, item in ipairs(ITEMS) do
        local button = Button.new({
            x = x, y = MENU_Y + (i - 1) * (BUTTON_H + BUTTON_GAP), w = BUTTON_W, h = BUTTON_H,
            textKey = item.key, font = Assets.fonts.bold,
            enabled = not item.soon, tooltipKey = item.soon and "COMING_SOON" or nil,
            onClick = item.run,
        })
        self.ui:add(button)
    end

    self.languageButton = self.ui:add(Button.new({
        w = 90, h = 18, autoWidth = true,
        onClick = function() StateManager.push(S.LANGUAGE, { returnTo = "pop" }) end,
    }))

    -- The character stands on the side opposite to the reading start.
    self.character = Character.new(0, MenuBase.MENU_FLOOR_Y)
    self.hopTimer = 3
end

function MainMenuState:resume()
    -- Back from a side screen: keep the focus where it was.
end

function MainMenuState:back()
    ITEMS[#ITEMS].run()
end

function MainMenuState:onUpdate(dt)
    local rtl = Localization.isRTL()

    local lb = self.languageButton
    lb.text = Localization.get("LANGUAGE") .. ": " .. Localization.getNativeName(Localization.getLanguage())
    lb:fit()
    lb:setPosition(rtl and (VW - MARGIN - lb.w) or MARGIN, VH - MARGIN - lb.h)

    local character = self.character
    character.x = rtl and 128 or (VW - 128)
    local mx, my, inside = Input.getMousePosition()
    character:setLookTarget(inside and mx or nil, my)
    self.hopTimer = self.hopTimer - dt
    if self.hopTimer <= 0 then
        character:jump(90 + love.math.random() * 40)
        self.hopTimer = 3 + love.math.random() * 4
    end
    character:update(dt)
end

function MainMenuState:drawContent()
    MenuBase.drawBackground("backgroundMenu")

    -- Title: logo image for the interface language, or the title text.
    local logo = Localization.isRTL() and Assets.images.logoArabic or Assets.images.logoEnglish
    if logo then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(logo, math.floor((VW - logo:getWidth()) / 2), 24)
    else
        Localization.draw("GAME_TITLE", 0, 34, {
            font = Assets.fonts.title, width = VW, align = "center",
            color = Palette.primary, outlineColor = Palette.black,
        })
    end

    -- Shadow under the character, then the character.
    local cx = math.floor(self.character.x)
    love.graphics.setColor(Palette.withAlpha(Palette.black, 0.5))
    love.graphics.ellipse("fill", cx, MenuBase.MENU_FLOOR_Y + 1, 12, 2, 16)
    self.character:draw()

    local version = Localization.get("VERSION", { version = Config.app.version })
    local font = Assets.fonts.regular
    local midY = VH - MARGIN - 9 -- same row as the language button
    Localization.drawText(version, MARGIN, midY - Text.getCenterOffset(font, version), {
        font = font, width = VW - 2 * MARGIN, align = "end", color = Palette.textDim,
    })
    love.graphics.setColor(1, 1, 1, 1)
end

return MainMenuState
