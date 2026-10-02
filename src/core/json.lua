-- Small JSON encoder/decoder (own code, no third-party dependency).
--
--   local text = JSON.encode(value, { indent = 2 })
--   local value, err = JSON.decode(text)
--
-- Lua mapping:
--   object <-> table with string keys      array <-> table with keys 1..n
--   string, number, boolean as usual       null  -> nil (key omitted / array element skipped)
-- An empty Lua table is written as [] (arrays and objects are the same when empty).
-- Decoding never raises: it returns nil plus a message with line and column.
-- Data comes from player-editable files, so nesting depth and input shape
-- are checked, and a UTF-8 byte order mark at the start is ignored.
--
-- Pure Lua (no LÖVE dependency) so it can be unit-tested.

local Utf8 = require("src.localization.utf8_util")

local JSON = {}

local MAX_DEPTH = 64

-- Encoding ------------------------------------------------------------------------------------------

local ESCAPES = {
    ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
    ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t",
}

local function encodeString(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        return ESCAPES[c] or string.format("\\u%04x", c:byte())
    end) .. '"'
end

local function encodeNumber(n)
    if n ~= n or n == math.huge or n == -math.huge then
        error("cannot encode NaN or infinity", 0)
    end
    if n == math.floor(n) and math.abs(n) < 1e15 then
        return string.format("%d", n)
    end
    return string.format("%.14g", n)
end

-- Returns true and the length when t is a plain array (keys 1..n).
local function arrayLength(t)
    local n = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
            return nil
        end
        n = n + 1
    end
    for i = 1, n do
        if t[i] == nil then
            return nil
        end
    end
    return n
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do
        local kt = type(k)
        if kt ~= "string" and kt ~= "number" then
            error("cannot encode table key of type " .. kt, 0)
        end
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local encodeValue

local function isScalar(v)
    return type(v) ~= "table"
end

encodeValue = function(v, indent, level, out)
    local t = type(v)
    if t == "string" then
        out[#out + 1] = encodeString(v)
    elseif t == "number" then
        out[#out + 1] = encodeNumber(v)
    elseif t == "boolean" then
        out[#out + 1] = v and "true" or "false"
    elseif t == "table" then
        if level > MAX_DEPTH then
            error("nesting too deep", 0)
        end
        local n = arrayLength(v)
        local nl = indent and ("\n" .. string.rep(" ", indent * (level + 1))) or ""
        local nlEnd = indent and ("\n" .. string.rep(" ", indent * level)) or ""
        if n then
            if n == 0 then
                out[#out + 1] = "[]"
                return
            end
            -- Arrays of scalars stay on one line to keep the file readable.
            local inline = not indent
            if indent then
                inline = true
                for i = 1, n do
                    if not isScalar(v[i]) then inline = false break end
                end
            end
            out[#out + 1] = "["
            for i = 1, n do
                if i > 1 then out[#out + 1] = inline and (indent and ", " or ",") or "," end
                if not inline then out[#out + 1] = nl end
                encodeValue(v[i], indent, level + 1, out)
            end
            out[#out + 1] = inline and "]" or (nlEnd .. "]")
        else
            out[#out + 1] = "{"
            local first = true
            for _, k in ipairs(sortedKeys(v)) do
                if not first then out[#out + 1] = "," end
                first = false
                out[#out + 1] = nl
                out[#out + 1] = encodeString(tostring(k))
                out[#out + 1] = indent and ": " or ":"
                encodeValue(v[k], indent, level + 1, out)
            end
            out[#out + 1] = nlEnd .. "}"
        end
    else
        error("cannot encode value of type " .. t, 0)
    end
end

-- Raises an error for values that cannot be represented (functions,
-- NaN, ...). Callers that must not fail wrap this in pcall.
function JSON.encode(value, options)
    local indent = options and options.indent
    local out = {}
    encodeValue(value, indent, 0, out)
    return table.concat(out)
end

-- Decoding -----------------------------------------------------------------------------------------

local function fail(str, pos, message)
    local line, col = 1, 1
    for i = 1, math.min(pos - 1, #str) do
        if str:byte(i) == 10 then
            line, col = line + 1, 1
        else
            col = col + 1
        end
    end
    error({ json = true, message = string.format("%s at line %d, column %d", message, line, col) }, 0)
end

local function skipSpace(str, pos)
    return str:find("[^ \t\r\n]", pos) or (#str + 1)
end

local parseValue

local function parseString(str, pos)
    -- pos is at the opening quote
    local parts = {}
    local i = pos + 1
    while true do
        local s, e = str:find('["\\%c]', i)
        if not s then
            fail(str, pos, "unterminated string")
        end
        if s > i then
            parts[#parts + 1] = str:sub(i, s - 1)
        end
        local c = str:sub(s, s)
        if c == '"' then
            return table.concat(parts), s + 1
        elseif c == "\\" then
            local esc = str:sub(s + 1, s + 1)
            local simple = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
            if simple[esc] then
                parts[#parts + 1] = simple[esc]
                i = s + 2
            elseif esc == "u" then
                local hex = str:match("^%x%x%x%x", s + 2)
                if not hex then
                    fail(str, s, "invalid \\u escape")
                end
                local cp = tonumber(hex, 16)
                i = s + 6
                if cp >= 0xD800 and cp <= 0xDBFF then
                    local low = str:match("^\\u(%x%x%x%x)", i)
                    local lowCp = low and tonumber(low, 16)
                    if lowCp and lowCp >= 0xDC00 and lowCp <= 0xDFFF then
                        cp = 0x10000 + (cp - 0xD800) * 0x400 + (lowCp - 0xDC00)
                        i = i + 6
                    else
                        cp = 0xFFFD
                    end
                elseif cp >= 0xDC00 and cp <= 0xDFFF then
                    cp = 0xFFFD
                end
                parts[#parts + 1] = Utf8.char(cp)
            else
                fail(str, s, "invalid escape sequence")
            end
        else
            fail(str, s, "control character in string")
        end
    end
end

local function parseNumber(str, pos)
    local text = str:match("^-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
    local n = text and tonumber(text)
    if not n or n ~= n or n == math.huge or n == -math.huge then
        fail(str, pos, "invalid number")
    end
    return n, pos + #text
end

local function parseArray(str, pos, depth)
    local result = {}
    local i = skipSpace(str, pos + 1)
    if str:sub(i, i) == "]" then
        return result, i + 1
    end
    while true do
        local value
        value, i = parseValue(str, i, depth + 1)
        if value ~= nil then
            result[#result + 1] = value
        end
        i = skipSpace(str, i)
        local c = str:sub(i, i)
        if c == "," then
            i = skipSpace(str, i + 1)
        elseif c == "]" then
            return result, i + 1
        else
            fail(str, i, "expected ',' or ']'")
        end
    end
end

local function parseObject(str, pos, depth)
    local result = {}
    local i = skipSpace(str, pos + 1)
    if str:sub(i, i) == "}" then
        return result, i + 1
    end
    while true do
        if str:sub(i, i) ~= '"' then
            fail(str, i, "expected a string key")
        end
        local key
        key, i = parseString(str, i)
        i = skipSpace(str, i)
        if str:sub(i, i) ~= ":" then
            fail(str, i, "expected ':'")
        end
        local value
        value, i = parseValue(str, skipSpace(str, i + 1), depth + 1)
        result[key] = value
        i = skipSpace(str, i)
        local c = str:sub(i, i)
        if c == "," then
            i = skipSpace(str, i + 1)
        elseif c == "}" then
            return result, i + 1
        else
            fail(str, i, "expected ',' or '}'")
        end
    end
end

parseValue = function(str, pos, depth)
    if depth > MAX_DEPTH then
        fail(str, pos, "nesting too deep")
    end
    local c = str:sub(pos, pos)
    if c == "{" then
        return parseObject(str, pos, depth)
    elseif c == "[" then
        return parseArray(str, pos, depth)
    elseif c == '"' then
        return parseString(str, pos)
    elseif c == "-" or c:match("%d") then
        return parseNumber(str, pos)
    elseif str:sub(pos, pos + 3) == "true" then
        return true, pos + 4
    elseif str:sub(pos, pos + 4) == "false" then
        return false, pos + 5
    elseif str:sub(pos, pos + 3) == "null" then
        return nil, pos + 4
    elseif c == "" then
        fail(str, pos, "unexpected end of data")
    end
    fail(str, pos, "unexpected character '" .. c .. "'")
end

-- Returns the decoded value, or nil and an error message.
function JSON.decode(str)
    if type(str) ~= "string" then
        return nil, "not a string"
    end
    local start = 1
    if str:sub(1, 3) == "\239\187\191" then
        start = 4 -- UTF-8 byte order mark
    end
    local ok, value, pos = pcall(function()
        local v, p = parseValue(str, skipSpace(str, start), 1)
        p = skipSpace(str, p)
        if p <= #str then
            fail(str, p, "unexpected data after the value")
        end
        return v, p
    end)
    if ok then
        return value
    end
    if type(value) == "table" and value.json then
        return nil, value.message
    end
    return nil, tostring(value)
end

return JSON
