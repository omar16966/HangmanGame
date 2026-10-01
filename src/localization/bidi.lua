-- Bidirectional text (a compact implementation of the Unicode Bidi
-- Algorithm, UAX #9, without explicit embedding/isolate controls).
--
-- Converts a line of text from *logical* order (the order it is typed and
-- stored) to *visual* order (the order glyphs are drawn left to right):
--   * Arabic runs are reversed (right-to-left)
--   * English words and numbers inside Arabic text stay left-to-right
--   * punctuation and spaces take the direction of the text around them
--   * brackets are mirrored inside right-to-left runs
--
-- Usage:
--   local levels, baseLevel, classes = Bidi.resolveLevels(cps, "auto")
--   local visual = Bidi.reorderLine(cps, levels, classes, baseLevel, first, last)
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Bidi = {}

-- Bidi character classes --------------------------------------------------------------

local ASCII_CLASS = {
    [0x09] = "S", [0x0A] = "B", [0x0D] = "B", [0x0B] = "S", [0x0C] = "WS", [0x1C] = "B",
    [0x20] = "WS",
    [0x23] = "ET", [0x24] = "ET", [0x25] = "ET",   -- # $ %
    [0x2B] = "ES", [0x2D] = "ES",                  -- + -
    [0x2C] = "CS", [0x2E] = "CS", [0x2F] = "CS", [0x3A] = "CS", -- , . / :
}

local function inRange(cp, a, b)
    return cp >= a and cp <= b
end

function Bidi.classify(cp)
    if cp < 0x80 then
        if (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A) then return "L" end
        if cp >= 0x30 and cp <= 0x39 then return "EN" end
        local c = ASCII_CLASS[cp]
        if c then return c end
        if cp < 0x20 or cp == 0x7F then return "BN" end
        return "ON"
    end

    -- Latin-1 punctuation and symbols
    if cp == 0xA0 then return "CS" end
    if inRange(cp, 0xA2, 0xA5) or cp == 0xB0 or cp == 0xB1 then return "ET" end
    if cp == 0xB2 or cp == 0xB3 or cp == 0xB9 then return "EN" end
    if inRange(cp, 0xA1, 0xBF) or cp == 0xD7 or cp == 0xF7 then return "ON" end

    -- Combining marks
    if inRange(cp, 0x0300, 0x036F) then return "NSM" end

    -- Hebrew
    if inRange(cp, 0x0591, 0x05C7) then return "NSM" end
    if inRange(cp, 0x0590, 0x05FF) or inRange(cp, 0xFB1D, 0xFB4F) then return "R" end

    -- Arabic
    if inRange(cp, 0x0600, 0x08FF) then
        if inRange(cp, 0x0660, 0x0669) or cp == 0x066B or cp == 0x066C or inRange(cp, 0x0600, 0x0605) then
            return "AN"
        end
        if inRange(cp, 0x06F0, 0x06F9) then return "EN" end
        if cp == 0x066A then return "ET" end          -- ٪
        if cp == 0x060C then return "CS" end          -- ،
        if inRange(cp, 0x0610, 0x061A) or inRange(cp, 0x064B, 0x065F) or cp == 0x0670
            or inRange(cp, 0x06D6, 0x06DC) or inRange(cp, 0x06DF, 0x06E4)
            or cp == 0x06E7 or cp == 0x06E8 or inRange(cp, 0x06EA, 0x06ED) then
            return "NSM"
        end
        if inRange(cp, 0x07C0, 0x085F) then return "R" end
        return "AL"
    end
    if inRange(cp, 0xFB50, 0xFDFF) or inRange(cp, 0xFE70, 0xFEFE) then return "AL" end

    -- General punctuation, symbols
    if cp == 0x200E then return "L" end      -- LRM
    if cp == 0x200F then return "R" end      -- RLM
    if inRange(cp, 0x200B, 0x200D) then return "BN" end
    if inRange(cp, 0x2000, 0x200A) then return "WS" end
    if cp == 0x2028 then return "WS" end
    if cp == 0x2029 then return "B" end
    if inRange(cp, 0x2030, 0x2034) or inRange(cp, 0x20A0, 0x20CF) then return "ET" end
    if inRange(cp, 0x2010, 0x2BFF) then return "ON" end
    if inRange(cp, 0x3000, 0x303F) then return cp == 0x3000 and "WS" or "ON" end

    return "L"
end

-- Detects the paragraph direction from the first strong character.
-- Returns "rtl", "ltr" or nil when the text has no strong character.
function Bidi.detectDirection(cps)
    for i = 1, #cps do
        local c = Bidi.classify(cps[i])
        if c == "L" then return "ltr" end
        if c == "R" or c == "AL" then return "rtl" end
    end
    return nil
end

-- Level resolution ----------------------------------------------------------------------

local function isNeutral(t)
    return t == "ON" or t == "WS" or t == "B" or t == "S" or t == "BN"
end

-- direction: "rtl", "ltr" or "auto" (auto falls back to `fallback`, default "ltr").
-- Returns levels (array), baseLevel and the original classes (needed by reorderLine).
function Bidi.resolveLevels(cps, direction, fallback)
    local n = #cps
    local classes, types = {}, {}
    for i = 1, n do
        classes[i] = Bidi.classify(cps[i])
        types[i] = classes[i]
    end

    if direction ~= "rtl" and direction ~= "ltr" then
        direction = Bidi.detectDirection(cps) or fallback or "ltr"
    end
    local baseLevel = direction == "rtl" and 1 or 0
    local sor = baseLevel == 1 and "R" or "L"

    -- W1: non-spacing marks take the type of the previous character.
    for i = 1, n do
        if types[i] == "NSM" then
            types[i] = i > 1 and types[i - 1] or sor
        end
    end

    -- W2: European numbers after Arabic letters become Arabic numbers.
    local lastStrong = sor
    for i = 1, n do
        local t = types[i]
        if t == "L" or t == "R" or t == "AL" then
            lastStrong = t
        elseif t == "EN" and lastStrong == "AL" then
            types[i] = "AN"
        end
    end

    -- W3: AL -> R.
    for i = 1, n do
        if types[i] == "AL" then types[i] = "R" end
    end

    -- W4: a single separator between two numbers of the same kind joins them.
    for i = 2, n - 1 do
        local t, a, b = types[i], types[i - 1], types[i + 1]
        if t == "ES" and a == "EN" and b == "EN" then
            types[i] = "EN"
        elseif t == "CS" and a == b and (a == "EN" or a == "AN") then
            types[i] = a
        end
    end

    -- W5: terminators (%, $, ...) next to European numbers become numbers.
    local i = 1
    while i <= n do
        if types[i] == "ET" then
            local j = i
            while j + 1 <= n and types[j + 1] == "ET" do j = j + 1 end
            if (i > 1 and types[i - 1] == "EN") or (j < n and types[j + 1] == "EN") then
                for k = i, j do types[k] = "EN" end
            end
            i = j + 1
        else
            i = i + 1
        end
    end

    -- W6: remaining separators and terminators are neutral.
    for k = 1, n do
        local t = types[k]
        if t == "ES" or t == "ET" or t == "CS" then types[k] = "ON" end
    end

    -- W7: European numbers after Latin text are treated as Latin.
    lastStrong = sor
    for k = 1, n do
        local t = types[k]
        if t == "L" or t == "R" then
            lastStrong = t
        elseif t == "EN" and lastStrong == "L" then
            types[k] = "L"
        end
    end

    -- N1/N2: neutrals between two runs of the same direction take that
    -- direction (numbers count as R); otherwise the paragraph direction.
    local function strongDir(t)
        if t == "L" then return "L" end
        if t == "R" or t == "EN" or t == "AN" then return "R" end
        return nil
    end
    i = 1
    while i <= n do
        if isNeutral(types[i]) then
            local j = i
            while j + 1 <= n and isNeutral(types[j + 1]) do j = j + 1 end
            local before = i > 1 and strongDir(types[i - 1]) or sor
            local after = j < n and strongDir(types[j + 1]) or sor
            local dir = (before == after) and before or sor
            for k = i, j do types[k] = dir end
            i = j + 1
        else
            i = i + 1
        end
    end

    -- I1/I2: implicit levels.
    local levels = {}
    for k = 1, n do
        local t = types[k]
        if baseLevel == 0 then
            if t == "R" then
                levels[k] = 1
            elseif t == "EN" or t == "AN" then
                levels[k] = 2
            else
                levels[k] = 0
            end
        else
            if t == "L" or t == "EN" or t == "AN" then
                levels[k] = 2
            else
                levels[k] = 1
            end
        end
    end

    return levels, baseLevel, classes
end

-- Reordering ------------------------------------------------------------------------------

local MIRROR = {
    [0x28] = 0x29, [0x29] = 0x28, -- ( )
    [0x3C] = 0x3E, [0x3E] = 0x3C, -- < >
    [0x5B] = 0x5D, [0x5D] = 0x5B, -- [ ]
    [0x7B] = 0x7D, [0x7D] = 0x7B, -- { }
    [0xAB] = 0xBB, [0xBB] = 0xAB, -- « »
    [0x2039] = 0x203A, [0x203A] = 0x2039, -- ‹ ›
}

-- Returns the visual-order codepoints of cps[first..last] (one line).
function Bidi.reorderLine(cps, levels, classes, baseLevel, first, last)
    first = first or 1
    last = last or #cps
    local count = last - first + 1
    if count <= 0 then
        return {}
    end

    local lineLevels, order = {}, {}
    for k = 1, count do
        lineLevels[k] = levels[first + k - 1]
        order[k] = first + k - 1
    end

    -- L1: whitespace at the end of the line, and before tabs, goes back to
    -- the paragraph level.
    local trailing = true
    for k = count, 1, -1 do
        local c = classes[first + k - 1]
        if c == "WS" or c == "BN" then
            if trailing then lineLevels[k] = baseLevel end
        elseif c == "S" or c == "B" then
            lineLevels[k] = baseLevel
            trailing = true
        else
            trailing = false
        end
    end

    -- L2: reverse every run at or above each level, from the highest down
    -- to the lowest odd level.
    local maxLevel, minOdd = 0, math.huge
    for k = 1, count do
        local lv = lineLevels[k]
        if lv > maxLevel then maxLevel = lv end
        if lv % 2 == 1 and lv < minOdd then minOdd = lv end
    end
    if minOdd ~= math.huge then
        for lv = maxLevel, minOdd, -1 do
            local k = 1
            while k <= count do
                if lineLevels[k] >= lv then
                    local j = k
                    while j + 1 <= count and lineLevels[j + 1] >= lv do j = j + 1 end
                    local a, b = k, j
                    while a < b do
                        order[a], order[b] = order[b], order[a]
                        lineLevels[a], lineLevels[b] = lineLevels[b], lineLevels[a]
                        a, b = a + 1, b - 1
                    end
                    k = j + 1
                else
                    k = k + 1
                end
            end
        end
    end

    -- L4: mirror brackets that ended up in right-to-left runs.
    local visual = {}
    for k = 1, count do
        local src = order[k]
        local cp = cps[src]
        if levels[src] % 2 == 1 and MIRROR[cp] then
            cp = MIRROR[cp]
        end
        visual[k] = cp
    end
    return visual
end

-- Convenience: logical codepoints -> visual codepoints for a single line.
function Bidi.toVisual(cps, direction)
    local levels, baseLevel, classes = Bidi.resolveLevels(cps, direction)
    return Bidi.reorderLine(cps, levels, classes, baseLevel, 1, #cps), baseLevel
end

return Bidi
