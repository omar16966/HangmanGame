-- Input manager: turns raw devices into game actions.
--
-- States never ask "was the Enter key pressed?". They receive abstract
-- actions (CONFIRM, BACK, LEFT, ...) defined in Config.input.bindings, so
-- adding a gamepad later only means adding new bindings here.
--
-- Mouse positions are always reported in virtual (canvas) coordinates.

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

-- When one key has several actions (Esc = BACK and PAUSE), they are sent in
-- this order and the first action a state uses wins.
local ACTION_ORDER = {
    "CONFIRM", "BACK", "PAUSE", "LEFT", "RIGHT", "UP", "DOWN",
    "TOGGLE_FULLSCREEN", "TOGGLE_DEBUG_OVERLAY", "OPEN_DIAGNOSTICS",
}

local function addBindings(bindings)
    local ordered = {}
    for _, action in ipairs(ACTION_ORDER) do
        if bindings[action] then ordered[#ordered + 1] = action end
    end
    for action in pairs(bindings) do
        local known = false
        for _, a in ipairs(ACTION_ORDER) do
            if a == action then known = true end
        end
        if not known then ordered[#ordered + 1] = action end
    end
    for _, action in ipairs(ordered) do
        for _, key in ipairs(bindings[action]) do
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
