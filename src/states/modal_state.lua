-- Overlay state showing a Modal dialog over the current screen.
-- See src/ui/modal.lua for the parameters.

local State = require("src.states.state")
local StateManager = require("src.core.state_manager")
local Input = require("src.core.input")
local Modal = require("src.ui.modal")

local ModalState = State.extend("modal")
ModalState.isOverlay = true

function ModalState:enter(params)
    self.params = params
    self.done = false
    self.modal = Modal.new(params, function(value) self:finish(value) end)
end

function ModalState:finish(value)
    if self.done then
        return
    end
    self.done = true
    StateManager.pop()
    if self.params.onResult then
        self.params.onResult(value)
    end
end

function ModalState:update(dt)
    self.modal.ui:update(dt)
end

function ModalState:draw()
    self.modal:draw()
end

function ModalState:action(action)
    if action == Input.Actions.BACK or action == Input.Actions.PAUSE then
        self:finish(self.params.cancelValue)
        return true
    end
    return self.modal.ui:action(action)
end

function ModalState:mousepressed(x, y, button)
    return self.modal.ui:mousepressed(x, y, button)
end

function ModalState:mousereleased(x, y, button)
    return self.modal.ui:mousereleased(x, y, button)
end

function ModalState:mousemoved(x, y)
    self.modal.ui:mousemoved(x, y)
end

return ModalState
