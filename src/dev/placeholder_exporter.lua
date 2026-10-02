-- Development tool: renders the code-drawn placeholder art into PNG files
-- with the exact names, sizes and frame layouts listed in assets_list.md.
-- They act as dummy assets and as templates for the real art.
--
--   love . --export-placeholders      (debug builds only)
--
-- Files are written to the LÖVE save folder under export/assets/;
-- tools/export_placeholders.sh copies them into the project's assets/
-- folder without overwriting existing files.

local Config = require("src.core.config")
local Logger = require("src.core.logger")
local Palette = require("src.graphics.palette")
local Placeholders = require("src.graphics.placeholders")
local Scene = require("src.gameplay.scene")
local Text = require("src.localization.text")
local Icons = require("src.ui.icons")

local Exporter = {}

local OUT = "export/assets/"
local VW, VH = Config.virtualWidth, Config.virtualHeight

local function save(path, w, h, drawFn)
    local canvas = love.graphics.newCanvas(w, h)
    canvas:setFilter("nearest", "nearest")
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    drawFn()
    love.graphics.pop()
    local full = OUT .. path
    love.filesystem.createDirectory(full:match("^(.*)/[^/]+$"))
    love.filesystem.write(full, canvas:newImageData():encode("png"))
    Logger.info("Exported %s (%dx%d)", path, w, h)
end

-- Backgrounds ---------------------------------------------------------------------------------

local GAMEPLAY_FLOOR_Y = 160
local MENU_FLOOR_Y = 300

local function exportBackgrounds()
    save("backgrounds/gameplay.png", VW, VH, function()
        Placeholders.drawGameplayBackground(VW, VH, GAMEPLAY_FLOOR_Y)
    end)
    save("backgrounds/menu.png", VW, VH, function()
        love.graphics.draw(Placeholders.getRoomBackground(VW, VH, MENU_FLOOR_Y), 0, 0)
    end)
    save("backgrounds/results.png", VW, VH, function()
        love.graphics.draw(Placeholders.getRoomBackground(VW, VH, MENU_FLOOR_Y), 0, 0)
        love.graphics.setColor(Palette.withAlpha(Palette.black, 0.45))
        love.graphics.rectangle("fill", 0, 0, VW, VH)
    end)
    -- Parallax layers: empty (transparent) until real art is added.
    save("backgrounds/gameplay_far.png", VW, VH, function() end)
    save("backgrounds/gameplay_near.png", VW, VH, function() end)
end

-- Scene and character -------------------------------------------------------------------------------

local function exportStages()
    save("sprites/hangman_stages.png", Scene.WIDTH * 7, Scene.HEIGHT, function()
        for stage = 0, 6 do
            love.graphics.push()
            love.graphics.translate(stage * Scene.WIDTH, 0)
            Scene.drawPlaceholderStage(stage)
            love.graphics.pop()
        end
    end)
end

local CHARACTER_FRAMES = {
    { mood = "calm" },
    { mood = "calm", blink = true },
    { mood = "happy" },
    { mood = "worried" },
    { mood = "scared" },
    { mood = "sad" },
    { mood = "calm", rx = 15, ry = 10 },   -- squash
    { mood = "calm", rx = 12, ry = 14 },   -- stretch
}

local function exportCharacter()
    save("sprites/character.png", 32 * 10, 32, function()
        for i, f in ipairs(CHARACTER_FRAMES) do
            Placeholders.drawCharacter({
                x = (i - 1) * 32 + 16, y = 16, rx = f.rx or 14, ry = f.ry or 12,
                mood = f.mood, blink = f.blink, lookX = 0, lookY = 0,
            })
        end
        Placeholders.drawFoot(8 * 32 + 16, 16)
        Placeholders.drawLeaf(9 * 32 + 16, 16, 9 * 32 + 16, 8)
    end)
end

-- UI -----------------------------------------------------------------------------------------------

local CURSOR = {
    "#...............", "##..............", "#W#.............", "#WW#............",
    "#WWW#...........", "#WWWW#..........", "#WWWWW#.........", "#WWWWWW#........",
    "#WWWWWWW#.......", "#WWWWW#####.....", "#WW#WW#.........", "#W#.#WW#........",
    "##..#WW#........", "#....#WW#.......", ".....#WW#.......", "......##........",
}

local function exportUI()
    save("ui/panel.png", 24, 24, function()
        Placeholders.drawFrame("panel", "normal", 0, 0, 24, 24)
    end)
    save("ui/button.png", 64, 16, function()
        for i, state in ipairs({ "normal", "hover", "pressed", "disabled" }) do
            Placeholders.drawFrame("button", state, (i - 1) * 16, 0, 16, 16)
        end
    end)
    save("ui/key.png", 64, 16, function()
        for i, state in ipairs({ "normal", "pressed", "correct", "wrong" }) do
            Placeholders.drawFrame("key", state, (i - 1) * 16, 0, 16, 16)
        end
    end)
    save("ui/cursor.png", 16, 16, function()
        for y, row in ipairs(CURSOR) do
            for x = 1, #row do
                local c = row:sub(x, x)
                if c ~= "." then
                    love.graphics.setColor(c == "#" and Palette.black or Palette.text)
                    love.graphics.rectangle("fill", x - 1, y - 1, 1, 1)
                end
            end
        end
    end)

    -- Title logos drawn with the pixel font at 3x (Arabic shaped correctly).
    local logoFont = love.graphics.newFont("assets/PixelAE/PixelAE-Bold.ttf", 30, "mono")
    logoFont:setFilter("nearest", "nearest")
    for file, title in pairs({ ["ui/logo_ar.png"] = "الرجل المشنوق", ["ui/logo_en.png"] = "HANGMAN" }) do
        local w = math.min(400, Text.measure(title, { font = logoFont }) + 12)
        save(file, w, 64, function()
            local opts = { font = logoFont, width = w, align = "center", color = Palette.primary,
                outlineColor = Palette.black, shadowColor = Palette.primaryDark, shadowX = 0, shadowY = 3 }
            Text.draw(title, 0, 12, opts)
        end)
    end
end

local ICON_COLORS = {
    heart = Palette.incorrect, heart_empty = Palette.textDim, hint = Palette.highlight,
    reveal = Palette.text, star = Palette.highlight, pause = Palette.text, back = Palette.text,
    sound = Palette.text, check = Palette.correct, cross = Palette.incorrect,
    lock = Palette.textDim, trophy = Palette.primary,
}

local function exportIcons()
    save("icons/icons.png", Icons.SIZE * #Icons.ORDER, Icons.SIZE, function()
        for i, name in ipairs(Icons.ORDER) do
            love.graphics.setColor(ICON_COLORS[name] or Palette.text)
            love.graphics.draw(Placeholders.getIcon(name), (i - 1) * Icons.SIZE, 0)
        end
    end)
end

function Exporter.run()
    exportBackgrounds()
    exportStages()
    exportCharacter()
    exportUI()
    exportIcons()
    Logger.info("Placeholder export finished: %s/%s", love.filesystem.getSaveDirectory(), OUT)
end

return Exporter
