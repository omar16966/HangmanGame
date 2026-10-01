-- Unified text API. Every piece of text in the game is drawn through here,
-- so Arabic shaping, bidi reordering, wrapping and alignment work the same
-- way everywhere.
--
--   Text.draw("ابدأ اللعب", x, y, { align = "center", width = 120 })
--   local w, h = Text.measure(str, { font = Assets.fonts.bold })
--
-- Pipeline (cached per string/font/width/direction):
--   UTF-8 -> codepoints -> Arabic shaping -> bidi levels -> line wrapping
--   -> visual reordering per line -> drawable strings
--
-- Options:
--   font            LÖVE Font (default: Assets.fonts.regular)
--   width           box width: enables wrapping and box alignment
--   wrap            false to disable wrapping even when width is given
--   height, valign  box height and "top" | "middle" | "bottom"
--   align           "left" | "center" | "right" | "start" | "end" (default "start")
--   alignDirection  "rtl" | "ltr": direction used to resolve start/end
--                   (default: the text's own direction)
--   direction       "rtl" | "ltr" | "auto" paragraph direction (default "auto")
--   color           text color (default white)
--   shadowColor     1px drop shadow color (offset with shadowX/shadowY, default 1,1)
--   outlineColor    1px outline color
--   lineHeight      line advance in pixels (default: the font's line height)

local Utf8 = require("src.localization.utf8_util")
local Shaper = require("src.localization.arabic_shaper")
local Bidi = require("src.localization.bidi")
local Assets = require("src.managers.asset_manager")

local Text = {}

local floor = math.floor
local SPACE = 0x20
local EMPTY = {}
local WHITE = { 1, 1, 1, 1 }

local CACHE_LIMIT = 800
local cache, cacheCount = {}, 0

-- Paragraph direction used when a string has no strong characters
-- (e.g. "123"). Set by the LocalizationManager from the interface language.
local defaultDirection = "ltr"

function Text.setDefaultDirection(direction)
    if direction ~= defaultDirection then
        defaultDirection = direction
        Text.clearCache()
    end
end

function Text.getDefaultDirection()
    return defaultDirection
end

function Text.clearCache()
    cache, cacheCount = {}, 0
end

-- Per-font glyph availability (memoized).
local fontInfo = setmetatable({}, { __mode = "k" })
local function getFontInfo(font)
    local info = fontInfo[font]
    if not info then
        local memo = {}
        info = {
            hasGlyph = function(cp)
                local v = memo[cp]
                if v == nil then
                    v = font:hasGlyphs(cp)
                    memo[cp] = v
                end
                return v
            end,
        }
        -- Drop Arabic diacritics when the font cannot draw them (PixelAE).
        info.stripMarks = not font:hasGlyphs(0x064E)
        fontInfo[font] = info
    end
    return info
end

function Text.getLineHeight(font)
    return floor(font:getHeight() * font:getLineHeight() + 0.5)
end

-- Distance from the top of a line to its visual middle. To center one line
-- of text on a point: Text.draw(str, x, centerY - Text.getCenterOffset(font, str)).
-- Latin capitals sit around 60% of the ascent; the body of Arabic letters
-- sits lower (around 80%), so Arabic strings get a larger offset.
function Text.getCenterOffset(font, str)
    local factor = 0.6
    if str and str:find("[\216-\219]") then -- UTF-8 lead bytes of U+0600-06FF
        factor = 0.8
    end
    return floor(font:getAscent() * factor + 0.5)
end

-- True when the font (or its fallbacks) can draw the codepoint.
function Text.hasGlyph(font, cp)
    return getFontInfo(font).hasGlyph(cp)
end

-- Layout --------------------------------------------------------------------------------------

local function measure(font, cps, first, last)
    if last < first then
        return 0
    end
    return font:getWidth(Utf8.encode(cps, first, last))
end

-- Splits one paragraph into line ranges {first, last} that fit maxWidth.
-- Breaks at spaces; a single word wider than the box is split by characters.
local function wrapRanges(font, cps, maxWidth)
    local n = #cps
    if not maxWidth or n == 0 then
        return { { 1, n } }
    end

    local words = {}
    local k = 1
    while k <= n do
        if cps[k] == SPACE then
            k = k + 1
        else
            local s = k
            while k <= n and cps[k] ~= SPACE do k = k + 1 end
            words[#words + 1] = { s, k - 1 }
        end
    end
    if #words == 0 then
        return { { 1, 0 } }
    end

    local ranges = {}
    local lineFirst, lineLast = nil, nil
    local w = 1
    while w <= #words do
        local s, e = words[w][1], words[w][2]
        if lineFirst == nil then
            if measure(font, cps, s, e) <= maxWidth then
                lineFirst, lineLast = s, e
            else
                -- Too long for any line: split the word itself.
                local a = s
                while a <= e do
                    local b = a
                    while b + 1 <= e and measure(font, cps, a, b + 1) <= maxWidth do
                        b = b + 1
                    end
                    if b < e then
                        ranges[#ranges + 1] = { a, b }
                    else
                        lineFirst, lineLast = a, b
                    end
                    a = b + 1
                end
            end
            w = w + 1
        elseif measure(font, cps, lineFirst, e) <= maxWidth then
            lineLast = e
            w = w + 1
        else
            ranges[#ranges + 1] = { lineFirst, lineLast }
            lineFirst, lineLast = nil, nil
        end
    end
    if lineFirst then
        ranges[#ranges + 1] = { lineFirst, lineLast }
    end
    return ranges
end

-- Returns a cached layout: { lines = { {text, width, direction} }, width,
-- height, lineHeight, direction }.
function Text.layout(str, font, maxWidth, direction)
    str = tostring(str)
    direction = direction or "auto"
    local key = str .. "\31" .. tostring(font) .. "\31" .. tostring(maxWidth) .. "\31" .. direction
    local cached = cache[key]
    if cached then
        return cached
    end

    local info = getFontInfo(font)
    local lineHeight = Text.getLineHeight(font)
    local lines = {}
    local maxLineWidth = 0
    local layoutDirection = nil

    for paragraph in (str .. "\n"):gmatch("(.-)\n") do
        local cps = Utf8.decode(paragraph)
        local shaped = Shaper.shape(cps, { stripMarks = info.stripMarks, hasGlyph = info.hasGlyph })
        local levels, baseLevel, classes = Bidi.resolveLevels(shaped, direction, defaultDirection)
        local paragraphDirection = baseLevel == 1 and "rtl" or "ltr"
        layoutDirection = layoutDirection or paragraphDirection

        for _, range in ipairs(wrapRanges(font, shaped, maxWidth)) do
            local visual = Bidi.reorderLine(shaped, levels, classes, baseLevel, range[1], range[2])
            local text = Utf8.encode(visual)
            local width = font:getWidth(text)
            if width > maxLineWidth then
                maxLineWidth = width
            end
            lines[#lines + 1] = { text = text, width = width, direction = paragraphDirection }
        end
    end

    local layout = {
        lines = lines,
        width = maxLineWidth,
        height = #lines * lineHeight,
        lineHeight = lineHeight,
        direction = layoutDirection or defaultDirection,
    }

    if cacheCount >= CACHE_LIMIT then
        Text.clearCache()
    end
    cache[key] = layout
    cacheCount = cacheCount + 1
    return layout
end

-- Drawing ---------------------------------------------------------------------------------------

local function resolveAlign(align, direction)
    if align == "start" then
        return direction == "rtl" and "right" or "left"
    elseif align == "end" then
        return direction == "rtl" and "left" or "right"
    end
    return align
end
Text.resolveAlign = resolveAlign

local function getLayout(str, opts)
    local font = opts.font or Assets.fonts.regular
    local wrapWidth = nil
    if opts.width and opts.wrap ~= false then
        wrapWidth = opts.width
    end
    return Text.layout(str, font, wrapWidth, opts.direction), font
end

-- Returns width, height (pixels) and the layout of a string.
function Text.measure(str, opts)
    opts = opts or EMPTY
    local layout = getLayout(str, opts)
    local lineHeight = opts.lineHeight or layout.lineHeight
    return layout.width, #layout.lines * lineHeight, layout
end

local function printLine(text, x, y, opts)
    if opts.outlineColor then
        love.graphics.setColor(opts.outlineColor)
        love.graphics.print(text, x - 1, y)
        love.graphics.print(text, x + 1, y)
        love.graphics.print(text, x, y - 1)
        love.graphics.print(text, x, y + 1)
    end
    if opts.shadowColor then
        love.graphics.setColor(opts.shadowColor)
        love.graphics.print(text, x + (opts.shadowX or 1), y + (opts.shadowY or 1))
    end
    love.graphics.setColor(opts.color or WHITE)
    love.graphics.print(text, x, y)
end

-- Draws a string. Without opts.width, x is the anchor point for the alignment
-- (left edge, center or right edge). Returns the drawn width and height.
function Text.draw(str, x, y, opts)
    opts = opts or EMPTY
    local layout, font = getLayout(str, opts)
    local lineHeight = opts.lineHeight or layout.lineHeight
    local totalHeight = #layout.lines * lineHeight
    local align = resolveAlign(opts.align or "start", opts.alignDirection or layout.direction)

    if opts.height then
        if opts.valign == "middle" then
            y = y + (opts.height - totalHeight) / 2
        elseif opts.valign == "bottom" then
            y = y + opts.height - totalHeight
        end
    end

    local r, g, b, a = love.graphics.getColor()
    love.graphics.setFont(font)
    for i, line in ipairs(layout.lines) do
        local lx = x
        if opts.width then
            if align == "center" then
                lx = x + (opts.width - line.width) / 2
            elseif align == "right" then
                lx = x + opts.width - line.width
            end
        elseif align == "center" then
            lx = x - line.width / 2
        elseif align == "right" then
            lx = x - line.width
        end
        printLine(line.text, floor(lx), floor(y + (i - 1) * lineHeight), opts)
    end
    love.graphics.setColor(r, g, b, a)
    return layout.width, totalHeight
end

return Text
