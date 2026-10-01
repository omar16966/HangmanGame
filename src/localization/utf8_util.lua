-- Minimal UTF-8 helpers in pure Lua (no LÖVE dependency, so the text
-- pipeline can be unit-tested with plain LuaJIT).

local Utf8 = {}

local floor = math.floor
local char = string.char
local byte = string.byte

-- Decodes a UTF-8 string into an array of codepoints.
-- Invalid bytes are replaced with U+FFFD instead of raising an error.
function Utf8.decode(s)
    local out = {}
    local i, n = 1, #s
    while i <= n do
        local c = byte(s, i)
        local cp, len
        if c < 0x80 then
            cp, len = c, 1
        elseif c >= 0xC2 and c < 0xE0 then
            cp, len = c - 0xC0, 2
        elseif c >= 0xE0 and c < 0xF0 then
            cp, len = c - 0xE0, 3
        elseif c >= 0xF0 and c < 0xF5 then
            cp, len = c - 0xF0, 4
        else
            cp, len = 0xFFFD, 1
        end
        if len > 1 then
            if i + len - 1 > n then
                cp, len = 0xFFFD, 1
            else
                for k = 1, len - 1 do
                    local cc = byte(s, i + k)
                    if cc < 0x80 or cc > 0xBF then
                        cp, len = 0xFFFD, 1
                        break
                    end
                    cp = cp * 64 + (cc - 0x80)
                end
            end
        end
        out[#out + 1] = cp
        i = i + len
    end
    return out
end

-- Encodes one codepoint as a UTF-8 string.
function Utf8.char(cp)
    if cp < 0x80 then
        return char(cp)
    elseif cp < 0x800 then
        return char(0xC0 + floor(cp / 64), 0x80 + cp % 64)
    elseif cp < 0x10000 then
        return char(0xE0 + floor(cp / 4096), 0x80 + floor(cp / 64) % 64, 0x80 + cp % 64)
    end
    return char(0xF0 + floor(cp / 262144), 0x80 + floor(cp / 4096) % 64,
        0x80 + floor(cp / 64) % 64, 0x80 + cp % 64)
end

-- Encodes an array of codepoints (or the range first..last of it).
function Utf8.encode(cps, first, last)
    local parts = {}
    for i = first or 1, last or #cps do
        parts[#parts + 1] = Utf8.char(cps[i])
    end
    return table.concat(parts)
end

function Utf8.len(s)
    return #Utf8.decode(s)
end

return Utf8
