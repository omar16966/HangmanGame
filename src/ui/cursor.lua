-- Custom pixel-art mouse cursor (assets/ui/cursor.png, tip = top-left pixel).
-- Drawn on the virtual canvas, so it scales with the pixel art. The system
-- cursor is shown instead when the image is missing, when the option is off,
-- or while the pointer is over the letterbox bars.

local Config = require("src.core.config")
local Input = require("src.core.input")
local Assets = require("src.managers.asset_manager")

local Cursor = {}

local function active()
    return Config.graphics.customCursor and Assets.images.cursor ~= nil
end

function Cursor.update()
    if not active() then
        return
    end
    local _, _, inside = Input.getMousePosition()
    local systemVisible = not inside
    if love.mouse.isVisible() ~= systemVisible then
        love.mouse.setVisible(systemVisible)
    end
end

function Cursor.draw()
    if not active() then
        return
    end
    local x, y, inside = Input.getMousePosition()
    if inside and love.window.hasMouseFocus() then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(Assets.images.cursor, x, y)
    end
end

return Cursor
