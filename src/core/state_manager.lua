-- Stack-based state manager.
--
--   StateManager.switch("gameplay", params)  -- replace the whole stack
--   StateManager.push("pause")               -- open an overlay on top
--   StateManager.pop()                       -- close the top state
--
-- Requests are queued and applied at the start of the next update, so a
-- state can safely request a change from inside its own callbacks.

local Logger = require("src.core.logger")

local StateManager = {}

local registry = {}
local stack = {}
local pending = {}

-- Optional hook (installed by the transitions system) that wraps a switch:
-- runner(performSwitch, options). When nil, switches happen instantly.
local transitionRunner = nil

function StateManager.register(name, state)
    registry[name] = state
end

function StateManager.get(name)
    return registry[name]
end

function StateManager.setTransitionRunner(fn)
    transitionRunner = fn
end

function StateManager.switch(name, params, options)
    pending[#pending + 1] = { op = "switch", name = name, params = params, options = options }
end

function StateManager.push(name, params)
    pending[#pending + 1] = { op = "push", name = name, params = params }
end

function StateManager.pop(result)
    pending[#pending + 1] = { op = "pop", result = result }
end

function StateManager.current()
    return stack[#stack]
end

function StateManager.currentName()
    local top = stack[#stack]
    return top and top.name or "none"
end

function StateManager.getStackNames()
    local names = {}
    for i = 1, #stack do
        names[i] = stack[i].name
    end
    return names
end

-- Operations -------------------------------------------------------------------------

local function resolve(name)
    local state = registry[name]
    if not state then
        Logger.error("Unknown state requested: %s", tostring(name))
    end
    return state
end

local function doSwitch(name, params)
    local state = resolve(name)
    if not state then
        return
    end
    for i = #stack, 1, -1 do
        stack[i]:exit()
        stack[i] = nil
    end
    stack[1] = state
    Logger.debug("State -> %s", name)
    state:enter(params or {})
end

local function doPush(name, params)
    local state = resolve(name)
    if not state then
        return
    end
    stack[#stack + 1] = state
    Logger.debug("State push -> %s", name)
    state:enter(params or {})
end

local function doPop(result)
    local top = stack[#stack]
    if not top then
        return
    end
    if #stack == 1 then
        Logger.warning("Refusing to pop the last state (%s)", top.name)
        return
    end
    top:exit()
    stack[#stack] = nil
    Logger.debug("State pop <- %s", top.name)
    stack[#stack]:resume(result)
end

local function processPending()
    while #pending > 0 do
        local request = table.remove(pending, 1)
        if request.op == "switch" then
            if transitionRunner and request.options and request.options.transition then
                transitionRunner(function()
                    doSwitch(request.name, request.params)
                end, request.options)
            else
                doSwitch(request.name, request.params)
            end
        elseif request.op == "push" then
            doPush(request.name, request.params)
        elseif request.op == "pop" then
            doPop(request.result)
        end
    end
end

-- Frame ------------------------------------------------------------------------------

function StateManager.update(dt)
    processPending()

    -- Update the top state, and the ones below it while they allow it.
    for i = #stack, 1, -1 do
        stack[i]:update(dt)
        if not stack[i].updateBelow then
            break
        end
    end
end

function StateManager.draw()
    -- Find the lowest visible state: overlays let the state below show.
    local first = #stack
    while first > 1 and stack[first].isOverlay do
        first = first - 1
    end
    for i = first, #stack do
        stack[i]:draw()
    end
end

-- Sends an event to the top state. Returns true if it was consumed.
function StateManager.dispatch(event, ...)
    local top = stack[#stack]
    if not top then
        return false
    end
    return top[event](top, ...) == true
end

return StateManager
