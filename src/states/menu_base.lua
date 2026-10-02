-- Shared behaviour for menu-like states: a UIManager for widgets, a
-- background, and a Back button on the start side of the interface.
--
--   local MyState = MenuBase.extend("my_state")
--   function MyState:build(params) ... self.ui:add(...) ... end
--   function MyState:back() ... end              -- BACK / Esc / Back button
--   function MyState:drawContent() ... end

local State = require("src.states.state")
local Config = require("src.core.config")
local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")
local Localization = require("src.managers.localization_manager")
local Placeholders = require("src.graphics.placeholders")
local UIManager = require("src.ui.ui_manager")
local Button = require("src.ui.button")

local MenuBase = {}

local VW, VH = Config.virtualWidth, Config.virtualHeight
MenuBase.MARGIN = 12
MenuBase.MENU_FLOOR_Y = 300

-- Draws a background image, or the placeholder room when it is missing.
function MenuBase.drawBackground(imageKey)
    local image = Assets.images[imageKey]
    love.graphics.setColor(1, 1, 1, 1)
    if image then
        love.graphics.draw(image, 0, 0)
    else
        love.graphics.draw(Placeholders.getRoomBackground(VW, VH, MenuBase.MENU_FLOOR_Y), 0, 0)
    end
end

-- A Back button (arrow icon mirrored in RTL) kept at the bottom start corner.
function MenuBase.makeBackButton(onClick)
    return Button.new({ w = 70, h = 20, autoWidth = true, textKey = "BACK",
        icon = "back", iconDirectional = true, onClick = onClick })
end

function MenuBase.placeBackButton(button)
    button:fit()
    if Localization.isRTL() then
        button:setPosition(VW - MenuBase.MARGIN - button.w, VH - MenuBase.MARGIN - button.h)
    else
        button:setPosition(MenuBase.MARGIN, VH - MenuBase.MARGIN - button.h)
    end
end

local methods = {}

function methods:enter(params)
    self.params = params or {}
    self.ui = UIManager.new()
    self:build(self.params)
    if not self.ui:getFocused() then
        self.ui:focusFirst()
    end
end

function methods:build(params) end
function methods:back() end
function methods:onUpdate(dt) end
function methods:drawContent() end

function methods:update(dt)
    if self.backButton then
        MenuBase.placeBackButton(self.backButton)
    end
    self.ui:update(dt)
    self:onUpdate(dt)
end

function methods:draw()
    self:drawContent()
    self.ui:draw()
end

function methods:action(action)
    if self.ui:action(action) then
        return true
    end
    if action == Input.Actions.BACK then
        self:back()
        return true
    end
    return false
end

function methods:mousepressed(x, y, button)
    return self.ui:mousepressed(x, y, button)
end

function methods:mousereleased(x, y, button)
    return self.ui:mousereleased(x, y, button)
end

function methods:mousemoved(x, y)
    self.ui:mousemoved(x, y)
end

function MenuBase.extend(name)
    local state = State.extend(name)
    for k, fn in pairs(methods) do
        state[k] = fn
    end
    return state
end

return MenuBase
