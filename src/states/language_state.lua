-- Language selection in two steps: interface language, then puzzle
-- language. Headings are shown in both languages so anyone can read them
-- (this screen is also the first-launch setup, Phase 5).
--
-- Params: { returnTo = "pop" | stateName, returnParams = {...} (for that state),
--           firstLaunch = bool }

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Settings = require("src.core.settings")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Palette = require("src.graphics.palette")
local Button = require("src.ui.button")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW = Config.virtualWidth

local LanguageState = MenuBase.extend(S.LANGUAGE)

local STEPS = {
    { setting = "interfaceLanguage", headingKey = "CHOOSE_INTERFACE_LANGUAGE" },
    { setting = "puzzleLanguage", headingKey = "CHOOSE_PUZZLE_LANGUAGE" },
}
local CHOICE_W, CHOICE_H = 180, 40

function LanguageState:build(params)
    self.step = 1
    self.choices = {}
    for i, code in ipairs(Localization.getLanguageCodes()) do
        local button = Button.new({
            w = CHOICE_W, h = CHOICE_H, font = Assets.fonts.title,
            text = Localization.getNativeName(code),
            onClick = function() self:choose(code) end,
        })
        button.code = code
        self.choices[i] = button
        self.ui:add(button)
    end
    if not params.firstLaunch then
        self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
    end
    self:focusCurrent()
end

-- Focus the button of the language currently set for this step.
function LanguageState:focusCurrent()
    local current = Settings.get(STEPS[self.step].setting)
    for _, b in ipairs(self.choices) do
        if b.code == current then
            self.ui:setFocus(b, true)
        end
    end
end

function LanguageState:choose(code)
    Settings.set(STEPS[self.step].setting, code)
    if self.step < #STEPS then
        self.step = self.step + 1
        self:focusCurrent()
    else
        self:finish()
    end
end

function LanguageState:finish()
    local target = self.params.returnTo or S.MAIN_MENU
    if target == "pop" then
        StateManager.pop()
    else
        StateManager.switch(target, self.params.returnParams)
    end
end

function LanguageState:back()
    if self.step > 1 then
        self.step = self.step - 1
        self:focusCurrent()
    elseif not self.params.firstLaunch then
        self:finish()
    end
end

function LanguageState:onUpdate()
    -- Choices side by side, in reading order of the interface language.
    local rtl = Localization.isRTL()
    local gap = 24
    local total = #self.choices * CHOICE_W + (#self.choices - 1) * gap
    local x0 = math.floor((VW - total) / 2)
    for i, b in ipairs(self.choices) do
        local slot = rtl and (#self.choices - i) or (i - 1)
        b:setPosition(x0 + slot * (CHOICE_W + gap), 190)
    end
end

function LanguageState:drawContent()
    MenuBase.drawBackground("backgroundMenu")
    Panel.draw(80, 60, VW - 160, 220)

    -- Heading in both languages: Arabic above English.
    local key = STEPS[self.step].headingKey
    Localization.drawText(Localization.getIn("ar", key), 80, 82, {
        font = Assets.fonts.title, width = VW - 160, align = "center",
        color = Palette.primary, shadowColor = Palette.black,
    })
    Localization.drawText(Localization.getIn("en", key), 80, 122, {
        font = Assets.fonts.bold, width = VW - 160, align = "center",
        color = Palette.text, shadowColor = Palette.black,
    })

    -- Step dots.
    for i = 1, #STEPS do
        love.graphics.setColor(i == self.step and Palette.highlight or Palette.panelHighlight)
        love.graphics.rectangle("fill", VW / 2 - 10 + (i - 1) * 14, 252, 6, 6)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return LanguageState
