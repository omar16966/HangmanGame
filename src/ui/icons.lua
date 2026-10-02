-- Icons (16x16). Uses assets/icons/icons.png when present (one row of
-- 16x16 frames in the order below), otherwise built-in placeholder bitmaps.
--   Icons.draw("heart", x, y, color, mirror)

local Assets = require("src.managers.asset_manager")
local Placeholders = require("src.graphics.placeholders")

local Icons = {}

Icons.SIZE = 16
Icons.ORDER = {
    "heart", "heart_empty", "hint", "reveal", "star", "pause",
    "back", "sound", "check", "cross", "lock", "trophy",
}

local quads = nil
local function getQuad(name)
    local image = Assets.images.icons
    if not image then
        return nil
    end
    if not quads then
        quads = {}
        local iw, ih = image:getDimensions()
        for i, iconName in ipairs(Icons.ORDER) do
            if i * Icons.SIZE <= iw then
                quads[iconName] = love.graphics.newQuad((i - 1) * Icons.SIZE, 0, Icons.SIZE, Icons.SIZE, iw, ih)
            end
        end
    end
    return quads[name]
end

-- mirror = true flips the icon horizontally (directional icons in RTL).
-- Sheet icons are drawn in their own colors (darkened when `dimmed`);
-- placeholder icons use `color`.
function Icons.draw(name, x, y, color, mirror, dimmed)
    x, y = math.floor(x), math.floor(y)
    local sx, ox = 1, 0
    if mirror then
        sx, ox = -1, Icons.SIZE
    end
    local quad = getQuad(name)
    if quad then
        local v = dimmed and 0.45 or 1
        love.graphics.setColor(v, v, v, color and color[4] or 1)
        love.graphics.draw(Assets.images.icons, quad, x + ox, y, 0, sx, 1)
    else
        local image = Placeholders.getIcon(name)
        if image then
            love.graphics.setColor(color or { 1, 1, 1, 1 })
            love.graphics.draw(image, x + ox, y, 0, sx, 1)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Icons
