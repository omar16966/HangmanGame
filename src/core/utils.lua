-- Small general-purpose helpers shared by every system.

local Utils = {}

function Utils.clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Rounds to the nearest integer (halves away from zero).
function Utils.round(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function Utils.sign(value)
    if value > 0 then return 1 end
    if value < 0 then return -1 end
    return 0
end

function Utils.pointInRect(px, py, x, y, w, h)
    return px >= x and px < x + w and py >= y and py < y + h
end

function Utils.deepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do
        copy[Utils.deepCopy(k, seen)] = Utils.deepCopy(v, seen)
    end
    return copy
end

-- Fills every key missing from `target` (recursively) with a copy of the value
-- from `defaults`. Values of the wrong type are replaced as well.
-- Returns `target` for convenience.
function Utils.applyDefaults(target, defaults)
    if type(target) ~= "table" then
        return Utils.deepCopy(defaults)
    end
    for key, defaultValue in pairs(defaults) do
        local current = target[key]
        if current == nil or type(current) ~= type(defaultValue) then
            target[key] = Utils.deepCopy(defaultValue)
        elseif type(defaultValue) == "table" then
            Utils.applyDefaults(current, defaultValue)
        end
    end
    return target
end

function Utils.contains(list, value)
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

function Utils.shuffle(list, random)
    random = random or love.math.random
    for i = #list, 2, -1 do
        local j = random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

-- Converts "#rrggbb" or "#rrggbbaa" to a LÖVE color table {r, g, b, a} in 0..1.
function Utils.hexColor(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = 1
    if #hex >= 8 then
        a = tonumber(hex:sub(7, 8), 16) / 255
    end
    return { r, g, b, a }
end

function Utils.fileExists(path)
    return love.filesystem.getInfo(path, "file") ~= nil
end

return Utils
