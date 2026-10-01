-- Input manager: turns raw devices into game actions.
--
-- States never ask "was the Enter key pressed?". They receive abstract
-- actions (CONFIRM, BACK, LEFT, ...) defined in Config.input.bindings, so
-- adding a gamepad later only means adding new bindings here.
--
-- Mouse positions are always reported in virtual 320x180 coordinates.

local Config = require("src.core.config")
local Renderer = require("src.graphics.renderer")

local Input = {}

Input.Actions = {
    CONFIRM = "CONFIRM",
    BACK = "BACK",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    UP = "UP",
    DOWN = "DOWN",
    PAUSE = "PAUSE",
    TOGGLE_FULLSCREEN = "TOGGLE_FULLSCREEN",
    TOGGLE_DEBUG_OVERLAY = "TOGGLE_DEBUG_OVERLAY",
    OPEN_DIAGNOSTICS = "OPEN_DIAGNOSTICS",
}

local keyToActions = {}
local actionDown = {}
local mouseX, mouseY, mouseInside = 0, 0, false

-- "keyboard" or "mouse": lets the UI decide whether to show a focus cursor.
Input.lastDevice = "keyboard"

local function addBindings(bindings)
    for action, keys in pairs(bindings) do
        for _, key in ipairs(keys) do
            keyToActions[key] = keyToActions[key] or {}
            table.insert(keyToActions[key], action)
        end
    end
end

function Input.init()
    keyToActions = {}
    addBindings(Config.input.bindings)
    if Config.debug then
        addBindings(Config.input.debugBindings)
    end
end

-- Returns the list of actions bound to a key (may be empty).
function Input.actionsForKey(key)
    return keyToActions[key] or {}
end

function Input.actionForMouseButton(button)
    return Config.input.mouseBindings[button]
end

function Input.isDown(action)
    return actionDown[action] == true
end

-- Raw event tracking (called by Game) -----------------------------------------------

function Input.onKeyPressed(key)
    Input.lastDevice = "keyboard"
    for _, action in ipairs(Input.actionsForKey(key)) do
        actionDown[action] = true
    end
end

function Input.onKeyReleased(key)
    for _, action in ipairs(Input.actionsForKey(key)) do
        actionDown[action] = false
    end
end

function Input.onMouseMoved(x, y)
    Input.lastDevice = "mouse"
    mouseX, mouseY, mouseInside = Renderer.screenToVirtual(x, y)
    return mouseX, mouseY, mouseInside
end

-- Mouse position in virtual pixels, plus whether it is inside the game area.
function Input.getMousePosition()
    return mouseX, mouseY, mouseInside
end

-- Re-reads the OS cursor position (e.g. after a window resize).
function Input.refreshMouse()
    local x, y = love.mouse.getPosition()
    mouseX, mouseY, mouseInside = Renderer.screenToVirtual(x, y)
end

return Input
