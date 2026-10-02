-- Settings, in three tabs: Gameplay, Audio, Graphics.
-- Changes apply immediately (language, fullscreen, window size ...).
-- Params: { overlay = true } when opened from the pause menu.
-- (Settings are saved to disk from Phase 5; audio from Phase 7 and shaders
-- from Phase 8 use the values stored here.)

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local StateManager = require("src.core.state_manager")
local Settings = require("src.core.settings")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Renderer = require("src.graphics.renderer")
local Palette = require("src.graphics.palette")
local Tabs = require("src.ui.tabs")
local Toggle = require("src.ui.toggle")
local Slider = require("src.ui.slider")
local Selector = require("src.ui.selector")
local Panel = require("src.ui.panel")
local MenuBase = require("src.states.menu_base")

local S = Constants.States
local VW, VH = Config.virtualWidth, Config.virtualHeight

local SettingsState = MenuBase.extend(S.SETTINGS)

local PANEL_X, PANEL_Y, PANEL_W, PANEL_H = 70, 10, VW - 140, 304
local ROW_X, ROW_W, ROW_H, ROW_GAP = PANEL_X + 16, PANEL_W - 32, 20, 4
local ROWS_Y = PANEL_Y + 74
local TAB_KEYS = { "GAMEPLAY", "AUDIO", "GRAPHICS" }

local function setting(key)
    return function() return Settings.get(key) end, function(v) Settings.set(key, v) end
end

local function languageOptions()
    local options = {}
    for _, code in ipairs(Localization.getLanguageCodes()) do
        options[#options + 1] = { value = code, text = Localization.getNativeName(code) }
    end
    return options
end

local function windowOptions()
    local options = {}
    for _, size in ipairs(Config.window.presets) do
        options[#options + 1] = { value = size[1] .. "x" .. size[2], text = size[1] .. " x " .. size[2] }
    end
    return options
end

-- Row definitions per tab.
local function rowsFor(tab)
    if tab == 1 then
        local difficulty = {}
        for _, id in ipairs(Config.difficulty.order) do
            difficulty[#difficulty + 1] = { value = id, textKey = "DIFFICULTY_" .. id:upper() }
        end
        return {
            { Selector, "INTERFACE_LANGUAGE", "interfaceLanguage", options = languageOptions() },
            { Selector, "PUZZLE_LANGUAGE", "puzzleLanguage", options = {
                { value = "ar", textKey = "LANGUAGE_ARABIC" }, { value = "en", textKey = "LANGUAGE_ENGLISH" } } },
            { Selector, "DIFFICULTY", "difficulty", options = difficulty },
        }
    elseif tab == 2 then
        return {
            { Slider, "MASTER_VOLUME", "masterVolume" },
            { Slider, "MUSIC_VOLUME", "musicVolume" },
            { Slider, "SFX_VOLUME", "sfxVolume" },
            { Toggle, "MUTE", "mute" },
        }
    end
    return {
        { Toggle, "FULLSCREEN", "fullscreen" },
        { Selector, "WINDOW_SIZE", "window", options = windowOptions() },
        { Toggle, "SHADERS", "shaders" },
        { Toggle, "CRT_EFFECT", "crt" },
        { Toggle, "SCANLINES", "scanlines" },
        { Toggle, "SCREEN_SHAKE", "screenShake" },
        { Toggle, "PARTICLES", "particles" },
    }
end

-- The window size is not a plain setting: it resizes the window.
local function windowAccessors()
    local get = function()
        local w, h = love.window.getMode()
        return w .. "x" .. h
    end
    local set = function(value)
        local w, h = value:match("(%d+)x(%d+)")
        w, h = tonumber(w), tonumber(h)
        Renderer.setWindowSize(w, h)
        Settings.set("windowWidth", w)
        Settings.set("windowHeight", h)
    end
    return get, set
end

function SettingsState:build(params)
    self.isOverlay = params.overlay == true
    self.tab = self.tab or 1
    self:rebuild()
end

function SettingsState:rebuild()
    self.ui:clear()
    self.tabs = self.ui:add(Tabs.new({
        x = ROW_X, y = PANEL_Y + 40, w = ROW_W, h = 22, tabs = TAB_KEYS, selected = self.tab,
        onChange = function(index)
            self.tab = index
            self:rebuild()
            self.ui:setFocus(self.tabs, true)
        end,
    }))
    self.rows = {}
    for i, def in ipairs(rowsFor(self.tab)) do
        local get, set
        if def[3] == "window" then
            get, set = windowAccessors()
        else
            get, set = setting(def[3])
        end
        local widget = def[1].new({
            x = ROW_X, y = ROWS_Y + (i - 1) * (ROW_H + ROW_GAP), w = ROW_W, h = ROW_H,
            textKey = def[2], options = def.options, get = get, set = set,
        })
        widget.settingKey = def[3]
        self.rows[i] = widget
        self.ui:add(widget)
    end
    self.backButton = self.ui:add(MenuBase.makeBackButton(function() self:back() end))
    self.ui:setFocus(self.tabs, true)
end

function SettingsState:back()
    StateManager.pop()
end

function SettingsState:onUpdate()
    for _, row in ipairs(self.rows) do
        if row.settingKey == "window" then
            row:setEnabled(not Renderer.isFullscreen())
        end
    end
end

function SettingsState:drawContent()
    if self.isOverlay then
        Panel.dim(0.75)
    else
        MenuBase.drawBackground("backgroundMenu")
    end
    Panel.draw(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, { titleKey = "SETTINGS" })
    love.graphics.setColor(1, 1, 1, 1)
end

return SettingsState
