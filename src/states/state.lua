-- Base for every game state. A state only overrides the callbacks it needs.
--
--   local MyState = State.extend("my_state")
--   function MyState:enter(params) ... end
--
-- Input callbacks return true when they consumed the event; for keypressed
-- that stops the key from also being turned into actions.
--
-- Flags:
--   isOverlay  - drawn on top of the state below it (e.g. pause menu).
--   updateBelow - the state below keeps updating while this one is on top.

local State = {}
State.__index = State

function State.extend(name)
    local state = setmetatable({}, State)
    state.name = name
    state.isOverlay = false
    state.updateBelow = false
    return state
end

function State:enter(params) end
function State:exit() end
-- Called when a state pushed above this one is popped.
function State:resume() end
function State:update(dt) end
function State:draw() end

function State:action(action, isRepeat) return false end
function State:keypressed(key, scancode, isRepeat) return false end
function State:keyreleased(key, scancode) return false end
function State:textinput(text) return false end
function State:mousepressed(x, y, button, inside) return false end
function State:mousereleased(x, y, button, inside) return false end
function State:mousemoved(x, y, dx, dy, inside) return false end
function State:wheelmoved(dx, dy) return false end

-- Extra lines for the debug overlay (list of strings) or nil.
function State:debugInfo() return nil end

return State
