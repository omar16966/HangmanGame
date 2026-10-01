-- Draws the puzzle answer as letter cells: hidden letters are underlines,
-- found letters appear with a small drop animation.
--
-- Arabic puzzles are laid out right to left, and every revealed letter is
-- drawn in the connected form it has inside the word. When two neighbouring
-- letters are both revealed, the joining stroke between their cells is drawn
-- too, so revealed parts of a word read like real connected Arabic.
--
-- Size adapts to the answer: large cells on one line when they fit,
-- otherwise small cells, wrapping by word if still needed.

local Assets = require("src.managers.asset_manager")
local Utf8 = require("src.localization.utf8_util")
local Shaper = require("src.localization.arabic_shaper")
local Text = require("src.localization.text")
local Palette = require("src.graphics.palette")

local WordDisplay = {}
WordDisplay.__index = WordDisplay

local SIZES = {
    -- scale: font pixels -> screen pixels (PixelAE is a 10px font).
    { fontKey = "title", cellW = 22, cellH = 34, gap = 4, wordGap = 16, lineGap = 6, scale = 2 },
    { fontKey = "regular", cellW = 12, cellH = 18, gap = 3, wordGap = 10, lineGap = 4, scale = 1 },
}
local DROP_TIME = 0.22

-- area: { centerX, y, maxWidth }
function WordDisplay.new(round, area)
    local self = setmetatable({}, WordDisplay)
    self.round = round
    self.area = area
    self.rtl = round.language == "ar"
    self.timers = {}
    self.finished = nil   -- "won" | "lost" once the round is over
    self:prepareGlyphs()
    self:layout()
    return self
end

-- Picks the glyph to draw for every cell (contextual Arabic forms).
function WordDisplay:prepareGlyphs()
    local cells = self.round.cells
    self.connects = {}
    if not self.rtl then
        for i, cell in ipairs(cells) do
            cell.glyph = Utf8.char(cell.cp)
        end
        return
    end
    for _, word in ipairs(self.round.words) do
        local cps = {}
        for i = word[1], word[2] do
            cps[#cps + 1] = cells[i].cp
        end
        local font = Assets.fonts.title
        local shaped = Shaper.shape(cps, {
            noLigatures = true,
            hasGlyph = function(cp) return Text.hasGlyph(font, cp) end,
        })
        local joins = Shaper.connections(cps)
        for k = 1, #cps do
            local index = word[1] + k - 1
            cells[index].glyph = Utf8.char(shaped[k] or cps[k])
            self.connects[index] = joins[k] and k < #cps
        end
    end
end

local function wordWidth(word, size)
    local count = word[2] - word[1] + 1
    return count * size.cellW + (count - 1) * size.gap
end

-- Groups words into lines that fit maxWidth. Returns nil if a single word
-- does not fit.
local function breakLines(words, size, maxWidth)
    local lines, current, currentW = {}, {}, 0
    for index, word in ipairs(words) do
        local w = wordWidth(word, size)
        if w > maxWidth then
            return nil
        end
        local extra = (#current > 0) and size.wordGap or 0
        if #current > 0 and currentW + extra + w > maxWidth then
            lines[#lines + 1] = { words = current, width = currentW }
            current, currentW = {}, 0
            extra = 0
        end
        current[#current + 1] = index
        currentW = currentW + extra + w
    end
    if #current > 0 then
        lines[#lines + 1] = { words = current, width = currentW }
    end
    return lines
end

function WordDisplay:layout()
    local words = self.round.words
    local maxWidth = self.area.maxWidth
    local size, lines = nil, nil
    for i, candidate in ipairs(SIZES) do
        lines = breakLines(words, candidate, maxWidth)
        size = candidate
        -- Large cells only when the whole answer fits on one line.
        if lines and (#lines == 1 or i == #SIZES) then
            break
        end
    end
    if not lines then
        -- Last resort: one word per line, even if it overflows.
        lines = {}
        for index, word in ipairs(words) do
            lines[#lines + 1] = { words = { index }, width = wordWidth(word, size) }
        end
    end

    self.size = size
    self.font = Assets.fonts[size.fontKey]
    self.lines = lines
    self.height = #lines * size.cellH + (#lines - 1) * size.lineGap

    local cells = self.round.cells
    for li, line in ipairs(lines) do
        local y = self.area.y + (li - 1) * (size.cellH + size.lineGap)
        local left = math.floor(self.area.centerX - line.width / 2)
        local right = left + line.width
        local cursor = self.rtl and right or left
        for _, wordIndex in ipairs(line.words) do
            local word = words[wordIndex]
            for i = word[1], word[2] do
                local cell = cells[i]
                if self.rtl then
                    cell.x = cursor - size.cellW
                    cursor = cursor - size.cellW - size.gap
                else
                    cell.x = cursor
                    cursor = cursor + size.cellW + size.gap
                end
                cell.y = y
            end
            -- Replace the last letter gap with the word gap.
            if self.rtl then
                cursor = cursor + size.gap - size.wordGap
            else
                cursor = cursor - size.gap + size.wordGap
            end
        end
    end
end

function WordDisplay:getHeight()
    return self.height
end

function WordDisplay:onReveal(positions)
    for _, index in ipairs(positions or {}) do
        self.timers[index] = 0
    end
end

function WordDisplay:setFinished(result)
    self.finished = result
    for i, cell in ipairs(self.round.cells) do
        if cell.revealedBy == "end" and not self.timers[i] then
            self.timers[i] = 0
        end
    end
end

function WordDisplay:update(dt)
    for index, t in pairs(self.timers) do
        if t < DROP_TIME then
            self.timers[index] = math.min(DROP_TIME, t + dt)
        end
    end
end

local function colorFor(self, cell)
    if cell.revealedBy == "end" then
        return Palette.incorrect
    end
    if self.finished == "won" then
        return Palette.correct
    end
    if cell.revealedBy == "hint" then
        return Palette.secondary
    end
    return Palette.text
end

-- Glyph box (x, width) of a revealed cell, used for joining strokes.
local function glyphBox(self, cell)
    local w = self.font:getWidth(cell.glyph)
    return cell.x + math.floor((self.size.cellW - w) / 2), w
end

function WordDisplay:draw()
    local size, font = self.size, self.font
    local cells = self.round.cells
    local stroke = size.scale
    -- Baseline above the underline, leaving room for descenders
    -- (Arabic letters go 5 font pixels below the baseline, Latin 3).
    local descent = (self.rtl and 5 or 3) * size.scale
    local baseline = size.cellH - stroke - 1 - descent
    local glyphTop = baseline - font:getAscent()

    love.graphics.setFont(font)
    for i, cell in ipairs(cells) do
        if cell.isLetter then
            love.graphics.setColor(cell.revealed and Palette.textDim or Palette.text)
            love.graphics.rectangle("fill", cell.x, cell.y + size.cellH - stroke, size.cellW, stroke)
        end
        if cell.revealed then
            local t = self.timers[i]
            local drop = 0
            if t then
                local k = 1 - t / DROP_TIME
                drop = -math.floor(6 * k * k)
            end
            local gx = glyphBox(self, cell)
            local color = colorFor(self, cell)
            love.graphics.setColor(Palette.black)
            love.graphics.print(cell.glyph, gx + 1, cell.y + glyphTop + drop + 1)
            love.graphics.setColor(color)
            love.graphics.print(cell.glyph, gx, cell.y + glyphTop + drop)

            -- Arabic joining stroke towards the next letter of the word.
            local nextCell = cells[i + 1]
            local settled = not (t and t < DROP_TIME)
                and not (self.timers[i + 1] and self.timers[i + 1] < DROP_TIME)
            if self.connects[i] and nextCell and nextCell.revealed and nextCell.y == cell.y and settled then
                local nx, nw = glyphBox(self, nextCell)
                local x1 = nx + nw - 1
                local x2 = gx + 1
                if x2 > x1 then
                    local by = cell.y + baseline
                    love.graphics.setColor(Palette.black)
                    love.graphics.rectangle("fill", x1, by - stroke + 1, x2 - x1, stroke)
                    love.graphics.setColor(color)
                    love.graphics.rectangle("fill", x1, by - stroke, x2 - x1, stroke)
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return WordDisplay
