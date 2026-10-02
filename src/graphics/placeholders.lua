-- Placeholder art drawn in code. Used only while the matching image asset
-- is missing (see ASSETS.md). Every function here can be replaced by real
-- art without touching game logic: callers check Assets first.

local Palette = require("src.graphics.palette")
local Utils = require("src.core.utils")

local Placeholders = {}

local floor = math.floor

local function rect(color, x, y, w, h)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, w, h)
end

-- Backgrounds -------------------------------------------------------------------------------

local backgroundCache = {}

-- A wooden room: plank wall with dithered shading, and a floor.
local function buildRoom(w, h, floorY)
    local canvas = love.graphics.newCanvas(w, h)
    canvas:setFilter("nearest", "nearest")
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.clear(Palette.backgroundDeep)

    -- Wall planks.
    local plankW = 40
    for x = 0, w, plankW do
        local shade = (x / plankW) % 2 == 0 and Palette.background or Palette.backgroundDeep
        rect(shade, x, 0, plankW, floorY)
        rect(Palette.black, x, 0, 1, floorY)
    end

    -- Dithered darkening towards the top and the sides (cheap vignette).
    love.graphics.setColor(Palette.black)
    for y = 0, floorY - 1 do
        local t = 1 - y / floorY
        for x = 0, w - 1 do
            local side = math.abs(x - w / 2) / (w / 2)
            local v = math.max(t * 0.9, side * side * 0.8)
            local threshold = ((x % 2) * 2 + (y % 2)) / 4 + 0.125 -- 2x2 ordered dither
            if v > threshold + 0.35 then
                love.graphics.rectangle("fill", x, y, 1, 1)
            end
        end
    end

    -- Floor.
    rect(Palette.woodDark, 0, floorY, w, h - floorY)
    rect(Palette.wood, 0, floorY, w, 2)
    rect(Palette.black, 0, floorY + 2, w, 1)
    for y = floorY + 8, h, 8 do
        rect(Palette.black, 0, y, w, 1)
    end

    love.graphics.pop()
    return canvas
end

-- Returns a cached background canvas for a placeholder room.
function Placeholders.getRoomBackground(w, h, floorY)
    local key = w .. "x" .. h .. ":" .. floorY
    if not backgroundCache[key] then
        backgroundCache[key] = buildRoom(w, h, floorY)
    end
    return backgroundCache[key]
end

-- Gameplay background: the room down to the floor, then a dark band behind
-- the word, keyboard and buttons.
function Placeholders.drawGameplayBackground(w, h, floorY)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Placeholders.getRoomBackground(w, floorY + 14, floorY), 0, 0)
    rect(Palette.backgroundDeep, 0, floorY + 14, w, h - floorY - 14)
    rect(Palette.black, 0, floorY + 14, w, 1)
end

-- UI frames -----------------------------------------------------------------------------------

-- style: "panel" | "button" | "key"
-- state: "normal" | "hover" | "pressed" | "disabled" | "focused" |
--        "correct" | "wrong" | "hint"
function Placeholders.drawFrame(style, state, x, y, w, h)
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)

    if style == "panel" then
        rect(Palette.panelBorder, x, y, w, h)
        rect(Palette.panel, x + 1, y + 1, w - 2, h - 2)
        rect(Palette.panelHighlight, x + 2, y + 1, w - 4, 1)
        rect(Palette.shadow, x + 2, y + h - 2, w - 4, 1)
        return
    end

    local fill, top, depth = Palette.panelLight, Palette.panelHighlight, 2
    if state == "hover" or state == "focused" then
        fill, top = Palette.panelHighlight, Palette.textDim
    elseif state == "pressed" then
        depth = 0
    elseif state == "disabled" then
        fill, top, depth = Palette.panel, Palette.panel, 1
    elseif state == "correct" then
        fill, top, depth = Palette.correctDark, Palette.correct, 1
    elseif state == "wrong" then
        fill, top, depth = Palette.incorrectDark, Palette.incorrectDark, 0
    elseif state == "hint" then
        fill, top, depth = Palette.secondaryDark, Palette.secondary, 1
    end

    local offset = 2 - depth -- pressed keys sit lower
    rect(Palette.panelBorder, x, y + offset, w, h - offset)
    rect(Palette.shadow, x + 1, y + h - depth - 1, w - 2, depth)
    rect(fill, x + 1, y + offset + 1, w - 2, h - offset - depth - 2)
    rect(top, x + 2, y + offset + 1, w - 4, 1)
end

-- Icons ------------------------------------------------------------------------------------------

-- 8x8 bitmaps drawn at 2x (16x16). "#" = pixel.
local ICON_BITMAPS = {
    heart = { "........", ".##.##..", "#######.", "#######.", ".#####..", "..###...", "...#....", "........" },
    heart_empty = { "........", ".##.##..", "#..#..#.", "#.....#.", ".#...#..", "..#.#...", "...#....", "........" },
    hint = { "..###...", ".#...#..", ".#...#..", ".#...#..", "..#.#...", "..###...", "..###...", "........" },
    reveal = { "........", "..###...", ".#...#..", "#..#..#.", ".#...#..", "..###...", "........", "........" },
    star = { "...#....", "...#....", "#######.", ".#####..", "..###...", ".##.##..", "##...##.", "........" },
    pause = { "........", ".##.##..", ".##.##..", ".##.##..", ".##.##..", ".##.##..", ".##.##..", "........" },
    back = { "...#....", "..##....", ".######.", "#######.", ".######.", "..##....", "...#....", "........" },
    sound = { "...#....", "..##..#.", "####.#..", "####.#..", "####.#..", "..##..#.", "...#....", "........" },
    check = { "........", "......##", ".....##.", "#...##..", "##.##...", ".###....", "..#.....", "........" },
    cross = { "........", ".#....#.", "..#..#..", "...##...", "...##...", "..#..#..", ".#....#.", "........" },
    lock = { "..###...", ".#...#..", ".#...#..", "#######.", "###.###.", "###.###.", "#######.", "........" },
    trophy = { "#######.", "#.###.#.", ".#####..", "..###...", "...#....", "..###...", ".#####..", "........" },
}

local iconImages = {}

-- Returns a 16x16 white-on-transparent Image for an icon name (tint it with setColor).
function Placeholders.getIcon(name)
    if iconImages[name] then
        return iconImages[name]
    end
    local bitmap = ICON_BITMAPS[name]
    if not bitmap then
        return nil
    end
    local data = love.image.newImageData(16, 16)
    for row, line in ipairs(bitmap) do
        for col = 1, #line do
            if line:sub(col, col) == "#" then
                for dy = 0, 1 do
                    for dx = 0, 1 do
                        data:setPixel((col - 1) * 2 + dx, (row - 1) * 2 + dy, 1, 1, 1, 1)
                    end
                end
            end
        end
    end
    local image = love.graphics.newImage(data)
    image:setFilter("nearest", "nearest")
    iconImages[name] = image
    return image
end

-- Scene: wooden frame ----------------------------------------------------------------------------

function Placeholders.drawPlank(x, y, w, h)
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    rect(Palette.black, x - 1, y - 1, w + 2, h + 2)
    rect(Palette.wood, x, y, w, h)
    rect(Palette.woodLight, x, y, w, 1)
    rect(Palette.woodDark, x, y + h - 1, w, 1)
    -- Grain.
    love.graphics.setColor(Palette.woodDark)
    if w > h then
        for gx = x + 5, x + w - 6, 11 do
            love.graphics.rectangle("fill", gx, y + floor(h / 2), 4, 1)
        end
    else
        for gy = y + 6, y + h - 6, 13 do
            love.graphics.rectangle("fill", x + floor(w / 2), gy, 1, 4)
        end
    end
end

-- A diagonal brace made of stepped pixel blocks between two points.
function Placeholders.drawBrace(x1, y1, x2, y2, thickness)
    local steps = math.max(math.abs(x2 - x1), math.abs(y2 - y1))
    love.graphics.setColor(Palette.black)
    for i = 0, steps do
        local t = i / steps
        love.graphics.rectangle("fill", floor(x1 + (x2 - x1) * t) - 1, floor(y1 + (y2 - y1) * t) - 1,
            thickness + 2, thickness + 2)
    end
    love.graphics.setColor(Palette.wood)
    for i = 0, steps do
        local t = i / steps
        love.graphics.rectangle("fill", floor(x1 + (x2 - x1) * t), floor(y1 + (y2 - y1) * t), thickness, thickness)
    end
end

-- Scene: character ---------------------------------------------------------------------------------

local BODY = Utils.hexColor("#7fb8e0")
local BODY_DARK = Utils.hexColor("#4f7fa8")
local BODY_LIGHT = Utils.hexColor("#b5dcf5")
local CHEEK = Utils.hexColor("#f29bb0")
local LEAF = Utils.hexColor("#7bd66f")
local LEAF_DARK = Utils.hexColor("#3f8f45")

local function ellipse(color, cx, cy, rx, ry)
    love.graphics.setColor(color)
    love.graphics.ellipse("fill", cx, cy, rx, ry, 24)
end

local function drawMouth(mood, mx, my)
    love.graphics.setColor(Palette.black)
    if mood == "happy" then
        rect(Palette.black, mx - 3, my, 1, 1)
        rect(Palette.black, mx + 3, my, 1, 1)
        rect(Palette.black, mx - 2, my + 1, 5, 1)
        rect(Palette.incorrect, mx - 1, my + 2, 3, 1)
    elseif mood == "scared" then
        rect(Palette.black, mx - 1, my - 1, 3, 4)
        rect(Palette.incorrectDark, mx, my, 1, 2)
    elseif mood == "worried" then
        rect(Palette.black, mx - 2, my + 1, 1, 1)
        rect(Palette.black, mx - 1, my, 3, 1)
        rect(Palette.black, mx + 2, my + 1, 1, 1)
    elseif mood == "sad" then
        rect(Palette.black, mx - 2, my + 1, 1, 1)
        rect(Palette.black, mx - 1, my, 3, 1)
        rect(Palette.black, mx + 2, my + 1, 1, 1)
        rect(BODY_DARK, mx - 1, my + 1, 3, 1)
    else -- calm
        rect(Palette.black, mx - 2, my, 1, 1)
        rect(Palette.black, mx - 1, my + 1, 3, 1)
        rect(Palette.black, mx + 2, my, 1, 1)
    end
end

function Placeholders.drawFoot(fx, fy)
    ellipse(Palette.black, floor(fx), floor(fy), 5, 3)
    ellipse(BODY_DARK, floor(fx), floor(fy) - 1, 4, 2)
end

-- Leaf on the head: stem from (x1, y1) to the leaf at (x2, y2).
function Placeholders.drawLeaf(x1, y1, x2, y2)
    love.graphics.setColor(LEAF_DARK)
    love.graphics.setLineWidth(1)
    love.graphics.line(floor(x1) + 0.5, floor(y1) + 0.5, floor(x2) + 0.5, floor(y2) + 0.5)
    ellipse(LEAF_DARK, floor(x2), floor(y2), 4, 3)
    ellipse(LEAF, floor(x2), floor(y2) - 1, 3, 2)
end

-- A sweat drop (also drawn over sprite art).
function Placeholders.drawSweat(sx, sy)
    sx, sy = floor(sx), floor(sy)
    rect(Palette.white, sx, sy, 1, 1)
    rect(BODY_LIGHT, sx - 1, sy + 1, 3, 2)
    rect(BODY_LIGHT, sx, sy + 3, 1, 1)
end

-- The rope tied around the character's waist (also used over sprite art).
function Placeholders.drawBelt(p)
    local x, y, rx, ry = floor(p.x), floor(p.y), p.rx, p.ry
    rect(Palette.black, x - rx, y + floor(ry / 3) - 1, rx * 2 + 1, 4)
    rect(Palette.rope, x - rx, y + floor(ry / 3), rx * 2 + 1, 2)
    rect(Palette.woodDark, x - 1, y + floor(ry / 3) - 1, 3, 4)
end

-- Draws the character from a pose computed by the physics (Character module):
--   x, y          body center (whole pixels)
--   rx, ry        body radii (squash & stretch)
--   mood          calm | happy | worried | scared | sad
--   blink         true while the eyes are closed
--   lookX, lookY  pupil offset (-1..1)
--   feet          { {x, y}, {x, y} }
--   leaf          { x1, y1, x2, y2 } leaf stem on the head (spring physics)
--   sweat         nil or { x, y } sweat drop position
--   belt          true when the rope is tied around the waist
function Placeholders.drawCharacter(p)
    local x, y, rx, ry = floor(p.x), floor(p.y), p.rx, p.ry

    -- Feet behind the body (optional: sprite export draws parts separately).
    for _, f in ipairs(p.feet or {}) do
        Placeholders.drawFoot(f[1], f[2])
    end
    if p.leaf then
        Placeholders.drawLeaf(p.leaf[1], p.leaf[2], p.leaf[3], p.leaf[4])
    end

    -- Body: outline, shade, fill, highlight.
    ellipse(Palette.black, x, y, rx + 1, ry + 1)
    ellipse(BODY_DARK, x, y, rx, ry)
    ellipse(BODY, x - 1, y - 1, rx - 1, ry - 1)
    ellipse(BODY_LIGHT, x - floor(rx / 2), y - floor(ry / 2), 3, 2)

    -- Eyes.
    local eyeY = y - floor(ry / 4)
    local eyeDX = floor(rx / 2.6)
    for _, ex in ipairs({ x - eyeDX, x + eyeDX }) do
        if p.blink then
            rect(Palette.black, ex - 2, eyeY + 1, 4, 1)
        else
            rect(Palette.white, ex - 2, eyeY - 2, 4, 5)
            rect(Palette.black, ex - 1 + floor(p.lookX + 0.5), eyeY - 1 + floor(p.lookY + 0.5), 2, 3)
        end
    end
    if p.mood == "worried" or p.mood == "scared" or p.mood == "sad" then
        -- Eyebrows tilted up in the middle.
        rect(Palette.black, x - eyeDX - 2, eyeY - 4, 2, 1)
        rect(Palette.black, x - eyeDX, eyeY - 5, 2, 1)
        rect(Palette.black, x + eyeDX - 2, eyeY - 5, 2, 1)
        rect(Palette.black, x + eyeDX, eyeY - 4, 2, 1)
    end

    -- Cheeks and mouth.
    rect(CHEEK, x - eyeDX - 4, eyeY + 4, 3, 1)
    rect(CHEEK, x + eyeDX + 2, eyeY + 4, 3, 1)
    drawMouth(p.mood, x, eyeY + 5)

    if p.belt then
        Placeholders.drawBelt(p)
    end

    if p.sweat then
        Placeholders.drawSweat(p.sweat[1], p.sweat[2])
    end
end

return Placeholders
