-- UI skin: draws panels, buttons and keyboard keys from the 9-slice images
-- in assets/ui when they exist, otherwise from the code placeholders.
-- Replacing the art never requires code changes (see ASSETS.md for frame
-- order and corner sizes).

local Assets = require("src.managers.asset_manager")
local NineSlice = require("src.graphics.nine_slice")
local Placeholders = require("src.graphics.placeholders")
local Palette = require("src.graphics.palette")

local Skin = {}

-- image key, frame size, corner size, state -> frame index
local STYLES = {
    panel = { image = "panel", frame = 24, corner = 8, frames = { normal = 1 } },
    button = { image = "button", frame = 16, corner = 4,
        frames = { normal = 1, hover = 2, focused = 2, pressed = 3, disabled = 4 } },
    key = { image = "key", frame = 16, corner = 5,
        frames = { normal = 1, hover = 1, focused = 1, pressed = 2, correct = 3, wrong = 4, hint = 3, disabled = 4 } },
}

local slices = {}

local function getSlice(style)
    local def = STYLES[style]
    if slices[style] == nil then
        local image = Assets.images[def.image]
        slices[style] = image and NineSlice.new(image, def.frame, def.frame, def.corner) or false
    end
    return slices[style]
end

function Skin.drawFrame(style, state, x, y, w, h)
    local slice = getSlice(style)
    if slice then
        love.graphics.setColor(1, 1, 1, 1)
        slice:draw(STYLES[style].frames[state] or 1, x, y, w, h)
        -- Image frames have no separate hover/focus look for keys: add a light overlay.
        if style == "key" and (state == "hover" or state == "focused") then
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
        end
    else
        Placeholders.drawFrame(style, state, x, y, w, h)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draws a 1px focus outline (keyboard navigation), outside the frame.
function Skin.drawFocus(x, y, w, h)
    love.graphics.setColor(Palette.highlight)
    love.graphics.rectangle("line", math.floor(x) - 1.5, math.floor(y) - 1.5, math.floor(w) + 3, math.floor(h) + 3)
    love.graphics.setColor(1, 1, 1, 1)
end

-- How many pixels the content of a frame moves down in a given state
-- (pressed buttons look pushed in).
function Skin.contentOffset(state)
    if state == "pressed" then
        return 2
    elseif state == "wrong" then
        return 2
    elseif state == "correct" or state == "hint" or state == "disabled" then
        return 1
    end
    return 0
end

return Skin
