-- Developer diagnostics screen (debug builds only, F2).
--   Page 1 "Display": pixel-perfect scaling, letterboxing, mouse coordinate
--                     conversion, input actions, screen shake.
--   Page 2 "Text":    Arabic shaping, RTL/bidi, mixed text, numbers,
--                     wrapping and alignment, live language switching.
-- Tab switches pages, L toggles the interface language.
-- Sample sentences here are developer test data, intentionally not in the
-- localization dictionaries.

local State = require("src.states.state")
local StateManager = require("src.core.state_manager")
local Config = require("src.core.config")
local Input = require("src.core.input")
local Settings = require("src.core.settings")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")
local Renderer = require("src.graphics.renderer")

local L = Localization.L

local DiagnosticsState = State.extend("diagnostics")

local MAX_EVENTS = 5
local MAX_CLICKS = 12
local PAGES = { "display", "text" }

function DiagnosticsState:enter(params)
    self.isOverlay = params.overlay == true
    self.page = params.page or 1
    self.events = {}
    self.clicks = {}
    self.time = 0
    self.runnerX = 0
end

function DiagnosticsState:log(text)
    table.insert(self.events, 1, text)
    if #self.events > MAX_EVENTS then
        self.events[#self.events] = nil
    end
end

function DiagnosticsState:update(dt)
    self.time = self.time + dt
    -- A sub-pixel-speed mover: drawn snapped, so it must never look blurry.
    self.runnerX = (self.runnerX + dt * 23.7) % 96
end

function DiagnosticsState:action(action, isRepeat)
    self:log("action " .. action .. (isRepeat and " (repeat)" or ""))
    if action == Input.Actions.BACK and self.isOverlay then
        StateManager.pop()
    end
    return true
end

function DiagnosticsState:keypressed(key)
    if key == "tab" then
        self.page = self.page % #PAGES + 1
        return true
    elseif key == "l" then
        local nextLanguage = Settings.get("interfaceLanguage") == "ar" and "en" or "ar"
        Settings.set("interfaceLanguage", nextLanguage)
        self:log("language " .. nextLanguage)
        return true
    end

    local preset = Config.window.presets[tonumber(key) or 0]
    if preset then
        Renderer.setWindowSize(preset[1], preset[2])
        self:log(string.format("window %dx%d", preset[1], preset[2]))
        return true
    elseif key == "s" then
        Renderer.shake(2, 0.35)
        self:log("shake")
        return true
    end
    return false
end

function DiagnosticsState:textinput(text)
    self:log("text '" .. text .. "'")
    return true
end

function DiagnosticsState:mousepressed(x, y, button, inside)
    if inside then
        table.insert(self.clicks, { x = x, y = y })
        if #self.clicks > MAX_CLICKS then
            table.remove(self.clicks, 1)
        end
    end
    self:log(string.format("mouse %d at %d,%d%s", button, x, y, inside and "" or " (outside)"))
    return false -- let the right button still produce BACK
end

function DiagnosticsState:debugInfo()
    return { string.format("Diagnostics page %d/%d (%s)  UI language %s", self.page, #PAGES,
        PAGES[self.page], Localization.getLanguage()) }
end

-- Page 1: display ------------------------------------------------------------------------

local function drawGrid(vw, vh)
    love.graphics.setColor(Palette.panel)
    for x = 0, vw, 16 do
        love.graphics.rectangle("fill", x, 0, 1, vh)
    end
    for y = 0, vh, 16 do
        love.graphics.rectangle("fill", 0, y, vw, 1)
    end
end

local function drawChecker(x, y, size)
    for cy = 0, size - 1 do
        for cx = 0, size - 1 do
            love.graphics.setColor((cx + cy) % 2 == 0 and Palette.white or Palette.black)
            love.graphics.rectangle("fill", x + cx, y + cy, 1, 1)
        end
    end
end

local function drawCrosshair(x, y)
    love.graphics.setColor(Palette.highlight)
    love.graphics.rectangle("fill", x - 4, y, 3, 1)
    love.graphics.rectangle("fill", x + 2, y, 3, 1)
    love.graphics.rectangle("fill", x, y - 4, 1, 3)
    love.graphics.rectangle("fill", x, y + 2, 1, 3)
end

function DiagnosticsState:drawDisplayPage(vw, vh)
    drawGrid(vw, vh)

    -- 1px border: every edge pixel must be visible at every window size.
    love.graphics.setColor(Palette.primary)
    love.graphics.rectangle("line", 0.5, 0.5, vw - 1, vh - 1)

    love.graphics.setColor(Palette.secondary)
    love.graphics.rectangle("fill", 0, 0, 3, 3)
    love.graphics.rectangle("fill", vw - 3, 0, 3, 3)
    love.graphics.rectangle("fill", 0, vh - 3, 3, 3)
    love.graphics.rectangle("fill", vw - 3, vh - 3, 3, 3)

    drawChecker(vw - 38, 6, 32)

    Text.draw("DIAGNOSTICS", 10, 4, { font = Assets.fonts.title, color = Palette.primary, align = "left" })

    local mx, my, inside = Input.getMousePosition()
    local ww, wh = Renderer.getWindowSize()
    local lines = {
        string.format("Window %dx%d  Scale %s", ww, wh, tostring(Renderer.getScale())),
        string.format("Mouse %d,%d %s", mx, my, inside and "inside" or "outside"),
        string.format("Keys 1-%d window size   S shake   Tab page", #Config.window.presets),
        "F11 fullscreen   F3 overlay   L language",
    }
    for i, line in ipairs(lines) do
        Text.draw(line, 10, 40 + (i - 1) * 13, { align = "left", color = Palette.text })
    end
    Text.draw("Bold: The quick brown fox jumps over the lazy dog 0123456789", 10, 98,
        { font = Assets.fonts.bold, align = "left", color = Palette.secondary })
    Text.draw("2x: Pixel Hangman", 10, 116, { font = Assets.fonts.title, align = "left", color = Palette.text })

    for i, text in ipairs(self.events) do
        Text.draw(text, 10, 160 + (i - 1) * 13,
            { align = "left", color = i == 1 and Palette.highlight or Palette.textDim })
    end

    local runnerX, runnerY = vw - 130, vh - 40
    love.graphics.setColor(Palette.correct)
    love.graphics.rectangle("fill", runnerX + Renderer.snap(self.runnerX), runnerY, 8, 8)
    love.graphics.setColor(Palette.text)
    love.graphics.rectangle("fill", runnerX, runnerY + 10, 104, 1)

    love.graphics.setColor(Palette.incorrect)
    for _, click in ipairs(self.clicks) do
        love.graphics.rectangle("fill", click.x - 1, click.y - 1, 3, 3)
    end
    if inside then
        drawCrosshair(mx, my)
    end
end

-- Page 2: text --------------------------------------------------------------------------------

local MENU_KEYS = { "PLAY", "CONTINUE", "SCORES", "STATISTICS", "SETTINGS", "HOW_TO_PLAY", "EXIT" }

local function drawBox(x, y, w, h)
    love.graphics.setColor(Palette.panelLight)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)
end

function DiagnosticsState:drawTextPage(vw, vh)
    local rtl = Localization.isRTL()

    -- Title (localized, 2x font, outlined).
    Localization.draw("GAME_TITLE", 0, 6, {
        font = Assets.fonts.title, width = vw, align = "center",
        color = Palette.primary, outlineColor = Palette.black,
    })

    -- Menu column: on the interface's start side.
    local menuW, menuY, step = 130, 46, 16
    local menuX = rtl and (vw - menuW - 12) or 12
    drawBox(menuX - 4, menuY - 4, menuW + 8, #MENU_KEYS * step + 6)
    for i, key in ipairs(MENU_KEYS) do
        Localization.draw(key, menuX, menuY + (i - 1) * step, {
            width = menuW, align = "start",
            color = i == 1 and Palette.highlight or Palette.text,
        })
    end

    -- Mixed direction, numbers, punctuation.
    local samplesX = rtl and 12 or (menuW + 32)
    local samplesW = vw - menuW - 44
    local samples = {
        L("PUZZLE_LANGUAGE") .. ": English",
        L("POINTS", { value = 1250 }) .. "  /  " .. L("PERCENT", { value = 85 }),
        L("ATTEMPTS_LEFT", { count = 6 }),
        "(مرحبا) هل أنت مستعد؟ لأن الإعدادات",
        "Puzzle language: العربية (Arabic)",
        "الذكاء الاصطناعي - مُبَرْمِج",
    }
    for i, sample in ipairs(samples) do
        Localization.drawText(sample, samplesX, menuY + (i - 1) * step, {
            width = samplesW, align = "start", color = i % 2 == 1 and Palette.text or Palette.secondary,
        })
    end

    -- Wrapped paragraphs with boxes, both directions.
    local boxY, boxH = 180, 150
    local paraW = 300
    local paraOpts = { width = paraW - 8, align = "start", color = Palette.text }
    drawBox(12, boxY, paraW, boxH)
    Text.draw("اكتشف الكلمة المخفية حرفا بعد حرف قبل أن تنفد محاولاتك، وكل خطأ يقربك من النهاية. "
        .. "يمكنك استخدام التلميحات مقابل بعض النقاط.", 16, boxY + 4, paraOpts)
    Text.draw("الذكاء الاصطناعي", 16, boxY + 90, { font = Assets.fonts.title, width = paraW - 8,
        align = "start", color = Palette.secondary })
    drawBox(vw - paraW - 12, boxY, paraW, boxH)
    Text.draw("Guess the hidden word letter by letter before you run out of attempts. "
        .. "Hints cost a few points.", vw - paraW - 8, boxY + 4, paraOpts)
    Text.draw("Artificial Intelligence", vw - paraW - 8, boxY + 90, { font = Assets.fonts.title,
        width = paraW - 8, align = "start", color = Palette.secondary })

    Text.draw("Tab: page   L: " .. Localization.getNativeName(rtl and "en" or "ar"), vw / 2, vh - 16,
        { align = "center", color = Palette.textDim })
end

function DiagnosticsState:draw()
    local vw, vh = Renderer.getVirtualSize()
    love.graphics.setColor(Palette.backgroundDeep)
    love.graphics.rectangle("fill", 0, 0, vw, vh)

    if PAGES[self.page] == "text" then
        self:drawTextPage(vw, vh)
    else
        self:drawDisplayPage(vw, vh)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return DiagnosticsState
