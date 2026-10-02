-- Game: wires all systems together and receives the LÖVE callbacks from
-- main.lua. Gameplay logic lives in states and managers, not here.

local Config = require("src.core.config")
local Constants = require("src.core.constants")
local Logger = require("src.core.logger")
local Cli = require("src.core.cli")
local Input = require("src.core.input")
local Settings = require("src.core.settings")
local StateManager = require("src.core.state_manager")
local DebugOverlay = require("src.core.debug_overlay")
local Renderer = require("src.graphics.renderer")
local Cursor = require("src.ui.cursor")

local Game = {}

local options = {}
local elapsed = 0
local screenshotTaken = false

local function registerStates()
    local S = Constants.States
    StateManager.register(S.BOOT, require("src.states.boot_state"))
    StateManager.register(S.DIAGNOSTICS, require("src.states.dev.diagnostics_state"))
    StateManager.register(S.GAMEPLAY, require("src.states.gameplay_state"))
    StateManager.register(S.MAIN_MENU, require("src.states.main_menu_state"))
    StateManager.register(S.LANGUAGE, require("src.states.language_state"))
    StateManager.register(S.CATEGORY, require("src.states.category_state"))
    StateManager.register(S.PAUSE, require("src.states.pause_state"))
    StateManager.register(S.RESULT, require("src.states.result_state"))
    StateManager.register(S.SETTINGS, require("src.states.settings_state"))
    StateManager.register(S.HELP, require("src.states.help_state"))
    StateManager.register(S.CREDITS, require("src.states.credits_state"))
    StateManager.register(S.MODAL, require("src.states.modal_state"))
end

function Game.load(args)
    Logger.configure(Config.logging)
    Logger.info("%s %s starting (LÖVE %d.%d.%d)", Config.app.name, Config.app.version, love.getVersion())

    if Config.debug then
        options = Cli.parse(args)
    end

    Input.init()
    Renderer.init()
    if options.width then
        Renderer.setWindowSize(options.width, options.height)
    end
    if options.fullscreen then
        Renderer.setFullscreen(true)
    end
    Input.refreshMouse()

    if options.exportPlaceholders then
        require("src.dev.placeholder_exporter").run()
        love.event.quit()
        return
    end

    DebugOverlay.init()
    DebugOverlay.setVisible(options.overlay == true)

    -- Keep the window in sync with the fullscreen setting, whoever changes it.
    Settings.onChange(function(key, value)
        if key == "fullscreen" and value ~= Renderer.isFullscreen() then
            Renderer.setFullscreen(value)
        end
    end)

    registerStates()
    if options.lang then
        Settings.set("interfaceLanguage", options.lang)
    end
    for _, pair in ipairs(options.settings or {}) do
        Settings.set(pair[1], pair[2])
    end
    if options.seed then
        love.math.setRandomSeed(options.seed)
    end

    StateManager.switch(Constants.States.BOOT, {
        nextState = options.state or Config.startState,
        nextParams = { page = options.page },
        fresh = options.fresh,
    })
end

-- Development automation (screenshots / auto quit for testing).
local function updateAutomation(dt)
    elapsed = elapsed + dt
    if options.screenshot and not screenshotTaken and elapsed >= (options.screenshotAfter or 1) then
        screenshotTaken = true
        love.graphics.captureScreenshot(function(imageData)
            imageData:encode("png", options.screenshot)
            Logger.info("Screenshot saved: %s/%s", love.filesystem.getSaveDirectory(), options.screenshot)
        end)
    end
    if options.quitAfter and elapsed >= options.quitAfter then
        love.event.quit()
    end
end

function Game.update(dt)
    -- Avoid huge steps after the window was dragged or the game was paused by the OS.
    dt = math.min(dt, 1 / 15)
    Renderer.update(dt)
    StateManager.update(dt)
    Cursor.update()
    updateAutomation(dt)
end

function Game.draw()
    Renderer.beginFrame()
    StateManager.draw()
    Renderer.endFrame(Cursor.draw)
    Renderer.present()
    DebugOverlay.draw()
end

-- Input --------------------------------------------------------------------------------

-- Actions handled the same way in every state.
local function handleGlobalAction(action)
    if action == Input.Actions.TOGGLE_FULLSCREEN then
        Renderer.toggleFullscreen()
        return true
    elseif action == Input.Actions.TOGGLE_DEBUG_OVERLAY then
        DebugOverlay.toggle()
        return true
    elseif action == Input.Actions.OPEN_DIAGNOSTICS then
        if StateManager.currentName() ~= Constants.States.DIAGNOSTICS then
            StateManager.push(Constants.States.DIAGNOSTICS, { overlay = true })
        end
        return true
    end
    return false
end

function Game.keypressed(key, scancode, isRepeat)
    Input.onKeyPressed(key)

    -- Alt+Enter toggles fullscreen like most desktop games.
    if key == "return" and love.keyboard.isDown("lalt", "ralt") then
        if not isRepeat then
            Renderer.toggleFullscreen()
        end
        return
    end

    if StateManager.dispatch("keypressed", key, scancode, isRepeat) then
        return
    end
    -- The first action that is used stops the others (see Input ACTION_ORDER).
    for _, action in ipairs(Input.actionsForKey(key)) do
        local handled = (not isRepeat) and handleGlobalAction(action)
        if not handled then
            handled = StateManager.dispatch("action", action, isRepeat)
        end
        if handled then
            break
        end
    end
end

function Game.keyreleased(key, scancode)
    Input.onKeyReleased(key)
    StateManager.dispatch("keyreleased", key, scancode)
end

function Game.textinput(text)
    StateManager.dispatch("textinput", text)
end

function Game.mousepressed(x, y, button)
    local vx, vy, inside = Input.onMouseMoved(x, y)
    if StateManager.dispatch("mousepressed", vx, vy, button, inside) then
        return
    end
    local action = Input.actionForMouseButton(button)
    if action then
        StateManager.dispatch("action", action, false)
    end
end

function Game.mousereleased(x, y, button)
    local vx, vy, inside = Input.onMouseMoved(x, y)
    StateManager.dispatch("mousereleased", vx, vy, button, inside)
end

function Game.mousemoved(x, y, dx, dy)
    local vx, vy, inside = Input.onMouseMoved(x, y)
    local scale = Renderer.getScale()
    StateManager.dispatch("mousemoved", vx, vy, dx / scale, dy / scale, inside)
end

function Game.wheelmoved(dx, dy)
    StateManager.dispatch("wheelmoved", dx, dy)
end

-- Window -------------------------------------------------------------------------------

function Game.resize(w, h)
    Renderer.resize(w, h)
    Input.refreshMouse()
end

function Game.quit()
    Logger.info("Shutting down")
    return false -- false = allow the application to close
end

return Game
